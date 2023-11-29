# Stream format

We owe you something...and we would like to pay it back as soon as possible!
As promised in the [3rd chapter](03_Source.md), we will talk more about the concept of stream formats - which in fact we have used in the previous chapter, but which weren't described sufficiently.

## Why formats are important

Specifying stream formats allows us to define what kind of data is flowing through the [pad](../glossary/glossary.md#pad). 
This isn't necessarily limited to data formats, as you'll see below.
In the Membrane Framework's nomenclature, we say, that we define a stream format specification for a given [element](../glossary/glossary.md#element).

We believe that an example might speak here louder than a plain definition, so we will try to describe it with a real-life scenario example.
Let's say that we are connecting two elements that process the video multimedia.
The link is made between the pads which are working on raw video data.
Here is where stream formats come up - they can be defined with the following constraints:

- data format - in our case, we are having a raw video format
- some additional constraints - i.e. [frame](../glossary/glossary.md#frame) resolution (480p) , framerate (30 fps) etc.

The `:stream_format` action helps us find out if the given elements are capable to communicate with each other. Not only can we not send the data between the pads if the format they are expecting is different - we need to take into consideration some other constraints! We can think of a situation in which the _data format_ would be the same (i.e. raw video data), but the element which receives the data performs a much more complex computation on that data than the sender, and therefore cannot digest such a great amount of data as the sender is capable of transmitting. Then their stream formats wouldn't be compatible, which could be expressed by adding some constraint, i.e. framerate.

Stream formats help us define a contract between elements and prevent us from connecting incompatible elements. That is why it is always better to define precise constraints rather than using `stream_format: :any`.

## When are stream formats compatible?

A comparison between formats is made when an input pad receives the `stream_format` action, and checks whether it matches its [accepted format](https://hexdocs.pm/membrane_core/Membrane.Pad.html#t:accepted_format/0).
Here is how you define a stream format specification:

1. First you need to specify the format module

```elixir
defmodule Formats.Raw do
  defstruct [:pixel_format, :framerate, :width, :height]
end
```

Module name defines the type of the format, however it is possible to pass some other options in a form of a struct. That is why we have defined a structure with the use of `defstruct`. Our format will be described with the following options:

- :pixel_format - pixel format, i.e. [I420](https://en.wikipedia.org/wiki/Chroma_subsampling) ([YUV](https://en.wikipedia.org/wiki/YUV)) or RGB888
- :framerate - number of frames per second, i.e. 30 (FPS)
- :width - width of the picture in pixels, i.e. 480 (px)
- :height - height of the picture in pixels, i.e. 300 (px)

2. We specify the pad of the element with the format we have just defined, using the `:accepted_format` option. For the purpose of an example, let it be the `:input` pad:

```elixir
def_input_pad(:input,
  demand_unit: :buffers,
  accepted_format: [
     {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 480, height: 300},
     {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 720, height: 480}
  ]
)
```

As you can see, we pass a list of compatible formats, each described with the tuple, consisting of our module name, and the keywords list fulfilling the
structure defined in that module. For the format's options, we can use the `range/2` or `one_of/1` specifier, which will modify the way in which the comparison between the accepted specification and the actual format received by the element is performed.

3. Once the `:stream_format` event comes to the element's pad, the format description sent in that event is confronted with each of the formats in the specification list of the pad. If the event's format description matches even one of the formats present in the list it means that they are matching.

- We have used `framerate: range(30, 60)`, so will accept the framerate value in the given interval, between 30 and 60 FPS.
- We have also used `pixel_format: one_of([:I420, :I422]`, and that will accept formats, whose pixel format is either I420 or I422
- We have used a plain value to specify the `width` and the `height` of a picture - the format will match if that option will be equal to the value passed in the specification

4. As noted previously, one can specify the format as `:any`. Such a specification will match all the formats sent on the pad, however, it is not a recommended way to develop the element - formats are there for a reason!

Our journey with stream formats does not end here. We know how to describe their specification...but we also need to make our elements send the `:stream_format` events so that the following elements will be aware of what type of data our element is producing!

An element can send a stream format as one of the [actions](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html) it can take - the [`:stream_format` action](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:stream_format/0).

Another thing is that we can specify the behavior of an element when it receives the stream format with the use of [`handle_stream_format/4` callback](https://hexdocs.pm/membrane_core/Membrane.Element.WithInputPads.html#c:handle_stream_format/4).

For all the [filter elements](../glossary/glossary.md#filter), `handle_stream_format/4` has a default implementation, which is relaying the received format on all the output pads of that filter.
However, if your filter is changing the format of data being sent, it should override the implementation of that callback to prevent formats flying through it, and send the proper spec via the output pads.

For the [source element](../glossary/glossary.md#source), it is necessary to send the format as in each [pipeline](../glossary/glossary.md#pipeline) the source is the first element - formats wouldn't flow through the pipeline if the source element wouldn't have sent them. Sending can be done in the `handle_playing/2` callback.

## Example

Imagine a pipeline, which starts with the source producing a video, which is then passed to the filter, responsible for reducing the quality of that video if it is too high.
For the source element, we should have the `:output` pads format which would allow us to send video in the higher and in the lower quality. The same format should be specified on the input of the filter element. However, the stream format on the output of the filter should accept only video in the lower quality.
Here is the definition of the source element:

```elixir
# Source element

defmodule Source do
 def_output_pad(:output,
   demand_unit: :buffers,
   stream_format: [
      {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 480, height: 300},
      {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 720, height: 480}
   ]
 )
 ...
 def handle_playing(_ctx, state) do
 ...
   { {[stream_format: {:output, %Formats.Raw{pixel_format: I420, framerate: 45, width: 720, height: 300} }]}, state}
 end
```

While returning from the `handle_playing/2` callback, the element will send the format described by the `Formats.Raw` structure, through the `:output` pad.
Will this format meet the accepted specification provided by us? Think about it!
In fact, it will. The format matches (both in the event being sent and in the accepted specification of the pad, we have `Format.Raw` module). When it comes to the options, we see, that `I420` is in the `one_of` list, acceptable by the specification format for `width` equal to 720 and `height` equal to 480, and the `framerate`, equal to 45, is in the `range` between 30 and 60, as defined in the specification.
It means that the format can be sent through the `:output` pad.
Below there is the draft of the filter implementation:

```elixir
# Filter

defmodule Filter do
 def_input_pad(:input,
   demand_unit: :buffers,
   accepted_format: [
      {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 480, height: 300},
      {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 720, height: 480}
   ]
 )

 def_output_pad(:output,
   demand_unit: :buffers,
   accepted_format: {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 480, height: 300},
 )

 ...
 def handle_stream_format(_pad, _stream_format, _context, state) do
 ...
   { {:ok, [stream_format: {:output, %Formats.Raw{pixel_format: I420, framerate: 60, width: 480, height:300} }]}, state}
 end

end
```

When we receive the spec on the input pad, we do not propagate it to our `:output` pad - instead, we send a different format, with reduced quality (width and height options are lower).

We hope by now you have a better understanding of what stream formats are. This knowledge will be helpful in the following chapters.
