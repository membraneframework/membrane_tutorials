We are glad you have decided to continue your journey into the oceans of multimedia with us!
In this tutorial you will be able to see the Membrane in action - as we will prepare a solution responsible for converting
the incoming RTMP stream into an HLS stream, ready to be easily served on the internet.

## What do we want to achieve?

Imagine that we need to build a video streaming platform. That means - we want a particular system user, the streamer, to stream its multimedia on a server, where it will be available for other participants - the viewers.
We need to take advantage of the fact, that there will be only one person streaming, and take into consideration, that there might be multiple, possibly many, viewers. What's the best solution for such a use case?
Well, as the tutorial name suggests - we can use RTMP for the streamer to stream its multimedia to the server, and make them accessible for the viewers by broadcasting them via HLS protocol!
Easier said than done - how to achieve that? Well, with the Membrane Framework this will be easier than you can expect!
As a final product of this tutorial, we want to have a completely working solution for broadcasting a stream. It will consist of two parts:

- The pipeline, responsible for receiving an RTMP stream and preparing an HLS stream out of it
- The web player, capable of playing the HLS stream

The Membrane will find its ground to show off in the first part we will prepare a Membrane's Pipeline for converting the stream.
When it comes to the web player, we will use an existing solution - the [HLS.js](https://github.com/video-dev/hls.js/) player.

## Why one would need such a solution?

You might wonder why one would need to convert an RTMP stream into an HLS stream - couldn't we simply make the streamer broadcast its multimedia with the RTMP to all the viewers?
Technically speaking we could...but surprisingly it wouldn't be the easiest solution, since each of the viewers would need to act as an RTMP server. And definitely, it wouldn't be a solution that would scale - since RTMP is based on TCP, there is no way to broadcast the stream, and therefore the streamer would need to perform a three-way handshake with each of the viewers.
In contrast, the solution described above has plenty of advantages - the streamer needs to create a single connection with the RTMP server, and then the multimedia can be shared with the use of a regular HTTP server which is designed to serve multiple clients.

## A brief description of the technology we will use

As stated previously, we will use the preexisting protocols. You might find reading about them beneficial, and that is why we provide you with some links to a brief description of the technology we will be using:

- [How does RTMP work?](https://blog.stackpath.com/rtmp/) - if you are interested in how the connection in RTMP is established, take your time and read this short description!
- [What is RTMP and why should we care about it?](https://www.wowza.com/blog/rtmp-streaming-real-time-messaging-protocol) - here you can find another short description of RTMP, with the focus laid on the history of the protocol and comparison with other available protocols. Whatsmore, there is a comprehensive explanation of why we need to transcode RTMP to some HTTP-based protocol, just like HLS - which is the use case in our tutorial.
- [HLS behind the scenes](https://www.toptal.com/apple/introduction-to-http-live-streaming-hls) - dig into the ideas which stand behind the HLS, one of the most common HTTP-based streaming protocols.
- [Have you heard about CMAF?](https://www.wowza.com/blog/what-is-cmaf) - if you haven't make sure to read what is the purpose of having a `Common Media Application Format`!
