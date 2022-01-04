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
# What makes our module a Membrane Framework's element?
Let's start with specifying that our module will implement the `Membrane.Source` behavior as well as alias the modules which will be used later in the module's code:
```Elixir
# FILE: lib/elements/Source.ex

defmodule Basic.Elements.Source do
  use Membrane.Source
  alias Membrane.Buffer
  ...
end

```
# Pads and options
Later on we will make usage of macros defined in the `Membrane.Source` module:
```Elixir
# FILE: lib/elements/Source.ex

defmodule Basic.Elements.Source do
  ...
  def_options location: [type: :string, description: "Path to the file"]
  def_output_pad :output, [caps: {Basic.Formats.Packet, type: :custom_packets}, mode: :pull]
  ...
end

```

The first macro, `def_options` allows us to define the parameters which are expected to be passed while instantiating of the element. The parameters will be passed as a automatically generated structure `%Basic.Elements.Source{}`. In our case we will have a `:location` field inside of that structure. This parameter is about to be a path to the files which will consist of input packets.

The second macro, `def_output_pad`, helps us define the output pad. The pad name will be `:output` (which is a default name for the output pad). The second argument of the macro describes the `caps:` - which is the type of the data sent through the pad. As the code states, we want to send a data with `Basic.Formats.Packet` format.
What's more we have specified that the `:output` pad will work in the `:pull` mode. 
You can read more on the pad specification [here](https://hexdocs.pm/membrane_core/Membrane.Pad.html#t:common_spec_options_t/0).
# Initialization of the element
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
# Playback states
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
In case of the first callback, `handle_stopped_to_prepared/2`, what we do is that we are reading the file from the location specified in the options structure, and saved in the state of the element.
Then we split the content of the file to get the particular packets and save the list of those packets in the state of the element.
An interesting thing there is the action we are returning - the `:caps` action. That means that we want to transmit the information about the supported caps through the `output` pad, to the next element in the pipeline. In the [9th chapter](9_Caps.md) you will find out more about caps and formats and learn why it is required to do so.
The second callback, `handle_prepared_to_stopped`, defines behavior of the Source element while we are stopping the pipeline. What we want to do is to clear the content buffer in the state of our element.
# Demands
Before going any further let's stop for a moment and talk about the demands. Do you remember, that the `:output` pad is working in the pulling mode? That means that the succeeding element have to ask the Source element for the data to sent and our element have to take care of keeping that data in some kind of buffer until their are requested. 
Once the succeeding element requests for the data, the `handle_demand/4` callback will be invoked - therefore it would be good for us to define it:
```Elixir
#FILE: lib/elements/Source.ex
defmodule Basic.Elements.Source do
    ...
    @impl true
    def handle_demand(:output, 0, :buffers, _ctx, state) do
        {:ok, state}
    end

    @impl true
    def handle_demand(:output, size, :buffers, _ctx, %{content: content}=state) do
        if content == [] do
            {{:ok, end_of_stream: :output}, state}
        else
            [chosen|rest] = content
            state = %{state | content: rest}
            action = [buffer: {:output, %Buffer{payload: chosen}}]
            action = if size > 1, do: action++[redemand: :output], else: action
            {{:ok, action}, state}
        end
    end
    ...
end

```

The first callback's definition matches the situation in which 0 buffers of data are requested - then we simply do nothing. You might wonder why would anybody like to request for 0 buffers - and you will find out soon that it will be us who will do so!
The second callback's body describes the situation in which some buffers where in fact requested (and therefore the `size` argument is positive). Then we are checking if we have any packets left in the list persisting in the state of the element. If that list if empty, we are sending an `end_of_stream` action, indicating that there will be no more buffers sent through the `:output` pad and that is why there is no point in requesting for more buffers.
However, in case of the `content` list of packets being non-empty, we are taking the head of that list, and store the remaining tail of the list in the state of the element. Later on we are defining the actions we want to take - that is, we want to return a buffer with the head packet from the original list. We make use of the [`buffer:` action](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:buffer_t/0), and specify that we want to transmit the [`%Buffer`](https://hexdocs.pm/membrane_core/Membrane.Buffer.html#t:t/0) structure through the `:output` pad. Note the fields available in the `%Buffer` structure - in this we make use of only the `:payload` fields, which, according to the documentation, can be of `any` type - however in almost all cases you will need to send binary data within this field. Any structured data (just like timestamps etc.) should be passed in the other fields available in the `%Buffer`, designed specially for that cases.
However, there is the other action which is optionally taken if the requested `size` (meaning - the number of buffers requested) is greater than 1 (which basically means that the request cannot completely fulfilled in the single `handle_demand` invocation we are just processing), we specify the `:redemand` action to take place on the `:output` pad. This action will simply queue the `handle_demand/4` callback to be invoked once again. The great thing here is that the `size` of the demand will be automatically determined by the element and we do not need to specify it anyhow. Redemanding, in context of sources, helps use simplify the logic of the `handle_demand` callback since all we need to do in that callback is to supply a single piece of data and in case this is not enough, take a [`:redemand`](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:redemand_t/0) action and invoke that callback once again. As you will see later, the process of redemanding is even more powerful in context of the filter elements, as we will take advantage of the fact that it is asynchronous. 