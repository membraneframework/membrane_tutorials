## Multimedia

  - #### **Packet**
    It is a formatted unit of data transmitted over the network. To send data over the network it has to be fragmented into packets, which size is limited by [MTU(Maximum Transfer Unit)](https://en.wikipedia.org/wiki/Maximum_transmission_unit) - 1500 bytes when using [Ethernet](https://en.wikipedia.org/wiki/Ethernet_frame).
  - #### **Frame**
    'Frame' can refer to either [network frame](<https://en.wikipedia.org/wiki/Frame_(networking)>) or **media frame**, which is a basic data unit used by media coding formats. In particular, one media frame can represent a single image in a video.
  - #### **Track**
    A media track is equivalent to a single audio or video stream.
  - #### **Simulcast**
    It is the technique of broadcasting multiple versions of the same content simultaneously, typically at different resolutions or quality levels, to accommodate diverse network conditions and user devices.
  - #### **PTS** and **DTS**
  PTS (Presentation Timestamp) is a value in a video or audio stream that indicates the precise time a specific frame or sample should be displayed or played back, ensuring proper synchronization of media content during playback.
  DTS (Decoding Timestamp) is a value in a video or audio stream that specifies the exact moment a particular frame or sample should be decoded by the decoder, ensuring the correct decoding order and maintaining the integrity of media content during playback.
  
- ### Web protocols:
  - #### **UDP**
    User Datagram Protocol. A [transport layer](https://en.wikipedia.org/wiki/OSI_model#Layer_4:_Transport_layer) protocol using connectionless communication. See [here](https://www.imperva.com/learn/ddos/udp-user-datagram-protocol) for more details.
  - #### **TCP**
    Transmission Control Protocol. A [transport layer](https://en.wikipedia.org/wiki/OSI_model#Layer_4:_Transport_layer) protocol using connection-oriented communication. See [this explanation](https://www.khanacademy.org/computing/computers-and-internet/xcae6f4a7ff015e7d:the-internet/xcae6f4a7ff015e7d:transporting-packets/a/transmission-control-protocol--tcp) on how TCP works.
  - #### **RTP**
    Real-time Transport Protocol. An [application layer](https://en.wikipedia.org/wiki/OSI_model#Layer_7:_Application_layer) protocol for delivering real-time audio and video over IP networks. RTP packet structure is described [here](https://en.wikipedia.org/wiki/Real-time_Transport_Protocol#Packet_header). There is an extension of RTP - [SRTP](https://developer.mozilla.org/en-US/docs/Glossary/RTP) (Secure RTP), which adds security features and is used by [WebRTC](#webrtc).
  - #### **RTSP**
  RTSP (Real-Time Streaming Protocol) is a network control protocol designed for controlling media streaming sessions, enabling efficient delivery and playback of multimedia content over IP networks. It's commonly used by IP cameras.
  - #### **RTMP**
  RTMP (Real-Time Messaging Protocol) is a proprietary protocol developed by Adobe Systems for low-latency streaming of audio, video, and data between a server and Flash player.
  - #### **HLS**
  HLS (HTTP Live Streaming) is an adaptive streaming protocol developed by Apple for efficiently delivering live and on-demand multimedia content over the internet by breaking the media files into chunks and serving them over HTTP.
  - #### **MPEG-DASH**
  MPEG-DASH (Dynamic Adaptive Streaming over HTTP) is a standardized adaptive bitrate streaming protocol that dynamically adjusts media quality to fit the viewer's network conditions and device capabilities, seamlessly delivering multimedia content over the internet using HTTP.
  - #### **HTTP**
    Hypertext Transfer Protocol. An [application layer](https://en.wikipedia.org/wiki/OSI_model#Layer_7:_Application_layer) protocol for fetching data from a server by a client. It is used by [HLS](https://en.wikipedia.org/wiki/HTTP_Live_Streaming) and [MPEG-DASH](https://en.wikipedia.org/wiki/Dynamic_Adaptive_Streaming_over_HTTP) for media streaming.
  - #### **Long Polling** 
    HTTP Long Polling is a technique of keeping an open connection after the client's request for as long as new data is not available. This is more efficient than naive repeated polling by a client until new data is received.
  - #### **WebRTC**
    WebRTC (Web Real-Time Communication) is a free and open-source project providing web browsers and mobile applications with real-time communication (RTC). WebRTC implements three APIs: **MediaStream** used for acquiring media from the browser, **RTCPeerConnection** handling stable and efficient communication of streaming data between peers, and **RTCDataChannel** enabling a peer-to-peer exchange of arbitrary data with low latency and high throughput. Learn more about WebRTC [here](https://www.html5rocks.com/en/tutorials/webrtc/basics/).
  - #### **Signaling**
    In WebRTC it's a process of discovery, establishing, controlling, and terminating a connection between two devices.
  - #### **SDP**
    [Session Description Protocol](https://www.ietf.org/rfc/rfc2327.txt). A protocol used for describing multimedia communication sessions for announcement and invitation. It is used in the WebRTC signaling process for describing a session.
  - #### **WebSocket**
    An application layer communication protocol works allowing for communication between client and server in near real-time. It is based on TCP and, in contrast to HTTP, it provides full-duplex communication. Today it is supported by most web browsers and web servers.
  - #### **ICE**
    [Interactive Connectivity Establishment](https://developer.mozilla.org/en-US/docs/Glossary/ICE). It's a technique for establishing the most direct connection between two computers, which is used in P2P communication.
  - #### **STUN**
    Session Traversal Utilities for NAT. Protocol used in interactive communications with hosts hidden behind a NAT. Its goal is to find public addresses of the peers that they can use to directly communicate with each other.
  - #### **TURN**
    Traversal Using Relays around NAT. Protocol utilizing the TURN server which relays data between peers in the case when direct connection cannot be established. However, this comes with an overhead since all the media must be sent through this server.
  - #### **DTLS**
    [Datagram Transport Layer Security](https://developer.mozilla.org/en-US/docs/Glossary/DTLS). Protocol used for providing security to datagram-based applications. It is based on TLS and guarantees a similar level of security. All of the WebRTC-related protocols are required to encrypt their communications using DTLS, this includes [SCTP](https://developer.mozilla.org/en-US/docs/Glossary/SCTP), [SRTP](#RTP) and [STUN](#STUN).
- #### **NAT**
  [Network address translation](https://developer.mozilla.org/en-US/docs/Glossary/NAT). A technique of sharing one public IP address by multiple computers.
- #### **Container format**
  A file format that allows multiple data streams to be embedded into a single file, e.g. MP4 format can contain video, audio, and subtitles streams inside of it.
- #### **CMAF**
  CMAF (Common Media Application Format) is a standardized media file format for adaptive bitrate streaming over the internet. It enhances the interoperability between different streaming protocols, such as [HLS](#hls) and [MPEG-DASH](#mpeg-dash), by using a single set of media files and encryption methods. CMAF simplifies content delivery to various devices and platforms, reducing the need for multiple file formats and enabling more efficient media streaming.
- #### **YUV**
  Color space that defines one [luminance](https://en.wikipedia.org/wiki/Luminance) and two [chrominance](https://en.wikipedia.org/wiki/Chrominance) components. By reducing the resolution of the chrominance components it is possible to compress an image with a minuscule effect on human perception of the image. That encoding is commonly used for analog video processing.
- #### **YCbCr**
  Color space that defines one [luminance](https://en.wikipedia.org/wiki/Luminance) and two chrominance difference components: [blue-difference](https://en.wikipedia.org/wiki/B-Y) and [red-difference](https://en.wikipedia.org/wiki/R-Y). In contrast to **YUV** it's more often used in digital video processing. It happens that YCbCr is often mistakenly called [YUV](#yuv).
- #### **Encoding**
  A process of converting media from raw format to encoded format. The main purpose is to reduce media size - the raw format is uncompressed and takes up a lot of space. Examples of encoded formats are [MP3](https://en.wikipedia.org/wiki/MP3) and [AAC](https://en.wikipedia.org/wiki/Advanced_Audio_Coding) for audio and [AVC](https://en.wikipedia.org/wiki/Advanced_Video_Coding) and [MPEG-4 Part 2](https://en.wikipedia.org/wiki/MPEG-4_Part_2) for video.
- #### **Decoding**
  A process of converting media from encoded format to raw format, e.g. to play it on the end device.
- #### **Encryption**
  A way of modifying a message, so that only authorized parties can interpret it.
- #### **Decryption**
  A process of retrieving data from an encrypted message.
- #### **Muxing**
  Abbr. from multiplexing. A method of combining multiple streams into a single container, e.g. muxing video and audio into an MP4 container.
- #### **Demuxing**
  Abbr. from demultiplexing. A method of separating streams from one combined container, e.g. retrieving audio and video from MP4.
- ### Types of transmission in computer networks:
  - #### **unicast**
  Unicast is a communication method in which a single sender transmits packets to a single recipient.
  - #### **multicast**
  Multicast is a communication method where a single sender transmits packets to multiple recipients in a specific group simultaneously.
  - #### **broadcast**
  Broadcast is a communication method in which a single sender transmits packets to all the recipients connected to the network.
  - #### **anycast**
  Anycast is a communication method that involves a single sender transmitting packets to the topologically nearest recipient among a group of potential recipients.
- ### Server's architecture
  [Here](https://millo-l.github.io/WebRTC-implementation-method-Mesh-SFU-MCU/) is a short article to get you started
  - #### **SFU**
    [Selective Forwarding Unit](https://millo-l.github.io/WebRTC-implementation-method-Mesh-SFU-MCU/#22-sfuselective-forwarding-unit-server). A video conferencing architecture that consists of a single server, which receives incoming streams from all participants and forwards each participant's stream to all other conference participants.
  - #### **MCU** 
    [Multipoint Control Unit](https://millo-l.github.io/WebRTC-implementation-method-Mesh-SFU-MCU/#23-mcumulti-point-control-unit-server). An architecture consisting of a single server, which receives incoming streams from all participants, mixes the streams and sends them to each of the participants.
  - #### **P2P**
    [Peer to Peer](https://millo-l.github.io/WebRTC-implementation-method-Mesh-SFU-MCU/#21-signaling-serverp2pmesh). An architecture in which each participant is directly connected to all other participants, which eliminates the need for MCU or SFU. This architecture is also commonly referred to as a "mesh".
- ### Codecs
  A codec (short for coder-decoder or compressor-decompressor) is an algorithm or software that processes audio or video data, either compressing it for more efficient storage and transmission or decompressing it for playback and editing purposes. Codecs enable efficient management of digital media by reducing file sizes without significantly compromising quality.
  - #### **Access unit**
  An access unit is a complete and self-contained data element in a video or audio stream, representing the smallest unit that can be independently processed for decoding and presentation purposes. In the case of video, it typically consists of one video frame or a group of frames, along with any associated metadata needed for decoding and synchronization during playback.
  - #### **NAL unit**
  A NAL (Network Abstraction Layer) unit is a data packet in H.264/AVC and H.265/HEVC video coding standards, encapsulating video information such as compressed video slices or other related metadata. NAL units enable efficient storage and transmission of compressed video data over a variety of networks.
  - #### **Bitrate**
  Bitrate is a measure of the amount of data that is transmitted through a network or stored over a certain period. Specifically, it refers to the number of bits that are transmitted per second. Bitrate is typically used to describe the quality of audio or video recordings, where a higher bitrate means better quality and a lower bitrate usually means lower quality.
  - #### **SPS** and **PPS**
  SPS (Sequence Parameter Set) is a data structure (namely [NAL unit](#nal-unit)) in H.264/AVC video coding standard that contains information about the properties and configurations of video sequences, such as resolution, frame rate, and bit depth.
  PPS (Picture Parameter Set) is another [NAL unit](#nal-unit) type in H.264/AVC that specifies information relevant to individual frame decodings, such as macroblock configurations, slice types, and reference frame indices.
  - #### **NAL** and **VCL**
  NAL (Network Abstraction Layer) is a component within the H.264/AVC and H.265/HEVC video coding standards that encapsulates and delivers compressed video data, enabling efficient storage and transmission over various networks while maintaining video quality and synchronization. NAL operates by defining data packets called [NAL units](#nal-unit).
  VCL (Video Coding Layer) is another component in the H.264/AVC and H.265/HEVC video coding standards responsible for the actual compression process. The VCL efficiently represents the video content by applying various compression techniques, such as motion compensation, spatial prediction, and transform coding. The compressed video data is then packetized into NAL units for transmission and storage.
  - #### **DCT**
  DCT (Discrete Cosine Transform) is a mathematical transformation widely used in image and video compression algorithms to efficiently represent data in the frequency domain. By converting spatial data (pixels) into frequency coefficients, DCT helps identify redundant or visually less-important information, which can be compressed or discarded to reduce the file size while maintaining an acceptable level of an image or video quality.
  - #### **H.264/AVC**
  H.264, also known as AVC (Advanced Video Coding), is a widely used video compression standard that provides efficient video encoding and transmission, delivering high-quality video with reduced bandwidth requirements and lower storage needs, making it suitable for various applications such as online streaming, video conferencing, and video storage.
  - #### **H.264 profiles**
  H.264 profiles are predefined sets of constraints and features within the H.264/AVC video coding standard, designed to cater to different use cases and performance requirements. These profiles ensure compatibility among various devices and applications while maintaining efficient video compression and quality. 
  - #### **Annex B** and **AVCC**
  Annex B and AVCC are two different formats for representing encoded video data in the context of H.264/MPEG-4 AVC video compression.
  Annex B specifies how the compressed video data is packetized for transmission over IP networks, including the format of the start codes that allow identifying the position of particular [NAL units](#nal-unit) in the stream. Annex B is defined in the H.264/MPEG-4 AVC specification (MPEG-4 part 10), which can be found at the following [link](http://www.itu.int/rec/T-REC-H.264). Annex B is a good choice when the video is about to be live-streamed.
  The AVCC format is defined in the ISO/IEC 14496-15:2010 specification (MPEG-4 part 15), which can be found at the following [link](https://www.iso.org/standard/55970.html). Compared to the Annex B format, AVCC is better suited for storing the video stream in a file. In colloquial terms, the AVCC format is sometimes referred to as "length-prefix", since the information about the position of NAL units in the stream is stored in the form of a length of particular NAL units. This makes it easier to work with the stream in a file format, as the decoder can read ahead to determine the length of each NAL unit and parse it accordingly.
  - ### Frame types:
    In video codecs, e.g. H.264, there is a concept of distinguishing different video frames, depending on their role
    in the intra-frame prediction compression process. 
    - #### **I frame**
    An I-frame (Intra frame) is a self-contained frame in a video stream that serves as a reference for encoding and decoding other frames, storing the entire picture without relying on any other frames for information.
    - #### **P frame**
    A P frame (Predictive frame) is a video compression frame that depends on the preceding I frame or P frame for data, using the motion differences between the two frames to reduce the amount of stored information and make the file size smaller.
    - #### **B frame**
    A B frame (Bidirectional predictive frame) is a video compression frame that relies on both the preceding and following I or P frames for data, using the motion differences between these frames to further reduce the stored information, resulting in even smaller file sizes and better compression efficiency.
## Membrane Framework
- #### **Action**
  An action can be returned from [callback](#callback) and it is a way of element interaction with other elements and parts of the framework. An exemplary action might be [`:buffer`](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:buffer/0) action, that sends buffers through a pad, or [`:terminate`](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:terminate/0) action, that terminates element with given reason.
- #### **Callback**
  A callback is a function defined by a user, that gets called once a particular event happens.
  Exemplary callbacks in the Membrane Framework are: [`handle_end_of_stream/3`](https://hexdocs.pm/membrane_core/Membrane.Element.WithInputPads.html#c:handle_end_of_stream/3) being called once the end of stream event is received on some pad or [`handle_init/2`](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#c:handle_init/2) called on initialization of an [element](#element).
- #### **Pad**
  An input or output of an [elements](#element) or a [bin](#bin). Output pads of one element or a bin are connected to input pads of another element or a bin.
- #### **Stream format, formerly: caps**
  It defines [pads](#pad) specification, allowing us to determine whether two elements are compatible with each other.
  The formerly used name "caps" is an abbreviation of "capabilities". 
- #### **Pipeline**
  A chain of linked [elements](#element) or [bins](#bin) which together accomplish some media processing task.
- #### **Bin**
  A container for elements, which allows for creating reusable groups of [elements](#element). Bin can incorporate elements and other bins as well.
- #### **Buffer**
  A fundamental structure in the Membrane that is used to send data between elements.
- ### **Element** 
  The most basic entity that is responsible for processing multimedia. Each element is created to solve one problem. Elements can be divided into four categories:
  - #### **Source** 
    An element with only output [pads](#pads), the first element of each pipeline. It is responsible for fetching the data and transmitting it through the output pad.
  - #### **Filter**
    An element with both input and output [pads](#pads), which is responsible for transforming data.
  - #### **Sink** 
    An element with only input [pads](#pads), the last element of a pipeline. It might be responsible, i.e. for writing the output to the file or playing the incoming media stream.
  - #### **Endpoint**
    An element with both input and output [pads](#pads), responsible for receiving and consuming data (e.g., writing to a soundcard, sending via TCP, etc.) as well as producing data (e.g., reading from a soundcard, downloading via HTTP, etc.) and sending it through the corresponding pads. It can be thought of as an element merging all the functionalities of previously mentioned element categories: source, filter, and sink.
- #### **ChildrenSpec**
  In Membrane Framework, `ChildrenSpec` is a way of describing the topology of a [pipeline](#pipeline) or a [bin](#bin). You can read more about `ChildrenSpec` [here](https://hexdocs.pm/membrane_core/Membrane.ChildrenSpec.html).
- ### Types of elements:
  - #### **Payloader** and **Depayloader**
    Payloader is responsible for preparing the data stream to be put in some specific format, typically a network-friendly format
    or a container format. This preparation may include the addition of headers or various metadata. Depayloader does the reverse operation - it allows to receive the original data stream from a specific format.
  - #### **Encoder** and **Decoder**
    Elements responsible for [encoding](#encoding) and [decoding](#decoding).
  - #### **Encryptor** and **Decryptor**
    Elements responsible for [encryption](#encryption) and [decryption](#decryption).
  - #### **Muxer** and **Demuxer**
    Elements responsible for [muxing](#muxing) and [demuxing](#demuxing).
  - #### **Mixer**
    An element responsible for mixing multiple media streams into a single stream. Unlike multiplexing, mixing is an irreversible operation.
  - #### **Jitter buffer** / **Ordering buffer**
    An element that is responsible for ordering packets incoming from the network as their order can be disrupted during transmission due to network unreliability. The name "jitter buffer" comes from the "packet jitter" term used in computer network terminology. "Packet jitter" refers to the variation in latency between consecutive packets in a network, which can lead to disruptions in audio or video streaming quality.
  - #### **Tee**
    An element that allows for copying a single input stream to multiple output streams. A possible implementation of the Tee can be found [here](https://github.com/membraneframework/membrane_tee_plugin).
  - #### **Funnel**
    An element that allows for merging multiple input streams into a single output stream. A possible implementation of the Funnel can be found [here](https://github.com/membraneframework/membrane_funnel_plugin).
- ### Demands mechanism
  - #### **Demands**, **Demanding**
    Demanding is a name for the Membrane Framework backpressure mechanism. Elements are allowed to send "demands" to the preceding
    element, in which they describe the amount of data they want to receive.
  - #### **Redemands**
    In Membrane it's an element's action that lets the programmer handle just one buffer at a time. When redemanding, the `handle_demand/5` callback is synchronously called. You can read more about redemands [here](https://hexdocs.pm/membrane_core/Membrane.Element.Action.html#t:redemand/0).

## General Elixir/Erlang concepts
- ### OTP Behaviour
  - #### **GenServer**
    Elixir behaviour abstracts client/server interaction. [https://elixir-lang.org/getting-started/mix-otp/genserver.html](https://elixir-lang.org/getting-started/mix-otp/genserver.html)
- ### **Phoenix** 
    The web development framework is written in Elixir. [https://phoenixframework.org/](https://phoenixframework.org/)
- ### **Mix**
    A build tool for creating and managing Elixir projects. [https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html)
