# Mixer

Here comes the mixer - an [element](../glossary/glossary.md#element) responsible for mixing two streams of [frames](../glossary/glossary.md#frame), coming from two different sources.
Once again we start with defining the initialization options and the pads of both types:

**_`lib/elements/mixer.ex`_**

```elixir
defmodule Basic.Elements.Mixer do
  @moduledoc """
  Element responsible for mixing the frames coming from two sources, basing on their timestamps.
  """
  use Membrane.Filter
  alias Basic.Formats.Frame

  def_input_pad :first_input,
    flow_control: :manual,
    demand_unit: :buffers,
    accepted_format: %Frame{encoding: :utf8}

  def_input_pad :second_input,
    flow_control: :manual,
    demand_unit: :buffers,
    accepted_format: %Frame{encoding: :utf8}

  def_output_pad :output,
    flow_control: :manual,
    accepted_format: %Frame{encoding: :utf8}
 ...
end
```

Note, that we have defined two input [pads](../glossary/glossary.md#pad): `:first_input` and the `:second_input`.
Each of these input pads will have a corresponding incoming [track](../glossary/glossary.md#track) in form of a [buffers](../glossary/glossary.md#buffer) stream. We need a structure that will hold the state of the track. Let's create it by defining a `Track` inside the mixer module:

**_`lib/elements/mixer.ex`_**

```elixir
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

As you can see in the code snippet above, the `Track` will consist of the `:buffer` field, holding the very last buffer received on the corresponding input pad, and the `:status` fields, indicating the status of the track - `:started`, in case we are still expecting some buffers to come (that means - in case `:end_of_stream` event hasn't been received yet) and `:finished` otherwise. 

It's a good practice to provide a type specification for such a custom struct since it makes the code easier to reuse and lets the compiler warn us about some misspellings (for instance in the status field atoms), which cause some hard to spot errors. 

A careful reader might notice, that we are holding only one buffer for each track, instead of a list of all the potentially unprocessed buffers - does it mean that we are losing some of them? Not at all, since we are taking advantage of the elements which have appeared earlier in the [pipeline](../glossary/glossary.md#pipeline) and which provide us with an ordered list of frames on each of the inputs - however, we will need to process each buffer just at the moment it comes on the pad.

The logic we're going to implement can be described in the following three steps:

- If all the tracks are in the 'active' state ('active' means - the ones in the `:started` state or the ones in the `:finished` state but with an unprocessed buffer in the `Track` structure) - output the one with the lower timestamp. Otherwise do nothing.
- If all the tracks are in the `:finished` state and their `:buffer` is empty - send the `:end_of_stream` event.
- For all the tracks which are in the `:started` state and their buffer is empty - demand on the pad corresponding to that track.

The next step in our element implementation is quite an obvious one:

**_`lib/elements/mixer.ex`_**

```elixir
defmodule Basic.Elements.Mixer do
 ...
  @impl true
  def handle_init(_context, _options) do
    {[],
     %{
       tracks: %{first_input: %Track{}, second_input: %Track{}}
     }}
  end
 ...
end
```

We have provided a `handle_init/2` callback, which does not expect any options to be passed. We are simply setting up the structure of the element state.
As mentioned previously, we will have a `Track` structure for each of the input pads. 

What's interesting is this is where the mixer having exactly two inputs stops being important. The missing functionality can be defined generically without much hassle. 

Following on the callbacks implementation, let's continue with the `handle_buffer/4` implementation:

**_`lib/elements/mixer.ex`_**

```elixir
defmodule Basic.Elements.Mixer do
 ...
  @impl true
  def handle_buffer(pad, buffer, _context, state) do
    tracks = Map.update!(state.tracks, pad, &%Track{&1 | buffer: buffer})
    {tracks, buffer_actions} = get_output_buffers_actions(tracks)
    state = %{state | tracks: tracks}

    {buffer_actions ++ [redemand: :output], state}
  end
 ...
end
```

In this callback we update the mixer's state by assigning the incoming buffer to its track. We can be sure no overwriting of an existing buffer happens, which will become more apparent as we delve further into the logic's implementation. 

Once the state is updated we gather all buffers that can be sent (might be none) in `get_output_buffers_actions/1` and return the coresponding `buffer` actions. In case any demands should be sent afterwards we also tell the output pad to redemand.

**_`lib/elements/mixer.ex`_**

```elixir
defmodule Basic.Elements.Mixer do
 ...
  @impl true
  def handle_end_of_stream(pad, _context, state) do
    tracks = Map.update!(state.tracks, pad, &%Track{&1 | status: :finished})
    {tracks, buffer_actions} = get_output_buffers_actions(tracks)
    state = %{state | tracks: tracks}

    if Enum.all?(tracks, fn {track_id, track} ->
         track.status == :finished and not has_buffer?({track_id, track})
       end) do
      {buffer_actions ++ [end_of_stream: :output], state}
    else
      {buffer_actions ++ [redemand: :output], state}
    end
  end
 ...
end
```

What we did here was similar to the logic defined in `handle_buffer/4` - we have just updated the state of the track (in that case - by setting its status to `:finished`), gather the buffers and send them. The important difference is that in case all inputs have closed, we should forward an `end_of_stream` action instead of a `redemand`, signaling the mixer has finished its processing. 

Let's now implement gathering ready buffers:

**_`lib/elements/mixer.ex`_**

```elixir
defmodule Basic.Elements.Mixer do
 ...
  defp has_buffer?({_track_id, track}),
    do: track.buffer != nil

  defp can_send_buffer?(tracks) do
    started_tracks =
      Enum.filter(
        tracks,
        fn {_track_id, track} -> track.status != :finished end
      )

    (started_tracks == [] and Enum.any?(tracks, &has_buffer?/1)) or
      (started_tracks != [] and Enum.all?(started_tracks, &has_buffer?/1))
  end

  defp get_output_buffers_actions(tracks) do
    {buffers, tracks} = prepare_buffers(tracks)
    buffer_actions = Enum.map(buffers, fn buffer -> {:buffer, {:output, buffer}} end)
    {tracks, buffer_actions}
  end

  defp prepare_buffers(tracks) do
    if can_send_buffer?(tracks) do
      {next_track_id, next_track} =
        tracks
        |> Enum.filter(&has_buffer?/1)
        |> Enum.min_by(fn {_track_id, track} -> track.buffer.pts end)

      tracks = Map.put(tracks, next_track_id, %Track{next_track | buffer: nil})
      {buffers, tracks} = prepare_buffers(tracks)
      {[next_track.buffer | buffers], tracks}
    else
      {[], tracks}
    end
  end
end
```

The `prepare_buffers/1` function is the most involved here, so let's start with that. We first check whether we can send a buffer at all. The next buffer to send in order will of course be one with lowest `.pts`. We then empty the corresponding track's buffer. There might be more than one buffer ready to send and so we iterate the gathering recursively. 

We define `can_send_buffer?` as follows. If there's any `:started` track still waiting on a buffer we cannot send more, since whatever buffers the mixer's currently holding might come after the one that's yet to be received on this track. 

Otherwise, if all tracks have finished it can still be the case that some have non-empty buffers. We can happily send all of these in order since it is guaranteed there is no buffer preceding them that we would have to wait for.

All that's left now is to handle redemands.

**_`lib/elements/mixer.ex`_**

```elixir
defmodule Basic.Elements.Mixer do
 ...
  def handle_demand(:output, _size, _unit, context, state) do
    demand_actions =
      state.tracks
      |> Enum.reject(&has_buffer?/1)
      |> Enum.filter(fn {track_id, track} ->
        track.status != :finished and context.pads[track_id].demand == 0
      end)
      |> Enum.map(fn {track_id, _track} -> {:demand, {track_id, 1}} end)

    {demand_actions, state}
  end
 ...
end
```

Since it should be responsible for producing and sending `demand` actions to the corresponding input pads, we accordingly filter tracks for ones that are empty, started, and with no demands pending. 
It should also become clearer why in `handle_buffer/4` the receiving track is sure to have an empty buffer ready to be overwritten, since we only send demands to input pads of empty tracks.

And that's all! the mixer's ready to mix, and ready to be tested:

```console
mix test test/elements/mixer_test.exs
```

Now all that's left to do is to save our stream to file using [`Sink`](../glossary/glossary.md#sink).
