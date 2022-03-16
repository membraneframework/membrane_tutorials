# Introduction
We owe you something...and we would like to pay it back as soon as possible!
As promised in the [3rd chapter](3_Source.md), we will talk more about the concept of caps - which in fact we have used in the previous chapter, but which weren't described in the sufficient way there.
# What are caps?
Caps (an abbreviation of the *capabilities*) is a concept allowing us to define what kind of data is flowing through the pad. 
In the Membrane Framework's nomenclature, we say, that we define a caps specification for a given element.

We believe that an example might speak here louder than a plain definition, so we will try to describe the caps with the real-life scenario example.
Let's say that we are connecting two elements that process the video multimedia.
The link is made between the pads which are working on raw video data.
Here is where caps come up - they can be defined with the following constraints:
+ data format - in our case, we are having a raw video format
+ some additional constraints - i.e. frame resolution (480p) , framerate (30 fps) etc.

Caps help us find out if the given elements are capable to communicate with each other. Not only we cannot send the data between the pads if the format they are expecting is different - we need to take into consideration some other constraints! We can think of a situation in which the format would be the same (i.e. raw video data), but the element which receives the data performs a much more complex computation on that data than the sender, and therefore cannot digest such a great amount of data as the sender is capable of transmitting. Then their caps wouldn't be compatible, which could be expressed by adding some constraint, i.e. framerate.

Caps help us define a contract between elements and prevent us from connecting incompatible elements. That is why it is always better to define precise caps rather than using caps of type `:any`.

# When the caps are compatible?
A comparison between caps is made when the pads are connected. Due to freedom in defining the type, the comparison is not that straightforward. It would be good for a responsible Membrane's element architect to be aware of how the caps are compared. You can refer to the implementation of the caps matcher, available [here](https://github.com/membraneframework/membrane_core/blob/82d6162e3df94cd9abc508c58bc0267367b02d58/lib/membrane/caps/matcher.ex#L124)...or follow on this chapter, and learn it by an example.
Here is how you define a caps specification:
1. First you need to specify the format module
 ``` Elixir
 defmodule Formats.Raw do
   defstruct [:format, :framerate, :width, :height]
 end
 ```
 Module name defines the type of the caps, however it is possible to pass some other options in a form of a struct. That is why we have defined a structure with the use of `defstruct`. Our format will be described with the following options:
 + :format - pixel format, i.e. [I420](https://en.wikipedia.org/wiki/Chroma_subsampling) ([YUV](https://en.wikipedia.org/wiki/YUV)) or RGB888
 + :framerate - number of frames per second, i.e. 30 (FPS)
 + :width - width of the picture in pixels, i.e. 480 (px)
 + :height - height of the picture in pixels, i.e. 300 (px)
2. We specify the pad of the element with the format we have just defined, using the `:caps` option. For the purpose of an example, let it be the `:input` pad:
 ```Elixir
 def_input_pad(:input, 
   demand_unit: :buffers, 
   caps: [
      {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 480, height: 300},
      {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 720, height: 480}
   ]
 )
 ```
 As you can see, we pass a list of compatible formats, each described with the tuple, consisting of our module name, and the keywords list fulfilling the 
 structure defined in that module. For the format's options, we can use the `range/2` or `one_of/1` specifier, which will modify the way in which the comparison between the caps specification and the actual caps received by the element is performed.

3. Once the caps event comes to the element's pad, the caps description sent in that event is confronted with each of the formats in the caps specification list of the pad.  If the event's caps description matches even one of the caps formats present in the list it means that caps are matching.
To match the caps with the particular format (one from the caps specification list), the module (first element of the tuple in caps format description) must be the same and all the options must match. For each option, a value sent within the event is confronted with the specification of the option. The way comparison occurs is dependent on how we defined that option in the specification:
 + We have used `framerate: range(30, 60)`, so will accept the framerate value in the given interval, between 30 and 60 FPS.
 + We have also used `pixel_format: one_of([:I420, :I422]`, and that will accept caps, whose pixel format is either I420 or I422
 + We have used a plain value to specify the `width` and the `height` of a picture - the caps will match if that option will be equal to the value passed in the specification 
4. As noted previously, one can specify the caps as `:any`. Such a specification will match all the caps sent on the pad, however, it is not a recommended way to develop the element - caps are there for some reason!

Our journey with caps does not end here. We know how to describe caps specification...but we also need to make our elements send the caps events so that the following elements will be aware of what type of data our element is producing!

An element can send caps as one of the [actions](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html) it can take - the [`:caps` action](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:caps_t/0).

Another thing is that we can specify the behavior of an element when it receives the caps with the use of [`handle_caps/4` callback](https://hexdocs.pm/membrane_core/Membrane.Element.WithInputPads.html#c:handle_caps/4).

For all the filter elements, `handle_caps/4` has a default implementation, which is relaying the received caps on all the output pads of that filter.
However, if your filter is changing the format of data being sent, it should override the implementation of that callback to prevent caps flying through it, and send the proper caps via the output pads. 

For the source element, it is necessary to send the caps as in each pipeline the source is the first element - caps wouldn't flow through the pipeline if the source element wouldn't have sent them. Sending can be done in the `handle_stopped_to_prepared/2` callback.
# Example
Imagine a pipeline, which starts with the source producing a video, which is then passed to the filter, responsible for reducing the quality of that video if it is too high.
For the source element, we should have the `:output` pads caps which would allow us to send video in the higher and in the lower quality. The same caps should be specified on the input of the filter element. However, the caps on the output of the filter should accept only video in the lower quality.
Here is the definition of the source element:
```Elixir
# Source element

defmodule Source do
 def_output_pad(:output, 
   demand_unit: :buffers, 
   caps: [
      {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 480, height: 300},
      {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 720, height: 480}
   ]
 )
 ...
 def handle_stopped_to_prepared(_ctx, state) do
 ...
   {{:ok, [caps: {:output, %Formats.Raw{pixel_format: I420, framerate: 45, width: 720, height: 300}}]}, state}
 end
```
While returning from the `handle_stopped_to_prepared/2` callback, the element will send the caps described by the `Formats.Raw` structure, through the `:output` pad.
Will those caps meet the caps specification provided by us? Think about it!
In fact, they will. The format matches (both in the caps being sent and in the caps specification of the pad, we have `Format.Raw` module). When it comes to the options, we see, that `I420` is in the `one_of` list, acceptable by the caps specification format for `width` equal to 720 and `height` equal to 480, and the `framerate`, equal to 45, is in the `range` between 30 and 60, as defined in the caps specification.
It means that the caps can be sent through the `:output` pad. 
Below there is the draft of the filter implementation:
```Elixir
# Filter

defmodule Filter do
 def_input_pad(:input, 
   demand_unit: :buffers, 
   caps: [
      {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 480, height: 300},
      {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 720, height: 480}
   ]
 )

 def_output_pad(:output, 
   demand_unit: :buffers, 
   caps: {Format.Raw, pixel_format: one_of([:I420, :I422]), framerate: range(30, 60), width: 480, height: 300},
 )

 ...
 def handle_caps(_pad, _caps, _context, state) do
 ...
   {{:ok, [caps: {:output, %Formats.Raw{pixel_format: I420, framerate: 60, width: 480, height:300}}]}, state}
 end

end
```

When we receive the caps on the input pad, we do not propagate them to our `:output` pad - instead, we send other caps, with reduced quality (width and height options of the format are lower).