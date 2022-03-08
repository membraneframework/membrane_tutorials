# Multimedia
+ **packet** is a formatted unit of data transmitted over network
+ **frame** is a data unit at the data link layer in OSI model
+ (media)**track** is equivalent to a single audio or video
+ **webRTC**(Web Real-Time Communication) is a free and open-source project providing web browsers and mobile applications with real-time communication (RTC) via application programming interfaces (APIs).
  + signalling - ?
+ Web protocols:
  + **UDP**(User Datagram Protocol) is a transport layer protocol using  connectionless communication
  + **TCP**(Transmission Control Protocol) is a transport layer protocol using connection-oriented communication
  + **RTP**(Real-time Transport Protocol) is a network protocol for delivering audio and video over IP networks
  + **HTTP**(Hypertext Transfer Protocol) is a 
+ Server's architecture:
  + **SFU**(Selective Forwarding Unit) is a video conferencing architecture which consists of a single server, which receives incoming streams from all participants and forwards each participant's stream to all other conference participants.
  + **MCU**(Multipoint Control Unit) is a device responsible for connecting conference participants and controlling the stream
  + **P2P**(Peer to Peer) is an architecture in which each participant is directly connected to all other participants, which eliminates the need for MCU
+ **SDP**(Session Description Protocol) is used for describing  multimedia communication sessions for the purposes of announcement and invitation. 
+ **WebSocket** is a communications protocol which enables full-duplex communication between client and server in near real-time.
+ (HTTP) **Long Polling** is a technique of keeping an open connection after client's request for as long as new data is not available. This is more efficient than naive repeated polling by a client until new data is received.
+ Types of elements:
  + **payloader**, **depayloader**
  + **encoder** and **decoder** convert media (audio or video) respectively from and to raw format
  + **encryptor** and **decryptor**
  + **muxer**, **demuxer**
  + **jitter buffer (ordering buffer)** is an area of memory, which is used to temporarily store incoming data in order to reduce the effect of packets incoming late
  + **mixer**
+ container format
+ **ICE** is a technique of establishing the most direct connection between two computers, which is used in P2P communication
  + **STUN**(Session Traversal Utilities for NAT) is a protocol used in interactive communications with hosts hiddent behind a NAT
  + **TURN**(Traversal Using Relays around NAT) is a protocol utilizing TURN server which relays data between clients
+ **DTLS**(Datagram Transport Layer Security) is a protocol used for providing security to datagram-based applications
+ **YUV** is a color encoding system used for image compression by removing information barely visible to human eye. 

# Membrane Framework
+ Caps
+ Pad
+ Buffer
+ Element
  + Source
  + Filter
  + Sink
+ Demands mechanism
  + redemands
  
# General Elixir/Erlang
+ OTP Behavior
  + GenServer
+ Phoenix
+ Mix


References:
 - https://trueconf.com/blog/wiki/sfu#:~:text=SFU%20(Selective%20Forwarding%20Unit)%20is,video%20streams%20from%20all%20endpoints.