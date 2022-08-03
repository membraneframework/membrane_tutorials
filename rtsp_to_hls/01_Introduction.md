In this tutorial we demonstrate the [RTSP to HLS](https://github.com/membraneframework/membrane_demo/tree/master/rtsp_to_hls) demo.

# Introduction

## Use case

Suppose that we have a surveillance camera, which is providing us with a video stream. We would like to stream this video to multiple viewers, for them to be easily accessible in the web browser. 

Unfortunately for us, we cannot stream and display RTSP to a web browser - that's why we need to convert it to another format - in our case it's going to be HLS.
In this tutorial you will learn how the RTSP to HLS converter works.

In this tutorial we will explain how the RTSP to HLS converter using Membrane works.

## Our solution

First of all, the vast majority of surveillance cameras use RTSP for transmitting data so we have no choice but to use RTSP for receiving the stream from the camera.

You might wonder, why don't we just play the RTSP stream and finish here. Technically it is possible - if you have [VLC](https://wiki.videolan.org/Documentation:Installing_VLC) or [ffmpeg](https://ffmpeg.org/download.html) installed you can play our sample RTSP stream by running respectively

```console
vlc rtsp://rtsp.membrane.work/testsrc.264
```
or
```console
ffplay rtsp://rtsp.membrane.work/testsrc.264
```

However, this solution is very inconvenient for the user, as it requires installing a media player capable of handling an RTSP stream. It is also quite demanding for the RTSP server, which is providing the stream for the clients, each connection requires opening two ports for the media transmission.

That's why we're going to convert the stream to [HLS](), which we will be able to easily play on most web browsers.
It's going to be less resource-demanding as well.

## What technology we will use 

Our solution will rely on a couple of media protocols. We will obviously use RTSP and HLS, but also RTP and RTCP which work together with RTSP. 

[Real Time Streaming Protocol (RTSP)](https://antmedia.io/rtsp-explained-what-is-rtsp-how-it-works)
is used for establishing and controlling multimedia streams.

[Real-time Transport Protocol (RTP) and RTP Control Protocol (RTCP)](https://www.techtarget.com/searchnetworking/definition/Real-Time-Transport-Protocol) are protocols used for delivering audio and video over internet. While the RTP transports the data, the RTCP is responsible for QoS and synchronization of multiple streams.

[HTTP Live Streaming (HLS)](https://www.toptal.com/apple/introduction-to-http-live-streaming-hls) is a protocol used for delivering media streams to majority of playback devices, such as web browsers and mobile devices.
