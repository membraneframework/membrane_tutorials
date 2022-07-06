<!-- Overview of RTSP and RTP/RTCP protocols, what are they used for, how they work, why are we using them in our case, what are the problems which come with them and how are we going to address them -->

# Introduction

In this tutorial we will demonstrate the [RTSP to HLS demo](https://github.com/membraneframework/membrane_demo/tree/master/rtsp_to_hls).

## What does "RTSP to HLS" even mean

`RTSP` stands for Real Time Streaming Protocol - it is used for establishing and controlling media sessions between endpoints.

Today RTSP is often used by IP cameras e.g. for surveillance or for purposes such as videoconferencing. However, it is no longer supported by playback devices, that's why we need to convert an RTSP stream to some other format which will be digestible by users.

`HLS` stands for HTTP Live Streaming, a protocol used for delivering media streams to majority of playback devices, such as web browsers and mobile devices.

It is widely supported on playback devices and de-facto standard when it comes to delivering media.
HLS supports adaptive bitrate, allowing for dynamically adjusting video quality according to available bandwidth.

You can get an idea of what RTSP is reading [this post](https://antmedia.io/rtsp-explained-what-is-rtsp-how-it-works/#rtsp_requests).

HLS is described in detail [here](https://www.dacast.com/blog/hls-streaming-protocol/).

## Why


#### RTSP (Real Time Streaming Protocol)
RTSP is an internet protocol designed for controlling multimedia streams.

"The protocol is used for establishing and controlling media sessions between endpoints."
It has been developed in the late 90s and has been in extensive use back then. It was designed to resemble the control of a videocassette recorder - providing PLAY, PAUSE, STOP and RECORD functionalities.
Today it has been mostly replaced by [HTTP Live Streaming](https://en.wikipedia.org/wiki/HTTP_Live_Streaming) (HLS) however, RTSP is still the main protocol used by IP cameras (think surveillance and videoconferencing).

While RTSP controls the media transmission, it is not responsible for the data transmission itself. Once a session between the client and RTSP server is established, the data is being transmitted using RTP (Real-time Transport Protocol).


<!-- RTSP is an internet protocol designed for controlling media transmission between two endpoints, aiming at achieving low latencies. Nowadays it has been replaced by newer protocols and its mainly used by IP cameras for data transmission. 

Although it is an old protocol (it was standardized in 1996) it is still often used, mostly for video streaming by IP cameras eg. for surveillance or conferencing.

RTSP is somewhat similar to HTTP, with most of the messages being sent by the client to the server. These requests include 

RTSP defines requests which are used to control the media stream.

These include OPTIONS, DESCRIBE, SETUP, PLAY and PAUSE.
When user  -->

<!-- History? -->


<!-- It is used for establishing and controlling media sessions between endpoints. However, data transmission itself is not a task of RTSP, that's what RTP is used for. -->

<!-- RTSP has some similarities to HTTP however, unlike HTTP it is a stateful protocol. It uses TCP in the transport layer. -->


#### RTP (Real-time Transport Protocol)
RTP is a network protocol designed for delivering audio and video. 


[RTP standard](https://datatracker.ietf.org/doc/html/rfc3550) defines both RTP and RTCP - RTP Control Protocol, which is used in conjunction with RTP for QoS and synchronization between the media streams.

RTP allows for real-time media streaming with jitter compensation and detection of packet loss and out-of-order delivery.

<!-- Together with RTP protocol, the [RTP standard](https://datatracker.ietf.org/doc/html/rfc3550) defines both RTP (Real) and RTCP (RTP Control Protocol). RTCP is used for QoS and synchronization between the media streams. -->

## External links

### RTSP:
- [Wowza](https://www.wowza.com/blog/rtsp-the-real-time-streaming-protocol-explained)
- [TechTarget](https://www.techtarget.com/searchvirtualdesktop/definition/Real-Time-Streaming-Protocol-RTSP)
- [Antmedia](https://antmedia.io/rtsp-explained-what-is-rtsp-how-it-works/)


### HLS:
- [cloudflare](https://www.cloudflare.com/en-gb/learning/video/what-is-http-live-streaming/)
- [dacast](https://www.dacast.com/blog/hls-streaming-protocol/)