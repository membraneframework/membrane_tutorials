# Pipelines

Building `Pipeline`s is the way to create streaming applications with Membrane. Pipeline allows you to spawn `Element`s and establish data flow between them. Pipelines can also communicate with elements or terminate them. Elements within a pipeline are often referred to as its `children` and the pipeline is their `parent`.

Connecting elements together is called `linking`. 

To create a pipeline, you need to implement the [Membrane.Pipeline](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html) behavior. It boils down to implementing callbacks and returning actions from them. For a simple pipeline, it's sufficient to implement the [handle_init](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#c:handle_init/2) callback, which is called upon the pipeline startup, and return the [spec](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html#t:spec/0) action, which spawns and links elements. Let's see it in an example:

## Sample pipeline

```elixir
Mix.install([
  :membrane_hackney_plugin,
  :membrane_mp3_mad_plugin,
  :membrane_portaudio_plugin,
])

defmodule MyPipeline do
  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, mp3_url) do
    spec =
      child(%Membrane.Hackney.Source{
        location: mp3_url, hackney_opts: [follow_redirect: true]
      })
      |> child(Membrane.MP3.MAD.Decoder)
      |> child(Membrane.PortAudio.Sink)

    {[spec: spec], %{}}
  end
end

mp3_url = "https://raw.githubusercontent.com/membraneframework/membrane_demo/master/simple_pipeline/sample.mp3"

Membrane.Pipeline.start_link(MyPipeline, mp3_url)
```

This is an [Elixir](elixir-lang.org) snippet, that streams an mp3 via HTTP and plays it on your speaker. Here's how to run it:
- Install [libmad](https://github.com/markjeee/libmad) and [portaudio](https://github.com/PortAudio/portaudio). Membrane uses these libs to decode the mp3 and to access your speaker, respectively. You can use these commands:
  - On Mac OS: `brew install libmad portaudio pkg-config`
  - On Debian: `apt install libmad0-dev portaudio19-dev`

- Option 1: Click the button below:

  [![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fmembraneframework%2Fmembrane_core%2Fblob%2Freadme%2Fexample.livemd)

  It will install [Livebook](livebook.dev), an interactive notebook similar to Jupyter, and it'll open the snippet in there for you. Then just click the 'run' button in there.

- Option 2: If you don't want to use Livebook, you can [install Elixir](https://elixir-lang.org/install.html), type `iex` to run interactive shell and paste the snippet there.


## Sample pipeline explained

Let's figure out step-by-step what happens in the sample pipeline.

Firstly, we install the needed dependencies:

```elixir
Mix.install([
  :membrane_hackney_plugin,
  :membrane_mp3_mad_plugin,
  :membrane_portaudio_plugin,
])
```

Instead of creating a script and using `Mix.install`, you can also [create a Mix project](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) and add these dependencies to `deps` in `mix.exs` file.

After installing the dependencies, we can create a module for our pipeline:

```elixir
defmodule MyPipeline do
  use Membrane.Pipeline

end
```

and implement the `handle_init` callback:

```elixir
defmodule MyPipeline do
  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, path_to_mp3) do

  end
end
```

The `handle_init` callback is executed at the pipeline startup. We use it to spawn and link elements:

```elixir
@impl true
def handle_init(_ctx, path_to_mp3) do
  spec =
    child(%Membrane.Hackney.Source{
      location: mp3_url, hackney_opts: [follow_redirect: true]
    })
    |> child(Membrane.MP3.MAD.Decoder)
    |> child(Membrane.PortAudio.Sink)

  {[spec: spec], %{}}
end
```

The spawned elements are:
- Hackney source - an element based on the [Hackney HTTP library](https://github.com/benoitc/hackney), that downloads a file via HTTP chunk by chunk, and sends these chunks through its `output` pad. We pass two options to it: a URL where the MP3 is stored and a flag to make it follow HTTP redirects.
- MP3 decoder - an element based on [libmad](https://github.com/markjeee/libmad), that accepts MP3 audio on the `input` pad and sends decoded audio through the `output` pad.
- PortAudio sink - an element that accepts decoded audio on its `input` pad and uses the [PortAudio](https://github.com/PortAudio/portaudio) library to play in on the speaker.

In our spec, we don't mention the names of the pads, because `input` and `output` are the defaults. However, we could explicitly specify them:

```elixir
spec =
  child(%Membrane.Hackney.Source{
    location: mp3_url, hackney_opts: [follow_redirect: true]
  })
  |> via_out(:output)
  |> via_in(:input)
  |> child(Membrane.MP3.MAD.Decoder)
  |> via_out(:output)
  |> via_in(:input)
  |> child(Membrane.PortAudio.Sink)
```

Even though not necessary here, [via_in](https://hexdocs.pm/membrane_core/Membrane.ChildrenSpec.html#via_in/3) and [via_out](https://hexdocs.pm/membrane_core/Membrane.ChildrenSpec.html#via_out/3) are useful in more complex scenarios that we'll cover later.

The value returned from `handle_init`:

```elixir
{[spec: spec], %{}}
```

is a tuple containing the list of actions and the state.
- Actions are the way to interact with Membrane. Apart from `spec`, you can for example return `terminate: reason` that will stop the elements and terminate the pipeline. Most actions, including `spec`, can be returned from multiple callbacks, allowing, for example, to spawn elements on demand. Check the [Membrane.Pipeline](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html) behavior for the available callbacks and [Membrane.Pipeline.Action](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html) for the available actions.
- State is an arbitrary data that will be passed to subsequent callbacks as the last argument. It's usually a map. As we have no use for the state in this case, we just set it to an empty map.

When we have created our pipeline module, we can call [Membrane.Pipeline.start_link](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#start_link/3) to run it:

```elixir
Membrane.Pipeline.start_link(MyPipeline, mp3_url)
```

We pass to it the pipeline module and options, which in our case is the `mp3_url`. The options are passed directly to the `handle_init` callback.

Now you know a thing or two about pipelines. Let's now have a deeper look at the elements.