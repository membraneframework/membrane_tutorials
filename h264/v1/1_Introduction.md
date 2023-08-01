# Introduction

## Once upon a time, there was a parser…

In Membrane, we have a concept of an H.264 parser - a processing element that is designed to put the incoming H.264 stream "in order" by splitting the stream into packets containing the given amount of information (i.e. into separate video frames) or fetching some information about the video (like resolution or framerate). Such processing is often required before muxing the stream into a container or putting it into some transport protocol's packets. 
We used to use an Elixir wrapper on ffmpeg SDK that performed the type of processing described above - we have called that wrapper H264.FFMpeg.Parser, and it's still available in our repository: membrane_h264_ffmpeg_plugin, along with the H264 software decoder and encoder. 
Initially, such a solution perfectly fit our needs - we had a concise yet bug-free parser implementation, and we didn't need to get our hands dirty with the h264 stream structure at all. The difficult stuff was already done by the great FFmpeg team, and we were just harvesting the fruits of their labor.

However, it wasn't that long until we faced a need to add some custom functionalities to the parser. Nothing particularly complicated: dropping frames from the stream before the parameters or keyframe appeared for the first time. 
That was the moment that we started struggling with a tremendous number of problems, which mostly originated in the fact that the state of the processing element was held in three different places:
* in the Elixir's GenServer state
* in the C bridge code between Elixir and FFMpeg SDK 
* internally, in the data structures provided by FFMpeg SDK
A stack of options, parameters and behavioral patterns had been growing, some options had become more or less explicitly incompatible with others, and more and more time was being spent on debugging the problems caused by the use of our parser. A decision was made - we need to perform a refactor. Soon we realized that there was in fact nothing to refactor - the whole code would have needed to be thrown out and the element would have needed to be written from scratch.

## The new hope

We realized that we were more experienced with multimedia processing than we had been when the wrapped parser was first created. So we asked ourselves - why not create the parser in plain Elixir and get rid of some native FFMpeg dependency? It shouldn't be that difficult, should it? …
Long story short, we learned a lot ;) And we would like to share some of our findings with you.
