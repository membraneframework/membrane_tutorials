Here comes the mixer - an element responsible for mixing two streams of frames, coming from two different sources. 
Once again we start with defining the initialization options and the pads of both types:
```Elixir
# FILE: lib/elements/Mixer.ex

defmodule Basic.Elements.Mixer do
 @moduledoc """
 The element responsible for mixing the frames coming from two sources, based on their timestamps.
 """
 use Membrane.Filter
 alias Basic.Formats.Frame
 
 def_input_pad(:first_input, demand_unit: :buffers, caps: {Frame, encoding: :utf8})

 def_input_pad(:second_input, demand_unit: :buffers, caps: {Frame, encoding: :utf8})

 def_output_pad(:output, caps: {Frame, encoding: :utf8})
 ...
end
```

Note, that we have defined two input pads: `:first_input` and the `:second_input`. 
Each of these input pads will have a corresponding incoming track in form of a buffers stream. That is why we might need a structure that would hold the state of such a track so that we would be able to fetch the last buffer which has appeared on the track as well as a mark that no more are we expecting a buffer to show up on the given input pad. Let's do it in the following way, by defining a `Track` inside the mixer module:

```Elixir
# FILE: lib/elements/Mixer.ex

defmodule Basic.Elements.Mixer do
 ...
 defmodule Track do
 @type t :: %__MODULE__{
  buffer: Membrane.Buffer.t(),
  status: :started | :finished
 }
 defstruct buffer: nil, status: :started
 end
 ...
end
```

