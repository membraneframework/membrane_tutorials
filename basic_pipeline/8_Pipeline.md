The time has come to assemble all the bricks together and create the pipeline!
This task is really easy since the Membrane Framework provides a sort of DSL (*Domain Specific Language*) which allows you to link the prefabricated components together.
In many real-life scenarios this part would be the only thing you would need to do, since you can take advantage of a great deal of ready components (in form of elements and bins) which are available as a part of the Membrane Framework. For now, we will create the pipeline out of the elements we have prepared during that tutorial!
# Defining the pipeline
Pipeline is another behavior introduced by the Membrane Framework. To make the module a pipeline, we need to make it `use Membrane.Pipeline`. That is how we will start our implementation of the pipeline module, in the `lib/pipeline.ex` file:
```Elixir
# FILE: lib/pipeline.ex

defmodule Basic.Pipeline do

  use Membrane.Pipeline
  ...
end
```

You could have guessed - all we need to do now is to describe the desired behavior by implementing the callbacks! In fact, the only callback we want to implement in case of our pipeline is the `handle_init/1` callback, called once the pipeline is initialized - of course there are plenty of other callbacks which you might find useful while dealing with more complex task. You can read about them (here)[https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#callbacks].
Please add the following callback signature to our `Basic.Pipeline` module:
```Elixir
# FILE: lib/pipeline.ex
defmodule Basic.Pipeline do

  ... 
  @impl true
  def handle_init(_opts) do

  end
end

```
As you can see, we can initialize the pipeline with some options, but in our case we do not need them.

# Supervisioning and children-parent relationship
In Elixir's actor model, derived from the Erlang programming language (as well as in many other implementations of the actor system) there is a concept of the actors supervising each other. 
In case of the actor failing (due to some more or less expected error) it is it's supervisor responsibility to deal with that fact - either by stopping that actor, restarting it or performing some other action.
With such a concept in mind, there is possible to create reliable and fault-tolerant actor systems.
[Here](https://blog.appsignal.com/2021/08/23/using-supervisors-to-organize-your-elixir-application.html) there is a really nice article describing that concept and providing an example of the actor system. Feel free to stop here and read about the supervision machanism in Elixir if you have never met with that concept before.
Our pipeline will also be an actor system - with the `Basic.Pipeline` module being the supervisor of all its elements.
As you have heard before - it is supervisor's responsibility to launch it's children processes. 
In the Membrane Framework's pipeline there is a special action designed for that purpose - [`:spec`](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html#t:spec_t/0). 
As you can see, you need to specify the `Membrane.ParentSpec` for that purpose.
It consists of:
+ `:children` - map of the pipeline's (or a bin) elements
+ `:links` - list consisting of links between the elements

Please stop for a moment and read about the [`Membrane.ParentSpec`](https://hexdocs.pm/membrane_core/Membrane.ParentSpec.html). 
We will wait for you and once you are ready, we will define our own children and links ;)

Let's start with defining what children do we need inside the `handle_init/1` callback! If you have forgotten what structure do we want to achieve please refer to the [2nd chapter](2_SystemArchitecture.md) and recall what elements do we need inside of our pipeline.
```Elixir
# FILE: lib/pipeline.ex

@impl true
def handle_init(_opts) do
    children = %{
      input1: %Basic.Elements.Source{location: "input1.txt"},
      ordering_buffer1: %Basic.Elements.OrderingBuffer{demand_factor: 1},
      depayloader1: %Basic.Elements.Depayloader{demand_factor: 5},

      input2: %Basic.Elements.Source{location: "input2.txt"},
      ordering_buffer2: %Basic.Elements.OrderingBuffer{demand_factor: 1},
      depayloader2: %Basic.Elements.Depayloader{demand_factor: 5},

      mixer: %Basic.Elements.Mixer{demand_factor: 1},
      output: %Basic.Elements.Sink{location: "output.txt"}
    }
end
```
We have just created the map, which key is in the form of an atom which name describes the particular child, and the value is a particular module built-in structure (with all the required fields passed).

Now we have a `children` map which we will use to launch the processes. But the Membrane needs to know how those children elements are connected (and, in fact, how the pipeline is defined!). Therefore let's create a `links` list with the description of the links between the elements:
```Elixir
# FILE: lib/pipeline.ex

def handle_init(_opts) do
    ...
    links = [
        link(:input1) |> to(:ordering_buffer1) |> to(:depayloader1),
        link(:input2) |> to(:ordering_buffer2) |> to(:depayloader2),
        link(:depayloader1) |> via_in(:first_input) |> to(:mixer),
        link(:depayloader2) |> via_in(:second_input) |> to(:mixer),
        link(:mixer) |> to(:output)
        ]
    ...
end
```
I hope the syntax is visually descriptive enough to show what is the desired result of that definition. But to make sure everything is clear to you let me tell you something about it.
Each pipeline's "branch" starts with the `link/1` which takes as an argument an atom corresponding to a given element. All the further elements in the branch can be accessed with the use of the `to/1` function, expecting and atom which identifies that element to be passed as it's argument. Note, that the mentioned atoms must be the same as the ones you have used as a keys in the `children` map!
`|>` operator allows "linking" of the elements accessed in the way described above, via their pads.By default, the elements' link will be using a `:input` pad as the input pad and a `:output` pad as the output pad.
`via_in/1` allows to specify an input pad with a given name. Since in a mixer there are two input pads (`:first_input` and `:second_input`, defined in `Basic.Elements.Mixer` module with `def_input_pad` and `def_output_pad` macros), we need to distinguish between them while linking the elements. 
Of course there is also a `via_out/1` function, which is used to point the output pad with given identifier, but there was no need to use it. 
In case of other elements we do not need to explicitly point the desired pads since we are taking advantage of the default pads name - `:input` for the input pads and `:output` for the output ones (see what names we have given to our pads in the elements other than the mixer!). However, we could rewrite the following `links` definitions and explicitly specify the pad names:
```Elixir
# FILE: lib/pipeline.ex

def handle_init(_opts) do
    ...
    links = [
        link(:input1) |> via_out(:output) |> via_in(:input) |> to(:ordering_buffer1) |> via_out(:output) |> via_in(:input) |> to(:depayloader1),
        link(:input2) |> via_out(:output) |> via_in(:input) |> to(:ordering_buffer2) |> via_out(:output) |> via_in(:input) |>to(:depayloader2),
        link(:depayloader1) |> via_out(:output) |> via_in(:first_input) |> to(:mixer),
        link(:depayloader2) |> via_out(:output) |> via_in(:second_input) |> to(:mixer),
        link(:mixer) |> |> via_out(:output) |> via_in(:input) |> to(:output)
        ]
    ...
end
```

That's almost it! All we need to do is to return a proper tuple from the `handle_init/1` callback, with the `:spec` action defined:
```Elixir
# FILE: lib/pipeline.ex

def handle_init(_opts) do
    ...
    spec = %ParentSpec{children: children, links: links}
    {{:ok, spec: spec}, %{}}
end
```
