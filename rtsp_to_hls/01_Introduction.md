# RTSP and RTP

## RTSP (Real Time Streaming Protocol)
RTSP is an internet protocol designed for controlling media transmission between two endpoints, aiming at achieving low latencies. Nowadays it has been replaced by newer protocols and its mainly used by IP cameras for data transmission. 

<!-- Although it is an old protocol (it was standardized in 1996) it is still often used, mostly for video streming by IP cameras eg. for surveillance or conferencing. -->

RTSP defines requests which are used to control the media stream. These include OPTIONS, DESCRIBE, SETUP, PLAY and PAUSE.
<!-- History? -->
While RTSP controls the media transmission, it is not responsible for the media transmission itself. This is a task of the RTP protocol. 

<!-- It is used for establishing and controlling media sessions between endpoints. However, data transmission itself is not a task of RTSP, that's what RTP is used for. -->

<!-- RTSP has some similarities to HTTP however, unlike HTTP it is a stateful protocol. It uses TCP in the transport layer. -->


## RTP (Real-time Transport Protocol)
RTP is a network protocol designed for delivering audio and video. RTP usually runs over UDP, in this case, it is used in conjunction with RTCP (RTP Control Protocol) which is used to monitor transmission statistics and QoS.

RTP allows for real-time media streaming with jitter compensation and detection of packet loss and out-of-order delivery.

RTP standard defines both RTP and RTCP (RTP Control Protocol). RTCP is used for QoS and synchronization between the media streams.