As you can see in the code snippet above, the `Track` will consist of the `:buffer` field, holding the very last buffer sent on the corresponding input pad, and the `:status` fields, indicating the status of the track - `:started`, in case we are still expecting some buffers to come (that means - in case `:end_of_stream` event hasn't been sent yet) and `:finished` otherwise.
It's a good practice to provide a type specification for such a custom specification since it makes the code be more easily reusable as well as can make the compiler warn us about some misspellings (for instance in the status field atoms), which cause some nasty to be spotted errors.
A careful reader might notice, that we are holding only a reference to only one buffer for each track, instead of a list of all the potentially unprocessed buffers - does it mean that we are losing some of them? Not at all, since we are taking advantage of the elements which have appeared earlier in the pipeline and which provide us an ordered list of frames on each of the inputs - however, we will need to process each buffer just at the moment it comes on the pad.

The logic we gonna implement can be described in the following three steps:
+ If all the tracks are in the 'active' state ('active' means - the ones in the `:started` state or the ones in the `:finished` state but with an unprocessed buffer in the `Track` structure) - output the one with the lower timestamp. Otherwise do nothing.
+ If all the tracks are in the `:finished` state and their `:buffer` is empty - send the `:end_of_stream` event.
+ For all the tracks which are in the `:started` state and their buffer is empty - demand on the pad corresponding to that track.

The next step in our element implementation is quite an obvious one:
```Elixir
# FILE: lib/elements/Mixer.ex

defmodule Basic.Elements.Mixer do
 ...
 @impl true
 def handle_init(_options) do
  {:ok,
  %{
    tracks: %{first_input: %Track{}, second_input: %Track{}}
  }}
 end
 ...
end
```
We have provided an `handle_init/1` callback, which does not expect any options to be passed. We are simply setting up the structure of the element state.
As mentioned previously, we will have a `Track` structure for each of the input pads.
Following on the callbacks implementation, let's continue with `handle_process/4` implementation:
```Elixir
# FILE: lib/elements/Mixer.ex

defmodule Basic.Elements.Mixer do
 ...
 @impl true
 def handle_process(pad, buffer, _context, state) do
  tracks =
    Map.update!(state.tracks, pad, fn track ->
      %Track{track | buffer: buffer}
    end)

  state = %{state | tracks: tracks}
  {{:ok, [{:redemand, :output}]}, state}
 end
 ...
end
```
What we do is that we are simply putting the incoming `buffer` into the `Track` structure for the given pad. Note, that we have to be sure that we are not losing any information which is in the `Track`'s buffer before the update. In case there is a buffer on a given `Track`, it has to be processed before another buffer comes. Why can we be sure of that in our implementation? That's because we will be returning the `:redemand` action. As you might remember from the chapter about the redemands, all the actions returned from the element's callback are taken immediately after the callback returns - that means, they are taken before any other incoming event is served. If we would have put the whole logic of processing the buffer into the `handle_demand/5` callback, we could simply call that callback with the `:redemand` action and be sure that the newly added buffer will be immediately processed before any other buffer comes (that means - before the other `handle_process/4` callback gets called).
Such an approach is powerful since we can also use it in other callback - `handle_end_of_stream/3`, which get's called once the `:end_of_stream` event comes on the given pad.
```Elixir
# FILE: lib/elements/Mixer.ex

defmodule Basic.Elements.Mixer do
 ...
 @impl true
 def handle_end_of_stream(pad, _context, state) do
  tracks =
    Map.update!(state.tracks, pad, fn track ->
      %Track{track | status: :finished}
    end)

  state = %{state | tracks: tracks}
  {{:ok, [{:redemand, :output}]}, state}
 end
 ...
end
```

What we did here was similar to the logic defined in the `handle_process/4` - we have just updated the state of the track (in that case - by setting its status as `:finished`) and then we called the `handle_demand/5` callback using the `:redemand` actions. The `handle_demand/5` will take care of the fact that the track state has changed.
There is nothing left to do apart from defining the `handle_demand/5` itself!
```Elixir
# FILE: lib/elements/Mixer.ex

defmodule Basic.Elements.Mixer do
 ...
 @impl true
 def handle_demand(:output, size, _unit, ctx, state) when size > 0 do
  {state, actions} = update_state_and_prepare_actions(state, ctx.pads)
  {{:ok, actions}, state}
 end

 @impl true
 def handle_demand(_ref, _size, _unit, _ctx, state), do: {state, []}
 ...
end
```

We have split that definition into two parts, depending on the demand size. If the demand size is greater than 0, we are calling the `update_state_and_prepare_actions/2` function (to which we have delegated the whole logic concerning the tracks processing). Otherwise, we do nothing.
```Elixir
# FILE: lib/elements/Mixer.ex

defmodule Basic.Elements.Mixer do
 ...
 defp update_state_and_prepare_actions(state, pads) do
  {state, buffer_actions} = output_buffers(state)
  {state, end_of_stream_actions} = send_end_of_stream(state)
  {state, demand_actions} = demand_on_empty_tracks(state, pads)

  actions = buffer_actions ++ end_of_stream_actions ++ demand_actions
  {state, actions}
 end
 ...
end
```

The private function `update_state_and_prepare_actions/2` is defined as described in the steps' list above - it aggregates the actions taken in order to:
+ output the ready buffers
+ send `:end_of_stream` notification if necessary
+ demand on empty tracks

Each of these steps has a corresponding private function.
```Elixir
# FILE: lib/elements/Mixer.ex

defmodule Basic.Elements.Mixer do
 ...
 defp output_buffers(state) do
  {buffers, tracks} = prepare_buffers(state.tracks)
  state = %{state | tracks: tracks}
  buffer_actions = Enum.map(buffers, fn buffer -> {:buffer, {:output, buffer}} end)
  {state, buffer_actions}
 end

 defp prepare_buffers(tracks) do
  active_tracks =
    tracks
    |> Enum.reject(fn {_track_id, track} ->
      track.status == :finished and track.buffer == nil
    end)
    |> Map.new()

  if active_tracks != %{} and
    Enum.all?(active_tracks, fn {_, track} -> track.buffer != nil end) do
      {track_id, track} =
        active_tracks
    |> Enum.min_by(fn {_track_id, track} -> track.buffer.pts end)

  buffer = track.buffer
  tracks = Map.put(tracks, track_id, %Track{track | buffer: nil})
  {buffers, tracks} = prepare_buffers(tracks)
  {[buffer | buffers], tracks}
  else
    {[], tracks}
  end
 end
 ...
end
```

In order to output the buffers, we need to fetch the desired buffers - that is what we do with the `prepare_buffers/1` function. Later on, we are simply creating the `:buffer` action, basing on the list of buffers to be output. 
In the `prepare_bufers/1` we get all the active tracks (by 'active' we mean that there is still an unprocessed buffer in the `Track` structure - independent of the status of that track). If all the active tracks have the buffers we can output the one with the lowest presentation timestamp and recursively call the `prepare_buffers/1` (in case there are some buffers that still need to be output - this can happen in a 'corner case' of processing the buffer from the track in the `:finished` state). Surely, we also need to update the state so that to remove the processed buffers.
Now let's focus on preparing `:end_of_stream` action:
```Elixir
# FILE: lib/elements/Mixer.ex

defmodule Basic.Elements.Mixer do
 ...
 defp send_end_of_stream(state) do
  end_of_stream_actions =
    if Enum.all?(state.tracks, fn {_, track} -> track.status == :finished end) do
      [end_of_stream: :output]
    else
      []
    end
 {state, end_of_stream_actions}
 end
 ...
end
```
This action needs to be sent if both the tracks are in the `:finished` state - since the `send_end_of_stream/1` function gets called after the `output_buffers/1`, we can be sure, that all the buffers which could possibly be on those tracks, despite they are in the `:finished` state, are already processed.
```Elixir
# FILE: lib/elements/Mixer.ex

defmodule Basic.Elements.Mixer do
 ...
 defp demand_on_empty_tracks(state, pads) do
  actions =
    state.tracks
    |> Enum.filter(fn {track_id, track} ->
      track.status != :finished and track.buffer == nil and pads[track_id].demand == 0
    end)
    |> Enum.map(fn {track_id, _} -> {:demand, {Pad.ref(track_id), 1}} end)

  {state, actions}
 end
 ...
end
```
The last type of actions we need to generate are`:demand` actions. From the [context](https://hexdocs.pm/membrane_core/Membrane.Element.CallbackContext.Demand.html#t:t/0) passed as one of the arguments in the `handle_demand/5` callback, we have passed the `context.pads`.
That is how we can fetch the information about the current demand size on the given pad.
For all the tracks which are not yet `:finished`, do not have the buffer and the demand was not made on behalf of that pad (there is where we are making usage of the context information - `pads[track_id].demand==0`), we are making such a demand for one buffer.

Starting from that moment, our mixer should be capable of mixing the inputs from two sources! In the later part of this tutorial, we will extend the mixer so that it will be able to mix any number of tracks.

