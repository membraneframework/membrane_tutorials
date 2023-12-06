# Depayloader
Since we have [packets](../glossary/glossary.md#packet) put in order by the [Ordering Buffer](../basic_pipeline/06_OrderingBuffer.md), we can assemble them into the original [frames](../glossary/glossary.md#frame).
The Depayloader is an element responsible for this task. Specifically speaking, it unpacks the payload from the packets -
and that is why it's called 'depayloader'.
Let's create a new module in the `lib/elements/depayloader.ex` file:

**_`lib/elements/depayloader.ex`_**

```elixir
defmodule Basic.Elements.Depayloader do
 use Membrane.Filter

 alias Basic.Formats.{Packet, Frame}
 ...
end
```

What input data do we expect? Of course in `Basic.Format.Packet` format!

**_`lib/elements/depayloader.ex`_**

```elixir
defmodule Basic.Elements.Depayloader do
 ...
  def_input_pad :input,
    flow_control: :manual,
    demand_unit: :buffers,
    accepted_format: %Packet{type: :custom_packets}
 ...
end
```

However, our element will process that input data in a way that will change the format - on output, there will be frames instead of packets!
We need to specify it while defining the `:output` pad:

**_`lib/elements/depayloader.ex`_**

```elixir
defmodule Basic.Elements.Depayloader do
 ...
  def_output_pad :output,
    flow_control: :manual,
    accepted_format: %Frame{encoding: :utf8}
 ...
end
```

We will also need a parameter describing how many packets should we request once we receive a demand for a frame:

**_`lib/elements/depayloader.ex`_**

```elixir
defmodule Basic.Elements.Depayloader do
 ...
  def_options packets_per_frame: [
                spec: pos_integer,
                description:
                  "Positive integer, describing how many packets form a single frame. Used to demand the proper number of packets while assembling the frame."
              ]
 ...
end
```

In the `handle_init/2` callback we are simply saving the value of that parameter in the state of our element:

**_`lib/elements/depayloader.ex`_**

```elixir
defmodule Basic.Elements.Depayloader do
 ...
  @impl true
  def handle_init(_context, options) do
    {[],
     %{
       frame: [],
       packets_per_frame: options.packets_per_frame
     }}
  end
 ...
end
```

Within the state, we will also hold a (potentially not complete) `:frame` - a list of packets, which form a particular frame. We will aggregate the packets in the `:frame` until the moment the frame is complete.

As noted in the [chapter dedicated to stream formats](04_StreamFormat.md), since we are changing the type of data within the element, we cannot rely on the default implementation of the `handle_stream_format/4` callback. We need to explicitly send the updated version of the format:

**_`lib/elements/depayloader.ex`_**

```elixir
defmodule Basic.Elements.Depayloader do
 ...
  @impl true
  def handle_stream_format(:input, _stream_format, _context, state) do
    {[stream_format: {:output, %Frame{encoding: :utf8}}], state}
  end
 ...
end
```

As in most elements, the `handle_demand/5` implementation is quite easy - what we do is simply make a demand on our `:input` pad once we receive a demand on the `:output` pad. However, since we are expected to produce a frame (which is formed from a particular number of packets) on the `:output` pad, we need to request a particular number of packets on the `:input` pad - that is why we have defined the `:packets_per_frame` option and now we will be making use of it. In case we would have been asked to produce 10 frames, and each frame would have been made out of 5 packets, then we would need to ask for 10\*5 = 50 packets on the `:input`.

**_`lib/elements/depayloader.ex`_**

```elixir
defmodule Basic.Elements.Depayloader do
 ...
  @impl true
  def handle_demand(:output, size, :buffers, _context, state) do
    {[demand: {:input, size * state.packets_per_frame}], state}
  end
 ...
end
```

There is nothing left apart from processing the input data - that is - the packets. Since the packets are coming in order, we can simply hold them in the `:frame` list until all the packets forming that frame will be there. As you might remember, each packet has a frame id in its header, which can be followed by a 'b' or 'e' character, indicating the type of the packet (the one beginning a frame or the one ending the frame). We will use information about the type to find a moment in which we should produce a frame out of the packets list.

**_`lib/elements/depayloader.ex`_**

```elixir
defmodule Basic.Elements.Depayloader do
 ...
  @impl true
  def handle_buffer(:input, buffer, _context, state) do
    packet = buffer.payload

    regex =
      ~r/^\[frameid\:(?<frame_id>\d+(?<type>[s|e]*))\]\[timestamp\:(?<timestamp>\d+)\](?<data>.*)$/

    %{"data" => data, "frame_id" => _frame_id, "type" => type, "timestamp" => timestamp} =
      Regex.named_captures(regex, packet)

    frame = [data | state.frame]
 ...
end
```

Once again we are taking advantage of the `Regex.named_captures`.
Once we fetch the interesting values of the header's parameters, we can update the `:frame`.

**_`lib/elements/depayloader.ex`_**

```elixir
defmodule Basic.Elements.Depayloader do
 ...
  @impl true
  def handle_buffer(:input, buffer, _context, state) do
   ...
    if type == "e" do
      buffer = %Membrane.Buffer{
        payload: prepare_frame(frame),
        pts: String.to_integer(timestamp)
      }

      {[buffer: {:output, buffer}], %{state | frame: []}}
    else
      {[], %{state | frame: frame}}
    end
 ...
end
```

Now, depending on the type of frame, we perform different actions.
If we have the 'ending' packet, we are making the `:buffer` action with the frame made out of the packets (that's where `prepare_frame/1` function comes in handy), and clear the `:frame` buffer. Here is how the `prepare_frame/1` function can be implemented:

**_`lib/elements/depayloader.ex`_**

```elixir
defmodule Basic.Elements.Depayloader do
 ...
  defp prepare_frame(frame) do
    frame |> Enum.reverse() |> Enum.join("")
  end
 ...
end
```

Otherwise, if the packet is not of the 'ending' type (that is - it can be both the 'beginning' frame or some packet in the middle), we are simply updating the state with the processed packet added to the `:frame` buffer and redemanding packet.

Test the `Depayloader`:

```console
mix test test/elements/depayloader_test.exs
```

With the [`Source`](../glossary/glossary.md#source), [`OrderingBuffer`](../glossary/glossary.md#jitter-buffer--ordering-buffer) and [`Depayloader`](../glossary/glossary.md#payloader-and-depayloader) elements ready we are able to read packets from file, order them based on their sequence ID and assemble them back into frames.
In the next chapter we will be dealing with the [`Mixer`](../glossary/glossary.md#mixer) which will merge two message streams in order to create complete conversation.
