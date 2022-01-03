Finally, we can get to the code! 
We will start where the all the pipelines start - with the `Source` element. 
Since this will be the first element we implement, we need to find out something more about how the Membrane Framework's elements should be implemented and some concepts associated with them.
The first think you need to be aware of is that `Membrane.Element` describes a specific behavior, based on the OTP GenServer's behavior.
Our process keeps a state which is updated in callbacks. 
We only need to provide implementation of some callbacks in order to make our element act in the desired way. 
The set of callbacks that can be implemented depends on the type of the elements and we will get familiar with them during the implementation of these elements.
However, each callback is required to return a tuple of a [specific form](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#t:callback_return_t/0).
As you can see, we are returning a status of the operation, an optional list of [actions](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html#t:t/0) to be performed, and 
the updated state (which later on will be passed to the next invoked callback).
Take your time and read about the possible actions which can be requested to be performed while returning from the callback. Their usage is crucial for the pipeline to work.

As you can judge basing on the structure of the project, all the elements will be put in the `lib/elements` directory. Therefore there is a place where `Source.ex` with the `Basic.Elements.Source` module's definition should be placed.

Let's start with specifying that our module will implement the `Membrane.Source` behavior as well as alias the modules which will be used later in the module's code:
```Elixir
# FILE: lib/elements/Source.ex

defmodule Basic.Elements.Source do
  use Membrane.Source
  alias Membrane.Buffer
  ...
end

```

Later on we will make usage of macros defined in the `Membrane.Source` module:
```Elixir
# FILE: lib/elements/Source.ex

defmodule Basic.Elements.Source do
  ...
  def_options location: [type: :string, description: "Path to the file"]
  def_output_pad :output, caps: {Basic.Formats.Packet, type: :custom_packets}
  ...
end

```

The first macro, `def_options` allows us to define the parameters which are expected to be passed while instantiating of the element. The parameters will be passed as a automatically generated structure `%Basic.Elements.Source{}`. In our case we will have a `:location` field inside of that structure. This parameter is about to be a path to the files which will consist of input packets.

The second macro, `def_output_pad`, helps us define the output pad. The pad name will be `:output` (which is a default name for the output pad). The second argument of the macro describes the `caps:` - which is the type of the data sent through the pad. As the code states, we want to send a data with `Basic.Formats.Packet` format.

Let's define our first callback! Why not to start with [`handle_init/1`](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#c:handle_init/1), which gets called once the element is created?
```Elixir
# FILE: lib/elements/Source.ex
defmodule Basic.Elements.Source do
  ...
  @impl true
  def handle_init(%__MODULE__{location: location}) do
    {:ok,
     %{
       location: location,
       content: nil
     }}
  end
  ...
end
```

Usage of __MODULE__ keyword is equivalent to writing the name of the module itself, which is - `Basic.Elements.Source`.
As said before, `handle_init/1` expects a structure with the previously defined parameters to be passed as an argument.
All we need to do there is to initialize the state - our state will be in a form of a map, and for now on we will put there a `location` (a path to the input file) and the `content`.where we will be holding packets read from the file, which hasn't been sent any further. For now the content is set to nil as we haven't read anything from the input file yet.
You might also wonder what is the purpose of the `@impl true` specifier, put just above the function signature - this is simply a way to tell the compiler that the function defined below is about to be a callback. If we have misspelled the function name (or provided a wrong arguments list), we will be informed in the compilation time.

Before going further you should stop for the moment and read about the [playback states](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:playback_change_t/0) in which the Pipeline (and therefore - it's elements) can be. Generally speaking, there are three playback states: **stopped**, **prepared** and **playing**. The transition between the states can happen automatically or as a result of an user's explicit action.
The callbacks we are about to implement will be called once the transition between playback states occurs.

```Elixir
# FILE: lib/elements/Source.ex
defmodule Basic.Elements.Source do
  ...
  @impl true
  def handle_stopped_to_prepared(_ctx, %{location: location} = state) do
    raw_file_binary = File.read!(location)
    content = String.split(raw_file_binary, "\n")
    state = %{state | content: content}
    { {:ok, [caps: {:output, %Basic.Formats.Packet{type: :custom_packets}}  ] }, state}
  end

  @impl true
  def handle_prepared_to_stopped(_ctx, state) do
    state = %{state | content: nil}
    {:ok, state}
  end
  ...
end

```

