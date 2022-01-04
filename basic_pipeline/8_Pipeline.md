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
@impl true
  def handle_init(_opts) do

  end
```
As you can see, we can initialize the pipeline with some option, but in our case we do not need them.

# Supervisioning and children-parent relationship