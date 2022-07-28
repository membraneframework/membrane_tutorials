# Dynamic Pads

The solution we have implemented along the tutorial has at least one downside - it is definitely not easily extendable.
What if we needed to support mixing streams coming from three different speakers in the conversation?
Well, we would need to add another input [pad](../glossary/glossary.md#pad) in the [Mixer](../glossary/glossary.md#mixer), for instance - `:third_input` pad, and then update our [pipeline](../glossary/glossary.md#pipeline) definition:

**_`lib/Pipeline.ex`_**

```Elixir
@impl true
def handle_init(_opts) do
 children = %{
    ...
    input3: %Basic.Elements.Source{location: "input.C.txt"},
    ordering_buffer3: Basic.Elements.OrderingBuffer,
    depayloader3: %Basic.Elements.Depayloader{packets_per_frame: 4},
    ...
}
 
 links = [
    ...
    link(:input3) |> to(:ordering_buffer3) |> to(:depayloader3),
    ...
    link(:depayloader3) |> via_in(:third_input) |> to(:mixer),
    ...
 ]
 ...
end
```

But what if there were 4 people in the conversation? Adding another pad to the Mixer would solve the problem, but this solution does not scale well.
And what if the number of speakers was unknown at the moment of the compilation? Then we wouldn't be able to predefine the pads in the Mixer.
The Membrane Framework comes with a solution for this sort of problem - and the solution is called: **dynamic pads**.

## What is the idea behind the dynamic pads?

Well, the idea is quite simple! Instead of specifying a single pad with a predefined name (*static pad*) as we did in all the modules before, we specify, that we want **a set of pads** of a given type. Initially, that set will be empty, but with each link created in the parent's child specification, the [element](../glossary/glossary.md/#element) will be informed, that the pad of a given type was added - and therefore it will be able to invoke the `handle_pad_added/3` callback.

## The Mixer revisited

Let's try to use dynamic pads for the input in the Mixer!
The very first thing we need to do is to use the `def_input_pads` appropriately.

**_`lib/elements/Mixer.ex`_**

```Elixir
...
def_input_pad(:input, demand_unit: :buffers, availability: :on_request, caps: {Basic.Formats.Frame, encoding: :utf8})
...
```

We have added the [`availability: :on_request` option](https://hexdocs.pm/membrane_core/Membrane.Pad.html#t:availability_t/0), which allows us to define the set of dynamic pads, identified as `:input`.

No more do we have the `:first_input` and the `:second_input` pads defined, so we do not have the [tracks](../glossary/glossary.md#track) corresponding to them either! Let's update the `handle_init/1` callback:

**_`lib/elements/Mixer.ex`_**

```Elixir
...
@impl true
def handle_init(_options) do
    { :ok,
        %{ tracks: %{} }
    }
end
...
```

Tracks map is initially empty since there are no corresponding pads.
The next thing we need to do is to implement the `handle_pad_added/3` callback, which will be called once the pipeline starts, with some links pointing to dynamic pads:

**_`lib/elements/Mixer.ex`_**

```Elixir

...
@impl true
def handle_pad_added(pad, _context, state) do
 state = %{state| tracks: Map.put(state.tracks, pad, %Track{})}
 {:ok, state}
end
...
```

Once a pad is created, we add a new `Track` to the tracks map, with the pad being its key.
That's it! Since we have already designed the Mixer in a way it is capable of serving more tracks, there is nothing else to do.

## Updated pipeline

Below you can find the updated version of the pipeline's `handle_init/1` callback:

**_`lib/Pipeline.ex`_**

```Elixir
...
@impl true
def handle_init(_opts) do
 children = %{
    input1: %Basic.Elements.Source{location: "input.A.txt"},
    ordering_buffer1: Basic.Elements.OrderingBuffer,
    depayloader1: %Basic.Elements.Depayloader{packets_per_frame: 4},

    input2: %Basic.Elements.Source{location: "input.B.txt"},
    ordering_buffer2: Basic.Elements.OrderingBuffer,
    depayloader2: %Basic.Elements.Depayloader{packets_per_frame: 4},

    mixer: Basic.Elements.Mixer,
    output: %Basic.Elements.Sink{location: "output.txt"}
 }

 links = [
    link(:input1) |> to(:ordering_buffer1) |> to(:depayloader1),
    link(:input2) |> to(:ordering_buffer2) |> to(:depayloader2),
    link(:depayloader1) |> via_in(Pad.ref(:input, :first)) |> to(:mixer),
    link(:depayloader2) |> via_in(Pad.ref(:input, :second)) |> to(:mixer),
    link(:mixer) |> to(:output)
 ]

 spec = %ParentSpec{children: children, links: links}

 { {:ok, spec: spec}, %{} }
end
...
```

The crucial thing was to change the plain atom name identifying the pad (like `:first_input`) into the [Membrane.Pad.ref/2](https://hexdocs.pm/membrane_core/Membrane.Pad.html#ref/2).
The first argument passed to that function is the name of the dynamic pad's set (in our case: `:input`, as we have defined the `:input` dynamic pads set in the Mixer element), and the second argument is a particular pad identifier.
As you can see, we have created two `:input` pads: `:first` and `:second`. While starting the pipeline, the `handle_pad_added/3` callback will be called twice, once per each dynamic pad created.

## Further actions

As an exercise, you can try to modify the `lib/Pipeline.ex` file and define a pipeline consisting of three parallel branches, being mixed in a single Mixer. Later on, you can check if the pipeline works as expected, by generating the input files out of the conversation in which participate three speakers.

The proposed solution can be found on the [dynamic_pads branch of the template repository](https://github.com/membraneframework/membrane_basic_pipeline_tutorial/tree/dynamic_pads).

If you combine the approach taken in the chapter about [Bin](/basic_pipeline_extension/02_Bin.md) you can simplify this solution by reducing the size of the link defitions inside the pipeline.
