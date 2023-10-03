# Bins

Bins, similarly to pipelines, are containers for elements. However, at the same time, they can be placed and linked within pipelines. Although a bin is a separate Membrane entity, it can be perceived as a pipeline within an element. Bins can also be nested within one another, though we don't recommend too much nesting, as it may end up hard to maintain.

To see how to create a simple bin, we can encapsulate a part of our pipeline into one:

```elixir
defmodule PlayMP3Bin do
  use Membrane.Bin

  alias Membrane.{MPEGAudio, RemoteStream}

  def_input_pad :input, accepted_format: any_of(RemoteStream, MPEGAudio)

  @impl true
  def handle_init(_ctx, _options) do
    spec =
      bin_input()
      |> child(Membrane.MP3.MAD.Decoder)
      |> child(Membrane.PortAudio.Sink)

    {[spec: spec], %{}}
  end
end
```

Our new bin decodes an MP3 coming from an input pad plays it out using PortAudio.

Firstly, we define an `input` pad. Bin's pads are defined and linked similarly to element's pads. However, their role is limited to proxy the stream to other elements and bins inside (inputs) or outside (outputs). To achieve that, each input pad of a bin needs to be linked to both an output pad from the outside of a bin and an input pad of its child inside. Accordingly, each bin's output should be linked to output inside and input outside of the bin.

In our case, we need to receive the stream from the element linked to the bin's input externally and forward it to the decoder's input. To do that, we use the [bin_input](https://hexdocs.pm/membrane_core/Membrane.ChildrenSpec.html#bin_input/1) function and pipe it to the decoder definition. If we wanted to forward the stream to the outside of the bin, we would pipe to the [bin_output](https://hexdocs.pm/membrane_core/Membrane.ChildrenSpec.html#bin_output/2). Just like elements, bins can have multiple pads, both static and dynamic. You'll learn more about pads in the `Pads and linking` chapter.

Let's refactor the initial pipeline to use our bin. To do that, we will use it instead of `Membrane.MP3.MAD.Decoder` and `Membrane.PortAudio.Sink`.

```elixir
@impl true
def handle_init(_ctx, mp3_url) do
  spec =
    child(%Membrane.Hackney.Source{
      location: mp3_url, hackney_opts: [follow_redirect: true]
    })
    |> child(PlayMP3Bin)

  {[spec: spec], %{}}
end
```

This simple example shows how to create a bin, but, as you can see, it didn't simplify the pipeline much. Also, it's no longer possible to plug the `VolumeKnob` element, as we did in the previous chapter, unless we modify the bin. Still, such simple and small bins can be good convenience tools for common elements' sequences. If such a bin happens to be too limiting, the user can always fall back to specifying particular elements by hand.

That said, bins come in most useful when they encapsulate more complex logic, for example, dynamically spawning elements on demand. The more of it is hidden in a bin, the more powerful yet simple pipelines we can create. Also, if you put a bin in a [crash group](https://hexdocs.pm/membrane_core/Membrane.ChildrenSpec.html#module-crash-groups), it won't crash the entire pipeline in case of an error.

For more examples of bins, have a look at the [RTMP source bin](https://github.com/membraneframework/membrane_rtmp_plugin/blob/master/lib/membrane_rtmp_plugin/rtmp/source/bin.ex) or [HTTP adaptive stream sink bin](https://github.com/membraneframework/membrane_http_adaptive_stream_plugin/blob/master/lib/membrane_http_adaptive_stream/sink_bin.ex).

## Bin and the stream

Although the bin's pads define where the data should flow, it's always sent directly from element to element and never reaches the bin itself. Thus, callbacks such as `handle_process` or `handle_event` are not found there. This is because the responsibility of the bin is to manage its children, not to process the stream. Whatever the bin needs to know about the stream, it should get through notifications from the children. It also means that bins themselves don't introduce any overhead to the stream processing.

## Bin as a black box

Bins are designed to take as much responsibility for their children as possible so that pipelines (or parent bins) don't have to depend on bins' internals. That's why notifications from the children are sent to their direct parents only. Also, messages received by a bin or pipeline can be forwarded only to its direct children.
