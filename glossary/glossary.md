## Multimedia

  - #### **Packet**
    It is a formatted unit of data transmitted over network. In order to send data over network it has to be fragmented into packets, which size is limited by [MTU(Maximum Transfer Unit)](https://en.wikipedia.org/wiki/Maximum_transmission_unit) - 1500 bytes when using [Ethernet](https://en.wikipedia.org/wiki/Ethernet_frame).
  - #### **Frame**
    Frame can refer to either [network frame](<https://en.wikipedia.org/wiki/Frame_(networking)>) or **media frame**, which is a basic data unit used by media coding formats. In particular one media frame can represent a single image in a video.
  - #### **Track**
    Media track is equivalent to a single audio or video stream.
- ### Web protocols:
  - #### **UDP**
    User Datagram Protocol. A [transport layer](https://en.wikipedia.org/wiki/OSI_model#Layer_4:_Transport_layer) protocol using connectionless communication. See [here](https://www.imperva.com/learn/ddos/udp-user-datagram-protocol) for more details.
  - #### **TCP**
    Transmission Control Protocol. A [transport layer](https://en.wikipedia.org/wiki/OSI_model#Layer_4:_Transport_layer) protocol using connection-oriented communication. See [this explanation](https://www.khanacademy.org/computing/computers-and-internet/xcae6f4a7ff015e7d:the-internet/xcae6f4a7ff015e7d:transporting-packets/a/transmission-control-protocol--tcp) on how TCP works.
  - #### **RTP**
    Real-time Transport Protocol. An [application layer](https://en.wikipedia.org/wiki/OSI_model#Layer_7:_Application_layer) protocol for delivering real-time audio and video over IP networks. RTP packet structure is described [here](https://en.wikipedia.org/wiki/Real-time_Transport_Protocol#Packet_header). There is an extension of RTP - [SRTP](https://developer.mozilla.org/en-US/docs/Glossary/RTP) (Secure RTP), which adds security features and is used by [WebRTC](#webrtc).
  - #### **HTTP**
    Hypertext Transfer Protocol. An [application layer](https://en.wikipedia.org/wiki/OSI_model#Layer_7:_Application_layer) protocol for fetching data from a server by a client. It is used by [HLS](https://en.wikipedia.org/wiki/HTTP_Live_Streaming) and [MPEG-DASH](https://en.wikipedia.org/wiki/Dynamic_Adaptive_Streaming_over_HTTP) for media streaming.
  - #### **Long Polling** 
    HTTP Long Pollingis a technique of keeping an open connection after the client's request for as long as new data is not available. This is more efficient than naive repeated polling by a client until new data is received.
  - #### **WebRTC**
    WebRTC (Web Real-Time Communication) is a free and open-source project providing web browsers and mobile applications with real-time communication (RTC). WebRTC implements three APIs: **MediaStream** used for acquiring media from the browser, **RTCPeerConnection** handling stable and efficient communication of streaming data between peers, and **RTCDataChannel** enabling a peer-to-peer exchange of arbitrary data with low latency and high throughput. Learn more about WebRTC [here](https://www.html5rocks.com/en/tutorials/webrtc/basics/).
  - #### **Signaling**
    In WebRTC it's a process of discovery, establishing, controlling, and terminating a connection between two devices.
  - #### **SDP**
    [Session Description Protocol](https://www.ietf.org/rfc/rfc2327.txt). A protocol used for describing multimedia communication sessions for the purposes of announcement and invitation. It is used in the WebRTC signaling process for describing a session.
  - #### **WebSocket**
    An application layer communication protocol working allowing for a communication between client and server in near real-time. It is based on TCP and, in contrast to HTTP, it provides full-duplex communication. Today it is supported by most web browsers and web servers.
  - #### **ICE**
    [Interactive Connectivity Establishment](https://developer.mozilla.org/en-US/docs/Glossary/ICE). It's a technique for establishing the most direct connection between two computers, which is used in P2P communication.
  - #### **STUN**
    Session Traversal Utilities for NAT. Protocol used in interactive communications with hosts hidden behind a NAT. Its goal is to find public addresses of the peers that they can use to directly communicate with each other.
  - #### **TURN**
    Traversal Using Relays around NAT. Protocol utilizing TURN server which relays data between peers in case when direct connection cannot be established. However, this comes with an overhead since all the media must be sent through this server.
  - #### **DTLS**
    [Datagram Transport Layer Security](https://developer.mozilla.org/en-US/docs/Glossary/DTLS). Protocol used for providing security to datagram-based applications. It is based on TLS and guarantees a similar level of security. All of the WebRTC related protocols are required to encrypt their communications using DTLS, this includes [SCTP](https://developer.mozilla.org/en-US/docs/Glossary/SCTP), [SRTP](#RTP) and [STUN](#STUN).
- #### **NAT**
  [Network address translation](https://developer.mozilla.org/en-US/docs/Glossary/NAT). A technique of sharing one public IP address by multiple computers.
- #### **Container format**
  A file format that allows multiple data streams to be embedded into a single file, e.g. MP4 format can contain video, audio, and subtitles streams inside of it.
- #### **YUV**
  A color encoding system that defines one [luminance](https://en.wikipedia.org/wiki/Luminance) and two [chrominance](https://en.wikipedia.org/wiki/Chrominance) components. By reducing the resolution of the chrominance components it is possible to compress an image with minuscule effect on human perception of the image.
- #### **Encoding**
  A process of converting media from raw format to encoded format. The main purpose is to reduce media size - the raw format is uncompressed and takes up a lot of space. Examples of encoded formats are [MP3](https://en.wikipedia.org/wiki/MP3) and [AAC](https://en.wikipedia.org/wiki/Advanced_Audio_Coding) for audio and [AVC](https://en.wikipedia.org/wiki/Advanced_Video_Coding) and [MPEG-4 Part 2](https://en.wikipedia.org/wiki/MPEG-4_Part_2) for video.
- #### **Decoding**
  A process of converting media from encoded format to raw format, e.g. in order to play it on the end device.
- #### **Encryption**
  A way of modifying a message, so that only authorized parties are able to interpret it.
- #### **Decryption**
  A process of retrieving data from an encrypted message.
- #### **Muxing**
  Abbr. from multiplexing. A method of combining multiple streams into a single container, e.g. muxing video and audio into an MP4 container.
- #### **Demuxing**
  Abbr. from demultiplexing. A method of separating streams from one combined container, e.g. retrieving audio and video from MP4.
- ### Server's architecture
  [Here](https://millo-l.github.io/WebRTC-implementation-method-Mesh-SFU-MCU/) is a short article to get you started
  - #### **SFU**
    [Selective Forwarding Unit](https://millo-l.github.io/WebRTC-implementation-method-Mesh-SFU-MCU/#22-sfuselective-forwarding-unit-server). A video conferencing architecture that consists of a single server, which receives incoming streams from all participants and forwards each participant's stream to all other conference participants.
  - #### **MCU** 
    [Multipoint Control Unit](https://millo-l.github.io/WebRTC-implementation-method-Mesh-SFU-MCU/#23-mcumulti-point-control-unit-server). An architecture consisting of a single server, which receives incoming streams from all participants, mixes the streams, and sends them to each of the participants.
  - #### **P2P**
    [Peer to Peer](https://millo-l.github.io/WebRTC-implementation-method-Mesh-SFU-MCU/#21-signaling-serverp2pmesh). An architecture in which each participant is directly connected to all other participants, which eliminates the need for MCU or SFU.
## Membrane Framework
- #### **Action**
  An action can be returned from [callback][#callback] and it is a way of element interaction with other elements and parts of framework. An exemplary actions might be: [`:buffer`](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:buffer/0) action, that sends buffers through a pad, or [`:terminate`](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:terminate/0) action, that terminates element with given reason.
- #### **Callback**
  A callback is a function defined by user, that gets called once a particular event happens.
  An exemplary callbacks in the Membrane Framework are: [`handle_end_of_stream/3`](https://hexdocs.pm/membrane_core/Membrane.Element.WithInputPads.html#c:handle_end_of_stream/3) being called once end of stream event is received on some pad or []`handle_init/2`](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#c:handle_init/2) called on initialization of an [element](#element).
- #### **Pad**
  An input or output of an [elements](#element) or a [bin](#bin). Output pads of one element or a bin are connected to input pads of another element or a bin.
- #### **Stream format, formely: caps**
  It defines [pads](#pad) specification, allowing us to determine whether two elements are compatible with each other.
  The formely used name "caps" is an abbrevation from "capabilities". 
- #### **Pipeline**
  A chain of linked [elements](#element) or [bins](#bin) which together accomplish some media processing task.
- #### **Bin**
  A container for elements, which allows for creating reusable groups of [elements](#element). Bin can incorporate elements and other bins as well.
- #### **Buffer**
  A fundamental structure in Membrane used to send data between elements.
- #### **Element** 
  The most basic entity responsible for processing multimedia. Each element is created to solve one problem. Elements can be divided into four categories:
  - #### **Source** 
    An element with only output [pads](#pads), the first element of each pipeline. It is responsible for fetching the data and transmitting it through the output pad.
  - #### **Filter**
    An element with both input and output [pads](#pads), which is responsible for transforming data.
  - #### **Sink** 
    An element with only input [pads](#pads), the last element of a pipeline. It might be responsible, i.e. for writing the output to the file or playing the incoming media stream.
  - #### **Endpoint**
    An element with both input and output [pads](#pads), responsible for receiving and consuming data (e.g., writing to a soundcard, sending via TCP, etc.) as well as producing data (e.g., reading from a soundcard, downloading via HTTP, etc.) and sending it through the corresponding pads. It can be thought as an element merging all the functionalities of previously mentioned element categories: source, filter and sink.
- ### Types of elements:
  - #### **Payloader** and **Depayloader**
    Payloader is responsible for preparing the data stream to be put in some specific format, typically a network-friendly format
    or a container format. This preparation may include the addition of headers or various metadata. Depayloader does the reverse operation - it allows to receive original data stream from specific format.
  - #### **Encoder** and **Decoder**
    Elements responsible for [encoding](#encoding) and [decoding](#decoding).
  - #### **Encryptor** and **Decryptor**
    Elements responsible for [encryption](#encryption) and [decryption](#decryption).
  - #### **Muxer** and **Demuxer**
    Elements responsible for [muxing](#muxing) and [demuxing](#demuxing).
  - #### **Mixer**
    An element responsible for mixing multiple media streams into a single stream. Unlike multiplexing, mixing is an irreversible operation.
  - #### **Jitter buffer** / **Ordering buffer**
    An element responsible for ordering packets incoming from the network as their order can be disrupted during transmission due to network unreliability.
- ### Demands mechanism
  - #### **Demands**, **Demanding**
    Demanding is a name for Membrane Framework backpressure mechanism. Elements are allowed to send "demands" to the preceeding
    element, in which they describe the amount of data they want to receive.
  - #### **Redemands**
    In Membrane it's an element's action that lets the programmer handle just one buffer at a time. When redemanding, the `handle_demand/5` callback is synchronously called. You can read more about redemands [here](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:redemand/0).

## General Elixir/Erlang concepts
- ### OTP Behavior
  - #### **GenServer**
    Elixir bahaviour abstracts client/server interaction. [https://elixir-lang.org/getting-started/mix-otp/genserver.html](https://elixir-lang.org/getting-started/mix-otp/genserver.html)
- ### **Phoenix** 
    The web development framework written in Elixir. [https://phoenixframework.org/](https://phoenixframework.org/)
- ### **Mix**
    A build tool for creating and managing Elixir projects. [https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html)
