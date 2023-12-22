# Dynamic Pads

The solution we have implemented along the tutorial has at least one downside - it is definitely not easily extendable.
What if we needed to support mixing streams coming from three different speakers in the conversation?
Well, we would need to add another input [pad](../glossary/glossary.md#pad) in the [Mixer](../glossary/glossary.md#mixer), for instance - `:third_input` pad, and then update our [pipeline](../glossary/glossary.md#pipeline) definition:

**_`lib/Pipeline.ex`_**

```elixir
@impl true
def handle_init(_ctx, _opts) do
 spec = [
   ...
   child(:input3, %Basic.Elements.Source{location: "input.C.txt"}) 
   |> child(:ordering_buffer3, Basic.Elements.OrderingBuffer) 
   |> child(:depayloader3, %Basic.Elements.Depayloader{packets_per_frame: 4}),
   ...
   get_child(:depayloader3) 
   |> via_in(:third_input) 
   |> get_child(:mixer),
 ]
 ...
end
```

But what if there were 4 people in the conversation? Adding another pad to the Mixer would solve the problem, but this solution does not scale well.
And what if the number of speakers was unknown at the moment of the compilation? Then we wouldn't be able to predefine the pads in the Mixer.
The Membrane Framework comes with a solution for this sort of problem - and the solution is called: **dynamic pads**.

## What is the idea behind the dynamic pads?

Well, the idea is quite simple! Instead of specifying a single pad with a predefined name (*static pad*) as we did in all the modules before, we specify, that we want **a set of pads** of a given type. Initially, that set will be empty, but with each link created in the parent's child specification, the [element](../glossary/glossary.md#element) will be informed, that the pad of a given type was added - and therefore it will be able to invoke the `handle_pad_added/3` callback.

## The Mixer revisited

Let's try to use dynamic pads for the input in the Mixer!
The very first thing we need to do is to use the `def_input_pads` appropriately.

**_`lib/elements/Mixer.ex`_**

```elixir
...
def_input_pad :input, 
   demand_unit: :buffers, 
   flow_control: :pull, 
   availability: :on_request, 
   accepted_format: %Basic.Formats.Frame{encoding: :utf8}
...
```

We have added the [`availability: :on_request` option](https://hexdocs.pm/membrane_core/Membrane.Pad.html#t:availability/0), which allows us to define the set of dynamic pads, identified as `:input`.

No more do we have the `:first_input` and the `:second_input` pads defined, so we do not have the [tracks](../glossary/glossary.md#track) corresponding to them either! Let's update the `handle_init/2` callback:

**_`lib/elements/Mixer.ex`_**

```elixir
...
@impl true
def handle_init(_ctx, _options) do
    {[], %{ tracks: %{} }}
end
...
```

Tracks map is initially empty since there are no corresponding pads.
The next thing we need to do is to implement the `handle_pad_added/3` callback, which will be called once the pipeline starts, with some links pointing to dynamic pads:

**_`lib/elements/Mixer.ex`_**

```elixir
...
@impl true
def handle_pad_added(pad, _context, state) do
 state = %{state | tracks: Map.put(state.tracks, pad, %Track{})}
 {[], state}
end
...
```

Once a pad is created, we add a new `Track` to the tracks map, with the pad being its key.
That's it! Since we have already designed the Mixer in a way it is capable of serving more tracks, there is nothing else to do.

## Updated pipeline

Below you can find the updated version of the pipeline's `handle_init/2` callback:

**_`lib/Pipeline.ex`_**

```elixir
...
@impl true
def handle_init(_ctx, _opts) do
 spec = [
    child(:input1, %Basic.Elements.Source{location: "input.A.txt"}) 
    |> child(:ordering_buffer1, Basic.Elements.OrderingBuffer) 
    |> child(:depayloader1, %Basic.Elements.Depayloader{packets_per_frame: 4}),
    child(:input2, %Basic.Elements.Source{location: "input.B.txt"}) 
    |> child(:ordering_buffer2, Basic.Elements.OrderingBuffer) 
    |> child(:depayloader2, %Basic.Elements.Depayloader{packets_per_frame: 4}),
    get_child(:depayloader1) 
    |> via_in(Pad.ref(:input, :first))
    |> child(:mixer, Basic.Elements.Mixer),
    get_child(:depayloader2) 
    |> via_in(Pad.ref(:input, :second)) 
    |> get_child(:mixer),
    get_child(:mixer) 
    |> child(:output, %Basic.Elements.Sink{location: "output.txt"})
 ]

 {[spec: spec], %{}}
end
...
```

The crucial thing was to change the plain atom name identifying the pad (like `:first_input`) into the [Membrane.Pad.ref/2](https://hexdocs.pm/membrane_core/Membrane.Pad.html#ref/2).
The first argument passed to that function is the name of the dynamic pad's set (in our case: `:input`, as we have defined the `:input` dynamic pads set in the Mixer element), and the second argument is a particular pad identifier.
As you can see, we have created two `:input` pads: `:first` and `:second`. While starting the pipeline, the `handle_pad_added/3` callback will be called twice, once per each dynamic pad created.

## Further actions

As an exercise, you can try to modify the `lib/pipeline.ex` file and define a pipeline consisting of three parallel branches, being mixed in a single Mixer. Later on, you can check if the pipeline works as expected, by generating the input files out of the conversation in which participate three speakers.

If you combine the approach taken in the chapter about [Bin](02_Bin.md) you can simplify this solution by reducing the size of the link defintions inside the pipeline.
