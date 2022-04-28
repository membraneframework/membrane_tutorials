# Ordering Buffer

In this chapter we will deal with the next element in our pipeline - the Ordering Buffer.
As stated in the [chapter about the system architecture](02_SystemArchitecture.md), this element is responsible for ordering the incoming packets, based on their sequence id.
Because Ordering Buffer is a filtering element, we need to specify both the input and the output pads:
###### **`lib/elements/OrderingBuffer.ex`**
```Elixir
defmodule Basic.Elements.OrderingBuffer do
  use Membrane.Filter
  alias Basic.Formats.Packet

  def_input_pad(:input, demand_unit: :buffers, caps: {Packet, type: :custom_packets})

  def_output_pad(:output, caps: {Packet, type: :custom_packets})
  ...
end
```

Note the caps specification definition there - we expect `Basic.Formats.Packet` of type `:custom_packets` to be sent on the input pad, and the same type of packets to be sent through the output pad.
In the next step let's specify how we want the state of our element to look like:
###### **`lib/elements/OrderingBuffer.ex`**
```Elixir
defmodule Basic.Elements.OrderingBuffer do
  ...
  @impl true
  def handle_init(_options) do
    {:ok,
      %{
        ordered_packets: [],
        last_sent_seq_id: 0
      }
    }
  end
  ...
end
```
If you don't remember what is the purpose of the Ordering Buffer, please refer to the [2nd chapter](02_SystemArchitecture.md).
We will need to hold a list of ordered packets, as well as a sequence id of the packet, which most recently was sent through the output pad (we need to know if there are some packets missing between the last sent packet and the first packet in our ordered list).

Handling demand is quite straightforward:
###### **`lib/elements/OrderingBuffer.ex`**
```Elixir
defmodule Basic.Elements.OrderingBuffer do
 ...
 @impl true
 def handle_demand(_ref, size, _unit, _ctx, state) do
  { {:ok, demand: {Pad.ref(:input), size} }, state}
 end
 ...
end
```

We simply send the `:demand` on the `:input` pad once we receive a demand on the `:output` pad. One packet on input corresponds to one packet on output so for each 1 unit of demand we send 1 unit of demand to the `:input` pad.

Now we can go to the main part of the Ordering Buffer implementation - the `handle_process/4` callback.
The purpose of this callback is to process the incoming buffer. It gets called once a new buffer is available and waiting to be processed.
###### **`lib/elements/OrderingBuffer.ex`**
```Elixir
defmodule Basic.Elements.OrderingBuffer do
  ...
  @impl true
  def handle_process(:input, buffer, _context, state) do
    packet = unzip_packet(buffer.payload)
    ordered_packets = [packet | state.ordered_packets] |> Enum.sort()
    state = %{state | ordered_packets: ordered_packets}
    {last_seq_id, _} = Enum.at(ordered_packets, 0)
    ...
  end

  defp unzip_packet(packet) do
    regex = ~r/^\[seq\:(?<seq_id>\d+)\](?<data>.*)$/
    %{"data" => data, "seq_id" => seq_id} = Regex.named_captures(regex, packet)
    {String.to_integer(seq_id), %Membrane.Buffer{payload: data} }
  end
  ...
end
```

