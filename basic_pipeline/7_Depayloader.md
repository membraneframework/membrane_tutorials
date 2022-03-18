Since we have packets put in order by the Ordering Buffer, we can assemble them into the original frames.
The Depayloader is an element responsible for this task. Specifically speaking, it unpacks the payload from the packets -
and that is why it's called 'depayloader'.
Let's create a new module in the `lib/elements/Depayloader.ex` file:
```Elixir
# FILE: lib/elements/Depayloader.ex

defmodule Basic.Elements.Depayloader do
 alias Basic.Formats.{Packet, Frame}
 ...
end
```

What input data do we expect? Of course in `Basic.Format.Packet` format!
```Elixir
# FILE: lib/elements/Depayloader.ex

defmodule Basic.Elements.Depayloader do
 def_input_pad(:input, demand_unit: :buffers, caps: {Packet, type: :custom_packets})
 ...
end
```

However, our element will process that input data in a way that will change the format - on output, there will be frames instead of packets!
We need to specify it while defining the `:output` pad:
```Elixir
# FILE: lib/elements/Depayloader.ex

defmodule Basic.Elements.Depayloader do
 ...
 def_output_pad(:output, caps: {Frame, encoding: :utf8})
 ...
end
```

We will also need a parameter describing how many packets should we request once we receive a demand for a frame:
```Elixir
# FILE: lib/elements/Depayloader.ex

defmodule Basic.Elements.Depayloader do
 ...
 def_options(
    packets_per_frame: [
    type: :integer,
    spec: pos_integer,
    description:
    "Positive integer, describing how many packets form a single frame. Used to demand the proper number of packets while assembling the frame."
    ]
 )
 ...
end
```

In the `handle_init/1` callback we are simply saving the value of that parameter in the state of our element:
```Elixir
# FILE: lib/elements/Depayloader.ex

@impl true
def handle_init(options) do
{:ok,
 %{
    frame: [],
    packets_per_frame: options.packets_per_frame
 }}
end
```
Within the state, we will also hold a (potentially not complete) `:frame` - a list of packets, which form a particular frame. We will aggregate the packets in the `:frame` until the moment the frame is complete.

As noted in the [chapter dedicated to the caps](4_Caps.md), since we are changing the type of data within the element, we cannot rely on the default implementation of the `handle_caps/4` callback. We need to explicitly send the updated version of caps:
```Elixir
# FILE: lib/elements/Depayloader.ex

@impl true
def handle_caps(_pad, _caps, _context, state) do
 caps = %Frame{encoding: :utf8}
 {{:ok, caps: {:output, caps}}, state}
end
```

As in most elements, the `handle_demand/5` implementation is quite easy - what we do is simply to make a demand on our `:input` pad once we receive a demand on the `:output` pad. However, since we are expected to produce a frame (which is formed from a particular number of packets) on the `:output` pad, we need to request a particular number of packets on the `:input` pad - that is why we have defined the `:packets_per_frame` option and now we will be making usage of it. In case we would have been asked to produce 10 frames, and each frame would have been made out of 5 packets, then we would need to ask for 10\*5 = 50 packets on the `:input`.
```Elixir
# FILE: lib/elements/Depayloader.ex

@impl true
def handle_demand(_ref, size, _unit, _ctx, state) do
 {{:ok, demand: {Pad.ref(:input), size * state.packets_per_frame}}, state}
end
```

There is nothing left apart from processing the input data - that is - the packets. Since the packets are coming in order, we can simply hold them in the `:frame` list up until the moment all the packets forming that frame will be there. As you might or might not remember, each packet has a frame id in its header, which can be followed by a 'b' or 'e' character, indicating the type of the packet (the one begging a frame or the one ending the frame). We will use information about the type to find a moment in which we should produce a frame out of the packets list.
```Elixir
# FILE: lib/elements/Depayloader.ex

@impl true
def handle_process(_ref, buffer, _ctx, state) do
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
```Elixir
# FILE: lib/elements/Depayloader.ex

@impl true
def handle_process(_ref, buffer, _ctx, state) do
 ...
case type do
   "e" ->
      frame = prepare_frame(frame)
      state = Map.put(state, :frame, [])
      buffer = %Membrane.Buffer{payload: frame, pts: String.to_integer(timestamp)}
      {{:ok, [buffer: {:output, buffer}]}, state}

   _ ->
      state = Map.put(state, :frame, frame)
      {:ok, state}
   end
end
```

Now, depending on the type of frame, we perform different actions. 
If we have the 'ending' packet, we are making the `:buffer` action with the frame made out of the packets (that's where `prepare_frame/1` function comes in handy), and clear the `:frame` buffer. Here is how can the `prepare_frame/1` function be implemented:
```Elixir
# FILE: lib/elements/Depayloader.ex

defp prepare_frame(frame) do
   frame |> Enum.reverse() |> Enum.join("")
end
```

Otherwise, if the packet is not of the 'ending' type (that is - it can be both the 'beginning' frame or some packet in the middle), we are simply updating the state with the processed packet added to the `:frame` buffer. The last thing we do is to redemand.

With the `Source`, `OrderingBuffer` and `Depayloader` elements ready we are able to read packets from file, order them chronologically and assemble them back into frames.
In the next chapter we will be dealing with `Mixer` which will merge two message streams in order to create complete conversation.