# Multimedia 
+ #### *packet* is a formatted unit of data transmitted over network 
+ #### *frame* is a data unit at the data link layer in [OSI model](https://en.wikipedia.org/wiki/OSI_model#Layer_architecture) 
+ #### (media)*track* is equivalent to a single audio or video 
+ #### *WebRTC*(Web Real-Time Communication) is a free and open-source project providing web browsers and mobile applications with real-time communication (RTC)
  + #### *signalling* in WebRTC is a process of discovery and establishing connection between two devices
+ #### Web protocols:
  + #### *UDP*(User Datagram Protocol) is a [transport layer](https://en.wikipedia.org/wiki/OSI_model#Layer_4:_Transport_layer) protocol using connectionless communication
  + #### *TCP*(Transmission Control Protocol) is a [transport layer](https://en.wikipedia.org/wiki/OSI_model#Layer_4:_Transport_layer) protocol using connection-oriented communication
  + #### *RTP*(Real-time Transport Protocol) is a network protocol for delivering audio and video over IP networks
  + #### *HTTP*(Hypertext Transfer Protocol) is a protocol for fetching data from a server by a client
+ #### Server's architecture:
  + #### *SFU*(Selective Forwarding Unit) is a video conferencing architecture which consists of a single server, which receives incoming streams from all participants and forwards each participant's stream to all other conference participants
  + #### *MCU*(Multipoint Control Unit) is a device responsible for connecting conference participants and controlling the stream
  + #### *P2P*(Peer to Peer) is an architecture in which each participant is directly connected to all other participants, which eliminates the need for MCU 
+ #### *SDP*(Session Description Protocol) is used for describing  multimedia communication sessions for the purposes of announcement and invitation.  
+ #### *WebSocket* is a communications protocol which enables full-duplex communication between client and server in near real-time 
+ #### (HTTP) *Long Polling* is a technique of keeping an open connection after client's request for as long as new data is not available. This is more efficient than naive repeated polling by a client until new data is received. 
+ #### container format 
+ #### *ICE* is a technique of establishing the most direct connection between two computers, which is used in P2P communication
  + #### *STUN*(Session Traversal Utilities for NAT) is a protocol used in interactive communications with hosts hiddent behind a NAT
  + #### *TURN*(Traversal Using Relays around NAT) is a protocol utilizing TURN server which relays data between clients 
+ #### *DTLS*(Datagram Transport Layer Security) is a protocol used for providing security to datagram-based applications 
+ #### *YUV* is a color encoding system which defines one luminance and two chrominance components. By reducing the resolution of chrominance components it is possible to compress an image with miniscule effect on human perception of the image. 
+ #### *Encoding* is a process of converting media to or from raw format
+ #### *Decoding* is a process reverse to [encoding](/glossary/glossary#encoding)
+ #### *Encryption* is a way of modifying a message, so that only authorized parties are able to interpret it
+ #### *Decryption* is a process of retrieving data from an encrypted message
+ #### *Muxing*(abbr. from multiplexing) is a method of combining multiple signals into one signal over a shared medium. Such signal can be then [demuxed](/glossary/glossary#demuxing) back into original signals
+ #### *Demuxing*(abbr. from demultiplexing) is a method of separating signals from one combined signal

# Membrane Framework 
+ #### *Caps*(abbr. from capabilities) define [pads](/glossary/glossary#pad) specification, allowing us to determine whether two elements are compatible with each other 
+ #### *Pad* is an input or output of an element. Output pads of one element are connected to input pads of another element.
+ #### *Pipeline* is a chain of linked elements #TODO
+ #### *buffer*
+ #### *Element* is the most basic entity responsible for processing multimedia. Each element is created to solve one problem. Elements can be divided into three categories:
  + #### *Source* is an element with only output pads, the first element of each pipeline. It is responsible for fetching the data and transmitting it through the output pad.
  + #### *Filter* is an element with both input and output pads, which is responsible for transforming data
  + #### *Sink* is an element with only input pads, the last element of a pipeline.
+ #### Types of elements:
  + #### *payloader* and *depayloader* are responsible for respectively dividing frames into packets and assembling packets back into frames
  + #### *encoder* and *decoder* are responsible for [encoding](/glossary/glossary#encoding) and [decoding](/glossary/glossary#decoding)
  + #### *encryptor* and *decryptor* are responsible for [encryption](/glossary/glossary#encryption) and [decryption](/glossary/glossary#decryption)
  + #### *muxer* and *demuxer* are responsible for [muxing](/glossary/glossary#muxing) and [demuxing](/glossary/glossary#demuxing)
  + *mixer* 
  + #### *jitter buffer / ordering buffer* is an area of memory, which is used to temporarily store data incoming from network, used to arrange the data in the order in which it was sent
+ #### *Demands mechanism*
  + *redemands*

# *General Elixir/Erlang concepts* 
+ #### OTP Behavior
  + #### *GenServer* abstracts client/server interaction
+ #### *Phoenix* is a web development framework written in Elixir
+ #### *Mix* is a build tool for creating and managing Elixir projects