First, we are taking advantage of the [Regex module](https://hexdocs.pm/elixir/1.13/Regex.html) available in the Elixir.
With the `Regex.named_captures` we can access the values of the fields defined within the regex description.
Do you remember what our packet looks like? 
```
[seq:7][frameid:2][timestamp:3]data
```
Above you can see an exemplary packet. We need to fetch the value of the sequence id (in our case it is equal to 7) and get the rest of the packet.
Therefore we have defined the regex description as:
```Elixir
~r/^\[seq\:(?<seq_id>\d+)\](?<data>.*)$/
```

> ### TIP - How to read the regex?
> + `~r/.../` stands for the `sigil_r/1` [sigil](https://elixir-lang.org/getting-started/sigils.html)
> + `^` describes the beginning of the input
> + `\[` stands for the opening square bracket ('[') at the beginning is required to escape the char since the plain '[' has a special meaning in the regex syntax
> + `seq` is a sequence of 's', 'e', 'q' characters (we need to adjust our regex description to match the header of the packet)
> + `\:` stands for the ':' character (we also need to escape that character since it is meaningful in the regex's syntax)
> + `(?<seq_id>\d+)` allows us to define a named capture - later one, once we use the `Regex.named_captures/2`, we will retrieve the map with 'seq_id' key and the corresponding value equal to the string described by the `\d+` 'partial' regex (which means - one or more occurrences of a decimal). Generally speaking, a named capture can be specified with the following structure: `(?<key>regex)` where `regex` is a regex description.
> + `\]` is the escaped closing square bracket character
> + `(?<data>.*)` is a named capture description that allows us to get the value of a `.*` regex (any character no or any number of times) under a `data` key.
> + `$` stands for the end of the input

The result of `Regex.named_captures/2` applied to that regex description and the exemplary packet should be following:
```Elixir
{"seq_id"=>7, "data"=>"[frameid:2][timestamp:3]data"}
```

Once we unzip the header of the packet in the `handle_process/4` callback, we can put the incoming packet in the `ordered_packets` list and sort that list. Due to the fact, that elements of this list are tuples, whose first element is a sequence id (a value that is unique), the list will be sorted based on the sequence id.
We also get the sequence id of the first element in the updated `ordered_packets` list.


Here comes the rest of the `handle_process/4` definition:
###### **`lib/elements/OrderingBuffer.ex`**
```Elixir
defmodule Basic.Elements.OrderingBuffer do
  ...
  def handle_process(:input, buffer, _context, state) do
  ...
    if state.last_sent_seq_id + 1 == last_seq_id do
      {reversed_ready_packets_sequence, ordered_packets} = get_ready_packets_sequence(ordered_packets, [])
      [{last_sent_seq_id, _} | _] = reversed_ready_packets_sequence

      state = %{
        state
        | ordered_packets: ordered_packets,
          last_sent_seq_id: last_sent_seq_id
      }
      buffers = Enum.reverse(reversed_ready_packets_sequence) |> Enum.map(fn {_seq_id, data} -> data end)

      { {:ok, buffer: {:output, buffers} }, state}
    else
      { {:ok, redemand: :output}, state}
    end
  end
  ...
end
```

We need to distinguish between two situations: the currently processed packet can have a sequence id which is subsequent to the sequence id of the last sent packet or there might be some packets not yet delivered to us, with sequence ids in between the last sent sequence id and the sequence id of a currently processed packet. In the second case, we should store the packet and wait for the next packets to arrive. We will accomplish that using `redemands` mechanism, which will be explained in detail in the next chapter.
However, in the first situation, we need to get the ready packet's sequence - that means, a consistent batch of packets from the `:ordered_packets`. This can be done in the following way:
###### **`lib/elements/OrderingBuffer.ex`**
```Elixir 
defmodule Basic.Elements.OrderingBuffer do
  ...
  defp get_ready_packets_sequence([], acc) do
    {acc, []}
  end

  defp get_ready_packets_sequence(
    [{first_id, _first_data} = first_seq | [{second_id, second_data} | rest]], acc)
  when first_id + 1 == second_id do
    get_ready_packets_sequence([{second_id, second_data} | rest], [first_seq | acc])
  end

  defp get_ready_packets_sequence([first_seq | rest], acc) do
    {[first_seq | acc], rest}
  end 
end
```

Note the order of the definitions, since we are taking advantage of the pattern matching mechanism!
The algorithm implemented in the snippet above is really simple - we are recursively taking the next packet out of the `:ordered_packets` buffer until it becomes empty or there is a missing packet (`first_id + 1 == second_id`) between the last taken packet and the next packet in the buffer.
Once we have a consistent batch of packets, we can update the state (both the`:ordered_packets` and the `:last_sent_seq_id` need to be updated) and output the ready packets by defining the `:buffer` action.

Test the `OrderingBuffer`:
```
mix test test/elements/ordering_buffer_test.exs
```

Now the `OrderingBuffer` element is ready. Before we implement the next element let us introduce you to the concept of redemands.