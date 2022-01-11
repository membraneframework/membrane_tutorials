We owe you something...and we would like to payback as soon as possible!
As promised in the [3rd chapter](3_Source.md), we will talk more about the concept of caps - which in fact we have used in the previous chapter, but which weren't described in the sufficient way there.
# What are caps?
Caps (a abbreviation of the *capabilities*) is an concept allowing us to define what kind of data is flowing through the pad. 
In the Membrane Framework's nomenclature we say, that a pad has a given caps.
I believe that an example might speak here lauder that a plain definition, so I will try to describe the caps with the real-life scenario example.
Let's say that we are connecting two elements which process the video multimedia.
The link is made between the pads which are working on raw video data.
Here is where caps come up - they can be defined with the following constraints:
+ data format - in our case we are having a raw video format
+ some additional constraints - i.e. frame resolution (480p) , framerate (30 fps) etc.

Caps help us find out if the given elements are compatible - not only we cannot send the data between the pads if the format they are expecting is different. We can think of a situation in which the format would be the same (i.e. raw video data), but the element which receives the data performs a much complex computation on that data then the sender, and therefore cannot digest such a great amount of data as the sender is capable of transmitting. 

Caps helps us define a contract between elements and prevent us from connecting incompatible elements. That is why it is always better to define precise caps rather then using caps of type `:any`.

# When the caps are compatible?
Comparison between caps is being made when the pads are connected. By due to a freedom in defining the type, the comparison is not that straight forward. It would be good for a responsible Membrane's element architect to be aware how the caps are compared.