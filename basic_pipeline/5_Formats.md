Since we have already discussed what caps are and how to use them, let's make use of them in our project!
The first thing to do is to define modules responsible for describing the formats used in our pipeline.
We will put them in a separate directory - `lib/formats`. Let's start with the format describing the packets:
```Elixir
# FILE: lib/formats/PacketFormat.ex

defmodule Basic.Formats.Packet do
 @moduledoc """
 A module describing the format of the packet.
 """
 defstruct type: :custom_packets
end
```

The definition of the module is not complicated, as you can see in the code snippet above - we are only defining a structure within that module, with a `:type` parameter, whose default value in `:custom_packtes`.

In our pipeline we will also send another type of data - frames. Let's define a format for them:
```Elixir
# FILE: lib/formats/FrameFormat.ex

defmodule Basic.Formats.Frame do
 @moduledoc """
 A module describing the format of the frame.
 """
 defstruct encoding: :utf8
end
```
Same as in the case of the previous format - we are defining a structure with a single field, called `:encoding`, and the default value of that field - `:utf8`.

That's it! Format modules are really simple - the more complicated thing is to make use of them - which we will do in the subsequent chapters while defining the caps!