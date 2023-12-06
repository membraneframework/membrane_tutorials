# Pipeline

The time has come to assemble all the bricks together and create the pipeline!
This task is really easy since the Membrane Framework provides a sort of DSL (*Domain Specific Language*) which allows you to link the prefabricated components together.
In many real-life scenarios, this part would be the only thing you would need to do since you can take advantage of plenty of ready components (in form of [elements](../glossary/glossary.md#element) and [bins](../glossary/glossary.md#bin)) which are available as a part of the Membrane Framework. For now, we will create the pipeline out of the elements we have created during that tutorial!

## Defining the pipeline

The pipeline is another behavior introduced by the Membrane Framework. To make the module a pipeline, we need to make it `use Membrane.Pipeline`. That is how we will start our implementation of the pipeline module, in the `lib/pipeline.ex` file:

**_`lib/pipeline.ex`_**

```elixir

defmodule Basic.Pipeline do

  use Membrane.Pipeline
 ...
end
```

You could have guessed - all we need to do now is to describe the desired behavior by implementing the callbacks! In fact, the only callback we want to implement if the pipeline is the `handle_init/2` callback, called once the pipeline is initialized - of course, there are plenty of other callbacks which you might find useful while dealing with a more complex task. You can read about them [here](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#callbacks).
Please add the following callback signature to our `Basic.Pipeline` module:

**_`lib/pipeline.ex`_**

```elixir

defmodule Basic.Pipeline do
 ...
 @impl true
 def handle_init(_context, _options) do

 end
end
```

As you can see, we can initialize the pipeline with some options, but in our case, we do not need them.

## Supervising and children-parent relationship

In Elixir's actor model, derived from the Erlang programming language (as well as in many other implementations of the actor system) there is a concept of the actors supervising each other.
In case of the actor failing due to an error it is its supervisor's responsibility to deal with that fact - either by stopping that actor, restarting it, or performing some other action.
With such a concept in mind, it's possible to create reliable and fault-tolerant actor systems.
[Here](https://blog.appsignal.com/2021/08/23/using-supervisors-to-organize-your-elixir-application.html) there is a really nice article describing that concept and providing an example of the actor system. Feel free to stop here and read about the supervision mechanism in Elixir if you have never met with that concept before.
Our pipeline will also be an actor system - with the `Basic.Pipeline` module being the supervisor of all its elements.
As you have heard before - it is the supervisor's responsibility to launch its children's processes.
In the Membrane Framework's pipeline there is a special action designed for that purpose - [`:spec`](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html#t:spec/0).
As you can see, you need to specify the `Membrane.ChildrenSpec` for that purpose.

Please stop for a moment and read about the [`Membrane.ChildrenSpec`](https://hexdocs.pm/membrane_core/Membrane.ChildrenSpec.html).
We will wait for you and once you are ready, we will define our own children and links ;)

Let's start with defining what children we need inside the `handle_init/2` callback! If you have forgotten what structure we want to achieve please refer to the [2nd chapter](02_SystemArchitecture.md) and recall what elements we need inside of our pipeline.

**_`lib/pipeline.ex`_**

```elixir
defmodule Basic.Pipeline do
 ...
  @impl true
  def handle_init(_context, _options) do
    spec = [
      child(:input1, %Basic.Elements.Source{location: "input.A.txt"})
      |> child(:ordering_buffer1, Basic.Elements.OrderingBuffer)
      |> child(:depayloader1, %Basic.Elements.Depayloader{packets_per_frame: 4})
      |> via_in(:first_input)
      |> child(:mixer, Basic.Elements.Mixer)
      |> child(:output, %Basic.Elements.Sink{location: "output.txt"}),
      child(:input2, %Basic.Elements.Source{location: "input.B.txt"})
      |> child(:ordering_buffer2, Basic.Elements.OrderingBuffer)
      |> child(:depayloader2, %Basic.Elements.Depayloader{packets_per_frame: 4})
      |> via_in(:second_input)
      |> get_child(:mixer)
    ]

    {[spec: spec], %{}}
  end
 ...
```

Remember to pass the desired file paths in the `:location` option! 

Now... that's it! :) 
The spec list using Membrane's DSL is enough to describe our pipeline's topology. The child keywords spawn components of the specified type and we can use the `|>` operator to link them together. When the pads that should be linked are unamibiguous this is straightforward but for links like those with `Mixer` we can specify the pads using `via_in/1`. There also exists a `via_out/1` keyword which works in a similar way. 
As you can see the first argument to `child/2` is a component identifier, but it's also possible to have anonymous children using `child/1`, which just has Membrane generate a unique id under the hood.

Our pipeline is ready! Let's try to launch it.
We will do so by starting the pipeline, and then playing it. For the ease of use we will do it in a script.

**_`start.exs`_**

```elixir
{:ok, _sup, _pipeline} = Membrane.Pipeline.start_link(Basic.Pipeline)
Process.sleep(500)
```

You can execute it by running `mix run start.exs` in the terminal.

In the output file (the one specified in the `handle_init/1` callback of the pipeline) you should see the recovered conversation.

In case of any problems you can refer to the code on the `template/end` branch of `membrane_basic_pipeline_tutorial` repository.

Now our solution is completed. You have acquired a basic understanding of Membrane, and you can implement a simple pipeline using elements.

If you wish to extend your knowledge of Membrane's concepts we encourage you to read the [extension to this tutorial](../basic_pipeline_extension/01_Introduction.md).
