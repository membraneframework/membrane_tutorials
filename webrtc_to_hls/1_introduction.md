The scope of this tutorial covers the process of creating a system which fetches user's video and audio from the web browser with the use of WebRTC standard and displays them in a form of an online stream based on HLS protocol.

# Introduction
In the [previous tutorial]() we have created a video room with the use of RTC Engine brought to us by the [Membrane Framework]().
We could take an advantage of the preexisting plugin because the use case of an engine which relays multimedia among many peers is quite a common one and that is why Membrane's developers have already implemented a tool which responds this use case, in a form of a plugin. 
But what if our use case was something more...specific? What if we would like to implement some multimedia streaming system which nobody has ever implemented before?
Here is where one of the biggest advantages of the Membrane Framework shows up - it's extensibility.
In a considerably easy way you can build a multimedia pipeline which will meet your expectations on your own!
# Prerequirements
Since this tutorial can be seen as a continuation of the [Videoroom Tutorial](), I strongly encourage you to read the former tutorial before taking this one. In the following chapters of this tutorial we will use the terminology introduced in the former tutorial as well as we will focus on topics which will allow you to create your own pipeline, slightly omitting less complex topics covered by that previous tutorial.
However, since we are digging deeper and deeper into the field of multimedia streaming, there are some other topic from knowledge of which you could benefit. I have listed them below and provided the links to, in my humble opinion, really well prepared tutorials which describe them. Please take your time and read them before following on this tutorial:

## [What are the container files and why do we care about them?](https://bitmovin.com/container-formats-fun-1/)
**Multi**media, as the name suggests, consists of multiple media streams. As an example think about the movie stream. It is possibly formed out of an audio stream, a video stream and some kind of subtitles stream. Dealing with each of these streams separately would be problematic, as we need to achieve some level synchronization between them. What's more, it seems to be reasonably more user-friendly approach to deliver the whole movie in a one file as the user won't need to separately load the video and audio to the player. That is why container formats have been introduced - you can read about the motivation for their existence as well as some technical tricks used in their implementation in the tutorial linked in this section.

## [CMAF - the new hope?](https://www.wowza.com/blog/what-is-cmaf)
The whole field of multimedia processing suffers from the lack of the standarization. In context of container files, there are obviously also plenty of them. Fortunately, efforts were made to deliver a solution which could be commonly used. Meet CMAF - a MPEG specification many other specifications converge to.

## [H.264](https://doc-kurento.readthedocs.io/en/latest/knowledge/h264.html)
Become ready to get your hands dirty with the tutorial linked in this section! Along our guide we will reach some low level concepts brought to us by H.264 codec and that is why the terminology used there might be worth knowing. Find out what NAL unit is and do not hesitate to get familiar with the concept of PPS and SPS!

## [HTTP Live Streaming or: How I Have Learned to Stop Worrying about NAT and Love the 7th Layer of ISO/OSI](https://www.dacast.com/blog/hls-streaming-protocol/)
It is not that uncommon that multimedia streaming makes us cry out of despair due to bandwidth limitations.
That is why we try to use some lightweight protocols (just like UDP) which do not have much of a overhead and allow us to transport the multimedia payload in the densest way possible. However, this approach might be problematic - and NAT is the very first thing which will prevent us from streaming in the easy manner. That is why sometimes we want to take advantage of protocols operating on higher level of abstraction - just like HTTP does. Learn about HLS - Apple's solution which allows you to stream multimedia fragmented into HTTP responses. 