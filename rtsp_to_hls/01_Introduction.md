In this tutorial we will demonstrate the demo of [RTSP to HLS transcoder](https://github.com/membraneframework/membrane_demo/tree/master/rtsp_to_hls).

## What does "RTSP to HLS" even mean

`RTSP` stands for Real Time Streaming Protocol - it is used for establishing and controlling multimedia streams.

Today RTSP is often used by IP cameras e.g. for surveillance or for purposes such as videoconferencing. However, it isn't supported on playback devices, that's why we need to convert an RTSP stream to some other format which will be digestible by users.

`HLS` stands for HTTP Live Streaming, a protocol used for delivering media streams to majority of playback devices, such as web browsers and mobile devices.

It is widely supported on playback devices and de-facto standard when it comes to delivering media.
HLS supports adaptive bitrate, allowing for dynamically adjusting video quality according to available bandwidth.

You can get an idea of what RTSP is reading [this post](https://antmedia.io/rtsp-explained-what-is-rtsp-how-it-works/#rtsp_requests).

HLS is described in detail [here](https://www.dacast.com/blog/hls-streaming-protocol/).

## Why

A very common use-case for RTSP to HLS transcoder is when we want to play the video streamed by some surveillance cameras. For example, during an online meeting we would like to show live stream from a surveillance camera as a background, to add more context to what is being discussed.

As most surveillance cameras do use RTSP for transmitting the data, we have to convert it to a format which will allow us to play it back.  

Due to its features HLS is the obvious option as it allows for easy playback and relatively low latency.

## Resources

### RTSP:
- [Wowza](https://www.wowza.com/blog/rtsp-the-real-time-streaming-protocol-explained)
- [TechTarget](https://www.techtarget.com/searchvirtualdesktop/definition/Real-Time-Streaming-Protocol-RTSP)
- [Antmedia](https://antmedia.io/rtsp-explained-what-is-rtsp-how-it-works/)

### HLS:
- [cloudflare](https://www.cloudflare.com/en-gb/learning/video/what-is-http-live-streaming/)
- [dacast](https://www.dacast.com/blog/hls-streaming-protocol/)