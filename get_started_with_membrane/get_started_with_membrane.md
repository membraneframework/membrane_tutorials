Hello there, and a warm welcome to the Membrane tutorials. We're glad you chose to learn Membrane; and we'd like to invite you on a journey around multimedia with us, where we explore how to utilize the Membrane Framework to build applications that process audio, video, and other multimedia content in interesting ways.

Let's start with some old-fashioned "Hello world!"

```elixir
defmodule Hello do

  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, path_to_mp3) do
    spec =
      child(:file, %Membrane.File.Source{location: path_to_mp3})
      |> child(:decoder, Membrane.MP3.MAD.Decoder)
      |> child(:converter, %Membrane.FFmpeg.SWResample.Converter{
        output_stream_format: %Membrane.RawAudio{
          sample_format: :s16le,
          sample_rate: 48000,
          channels: 2
        }
      })
      |> child(:portaudio, Membrane.PortAudio.Sink)

    {[spec: spec], %{}}
  end
end
```

That might not look too simple for now, but don't worry. There'll be a lot of new things you're going to encounter, and we shall introduce you to some of them or give hints about how and where to learn more.

> **Elixir**
>
> Membrane is written in Elixir. It's an awesome programming language of the functional paradigm with great fault tolerance and process management, which made it the best choice for Membrane.
> If you're not familiar with it, you can use [this cheatsheet](https://devhints.io/elixir) for a quick look-up.
> We encourage you to also take a [deep look into Elixir](https://elixir-lang.org/getting-started/introduction.html) and learn how to use it to take full advantage of all its awesomeness. We believe you'll fall in love with Elixir too!
>
> To play and work with Membrane, you'll need to have the Elixir environment installed on your system. You'll find installation instructions for your specific operating system [here](https://elixir-lang.org/install.html).

The code above is one of the simplest examples of Membrane usage. It plays an MP3 file through your computer's default audio playback device with the help of the [PortAudio](http://www.portaudio.com/) audio I/O library. Let's digest this code and put it to work playing some sound.

## Prerequisites

First we need to get all the libraries that Membrane needs to operate in our case. You can read more about them later, but for now, we'll just jump to installation:

### Linux

```bash
$ apt install clang-format portaudio19-dev ffmpeg libavutil-dev libswresample-dev libmad0-dev
```

### Mac

```bash
$ brew install clang-format portaudio ffmpeg libmad pkg-config
```

Alternatively, you can use our docker image that already contains all libraries you need to smoothly run any Membrane code. You can read more about how to do it [here](../videoroom/2_EnvironmentPreparation.md).

## Creating a Project

By installing Elixir, you get a bunch of useful tools. One of them is [Mix](https://hexdocs.pm/mix/Mix.html). Mix is described in its documentation preface as follows:

> Mix is a build tool that provides tasks for creating, compiling, and testing Elixir projects, managing its dependencies, and more.

Let's use it to create a project for our first Membrane adventure:

```bash
$ mix new hello --module Hello
```

The Mix generator will create some files for us. Let's take a closer look at two of them:

1. **mix.exs** - It's an entry file for our Mix project, a place where we can configure the project and set up our dependencies. We specify dependencies by adding them to the `deps` function:

```elixir
defp deps do
  [
    {:membrane_core, "~> 0.12.7"},
    {:membrane_file_plugin, "~> 0.14.0"},
    {:membrane_portaudio_plugin, "~> 0.16.1"},
    {:membrane_ffmpeg_swresample_plugin, "~> 0.17.2"},
    {:membrane_mp3_mad_plugin, "~> 0.16.0"},
  ]
end
```

1. **lib/hello.ex** - The `lib` directory contains our application's source files. The `hello.ex` file in `lib` is the current application's only source file. The file already contains the definition of the `Hello` module. We shall add all our code for this example within this module.

## Our first Pipeline

The [pipeline](../glossary/glossary.md#pipeline) is one of the basic concepts of Membrane. It's a schema of how the data packets are flowing through our application.

### Pipeline behaviour

Let's start with declaring that we'll be using the `Membrane.Pipeline` behaviour:

```elixir
defmodule Hello do

  use Membrane.Pipeline

end
```

Using this behaviour means we are treating our module as a Membrane Pipeline, so we will have access to functions defined in the `Membrane.Pipeline` module, and we can implement some of its callbacks. Let's implement the first callback, `handle_init/2`, which is a function that is invoked to initialize a pipeline during start-up.

As you can see in [the documentation](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#c:handle_init/2), `handle_init/2` takes two arguments: context and options. The `context` argument is a map that contains contextual information relevant for a given `Membrane.Pipeline` callback. We shall not use the context parameter in this example. `options`, on the other hand, is data that is passed to the pipeline during start-up (using one of the `start` or `start_link` functions). As our app's one and only purpose is to play an MP3 file, we shall pass the path of the file we want to play to the pipeline on start-up and receive that path as `handle_init/2`'s second argument:

```elixir
defmodule Hello do

  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, path_to_mp3) do
  end

end
```

The main purpose of the `handle_init/2` callback is to prepare our pipeline. Preparing a pipeline involves specifying all its [elements](../glossary/glossary.md#element) as children and setting up links between them to define the order in which data will flow through the pipeline.

A pipeline's callbacks are expected to return a tuple containing a list of actions to be taken as well as any data that represents the state in which the pipeline will be after that callback. An action can be one of these [types](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html#t:t/0). Since we want to spawn children processes and link them, we will use the [`spec`](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html#t:spec/0) action.

> If the concept of callbacks and behaviours is new to you, you should probably take some time to read about OTP in Elixir (especially the [GenServer](https://elixir-lang.org/getting-started/mix-otp/genserver.html) and [Supervisor](https://elixir-lang.org/getting-started/mix-otp/supervisor-and-application.html) behaviours). You can follow Elixir's [official Mix and OTP guide](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) to learn about OTP. [Elixir School](https://elixirschool.com/en) is another useful resource for learning Elixir and OTP.

### Elements

The elements we need to use to play our MP3 are:

- `Membrane.File.Source` - A source module from Membrane's file plugin that reads a file.
- `Membrane.MP3.MAD.Decoder` - An MP3 decoder based on [MAD](https://www.underbit.com/products/mad/).
- `Membrane.FFmpeg.SWResample.Converter` - A converter based on [FFmpeg SWResample](https://ffmpeg.org/doxygen/trunk/group__lswr.html#details), which we need to resample our raw audio stream from 24 bits to 16 bits.
- `Membrane.Portaudio.Sink` - A sink module that will be playing our music with [PortAudio](http://www.portaudio.com).

> All the elements we are using are not part of `membrane_core` but are plugins that exist as separate projects from the core. The [Membrane Guide](https://membrane.stream/guide/v0.9/introduction.html) features a list of [packages](https://membrane.stream/guide/v0.9/packages.html) provided by the Membrane Team. You can also learn how to write your own Element using the Membrane Guide.

The child elements of our player's pipeline and the links between them are specified in full as follows:

```elixir
spec =
  child(:file, %Membrane.File.Source{location: path_to_mp3})
  |> child(:decoder, Membrane.MP3.MAD.Decoder)
  |> child(:converter, %Membrane.FFmpeg.SWResample.Converter{
    output_stream_format: %Membrane.RawAudio{
      sample_format: :s16le,
      sample_rate: 48000,
      channels: 2
    }
  })
  |> child(:portaudio, Membrane.PortAudio.Sink)
```

The specification makes use of the [child/2](https://hexdocs.pm/membrane_core/Membrane.ChildrenSpec.html#child/2) and [child/3](https://hexdocs.pm/membrane_core/Membrane.ChildrenSpec.html#child/3) functions of the [Membrane.ChildrenSpec](https://hexdocs.pm/membrane_core/Membrane.ChildrenSpec.html) module. The `Membrane.ChildrenSpec` module is imported into our module as part of the `use Membrane.Pipeline` statement. From the documentation, `child/2` is used to spawn a named child (at the beginning of a specification) or an anonymous child, and `child/3` is used to spawn a named child or an anonymous child in the middle of a link specification.

We begin our pipeline with a call to `child/2` to create a `Membrane.File.Source` source element which will read the contents of our MP3 file into our pipeline for processing by subsequent elements:

```elixir
child(:file, %Membrane.File.Source{location: path_to_mp3})
```

>In our child specifications, the atoms `:file`, `:decoder`, `:converter`, and `:portaudio` are names that we associate with the various elements, thus creating named children. Giving a child a name allows it to be conveniently referred to by name later if need be.

The remaining child elements are created with `child/3` by passing in the result of a previous `child` call as the first argument of the next `child` call (using Elixir's pipe operator, i.e., `|>`), while also passing in a name and a child definition structure or module as the second and third arguments.

### Linking elements

A key feature of pipelines is that they encapsulate a data flow path for some processing task between a source of data and a final destination. For our example, our pipeline is created to move data from an MP3 file to an audio playback device to get some audible output. We establish the data flow path among our elements by linking them in proper order.

Each Membrane element can be of one of three types: **source**, **sink**, or **filter**. **Source elements** provide only output [pads](../glossary/glossary.md#pad) and can therefore provide data to other elements but cannot receive data from any other. In contrast to source elements, **sink elements** provide only input pads, so they can only receive data from other elements but cannot pass data to others. **Filter elements**, however, have both input and output pads. These characteristics imply the following:

- Source elements can only be used at the beginning of a pipeline since they cannot receive any inputs themselves (i.e., they have no input pads);
- Sink elements can only be used at the end of a pipeline since they cannot produce any ouptuts themselves (i.e., they have no output pads); and,
- Filter elements can be used only in the middle of a pipeline where they receive, process, and send data to subsequent filters or a sink element.

In our case, we set up our pipeline to begin with the `:file` source, followed by the `:decoder` and `:converter` filters, and finally the `:portaudio` sink. The links are established by means of the pipe operator, `|>`, which we have used between the `child` function calls in the child specification snippet. The code is repeated below for convenience:

```elixir
spec =
  child(:file, %Membrane.File.Source{location: path_to_mp3})
  |> child(:decoder, Membrane.MP3.MAD.Decoder)
  |> child(:converter, %Membrane.FFmpeg.SWResample.Converter{
    output_stream_format: %Membrane.RawAudio{
      sample_format: :s16le,
      sample_rate: 48000,
      channels: 2
    }
  })
  |> child(:portaudio, Membrane.PortAudio.Sink)
```

The `:file` element reads bytes from our MP3 file and sends them to the `:decoder` element (a filter) for [decoding](../glossary/glossary.md#encoder-and-decoder). The output from our decoder is further passed through the `:converter` filter for [resampling](https://en.wikipedia.org/wiki/Sample-rate_conversion). Finally, our resampled data is passed into the `:portaudio` sink, which receives the data and plays the sound 🎶 through PortAudio.

### Bringing our Pipeline to Life

The code we have written so far in `handle_init/2` specifies our pipeline's child elements and the appropriate links among them. To act on this specification and bring these elements and links to life, we need to return an action that will let Membrane know and perform our intentions. `handle_init/2` must return [a two-element tuple](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#t:callback_return/0) containing a list of actions and some state data. [Pipeline actions](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html) are messages that are used to communicate some instruction to a pipeline, an element or group of elements within a pipeline, or the Membrane application itself. Since we are now initializing our pipeline, we shall use the [`spec`](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html#t:spec/0) action, which is useful for instantiating and linking our pipeline's child elements. The `spec` action is a tagged tuple containing the atom `:spec` and an actual child specification structure. However, since the action part of the callback's return value should be a list, we take advantage of Elixir's [keyword list](https://elixir-lang.org/getting-started/keywords-and-maps.html) to simply our `handle_init/2` return tuple to the following:

```elixir
{[spec: spec], %{}}
```

The `:spec` action is our only action, and we also pass an empty map for our state since we don't need anything to be stored as state in this example. All together, our `Hello` module should finally look like this:

```elixir
defmodule Hello do

  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, path_to_mp3) do
    # Setup the flow of the data
    # Stream from file
    spec =
      child(:file, %Membrane.File.Source{location: path_to_mp3})
      # Decode frames
      |> child(:decoder, Membrane.MP3.MAD.Decoder)
      # Convert Raw :s24le to Raw :s16le
      |> child(:converter, %Membrane.FFmpeg.SWResample.Converter{
        output_stream_format: %Membrane.RawAudio{
          sample_format: :s16le,
          sample_rate: 48000,
          channels: 2
        }
      })
      # Stream data into PortAudio to play it on speakers.
      |> child(:portaudio, Membrane.PortAudio.Sink)

    {[spec: spec], %{}}
  end
end
```

And that's all the code we need to play our MP3 file.

## Running a pipeline

We can start a pipeline in a number of ways, but we shall use Elixir's interactive console, IEx, which is very convenient for quickly trying out some Elixir code. In a terminal window, `cd` to your project directory and type the following:

```bash
$ iex -S mix
```

This command compiles and loads your project into IEx. With the `Hello` module compiled and loaded, we can now create a pipeline process in IEx as follows:

```elixir
{:ok, supervisor_pid, pipeline_pid}  =  Hello.start("/path/to/mp3")
```

> We could also start our pipeline with `Hello.start_link/1` as follows:
>
> ```elixir
> {:ok, supervisor_pid, pipeline_pid}  =  Hello.start_link("/path/to/mp3")
> ```
>
> `start_link/1` links the pipeline process to the process that starts it.

The `start/1` or `start_link/1` call will start our `Hello` pipeline to play the MP3 file whose path we pass as our only argument to the function. Our [demo for this tutorial](https://github.com/membraneframework/membrane_demo/tree/master/simple_pipeline) contains a sample MP3 file you can play. You could also use [this "Hello!" recording](https://upload.wikimedia.org/wikipedia/commons/transcoded/6/6f/Voyager_Golden_Record_greeting_in_English.ogg/Voyager_Golden_Record_greeting_in_English.ogg.mp3) or your own MP3 file. If you use your own file, please ensure that the file has no ID3 or ID3v2 tags.

Once the pipeline starts successfully, you should hear the specified MP3 file being played on the default playback device in your system. The pipeline will be terminated when the file finishes playing, but you can also use `Hello.terminate` to stop playback and terminate the pipeline imperatively:

```elixir
Hello.terminate(pipeline_pid)
```

Congratulations! You've just built and run your first Membrane application.
