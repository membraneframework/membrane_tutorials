# Source

Let's get to the code!
We will start where all the [pipelines](../glossary/glossary.md#pipeline) start - with the `Source` [element](../glossary/glossary.md#element).
Since this will be the first element we implement, we need to find out something more about how the Membrane Framework's elements should be implemented and some concepts associated with them.
The first thing you need to be aware of is that `Membrane. Element` describes a specific behavior, based on the OTP [GenServer's](https://elixir-lang.org/getting-started/mix-otp/genserver.html) behavior.
Our process keeps a state which is updated in callbacks.
We only need to provide an implementation of some callbacks in order to make our element act in the desired way.
The set of callbacks that can be implemented depends on the type of the elements and we will get familiar with them during the implementation of these elements.
However, each callback is required to return a tuple of a [specific form](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#t:callback_return_t/0).
As you can see, we are returning a status of the operation, an optional list of [actions](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html#t:t/0) to be performed, and
the updated state (which later on will be passed to the next invoked callback).
Take your time and read about the possible actions which can be requested to be performed while returning from the callback. Their usage is crucial for the pipeline to work.

As you can judge based on the structure of the project, all the elements will be put in the `lib/elements` directory. Therefore there is a place where `Source.ex` with the `Basic.Elements.Source` module's definition should be placed.

## What makes our module a Membrane Framework's element?

Let's start with specifying that our module will implement the `Membrane.Source` behavior as well as alias the modules which will be used later in the module's code:

**_`lib/elements/Source.ex`_**

```Elixir
defmodule Basic.Elements.Source do
 use Membrane.Source
 alias Membrane.Buffer
 alias Basic.Formats.Packet
 ...
end

```

## Pads and options

Later on, we will make use of [macros](https://elixir-lang.org/getting-started/meta/macros.html) defined in the `Membrane.Source` module:

**_`lib/elements/Source.ex`_**

```Elixir
defmodule Basic.Elements.Source do
 ...
 def_options location: [type: :string, description: "Path to the file"]
 def_output_pad :output, [caps: {Packet, type: :custom_packets}, mode: :pull]
 ...
end

```

The first macro, `def_options` allows us to define the parameters which are expected to be passed while instantiating the element. The parameters will be passed as an automatically generated structure `%Basic.Elements.Source{}`. In our case, we will have a `:location` field inside of that structure. This parameter is about to be a path to the files which will contain input [packets](../glossary/glossary.md#packet).
Later on, while instantiating the Source element, we will be able to write:

```Elixir
%Basic.Elements.Source{location: "input.A.txt"}
```

and the `:location` option will be passed during the construction of the element.

The second macro, `def_output_pad`, lets us define the output pad. The pad name will be `:output` (which is a default name for the output pad). The second argument of the macro describes the `:caps` - which is the type of data sent through the pad. As the code states, we want to send data in `Basic.Formats.Packet` format.
What's more, we have specified that the `:output` pad will work in the `:pull` mode.
You can read more on the pad specification [here](https://hexdocs.pm/membrane_core/Membrane.Pad.html#t:common_spec_options_t/0).

## Initialization of the element

Let's define our first callback! Why not start with [`handle_init/1`](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#c:handle_init/1), which gets called once the element is created?

**_`lib/elements/Source.ex`_**

```Elixir
defmodule Basic.Elements.Source do
 ...
 @impl true
 def handle_init(options) do
  {:ok,
    %{
      location: options.location,
      content: nil
    }
  }
 end
 ...
end
```

As said before, `handle_init/1` expects a structure with the previously defined parameters to be passed as an argument.
All we need to do there is to initialize the state - our state will be in a form of a map, and for now on we will put there a `location` (a path to the input file) and the `content`, where we will be holding packets read from the file, which haven't been sent yet. For now, the content is set to nil as we haven't read anything from the input file yet.

> ### TIP
>
> You might also wonder what is the purpose of the `@impl true` specifier, put just above the function signature - this is simply a way to tell the compiler
> that the function defined below is about to be a callback. If we have misspelled the function name (or provided a wrong arguments list), we will be informed in the compilation time.

## Playback states

Before going further you should stop for the moment and read about the [playback states](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:playback_change_t/0) in which the Pipeline (and therefore - its elements) can be. Generally speaking, there are three playback states: **stopped**, **prepared**, and **playing**. The transition between the states can happen automatically or as a result of a user's explicit action.
The callbacks we are about to implement will be called once the transition between playback states occurs.

**_`lib/elements/Source.ex`_**

```Elixir
defmodule Basic.Elements.Source do
 ...
 @impl true
 def handle_stopped_to_prepared(_ctx, state) do
  raw_file_binary = File.read!(state.location)
  content = String.split(raw_file_binary, "\n")
  state = %{state | content: content}
  { {:ok, [caps: {:output, %Packet{type: :custom_packets} }]}, state}
 end

 @impl true
 def handle_prepared_to_stopped(_ctx, state) do
  state = %{state | content: nil}
  {:ok, state}
 end
 ...
end

```

In the case of the first callback, `handle_stopped_to_prepared/2`, what we do is that we are reading the file from the location specified in the options structure (which we have saved in the state of the element).
Then we split the content of the file to get the particular packets and save the list of those packets in the state of the element.
An interesting thing here is the action we are returning - the `:caps` action. That means that we want to transmit the information about the supported [caps](../glossary/glossary.md#caps) through the `output` pad, to the next element in the pipeline. In the [chapter 4](/04_Caps.md) you will find out more about caps and formats and learn why it is required to do so.
The second callback, `handle_prepared_to_stopped`, defines the behavior of the Source element while we are stopping the pipeline. What we want to do is to clear the content buffer in the state of our element.

## Demands

Before going any further let's stop for a moment and talk about the demands. Do you remember, that the `:output` pad is working in the pulling mode? That means that the succeeding element have to ask the Source element for the data to be sent and our element has to take care of keeping that data in some kind of buffer until it is requested.
Once the succeeding element requests for the data, the `handle_demand/4` callback will be invoked - therefore it would be good for us to define it:

**_`lib/elements/Source.ex`_**

```Elixir
defmodule Basic.Elements.Source do
 ...

 @impl true
 def handle_demand(:output, _size, :buffers, _ctx, state) do
  if state.content == [] do
    { {:ok, end_of_stream: :output}, state}
  else
    [first_packet | rest] = state.content
    state = %{state | content: rest}
    action = [buffer: {:output, %Buffer{payload: first_packet} }]
    action = action ++ [redemand: :output]
    { {:ok, action}, state}
  end
 end
 ...
end

```

The callback's body describes the situation in which some buffers were requested. Then we are checking if we have any packets left in the list persisting in the state of the element. If that list is empty, we are sending an `end_of_stream` action, indicating that there will be no more buffers sent through the `:output` pad and that is why there is no point in requesting more buffers.
However, in case of the `content` list of packets being non-empty, we are taking the head of that list, and storing the remaining tail of the list in the state of the element. Later on, we are defining the actions we want to take - that is, we want to return a buffer with the head packet from the original list. We make use of the [`buffer:` action](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:buffer_t/0), and specify that we want to transmit the [`%Buffer`](https://hexdocs.pm/membrane_core/Membrane.Buffer.html#t:t/0) structure through the `:output` pad. Note the fields available in the `%Buffer` structure - in our case, we make use of only the `:payload` field, which, according to the documentation, can be of `any` type - however, in almost all cases you will need to send binary data within this field. Any structured data (just like timestamps etc.) should be passed in the other fields available in the `%Buffer`, designed especially for that cases.
However, there is the other action that is taken - the `:redemand` action, queued to take place on the `:output` pad. This action will simply invoke the `handle_demand/4` callback once again, which is helpful when the whole demand cannot be completely fulfilled in the single `handle_demand` invocation we are just processing. The great thing here is that the `size` of the demand will be automatically determined by the element and we do not need to specify it anyhow. Redemanding, in the context of sources, helps us simplify the logic of the `handle_demand` callback since all we need to do in that callback is to supply a single piece of data and in case this is not enough, take a [`:redemand`](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:redemand_t/0) action and invoke that callback once again. As you will see later, the process of redemanding is even more powerful in the context of the [filter elements](../glossary/glossary.md#filter).

By now you should have created `Basic.Element.Source` element, with options and output pads defined and its `handle_init/1`, `handle_stopped_to_prepared/2`, `handle_prepared_to_stopped/2` and `handle_demand/5` callbacks implemented.

In the next chapter we will explore what `caps` are in Membrane.
