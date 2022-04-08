Since we have already discussed what caps are and how to use them, let's make use of them in our project!
The first thing to do is to define modules responsible for describing the formats used in our pipeline.
We will put them in a separate directory - `lib/formats`. Let's start with the format describing the packets:
###### **`lib/formats/PacketFormat.ex`**
```Elixir
defmodule Basic.Formats.Packet do
 @moduledoc """
 A module describing the format of the packet.
 """
 defstruct type: :custom_packets
end
```

The definition of the module is not complicated, as you can see in the code snippet above - we are only defining a structure within that module, with a `:type` parameter, which default value is `:custom_packtes`.

In our pipeline we will also send another type of data - frames. Let's define a format for them:
###### **`lib/formats/FrameFormat.ex`**
```Elixir
defmodule Basic.Formats.Frame do
 @moduledoc """
 A module describing the format of the frame.
 """
 defstruct encoding: :utf8
end
```
Same as in the case of the previous format - we are defining a structure with a single field, called `:encoding`, and the default value of that field - `:utf8`.

That's it! Format modules are really simple - the more complicated thing is to make use of them - which we will do in the subsequent chapters while defining the caps!

Before advancing you can test the `Source` element, using the tests provided in `/test` directory.
```
mix test test/elements/source_test.exs
```
In case of errors, you may go back to the [Source chapter](/basic_pipeline/03.0_Source.md) or take a look how [Source](https://github.com/membraneframework/membrane_basic_pipeline_tutorial/blob/template/end/lib/elements/Source.ex) and [formats](https://github.com/membraneframework/membrane_basic_pipeline_tutorial/tree/template/end/lib/formats) should look like.
