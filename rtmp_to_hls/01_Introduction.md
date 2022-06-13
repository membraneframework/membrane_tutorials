# Introduction

We are glad you have decided to continue your journey into the oceans of multimedia with us!
In this tutorial you will be able to see the Membrane in action - as we will prepare a solution responsible for converting 
incoming RTMP stream into a HLS stream, ready to be easly served in the internet.


## What do we want to acheive?
Imagine that we need to build a video streaming platform. That means - we want a particular system user, the streamer, to stream it's multimedia on a server, where it will be available for other participants - the viewers.
We need to take advantage of the fact, that there will be only one person streaming, and take under consideration, that there might be multiple, possible many, viewers. What's the best solution for such a use case?
Well, as the tutorial name suggests - we can use RTMP for the streamer to stream its multimedia to the server, and make them accesible for the viewers by broadcasting them via HLS protocol!
Easier said than done - how to acheive that? Well, with the Membrane Framework this will be easier than you can expect!
As a final product of this tutorial we want to have a completly working solution for broadcasting a stream. It will consist of two parts:
* The pipeline, responisble for receiving and RTMP stream and prepearing an HLS stream out of it
* The web player, capable of playing the HLS stream

The Membrane will found it's ground to show off in the first part - in fact, we will prepare a Membrane's Pipeline for converting the stream.
When it comes to the web player, we will use an exisiting solution - the [HLS.js](https://github.com/video-dev/hls.js/) player.


## Why one would need such a solution?
You might wonder why one would need to convert a RTMP stream into an HLS stream - couldn't we simply make the streamer broadcast it's multimedia with the RTMP to all the viewers?
Technically speaking we could...but surprisingly it wouldn't be the easiest solution, since each of the viewers would need to act as a RTMP server. And definitly it wouldn't be a solution that would scale - since RTMP is based on TCP, there is no way to broadcast the stream, and therefore the streamer would need to perform a three-way handshake with each of the viewers. 
In contrast, the solution described above has a plenty of advantages - the streamer needs to create a single connection with RTMP server, and then the multimedia can be shared with the use of a regular HTTP server which is designed to serve multiple clients.

## A brief description of the technology we will use
As stated previously, we will use the preexisting protocols. You might find reading about them beneficial, and that is why we provide you with some links to a brief description about 