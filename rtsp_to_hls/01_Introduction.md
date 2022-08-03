# Introduction

Being one of the oldest video transmission protocols, RTSP isn't so popular today anymore. However, there are still areas where it is still in use, primarily by surveillance cameras.
In this tutorial, we would like to show you how to use Membrane Framework to make an RTSP stream easily available to many users.

## Prerequisites
In this tutorial we assume, that you have some experience with Elixir, otherwise we recommend you have a [quick tour of the language](https://elixir-lang.org/getting-started/introduction.html).
It would be best if you had some basic understanding of the protocols used, if you don't have yet, just take a look at the resources at the bottom of this chapter!

## Use case

Suppose that we have a surveillance camera, which is providing us with an RTSP stream. We would like to stream this video to multiple viewers, for them to be easily accessible in the web browser.

Note, that we want this solution to be scalable as the number of users can be quite big.  

## Solution

Firstly, RTSP is very rarely supported on playback devices, so for the stream to be easily played back by the users we need to convert it to something more digestible. We will go with HLS (HTTP Live Streaming) as it is widely supported by devices and web browsers. It sends video and audio over HTTP, thus allowing it to traverse firewalls and proxies.
Also, if we were to stream the video using only RTSP, we would have to create a connection between the RTSP server and each of the end users, which would result in a high load on the server.
Yet another advantage of using HLS for streaming video to the devices is this protocol's adaptive bitrate which allows for dynamic change in video quality based on current network conditions.

## What technology we will use

Our solution will rely on a couple of media protocols. We will obviously use RTSP and HLS, but also RTP and RTCP which work together with RTSP. Check out the sources below:
  
[Real Time Streaming Protocol (RTSP)](https://antmedia.io/rtsp-explained-what-is-rtsp-how-it-works) - what RTSP is and how does it work?

[Real-time Transport Protocol (RTP) and RTP Control Protocol (RTCP)](https://www.techtarget.com/searchnetworking/definition/Real-Time-Transport-Protocol) are protocols used for delivering audio and video over the internet. While the RTP transports the data, the RTCP is responsible for QoS and synchronization of multiple streams.

[HTTP Live Streaming (HLS)](https://www.toptal.com/apple/introduction-to-http-live-streaming-hls) - introduction to HLS