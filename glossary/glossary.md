# Multimedia 
+ #### _packet_ is a formatted unit of data transmitted over network 
+ #### _frame_ is a data unit at the data link layer in [OSI model](https://en.wikipedia.org/wiki/OSI_model#Layer_architecture) 
+ #### (media)_track_ is equivalent to a single audio or video 
+ #### _webRTC_(Web Real-Time Communication) is a free and open-source project providing web browsers and mobile applications with real-time communication (RTC)
  + signalling - ? 
+ #### Web protocols:
  + #### _UDP_(User Datagram Protocol) is a [transport layer](https://en.wikipedia.org/wiki/OSI_model#Layer_4:_Transport_layer) protocol using connectionless communication
  + #### _TCP_(Transmission Control Protocol) is a [transport layer](https://en.wikipedia.org/wiki/OSI_model#Layer_4:_Transport_layer) protocol using connection-oriented communication
  + #### _RTP_(Real-time Transport Protocol) is a network protocol for delivering audio and video over IP networks
  + #### _HTTP_(Hypertext Transfer Protocol) is a protocol for fetching data from a server by a client
+ #### Server's architecture:
  + #### _SFU_(Selective Forwarding Unit) is a video conferencing architecture which consists of a single server, which receives incoming streams from all participants and forwards each participant's stream to all other conference participants
  + #### _MCU_(Multipoint Control Unit) is a device responsible for connecting conference participants and controlling the stream
  + #### _P2P_(Peer to Peer) is an architecture in which each participant is directly connected to all other participants, which eliminates the need for MCU 
+ #### _SDP_(Session Description Protocol) is used for describing  multimedia communication sessions for the purposes of announcement and invitation.  
+ #### _WebSocket_ is a communications protocol which enables full-duplex communication between client and server in near real-time. 
+ #### (HTTP) _Long Polling_ is a technique of keeping an open connection after client's request for as long as new data is not available. This is more efficient than naive repeated polling by a client until new data is received. 
+ #### container format 
+ #### _ICE_ is a technique of establishing the most direct connection between two computers, which is used in P2P communication
  + #### _STUN_(Session Traversal Utilities for NAT) is a protocol used in interactive communications with hosts hiddent behind a NAT
  + #### _TURN_(Traversal Using Relays around NAT) is a protocol utilizing TURN server which relays data between clients 
+ #### _DTLS_(Datagram Transport Layer Security) is a protocol used for providing security to datagram-based applications 
+ #### _YUV_ is a color encoding system used for image compression by removing information barely visible to human eye. 

# Membrane Framework 
+ #### _caps_(abbr. from capabilities) define [pads](/glossary/glossary#pad) specification, allowing us to determine whether two elements are compatible with each other 
+ #### _Pad_ is an input or output of an element
+ #### _buffer_ 
+ #### _Element_
  + #### _Source_ is an element with only output pads, the first element of each pipeline. It is responsible for fetching the data and transmitting it through the output pad.
  + #### _Filter_ is an element with both input and output pads, which is responsible for transforming data
  + #### _Sink_ is an element with only input pads, the last element of a pipeline.
  + #### Types of elements:
  + #### _payloader**, **depayloader_
  + #### _encoder** and **decoder_ convert media (audio or video) respectively from and to raw format
  + #### _encryptor** and **decryptor_
  + #### _muxer**, **demuxer_
  + #### _jitter buffer (ordering buffer)_ is an area of memory, which is used to temporarily store incoming data in order to reduce the effect of packets incoming late
  + _mixer_ 
+ #### _Demands mechanism_
  + _redemands_

# _General Elixir/Erlang concepts_ 
+ #### OTP Behavior
  + #### _GenServer_ abstracts client/server interaction
+ #### _Phoenix_ is a web development framework written in Elixir
+ #### _Mix_ is a build tool for creating and managing Elixir projects