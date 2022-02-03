Even not-so-much experienced developer could have noticed that we were missing a really important part of software development - the testing. Don't worry! We are hurrying with the description of testing framework and good practices which will allow you to write reliable tests for you Membrane system.
# Why do we need to test?
Testing in terms of the software engineering is no less important then funcionalities programming.
I am sure I do not need to persuade you that our pipeline, and especially speaking - its elements, needs testing.
That's why we will imediatelly jump to the code and try to experience the Membrane tests on our own.
# Our first test
Elixir comes with a great tool for testing - [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html).
If you have never written tests in ExUnit, feel free to stop for a moment and read about how the tests are constructed - however, ExUnit deals with tests in such a clear way that probably you will be able to see what's going on by just looking at the code snippets in the further part of this tutorial.
We need to specify, that we will be writing only unit tests - that means, we will write tests checking the behavior of a single element, isolated from the other elements in the pipeline.
Let's create a `test/elements/depayloader_test.exs` file and put the following code inside it:
```Elixir
#FILE: test/elements/depayloader_test.exs

defmodule DepayloaderTest do
  use ExUnit.Case   
  
  doctest Basic.Elements.OrderingBuffer

  test "Depayloader should assemble the packets and form a frame" do
    ...
  end
end
```
This way we are defining a testing module with the use of the ExUnit, as well as a single test (we will put the test logic inside the inner `do...end` scope). 
The `doctest` macro checks if the given module has a proper documentation (typespecs, module description etc.).

We have decided to show the process of writing tests based on the depayloader - since the the behavior of this element is well described and can be easly checked. Let's recall what is the responsibility of the depayloader - this element is receiving ordered packets and is about to form frames out of them. Let's check if it is doing it properly!
```Elixir
#FILE: test/elements/depayloader_test.exs

defmodule DepayloaderTest do
    ...
    alias Basic.Elements.Depayloader
    alias Membrane.Buffer
    
    test "Depayloader should assemble the packets and form a frame" do
        {:ok, state} = Depayloader.handle_init(%Depayloader{packets_per_frame: 5})
        {:ok, state} = Depayloader.handle_process(:input, %Buffer{payload: "[frameid:1s][timestamp:1]Hello! "}, nil, state)
        {:ok, state} = Depayloader.handle_process(:input, %Buffer{payload: "[frameid:1][timestamp:1]How are"}, nil, state)
        {{:ok, actions}, _state} = Depayloader.handle_process(:input, %Buffer{payload: "[frameid:1e][timestamp:1] you?"}, nil, state)
        [buffer: {:output, buffer}] = actions
        assert buffer.payload == "Hello! How are you?"
    end
end
```

We have been explicitely calling the callbacks defined in the `Depayloader` module, with the appropriate arguments.
First, we have initialized the state by calling the `handle_init/1` callback, later on we have made the depayloader `handle_process/4` some buffers (note that we had to explicitly pass the `%Membrane.Buffer{}` structure as the argument of the function invocation as well as keep track of the state, which gets updated after each call). 
Finally, after the last buffer is processed (the last buffer is the buffer whose `frameid` should contain the `e` letter meaning that that is the packet which is ending a given frame), we are expecting the action being returned - and this action should be a `:buffer` actions, transmitting the buffer with the complete frame through the `:output` pad. We also assert (using the ExUnit's [`assert`](https://hexdocs.pm/ex_unit/ExUnit.Assertions.html#assert/1) macro) the value hold in the buffer's payload (It should be a complete sentence).
If no action was returned from the last `handle_process/4`, the pattern wouldn't match to the `{{:ok, actions}, _state}`, and the test would fail.
If the assertion on the output buffer's payload wouldn't be true - the test would also fail.

# The Membrane's support for tests
The test written above is quite simple. Probably you have noticed that what we did there was "simulating" the behavior of the Membrane's Core, in a limited, but satisfying our needs, way. During the pipeline run it is Membrane's responsibility to invoke the callbacks and pass the updated version of the state as the argument.
However Membrane's Core behavior is much more complecated - if we were using some more complex mechanism (i.e. redemands), possibly we would need to simulate that behavior in a more detailed way - finally ending with the Membrane's Core in our test module.
Such an approach scales terribly - and that is why we want to avoid it. Membrane Core's developers have given us a support for testing the elements which allows us to have a simple pipeline consisting of a generic source and sink, as well as our element.
Such a pipeline behaves just like any other pipeline in a regular working Membrane system - however, we are also given a bunch of helpful tools (like assertion macros) to chceck if our element has a desired buissness logic implemented in its behavior.
Below we will rewrite the test we have just written, but with the support from the Membrane Framework:
```Elixir
#FILE: test/elemets/depayloader_test.exs

defmodule DepayloaderTest do
    ...
    alias Membrane.Buffer

    alias Membrane.Testing.{Source, Sink}

    import Membrane.Testing.Assertions
    alias Membrane.Testing.{Source, Sink, Pipeline}

    test "Depayloader should assemble the packets and form a frame (with membrane's testing framework)" do
        inputs = ["[frameid:1s][timestamp:1]Hello! ", "[frameid:1][timestamp:1]How are", "[frameid:1e][timestamp:1] you?"]
        options = %Pipeline.Options{
        elements: [
            source: %Source{output: inputs, caps: %Basic.Formats.Packet{type: :custom_packets}},
            depayloader: %Depayloader{packets_per_frame: 5},
            sink: Sink
        ]
        }

        {:ok, pipeline} = Pipeline.start_link(options)
        Pipeline.play(pipeline)
        assert_start_of_stream(pipeline, :sink)

        assert_sink_buffer(pipeline,:sink, %Buffer{payload: "Hello! How are you?"})

        assert_end_of_stream(pipeline, :sink)
        refute_sink_buffer(pipeline, :sink, _, 0)
        Pipeline.stop_and_terminate(pipeline, blocking?: true)
    end

end
```