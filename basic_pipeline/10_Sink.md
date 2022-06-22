# Sink

The sink is the last element in our pipeline, designed to store the data processed by the pipeline.
In contrast to the filter elements, it won't have any output pad - that is why we need to make our element `use Membrane.Sink` and define the input pad only.
Since we want to parameterize the usage of that element, it will be good to define the options structure, so that we can specify the path to the file where the output should be saved. This stuff is done in the code snippet below:

###### **`lib/elements/Sink.ex`**

```Elixir

defmodule Basic.Elements.Sink do
 @moduledoc """
 An element writing the data to the text file.
 """

 use Membrane.Sink

 def_options(location: [type: :string, description: "Path to the file"])

 def_input_pad(:input, demand_unit: :buffers, caps: :any)
 ...
end
```

No surprises there - now we need to specify the element's behavior by defining the relevant callbacks!

###### **`lib/elements/Sink.ex`**

```Elixir

defmodule Basic.Elements.Sink do
 ...
 @impl true
 def handle_init(options) do
  {:ok,
  %{
    location: options.location
  } }
 end
 ...
end
```

We have started with `handle_init/1`, where we are initializing the state of the element (we need to store the path to the output files).

Later on, we can specify the `handle_prepared_to_playing/2` callback - this callback gets called once the pipeline gets in the `:playing` state - that is a moment when we can demand the buffers for the first time (since the pipeline is already prepared to work):

###### **`lib/elements/Sink.ex`**

```Elixir

defmodule Basic.Elements.Sink do
 ...
 @impl true
 def handle_prepared_to_playing(_ctx, state) do
  { {:ok, demand: {:input, 10} }, state}
 end
 ...
end
```

There is only one more callback that needs to be specified - `handle_write/4`, which get's called once there are some buffers that can be processed (which means, that there are buffers to be written since there are no output pads through which we could be transmitting these buffers):

###### **`lib/elements/Sink.ex`**

```Elixir

defmodule Basic.Elements.Sink do
 ...
 @impl true
 def handle_write(:input, buffer, _ctx, state) do
  File.write!(state.location, buffer.payload <> "\n", [:append])
  { {:ok, demand: {:input, 10} }, state}
 end
end
```

Note, that after the successful writing, we are taking the `:demand` action and we ask for some more buffer.

With the `Sink` completed, we have implemented all elements of our pipeline. Now let's move to the very last step - defining the actual pipeline using the elements we have created.
