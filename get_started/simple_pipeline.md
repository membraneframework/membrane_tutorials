# Get Started with Membrane

Hello there, we're glad you chose to learn Membrane. We'd like to invite you on a journey around multimedia with us, to show you how to make all that stuff we made work for you. 

Lets start with some old-fashioned "Hello world!"

```elixir
defmodule Hello do

  use Membrane.Pipeline

  @impl true
  def handle_init(path_to_mp3) do
	children = %{
	  file: %Membrane.File.Source{location: path_to_mp3},
	  decoder: Membrane.MP3.MAD.Decoder,
	  converter: %Membrane.FFmpeg.SWResample.Converter{
	    output_caps: %Membrane.Caps.Audio.Raw{
		  format: :s16le,
		  sample_rate: 48000,
		  channels: 2
		}
	  },
	  portaudio: Membrane.PortAudio.Sink
    }

	links = [
	  link(:file)
	  |> to(:decoder)
	  |> to(:converter)
	  |> to(:portaudio)
	]

	spec = %ParentSpec{children: children, links: links}

	{{:ok, spec: spec}, %{}}
  end
end
```
That might not look too simple for now but don't worry, there'll be a lot of new things you're going to encounter, and we'll be introducing you to some of them, or giving hints about how and where to learn more.

> #### Elixir
> Membrane is written in Elixir. It's an awesome programming language of the functional paradigm with great fault tolerance and process management, which made it the best choice for Membrane.
> If you're not familiar with it, you can use [this cheatsheet](https://devhints.io/elixir) for quick look-up.
> We encourage you also to take a [deep look into Elixir](https://elixir-lang.org/getting-started/introduction.html) and learn how to use it to take full advantage of all it's awesomeness. We believe you'll fall in love with Elixir too!
>
> To play and work with Membrane you'll need to have the Elixir environment installed on your system. You'll find instructions for how to do it depending on your operating system [here](https://elixir-lang.org/install.html).


The code above is one of the simplest examples of Membrane usage. It plays an mp3 file through your device's `portaudio`. Let's make it work.

### Prerequisites

First we need to get all the libraries that Membrane needs to operate in our case. You can read about them more if you'd like, but for now we'll just jump to installation:

##### Linux
```bash
$ apt install clang-format portaudio19-dev ffmpeg libavutil-dev libswresample-dev libmad0-dev
```
##### Mac
```bash
$ brew install clang-format portaudio ffmpeg libmad pkg-config
```

Alternatively, you can use our docker image that already contains all libraries you need to smoothly run any membrane code. You can read more about how to do it [here](https://tutorials.membraneframework.org/tutorials/videoroom/2_EnvironmentPreparation.html#setting-environment-with-the-use-of-docker).

### Creating a Project

By installing Elixir you'll get a bunch of useful tools. One of them is [Mix](https://hexdocs.pm/mix/Mix.html). As you can read in its documentation preface:
> Mix is a build tool that provides tasks for creating, compiling, and testing Elixir projects, managing its dependencies, and more.

Lets use it to create a project for our first Membrane adventure:

```bash
$ mix new hello --module Hello
```

Mix generator will create some files for us. Lets take a closer look at two of them:

+ **mix.exs** - It's an entry file for our mix project, a place where we can configure it, and set-up our dependencies. We'll do it by adding them into `deps` function:

  ```elixir
  defp deps do
    [
	  {:membrane_core, "~> 0.7.0"},
	  {:membrane_file_plugin, "~> 0.6.0"},
	  {:membrane_portaudio_plugin, "~> 0.7.0"},
	  {:membrane_ffmpeg_swresample_plugin, "~> 0.7.1"},
	  {:membrane_mp3_mad_plugin, "~> 0.7.0"}
    ]
  end

### Our first Pipeline

#### Pipeline behaviour

Let's start with declaring that we'll be using the `Membrane.Pipeline` behaviour:

```elixir
defmodule Hello do

  use Membrane.Pipeline
  
end
```

Using a behaviour means we are treating our module as a Membrane pipeline, so we've access to functions defined in `Membrane.Pipeline` module, and we can implement some of it's callbacks.
Let's implement the first callback: `handle_init/1`. As you can see in [the documentation](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#c:handle_init/1) `handle_init` takes one argument which can be of any type - it's a way to pass some arguments needed for the pipeline to start. As our app's one and only purpose is to play an mp3 file we can assume that the only value we need to pass into the pipeline is a path for a file we want to play:
```elixir
defmodule Hello do

  use Membrane.Pipeline

  @impl true
  def handle_init(path_to_mp3) do
  end
  
end
```

The main purpose of the `handle_init` callback is to prepare our pipeline. Preparing means that we need to specify all its elements as children and set up links between those children to describe the order in which data will flow through the pipeline.
Pipeline's callbacks are expected to return a status and an optional list of actions to be taken. The action can be of one of the following [types](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html#t:t/0).
Since we want to spawn children processes and link them, we will use the [`spec_t()`](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html#t:spec_t/0) action which is described with the use of `Membrane.ParentSpec` structure.

>If the concept of callbacks and behaviours is new to you, you should probably take some time to read about OTP in Elixir (especially the part starring GenServer and Supervisor). You can find the proper guide [here](https://elixir-lang.org/getting-started/mix-otp/agent.html)

#### Elements

The elements we'd like to use to play our mp3 will be:

 - `Membrane.File.Source` - the Source module form Membrane file plugin that will read a file.
 - `Membrane.MP3.MAD.Decoder` - an mp3 decoder based on [MAD](https://www.underbit.com/products/mad/)
 - `Membrane.FFmpeg.SWResample.Converter` - a converter based on [FFmpeg SWResample](https://ffmpeg.org/doxygen/trunk/group__lswr.html#details). We'll be needing it to resample our row audio stream from 24 to 16 bits.
 - `Membrane.Portaudio.Sink` - A Sink module that will be playing our music with [Portaudio](http://www.portaudio.com)

> As you can see all elements we're using are not a part of `membrane_core`, but can be found in separate libraries. You can find a list of packages provided by Membrane team [here](https://membraneframework.org/guide/v0.7/packages.html). You can also learn how to write your own Element.

The full children declaration for our player will look like that:

```elixir
children = %{
  file: %Membrane.File.Source{location: path_to_mp3},
  decoder: Membrane.MP3.MAD.Decoder,
  converter: %Membrane.FFmpeg.SWResample.Converter{
    output_caps: %Membrane.Caps.Audio.Raw{
	  format: :s16le,
	  sample_rate: 48000,
	  channels: 2
	}
  },
  portaudio: Membrane.PortAudio.Sink
}
```

The keys in that keyword list are just a names we gave to elements. We're going to need them when linking.

#### Linking elements

Now we should link them in proper order. Each membrane element is one of three types: Source, Sink or Filter. The main difference is that Source provides only output pads, Sink only input and Filter both input and output. That means Source element can only start pipelines (it's not prepared to receive any data from other elements), Sink can only end pipeline (it will not send any data to succeeding elements), and Filters can be in the middle (it will receive, process and send data further). In our case a links declaration will look like that: 

```elixir
links = [
  link(:file)
  |> to(:decoder)
  |> to(:converter)
  |> to(:portaudio)
]
```

File Source read bytes from our mp3, sends them to decoder. Decoder, after decoding, sends them to converter. Converter, after conversion sends them to sink. Portaudio sink receives them and plays music through Portaudio 🎶

#### Parent Spec

Tha last but not least is to take elements and links together into a proper structure:

The structure here is `Membrane.ParentSpec` [docs](https://hexdocs.pm/membrane_core/Membrane.ParentSpec.html). You can also declare other options here if needed. In our pipeline `ParentSpec` will contain only children elements and links between them:

```elixir
spec = %ParentSpec{children: children, links: links}
```

At the end of the callback we need to return a proper tuple from `handle_init`. We can choose  from options described [here](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#t:callback_return_t/0-return-values). They are common for all callbacks, but as we're initialising a pipeline we need to choose one wich declares [actions to take within the pipeline](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html). Our action will be [`spec`](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html#t:spec_t/0):

```elixir
{{:ok, spec: spec}, %{}}
```
We're passing empty map for state, as we don't need anything to be stored as state.

After that the full module will look like this:

```elixir
defmodule Hello do

  use Membrane.Pipeline

  @impl true
  def handle_init(path_to_mp3) do
	children = %{
	  file: %Membrane.File.Source{location: path_to_mp3},
	  decoder: Membrane.MP3.MAD.Decoder,
	  converter: %Membrane.FFmpeg.SWResample.Converter{
	    output_caps: %Membrane.Caps.Audio.Raw{
		  format: :s16le,
		  sample_rate: 48000,
		  channels: 2
		}
	  },
	  portaudio: Membrane.PortAudio.Sink
    }

	links = [
	  link(:file)
	  |> to(:decoder)
	  |> to(:converter)
	  |> to(:portaudio)
	]

	spec = %ParentSpec{children: children, links: links}

	{{:ok, spec: spec}, %{}}
  end
end
```

### Running a pipeline

You can start your pipeline from any place in the code but it's convenient to use Elixir's interactive console:

```bash
$ iex -S mix
```

First, create a pipeline process:
```elixir
{:ok, pid}  =  Hello.start_link("/path/to/mp3")
```
Then, let it play:
```elixir
Hello.play(pid)
```

Our [demo with this tutorial](https://github.com/membraneframework/membrane_demo/tree/master/simple_pipeline) contains a file you can play, or you may want to use some [proper "Hello!" recording](https://upload.wikimedia.org/wikipedia/commons/transcoded/6/6f/Voyager_Golden_Record_greeting_in_English.ogg/Voyager_Golden_Record_greeting_in_English.ogg.mp3).

The specified mp3 file should be played on the default device in your system. Please use mp3 that has no ID3 or ID3v2 tags.
