# Source

Let's get to the code!
We will start where all the [pipelines](../glossary/glossary.md#pipeline) start - with the `Source` [element](../glossary/glossary.md#element).
Since this will be the first element we implement, we need to find out something more about how the Membrane Framework's elements should be implemented and some concepts associated with them.
The first thing you need to be aware of is that `Membrane. Element` describes a specific behavior, based on the OTP [GenServer's](https://elixir-lang.org/getting-started/mix-otp/genserver.html) behavior.
Our process keeps a state which is updated in callbacks.
We only need to provide an implementation of some callbacks in order to make our element act in the desired way.
The set of callbacks that can be implemented depends on the type of the elements and we will get familiar with them during the implementation of these elements.
However, each callback is required to return a tuple of a [specific form](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#t:callback_return/0).
As you can see, we are returning an optional list of [actions](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html#t:t/0) to be performed, and
the updated state (which later on will be passed to the next invoked callback).
Take your time and read about the possible actions which can be requested to be performed while returning from the callback. Their usage is crucial for the pipeline to work.

As you can judge based on the structure of the project, all the elements will be put in the `lib/elements` directory. Therefore there is a place where `Source.ex` with the `Basic.Elements.Source` module's definition should be placed.

## What makes our module a Membrane Framework's element?

Let's start with specifying that our module will implement the `Membrane.Source` behavior as well as alias the modules which will be used later in the module's code:

**_`lib/elements/Source.ex`_**

```elixir
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

```elixir
defmodule Basic.Elements.Source do
 ...
  def_options location: [
                spec: String.t(),
                description: "Path to the file"
              ]

  def_output_pad :output,
    accepted_format: %Packet{type: :custom_packets},
    flow_control: :manual
 ...
end
```

The first macro, `def_options` allows us to define the parameters which are expected to be passed while instantiating the element. The parameters will be passed as an automatically generated structure `%Basic.Elements.Source{}`. In our case, we will have a `:location` field inside of that structure. This parameter is about to be a path to the files which will contain input [packets](../glossary/glossary.md#packet).
Later on, while instantiating the Source element, we will be able to write:

```elixir
%Basic.Elements.Source{location: "input.A.txt"}
```

and the `:location` option will be passed during the construction of the element.

The second macro, `def_output_pad`, lets us define the output pad. The pad name will be `:output` (which is a default name for the output pad). The second argument of the macro describes the `:accepted_format` - which is the type of data sent through the pad. As the code states, we want to send data in `Basic.Formats.Packet` format.
What's more, we have specified that the `:output` pad will work in `:manual` mode.
You can read more on pad specification [here](https://hexdocs.pm/membrane_core/Membrane.Pad.html#types).

## Initialization of the element

Let's define our first callback! Why not start with [`handle_init/2`](https://hexdocs.pm/membrane_core/Membrane.Element.Base.html#c:handle_init/2), which gets called once the element is created?

**_`lib/elements/Source.ex`_**

```elixir
defmodule Basic.Elements.Source do
 ...
  @impl true
  def handle_init(_context, options) do
    {[setup: :incomplete],
     %{
       location: options.location,
       content: nil
     }}
  end
 ...
end
```

As said before, `handle_init/2` expects a structure with the previously defined parameters to be passed as an argument.
All we need to do there is to initialize the state - our state will be in a form of a map, and for now on we will put there a `location` (a path to the input file) and the `content`, where we will be holding packets read from the file, which haven't been sent yet. For now, the content is set to nil as we haven't read anything from the input file yet. That's also why we send back the action `setup: :incomplete`. In the next section we'll talk about more involved initialization and resources managed by our element.

> ### TIP
>
> You might also wonder what is the purpose of the `@impl true` specifier, put just above the function signature - this is simply a way to tell the compiler
> that the function defined below is about to be a callback. If we have misspelled the function name (or provided a wrong arguments list), we will be informed in the compilation time.

## Preparing our element

When an element requires more time to initialise, you should delegate complex tasks to `handle_setup/2`. This callback runs after `handle_init/2` if it returns the `setup: :incomplete` action. 
In our example, we'd like to open, read and save the contents of the input file. We then save it in our state as `content`.

**_`lib/elements/Source.ex`_**

```elixir
defmodule Basic.Elements.Source do
 ...
  @impl true
  def handle_setup(_context, state) do
    content =
      File.read!(state.location)
      |> String.split("\n")

    new_state = %{state | content: content}
    {[], new_state}
  end
 ...
end
```

When the setup is complete, the element goes into `playing` state. It can then demand buffers from previous elements and send its `:stream_format` to receiving elements. Since we are implementing a sink we do not have anything to demand from, but we can specify the format. We can do this, for example, in `handle_playing/2`:

**_`lib/elements/Source.ex`_**

```elixir
defmodule Basic.Elements.Source do
 ...
  @impl true
  def handle_playing(_context, state) do
    {[stream_format: {:output, %Packet{type: :custom_packets}}], state}
  end
 ...
end
```

The `:stream_format` action means that we want to transmit the information about the supported [formats](../glossary/glossary.md#stream-format-formerly-caps) through the `output` pad, to the next element in the pipeline. In [chapter 4](../basic_pipeline/04_Caps.md) you will find out more about stream formats and learn why it is required to do so.

## Demands

Before going any further let's stop for a moment and talk about the demands. Do you remember, that the `:output` pad is working in `:manual` mode? That means that the succeeding element has to ask the Source element for the data to be sent and our element has to take care of keeping that data in some kind of buffer until it is requested.
Once the succeeding element requests for the data, the `handle_demand/4` callback will be invoked - therefore it would be good for us to define it:

**_`lib/elements/Source.ex`_**

```elixir
defmodule Basic.Elements.Source do
 ...

 @impl true
 def handle_demand(:output, _size, :buffers, _ctx, state) do
  if state.content == [] do
    { [end_of_stream: :output], state}
  else
    [first_packet | rest] = state.content
    new_state = %{state | content: rest}
    
    actions = [
      buffer: {:output, %Buffer{payload: first_packet}},
      redemand: :output
    ]

    {actions, new_state}
  end
 end
 ...
end
```

The callback's body describes the situation in which some buffers were requested. Then we are checking if we have any packets left in the list persisting in the state of the element. If that list is empty, we are sending an `end_of_stream` action, indicating that there will be no more buffers sent through the `:output` pad and that is why there is no point in requesting more buffers.
However, in case of the `content` list of packets being non-empty, we are taking the head of that list, and storing the remaining tail of the list in the state of the element. Later on, we are defining the actions we want to take - that is, we want to return a buffer with the head packet from the original list. We make use of the [`buffer:` action](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:buffer_t/0), and specify that we want to transmit the [`%Buffer`](https://hexdocs.pm/membrane_core/Membrane.Buffer.html#t:t/0) structure through the `:output` pad. Note the fields available in the `%Buffer` structure - in our case, we make use of only the `:payload` field, which, according to the documentation, can be of `any` type - however, in almost all cases you will need to send binary data within this field. Any structured data (just like timestamps etc.) should be passed in the other fields available in the `%Buffer`, designed especially for that cases.
However, there is the other action that is taken - the `:redemand` action, queued to take place on the `:output` pad. This action will simply invoke the `handle_demand/4` callback once again, which is helpful when the whole demand cannot be completely fulfilled in the single `handle_demand` invocation we are just processing. The great thing here is that the `size` of the demand will be automatically determined by the element and we do not need to specify it anyhow. Redemanding, in the context of sources, helps us simplify the logic of the `handle_demand` callback since all we need to do in that callback is to supply a single piece of data and in case this is not enough, take a [`:redemand`](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:redemand_t/0) action and invoke that callback once again. As you will see later, the process of redemanding is even more powerful in the context of [filter elements](../glossary/glossary.md#filter). 
But don't give up if you don't grasp demands just yet! :) Membrane also supports `:auto` flow control, which takes care of demands and should be enough for 90% of use cases.

By now you should have created a `Basic.Element.Source` element, with options and output pads defined and its `handle_init/2`, `handle_setup/2`, `handle_playing/2` and `handle_demand/5` callbacks implemented.

In the next chapter we will explore what stream formats are in Membrane.
