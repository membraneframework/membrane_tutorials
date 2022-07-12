In this tutorial we will demonstrate the demo of [RTSP to HLS transcoder](https://github.com/membraneframework/membrane_demo/tree/master/rtsp_to_hls).

# Introduction

## Use case

In our scenario we have a surveillance camera, which is providing a video stream. Say, that we would like to stream this video to multiple viewers, for them to be easily accessible in the web browser. 

## Our solution

First of all, the vast majority of surveillance cameras use [RTSP]() for transmitting data so we have no choice but to use RTSP for receiving the stream from the camera.

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

`RTSP` stands for Real Time Streaming Protocol - it is used for establishing and controlling multimedia streams. You can get an idea of what RTSP is reading [this post](https://antmedia.io/rtsp-explained-what-is-rtsp-how-it-works).

`RTP`

`RTCP`

`HLS` stands for HTTP Live Streaming, a protocol used for delivering media streams to majority of playback devices, such as web browsers and mobile devices. HLS is described in detail [here](https://www.dacast.com/blog/hls-streaming-protocol/).

## Resources

### RTSP:
- [Wowza](https://www.wowza.com/blog/rtsp-the-real-time-streaming-protocol-explained)
- [TechTarget](https://www.techtarget.com/searchvirtualdesktop/definition/Real-Time-Streaming-Protocol-RTSP)
- [Antmedia](https://antmedia.io/rtsp-explained-what-is-rtsp-how-it-works/)

### HLS:
- [cloudflare](https://www.cloudflare.com/en-gb/learning/video/what-is-http-live-streaming/)
- [dacast](https://www.dacast.com/blog/hls-streaming-protocol/)


# Architecture

Now let's discuss how the architecture of our solution will look like.

The main component of the transcoder will be the pipeline, in which the RTP stream will be converted into an HLS.
Wait, what? What is RTP is supposed to mean? It just a typo, you meant RT**S**P? Well... the answer is no!
As described briefly in the [previously mentioned RTSP resource], RTSP is only responsible for controlling the media stream, the data itself is transmitted using [RTP (Real-time Transport Protocol)] protocol.
In short, it is a protocol capable of transmitting live audio and video over the internet. It also requires [RTCP] (RTP Control Protocol) to be used in conjunction with it, which is responsible for monitoring the transmission statistics, QoS and synchronization of multiple streams.
