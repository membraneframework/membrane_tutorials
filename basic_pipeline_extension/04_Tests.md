# Tests

When creating elements for the basic pipeline you used the provided tests.
In this chapter we will explain in detail how they work, and give you with some good practices which will allow you to write reliable tests for your Membrane system.

## Do we need testing?

Testing in terms of software engineering is no less important than functionalities programming.
We are sure we do not need to persuade you that our [pipeline](../glossary/glossary.md#pipeline), and especially its elements need testing. In fact - who wouldn't like to be sure, that changes just made in the functionalities code do not break the desired element's behavior? And all that in the matter of typing simple `mix test` command?

In the scope of this chapter we will implement some unit tests for the elements of our pipeline. They will check the behavior of the elements in isolation.
We will immediately jump to the code and try to experience the Membrane tests on our own.

## Our first test

Elixir comes with a great tool for testing - [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html).
If you have never written tests in ExUnit, feel free to stop for a moment and read about how the tests are constructed - however, ExUnit deals with tests in such a clear way that probably you will be able to see what's going on by just looking at the code snippets in the further part of this tutorial.
We need to specify, that we will be writing only unit tests - that means, we will write tests checking the behavior of a single [element](../glossary/glossary.md/#element), isolated from the other elements in the pipeline.
Let's create a `test/elements/depayloader_test.exs` file and put the following code inside it:

**_`test/elements/depayloader_test.exs`_**

```Elixir
defmodule DepayloaderTest do
 use ExUnit.Case 
 doctest Basic.Elements.Depayloader

 test "Depayloader should assemble the packets and form a frame" do
  ...
 end
end
```

This way we are defining a testing module with the use of the ExUnit, as well as a single test (we will put the test logic inside the inner `do...end` scope).
The `doctest` macro checks if the given module has proper documentation (typespecs, module description etc.).

We have decided to show the process of writing tests based on the depayloader - since the behavior of this element is well described and can be easily checked. Let's recall what is the responsibility of the depayloader - this element is receiving ordered [packets](../glossary/glossary.md#packet) and is about to form [frames](../glossary/glossary.md#frame) out of them. Let's check if it is doing it properly!

**_`test/elements/depayloader_test.exs`_**

```Elixir
defmodule DepayloaderTest do
 ...
 alias Basic.Elements.Depayloader
 alias Membrane.Buffer
 
 test "Depayloader should assemble the packets and form a frame" do
  {:ok, state} = Depayloader.handle_init(%Depayloader{packets_per_frame: 5})

  {:ok, state} =
    Depayloader.handle_process(
      :input,
      %Buffer{payload: "[frameid:1s][timestamp:1]Hello! "},
      nil,
      state
    )

  {:ok, state} =
    Depayloader.handle_process(
      :input,
      %Buffer{payload: "[frameid:1][timestamp:1]How are"},
      nil,
      state
    )

  { {:ok, actions}, _state} =
    Depayloader.handle_process(
      :input,
      %Buffer{payload: "[frameid:1e][timestamp:1] you?"},
      nil,
      state
    )

  [buffer: {:output, buffer}] = actions
  assert buffer.payload == "Hello! How are you?"
 end
end
```

We have been explicitly calling the callbacks defined in the `Depayloader` module, with the appropriate arguments.
First, we have initialized the state by calling the `handle_init/1` callback, later on, we have made the depayloader `handle_process/4` some [buffers](../glossary/glossary.md#buffer) (note that we had to explicitly pass the `%Membrane.Buffer{}` structure as the argument of the function invocation as well as keep track of the state, which gets updated after each call).
Finally, after the last buffer is processed (the last buffer is the buffer whose `frameid` should contain the `e` letter meaning that that is the packet that is ending a given frame), we are expecting the action to be returned - and this action should be a `:buffer` actions, transmitting the buffer with the complete frame through the `:output` pad. We also assert (using the ExUnit's [`assert`](https://hexdocs.pm/ex_unit/ExUnit.Assertions.html#assert/1) macro) the value hold in the buffer's payload (It should be a complete sentence).
If no action was returned from the last `handle_process/4`, the pattern wouldn't match to the `{ {:ok, actions}, _state}`, and the test would fail.
If the assertion on the output buffer's payload wouldn't be true - the test would also fail.

## The Membrane's support for tests

The test written above is quite simple. Probably you have noticed that what we did there was "simulating" the behavior of the Membrane's Core, in a limited, but satisfying our needs, way. During the pipeline run, it is Membrane's responsibility to invoke the callbacks and pass the updated version of the state as the argument.
However, Membrane's Core behavior is much more complicated - if we were using some more complex mechanism (i.e. [redemands](../glossary/glossary.md#redemands)), possibly we would need to simulate that behavior in a more detailed way - finally ending with the Membrane's Core in our test module.
Such an approach scales terribly - and that is why we want to avoid it. Membrane Core's developers have given us support for testing the elements which allow us to have a simple pipeline consisting of a generic [source](../glossary/glossary.md#source) and [sink](../glossary/glossary.md#sink), as well as our element.
Such a pipeline behaves just like any other pipeline in a regular working Membrane system - however, we are also given a bunch of helpful tools (like assertion macros) to check if our element has a desired business logic implemented in its behavior.
Below we will rewrite the test we have just written, but with the support from the Membrane Framework:

**_`test/elements/depayloader_test.exs`_**

```Elixir
defmodule DepayloaderTest do
  ...
  alias Membrane.Buffer

  alias Membrane.Testing.{Source, Sink}

  import Membrane.Testing.Assertions
  alias Membrane.Testing.{Source, Sink, Pipeline}
  alias Basic.Formats.Packet

  test "Depayloader should assemble the packets and form a frame (with membrane's testing framework)" do
    inputs = [
      "[frameid:1s][timestamp:1]Hello! ",
      "[frameid:1][timestamp:1]How are",
      "[frameid:1e][timestamp:1] you?"
    ]

    options = %Pipeline.Options{
      elements: [
        source: %Source{output: inputs, caps: %Packet{type: :custom_packets} },
        depayloader: %Depayloader{packets_per_frame: 5},
        sink: Sink
      ]
    }

    {:ok, pipeline} = Pipeline.start_link(options)
    Pipeline.play(pipeline)
    assert_start_of_stream(pipeline, :sink)

    assert_sink_buffer(pipeline, :sink, %Buffer{payload: "Hello! How are you?"})

    assert_end_of_stream(pipeline, :sink)
    refute_sink_buffer(pipeline, :sink, _, 0)
    Pipeline.stop_and_terminate(pipeline, blocking?: true)
 end
end
```

First, we have defined a `:inputs` list, consisting of the messages which will be wrapped by the `Membrane.Buffer` and used to "feed" our element.
Later on, we have specified the testing pipeline with the `%Membrane.Testing.Pipeline.Options` structure.
Our testing pipeline consists only of three elements - the source, the sink, and the element we are about to test.
We are specifying these elements by passing options structures, just as in the case of the regular pipeline.
The generic [`Membrane.Testing.Source`](https://hexdocs.pm/membrane_core/Membrane.Testing.Source.html) accepts `:output` field as one of its options - we can pass the list of payloads which will be sent through the `:output` pad of the testing - in our case we are passing the previously defined `:inputs` list.
It is also important to specify the `:caps` option, because, as you remember, the Source element is responsible for generating the [caps](../glossary/glossary.md#caps). In our case, we have specified the caps, which will be accepted by the Depayloader's caps specification.
Once the pipeline structure is defined, we can start the pipeline process.
Just after that, we start playing the pipeline.
And here comes the assertions section - we are taking advantage of some (Membrane specific assertions\](https://hexdocs.pm/membrane_core/Membrane.Testing.Assertions.html):

- first, we are asserting that the stream has started, with the `assert_start_of_stream/2`
- then we are asserting that the ink has received a buffer of a given form (in our case - we want the sink to receive the buffer with a frame assembled out of the input packets) - with the help of `assert_sink_buffer/3`
- then we are asserting that `:end_of_stream` has reached the `:sink` - with `assert_end_of_stream/2`
- the last assertion we made is that the `:sink` hasn't received any buffer within 2000 milliseconds - and `refute_sink_buffer/4` helps us do it

Finally, we need to stop and terminate our pipeline. It is a good practice to do it in a blocking manner so that the test returns after the pipeline is terminated.

At the first glance, this might look like a little bit of overkill to use the Membrane's testing framework - the amount of code in this particular test has swollen enormously!
But that is just because the functionality we are testing is quite simple.
Keep in mind that in the second test we are making some additional, more complicated assertions - just imagine if you were about to check if no buffer has reached the `:sink` after the `:end_of_stream` was sent - it wouldn't be that easy, would it?
With the Membrane's testing framework you can do it in one line only!

Now we can run the tests with a simple [mix](../glossary/glossary.md#mix) task, by typing:

```
mix test
```

If everything works (both the tests and the functionality's code itself), you should see a notification that the test has passed successfully, which we hope you do see!

## Some special types of tests

As you remember, Source and Sink elements act specifically different than the [Filter elements](../glossary/glossary.md#filter) - that is why they are communicating with the 'outer world', i.e. by reading the data from a file or saving the result to the file. In order to check if their behavior is desired, we cannot create a testing pipeline with generic Source and Sink, since it is a Source/Sink that we want to test.
We will need to somehow mock the `outer environment` - let's see how this can be done, based on the example of the Source test:

**_`test/elements/source_test.exs`_**

```Elixir
defmodule SourceTest do
 use ExUnit.Case, async: false
 import Mock
 alias Basic.Elements.Source
 alias Membrane.Buffer

 doctest Basic.Elements.Source

 @exemplary_content ["First Line", "Second Line"]
 @exemplary_location "path/to/file"
 @options %Source{location: @exemplary_location}
 ....

 test "reads the input file correctly" do
  with_mock File, read!: fn _ -> "First Line\nSecond Line" end do
    { {:ok, _}, state} =
    Source.handle_stopped_to_prepared(nil, %{location: @exemplary_location, content: nil})

    assert state.content == @exemplary_content
  end
 end
```

We take advantage of the [Mock](https://hexdocs.pm/mock/Mock.html) library which is designed to help us substitute the function invocations.
As you can see in the code snippet above, we have mocked the invocations of the `File.read!` function - inside the scope of `with_mock/2` they are always returning `"First Line\nSecondLine"`.
That makes our test so much easier since we do not need to create a mock file with some content meant just for testing - the whole test is defined inside one file.

Would you be able to write some more tests for the other pipeline's elements yourself? Or perhaps you could try to extend the tests for the element we have just checked in action?
Give it a try, as it is a great exercise that will not only examine if you are familiar with testing the Membrane's system but also - do you understand functionalities of the elements and what is the element generic behavior!

When writing your tests for other elements feel free to take inspiration from the ones we provided in the `test/` directory. You can find them [here](https://github.com/membraneframework/membrane_basic_pipeline_tutorial/tree/template/end/test).
