# Introduction

Being one of the oldest video transmission protocols, RTSP isn't so popular today anymore. However, there are still areas where it is still in use, primarily by surveillance cameras.
In the next couple chapters, we would like to show you a modification of the current RTMP to HLS converter, that will allow us to convert an RTSP stream instead.

## Use case

Suppose that we have a surveillance camera, which is providing us with an RTSP stream. We would like to stream this video to multiple viewers, for them to be easily accessible in the web browser.

Note, that we want this solution to be scalable as the number of users can be quite big.  

## Solution

The reasons for converting RTSP to HLS are very similar to the ones we explained with RTMP. RTSP is very rarely supported on playback devices, has problems with traversing firewalls and proxies and doesn't support adaptive bitrate.

## What technology we will use

Before going further, make sure you have some basic understanding of the protocols used:
  
[Real Time Streaming Protocol (RTSP)](https://antmedia.io/rtsp-explained-what-is-rtsp-how-it-works) - what RTSP is and how does it work?

[Real-time Transport Protocol (RTP) and RTP Control Protocol (RTCP)](https://www.techtarget.com/searchnetworking/definition/Real-Time-Transport-Protocol) are protocols used for delivering audio and video over the internet. While the RTP transports the data, the RTCP is responsible for QoS and synchronization of multiple streams.