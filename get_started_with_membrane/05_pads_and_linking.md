# Pads and linking

You learned how to link elements in the `Pipeline` chapter and how to define pads in the `Element` chapter. Now, let's have a deeper dive into pads and their capabilities.

## Dynamic Pads

A dynamic pad is a type of pad that acts as a template - each time some other pad is linked to a dynamic pad, a new instance of it is created.

Dynamic pads don't have to be linked when the element is started. This needs to be handled by the element, but in return, it gives new possibilities when the number of pads can change on the fly.

Another use case for dynamic pads is when the number of pads is not known at the compile time.
For example, an audio mixer may have any number of inputs.


### Creating an element with dynamic pads

To make a pad dynamic, you need to set its `availability` to `:on_request` in [def_input_pad](https://hexdocs.pm/membrane_core/Membrane.Element.WithInputPads.html#def_input_pad/2) or [def_output_pad](https://hexdocs.pm/membrane_core/Membrane.Element.WithOutputPads.html#def_output_pad/2).

Now, each time some element is linked to this pad, a new instance of the pad is created and [handle_pad_added](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#c:handle_pad_added/3) callback is invoked. Instances of a dynamic pad can be referenced as `Pad.ref(pad_name, pad_id)`. When a dynamic pad is unlinked, the [handle_pad_removed](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#c:handle_pad_removed/3) callback is called.

### Gotchas

As usual, with great power comes great responsibility. When implementing an element with dynamic pads, you need to consider what should happen when they are added or removed. Usually, you need to implement `handle_pad_added` and `handle_pad_removed` callbacks, and the logic of an element may generally become more complicated.

### Linking dynamic pads

Let's see how to link dynamic pads. We'll use [membrane_file_plugin](https://github.com/membraneframework/membrane_file_plugin), a plugin that allows reading and writing to files, and [membrane_tee_plugin](https://github.com/membraneframework/membrane_file_plugin) which allows forwarding the stream from a single input to multiple outputs. Running the pipeline below with `Membrane.Pipeline.start_link(MyPipeline)` should copy the "source" file to "target1", "target2" and "target3" files. Don't forget to create the "source" file before.

```elixir
Mix.install([
  :membrane_file_plugin,
  :membrane_tee_plugin
])

defmodule MyPipeline do
  use Membrane.Pipeline

  alias Membrane.{File, Tee}

  @impl true
  def handle_init(_ctx, _options)
    spec = [
      child(%File.Source{location: "source"})
      |> child(:tee, Tee.Parallel),
      get_child(:tee) |> child(%File.Sink{location: "target1"}),
      get_child(:tee) |> child(%File.Sink{location: "target2"}),
      get_child(:tee) |> child(%File.Sink{location: "target3"})
    ]
  end
end
```

The [Membrane.Tee.Parallel](https://hexdocs.pm/membrane_tee_plugin/Membrane.Tee.Parallel.html) element has a single static input and a single dynamic output pad. Because the output is dynamic, each time we link it, a new pad instance is created with a unique reference. In the example above, pad references were generated automatically. It's possible to specify them directly with [via_in](https://hexdocs.pm/membrane_core/Membrane.ChildrenSpec.html#via_in/3) or [via_out](https://hexdocs.pm/membrane_core/Membrane.ChildrenSpec.html#via_out/3) and [Membrane.Pad.ref](https://hexdocs.pm/membrane_core/Membrane.Pad.html#ref/1):

```elixir
spec = [
  child(%File.Source{location: "source"})
  |> child(:tee, Tee.Parallel),
  get_child(:tee) |> via_out(Pad.ref(:output, 1)) |> child(%File.Sink{location: "target1"}),
  get_child(:tee) |> via_out(Pad.ref(:output, 2)) |> child(%File.Sink{location: "target2"}),
  get_child(:tee) |> via_out(Pad.ref(:output, 3)) |> child(%File.Sink{location: "target3"})
]
```

In this case, it won't make a difference, but elements can rely on pad references and use them to identify the stream that should be sent or received through the given pad.

## Pad options

Just like elements, pads can have options. They have to be defined with the `options` key in `def_input_pad` and `def_output_pad`, using the same syntax as the element options. For example, [Membrane.AudioMixer](https://hexdocs.pm/membrane_audio_mix_plugin/Membrane.AudioMixer.html) does it to make its `input` pad accept the `offset` option:

```elixir
def_input_pad :input,
    availability: :on_request,
    options: [
      offset: [
        spec: Time.non_neg(),
        default: 0,
        description: "Offset of the input audio at the pad."
      ]
    ],
    # ...
```

Pad options can be set via a keyword list within the second argument of `via_in` or `via_out`. Here's how to provide the `offset` option to the mixer:

```elixir
spec = [
  # ...
  child(Membrane.MP3.MAD.Decoder)
  |> via_in(:input, options: [offset: Membrane.Time.seconds(2)])
  |> child(Membrane.AudioMixer)
  # ...
]
```

Pad options' values can be accessed in the context of the `handle_pad_added` callback:

```elixir
@impl true
def handle_pad_added(pad, context, state) do
  %{offset: offset} = context.pad_options
  # ...
end
```
