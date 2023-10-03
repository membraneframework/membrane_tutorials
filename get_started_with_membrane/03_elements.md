# Elements

Elements in Membrane are the most basic entities responsible for processing multimedia.
Each instance of an element is an Elixir process, that has an internal state and communicates by message passing. You've already seen some examples of elements in the previous chapter.

Elements are spawned and controlled by their parent, which can be a pipeline or a bin (we'll cover bins in the subsequent chapter).

## Element types

The basic types of elements are the following:

* `Source` - fetches the stream from outside of the pipeline and delivers it to other elements
* `Sink` - consumes the stream from other elements
* `Filter` - receives the stream from other elements, processes it and sends it further to the subsequent elements
* `Endpoint` - a `Source` and a `Sink` combined - can both deliver and consume the data from other elements

To create an element, you need to `use` the appropriate module - [Membrane.Source](https://hexdocs.pm/membrane_core/Membrane.Source.html), [Membrane.Sink](https://hexdocs.pm/membrane_core/Membrane.Sink.html), [Membrane.Filter](https://hexdocs.pm/membrane_core/Membrane.Filter.html) or [Membrane.Endpoint](https://hexdocs.pm/membrane_core/Membrane.Endpoint.html), for example:

```elixir
defmodule MyElement do
  use Membrane.Filter

  # Element implementation
end
```

The `Element implementation` consists of defining pads, options and callbacks. Let's find out how to do that.

## Pads

As you already learned, pads allow the creation of the flow of data between elements. Pads, much like contact pads on a printed circuit board, are inputs and outputs of an element and are used to connect the elements with one another.
Because of that, there are two types of pads: `input` and `output`. It is worth mentioning that `Source` elements may only contain `output` pads, `Sink` elements contain only `input` pads, and `Filter` and `Endpoint` elements can have both of them.

Every pad should define the format of data that it is expecting. This format can be, for example,
raw audio with a specific sample rate or encoded audio in a given format.

To send data between elements, their pads need to be linked. There are a couple of rules that apply to pad linking:

* One pad of an element can only be linked with one pad from another element.
  (Dynamic pads can help with that limitation; you'll learn about them in the `pads_and_linking` chapter)
* Only links between `output` and `input` pads are allowed.
* Accepted stream formats of pads have to be compatible.

### Defining pads

Pads can be defined using [def_input_pad](https://hexdocs.pm/membrane_core/Membrane.Element.WithInputPads.html#def_input_pad/2) and [def_output_pad](https://hexdocs.pm/membrane_core/Membrane.Element.WithOutputPads.html#def_output_pad/2) macros. They both accept the pad name and the list of properties. The name allows for the identification of the pad. If an element has a single input or output pad, the convention is to name it `input` or `output`, respectively. The pad properties are listed below:

* `accepted_format` - A pattern for a stream format expected on the pad, for example `Membrane.RawAudio` or `%Membrane.RawAudio{channels: 2}`. It serves documentation purposes and is validated in runtime.
* `flow_control` - Configures how back pressure should be handled on the pad. You can choose from the following options:
  * `:auto` - Membrane automatically manages the flow control. It works under the assumption that the element does not need to block or slow down the processing rate, it just processes or consumes the stream as it flows. This option is not available for `Source` elements.
  * `:manual` - You need to manually control the flow control by using the `demand` action on `input` pads and implementing the `handle_demand` callback for `output` pads.
  * `:push` - It's a simple mode where an element producing data pushes it right away through the `output` pad. An `input` pad in this mode should be always ready to process that data.
* `demand_unit` - Either `:bytes` or `:buffers`, specifies what unit will be used to request or receive demands. Must be specified if `flow_control` is set to `:manual`.
* `availability` - Either `:always` (default) - meaning the pad is static and available from the moment an element is spawned, or `:on_request` meaning it is dynamic. We'll learn more about it in the `Pads and linking` chapter.
* `options` - Optional; specification of options accepted by the pad. We'll learn more about it in the `Pads and linking` chapter.

A pad definition may look like this:

```elixir
def_input_pad :input, flow_control: :auto, accepted_format: %Membrane.RawAudio{channels: 2}
```

It means that the element has a static input pad called `input`, with automatic flow control, that accepts [raw audio](http://hexdocs.pm/membrane_raw_audio_format) with two channels.

## Options

Element options make it possible to pass configuration data to an element. Elements aren't required to accept any options, but it's useful in many cases. Available options can be specified using the [def_options](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#def_options/1) macro, for example:

```elixir
def_options some_option: [
              spec: integer() | string(),
              default: 0,
              description: """
              This option is intended for...
              """
            ],
            other_option: [
              # ...
            ]
```

Each option can have the following fields:
- `spec` - The [typespec](https://hexdocs.pm/elixir/1.12/typespecs.html) of the values that option can have. Defaults to `any`.
- `default` - The value that the option will have if it's not specified. If the default is not provided, the option must be always explicitly specified.
- `description` - Write here what the option does. It will be included in the module documentation.

We'll see a practical example of defining options in the [sample element](#sample-element).

## Callbacks

Apart from specifying pads and options, creating an element involves implementing callbacks. They have different responsibilities and are called in a specific order. As in the case of pipelines, callbacks interact with the framework by returning [actions](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html). Here are some most useful callbacks:

[handle_init](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#c:handle_init/2) is invoked once, upon the element creation.
It receives options specified by the user, which should be parsed and on their base,
the element should create and initialize its internal state. It is called synchronously (the parent waits until it returns), thus you shouldn't perform any long tasks there.

[handle_setup](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#c:handle_setup/2) is invoked right after `handle_init`. It's intended for resource allocation or some potentially time-consuming initialization. If you need to make sure that resources are properly released upon element termination, use [Membrane.ResourceGuard](https://hexdocs.pm/membrane_core/Membrane.ResourceGuard.html) or [Membrane.UtilitySupervisor](https://hexdocs.pm/membrane_core/Membrane.UtilitySupervisor.html)

After `handle_setup`, the following callbacks can be called at any point:
- [handle_pad_added](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#c:handle_pad_added/3) and [handle_pad_removed](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#c:handle_pad_removed/3) are called when a dynamic pad is added and removed, respectively
- [handle_parent_notification](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#c:handle_parent_notification/3) is called whenever the parent sends a notification to the element; elements can send notifications the other way with the **notify** action

[handle_playing](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#c:handle_playing/2) is called when the stream processing is ready to start. From that point, you can return the following actions:
- [stream_format](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:stream_format/0) tells the subsequent element what kind of stream it should expect on the given pad
- [buffer](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:buffer/0) sends media data to the subsequent element; stream_format has to be sent before the first buffer
- [event](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:event/0) sends a custom struct to the subsequent or preceding element; downstream events are sent in order with buffers
- [demand](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:demand/0) requests data from the previous element; only works for pads in `flow_control: manual` mode
- [end_of_stream](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:end_of_stream/0) tells the subsequent element that the stream has finished, nothing can be sent through that pad afterward

After `handle_playing`, you should expect the following callbacks to be called:

- [handle_stream_format](https://hexdocs.pm/membrane_core/Membrane.Element.WithInputPads.html#c:handle_stream_format/4) tells you what kind of stream you should expect on the given pad; called at least once, before `handle_start_of_stream`, may be called later when the stream format changes

- [handle_start_of_stream](https://hexdocs.pm/membrane_core/Membrane.Element.WithInputPads.html#c:handle_start_of_stream/3) is called just before the first buffer arrives from the preceding element

- [handle_process](https://hexdocs.pm/membrane_core/Membrane.Element.WithInputPads.html#c:handle_process/4) or [handle_write](https://hexdocs.pm/membrane_core/Membrane.Element.WithInputPads.html#c:handle_write/4) is called every time a buffer arrives from the preceding element

- [handle_event](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#c:handle_event/4) is called once an event arrives from the preceding or subsequent element

- [handle_demand](https://hexdocs.pm/membrane_core/Membrane.Element.WithOutputPads.html#c:handle_demand/5) is called when the subsequent element requests data on the given pad; only works for pads in `flow_control: :manual` mode

- [handle_end_of_stream](https://hexdocs.pm/membrane_core/Membrane.Element.WithInputPads.html#c:handle_end_of_stream/3) is called when the stream has finished; it may be because the preceding element explicitly returned `end_of_stream` action, the pad is about to be unlinked or the current element is about to terminate

Finally, [handle_terminate_request](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#c:handle_terminate_request/2) is called when the parent decides to remove the element. By default, it returns the `terminate: :normal` action and the element terminates gracefully. Note that this callback is only called when the element is gracefully asked to terminate.


## Sample element

That's enough for the theory, let's write some code! We'll create a sample element and plug it into the pipeline from the previous chapter. Here's the element:

```elixir
defmodule VolumeKnob do
  @moduledoc """
  Membrane filter that changes the audio volume
  by the gain passed via options.
  """
  use Membrane.Filter

  alias Membrane.RawAudio

  def_input_pad :input, accepted_format: RawAudio, flow_control: :auto
  def_output_pad :output, accepted_format: RawAudio, flow_control: :auto

  def_options gain: [
    spec: float(),
    description: """
    The factor by which the volume will be changed.

    A gain smaller than 1 reduces the volume and gain
    greater than 1 increases it.
    """
  ]

  @impl true
  def handle_init(_ctx, options) do
    {[], %{gain: options.gain}}
  end
  
  @impl true
  def handle_process(:input, buffer, ctx, state) do
    stream_format = ctx.pads.input.stream_format
    sample_size = RawAudio.sample_size(stream_format)
    payload =
      for <<sample::binary-size(sample_size) <- buffer.payload>>, into: <<>> do
        value = RawAudio.sample_to_value(sample, stream_format)
        scaled_value = round(value * state.gain)
        RawAudio.value_to_sample(scaled_value, stream_format)
      end

    buffer = %Membrane.Buffer{buffer | payload: payload}
    {[buffer: {:output, buffer}], state}
  end
end
```

As the `moduledoc` says, the element can be used to adjust the audio volume. As we create a filter, we start with `use Membrane.Filter` clause. Then we define pads, one input and one output:

```elixir
alias Membrane.RawAudio

def_input_pad :input, accepted_format: RawAudio, flow_control: :auto
def_output_pad :output, accepted_format: RawAudio, flow_control: :auto
```

The element is going to receive raw audio and send the raw audio too. The raw audio (sometimes referred to as PCM - Pulse Code Modulation) is a simple digital representation of an audio wave, that we can operate on - for example, change the volume. The `Membrane.RawAudio` format is defined in the `membrane_raw_audio_format` package.

Since the element only transforms the stream as it flows, we can safely set `flow_control` to `auto` on both pads.

After defining the pads, we can define options. In this case, it's a single option - `gain` by which the volume will be changed.

```elixir
def_options gain: [
  spec: number(),
  description: """
  The factor by which the volume will be changed.

  A gain smaller than 1 reduces the volume and gain
  greater than 1 increases it.
  """
]
```

It's important to provide the type spec and description for each option so that everyone knows how to use it.

Next, we implement the first callback - `handle_init`:

```elixir
@impl true
def handle_init(_ctx, options) do
  {[], %{gain: options.gain}}
end
```

The callback does not return any actions (thus the empty list), but it saves the gain passed through options in the state.

Then goes the main part of the element - the `handle_process` callback:

```elixir
@impl true
def handle_process(:input, buffer, ctx, state) do
```

The callback is called whenever a buffer arrives on a pad, and receives four arguments:
- the pad where the buffer arrived,
- the [Membrane.Buffer](https://hexdocs.pm/membrane_core/Membrane.Buffer.html) structure carrying the stream data,
- [Membrane.Element.CallbackContext.t](https://hexdocs.pm/membrane_core/Membrane.Element.CallbackContext.html#t:t/0), providing some useful information about the element,
- the element's state that we created in `handle_init`.

Firstly, we use the callback context to get the stream format present on the pad and use a utility from [Membrane.RawAudio](https://hexdocs.pm/membrane_raw_audio_format/Membrane.RawAudio.html) to calculate the sample size:
```elixir
stream_format = ctx.pads.input.stream_format
sample_size = RawAudio.sample_size(stream_format)
```

We could have implemented the `handle_stream_format` callback and stored the `sample_size` in the element's state too. When there's more work to be done once the stream format arrives, it's the preferred approach, though in a simple case like this we're good using the callback context.

The sample size is the amount of bytes that each audio sample takes. We'll use it to extract each sample from the payload:

```elixir
payload =
  for <<sample::binary-size(sample_size) <- buffer.payload>>, into: <<>> do
```

Now we can convert each sample to an integer with another utility from `Membrane.RawAudio`: (sample_to_value)[https://hexdocs.pm/membrane_raw_audio_format/Membrane.RawAudio.html#sample_to_value/2]`. Having the integer, we can multiply it by the gain and convert it back to the binary representation.

```elixir
    value = RawAudio.sample_to_value(sample, stream_format)
    scaled_value = round(value * state.gain)
    RawAudio.value_to_sample(scaled_value, stream_format)
  end
```

Finally, we can update the payload and forward the buffer to the output pad using the [buffer](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:buffer/0) action.

```elixir
  buffer = %Membrane.Buffer{buffer | payload: payload}
  {[buffer: {:output, buffer}], state}
end
```

Let's test our element by plugging it into the pipeline from the previous chapter. Since it accepts `Membrane.RawAudio`, we should plug it after the decoder, which accepts encoded audio and outputs raw audio. Let's update the spec in the `handle_init` callback of our pipeline:

```elixir
spec =
  child(%Membrane.Hackney.Source{
    location: mp3_url, hackney_opts: [follow_redirect: true]
  })
  |> child(Membrane.MP3.MAD.Decoder)
  |> child(%VolumeKnob{gain: 0.2})
  |> child(Membrane.PortAudio.Sink)
```

Let's run the pipeline again:

```elixir
Membrane.Pipeline.start_link(MyPipeline, mp3_url)
```

Since we set the gain to `0.2`, the audio should play quieter than before.

In this chapter, you learned how elements work and how to create one. Now let's figure out what are `Bin`s.