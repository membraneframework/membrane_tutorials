# System architecture

As noted previously, our system will be devided into two parts:
* the server, responsible for receiving RTMP stream, converting it into HLS and then publishing the created files as a HTTP server
* the client, responsible for playing the incoming HLS stream.

Considering our point of view, the first part will be more complex, since we will need to prepare the processing pipeline on our own. Let's start with that part.

## The server
Below you can find the desired flow of data in our application server:
![Pipeline scheme](assets/RTMP_to_HLS_pipeline.drawio.png)
 
As you can see, the server architecture consists of two bigger processing units - in Membrane Framework we refere to such a units as 'bins'.
The following bins will be used in our solution:
* RTMP Source Bin
* HLS Sink Bin

Each of these bins consist of some subunits, responsible for completing an atomic multimedia processing task - i.e. parsing or payloading the incoming stream.

Let's take a quick walk through the whole processing line and describe more specificly what it's given parts are meant to do.
### RTMP Source
The very first elements, just at the beggining of the RTMP Source Bin is the RTMP Source. It acts as a RTMP server, listening for the incoming stream. It will be exposing a TCP port, making the stream able to estabilish a connection and start sending RTMP packets through that channel. 
The incoming packets will be demuxed - meaning, that the packts will be unpacked and split, based on the track (video or audio) which data their are transporting. 
## Parsers
Buffers containg the given track data will be send to the appropriate parser - H264 parser for video data and AAC parser for audio data.
### H264 Parser
H264 parser is quite a complex element, designed to read the incoming H264 stream. Firstly, the parser reads the buffers and reproduces a sequence of so called
**NALu** (*Network Abstraction Layer unist*s). NALu is just an atomic piece of information sent with the use of H264 - it might contain some visual data, or a metadata used to properly decoded the stream of NALus. Based on that criterion we can distinguish two types of NAL units:
* VCL NALus - which stands for "Video coding layer" NALus
* Non-VCL NALus - which stands for "Non video coding layer" NALus

There are different types of both VCL and Non-VCL units - for more information on them you can refer [here](https://yumichan.net/video-processing/video-compression/introduction-to-h264-nal-unit/)

> With the use of Membrane Framework, you can inspect the types of NALus in your h264 file. To do so, you need to clone the H264 parser repository with:
> 
> ```
> git clone https://github.com/membraneframework/membrane_h264_ffmepg_plugin
> ```
> 
> Later on, inside the repository's directory, you can launch the Elixir's interactive shell, with compiled modules from the repository's mix project, by typing:
> 
> ```
> iex -S mix
> ```
> 
> Once in iex, you can do the following thing:
> ```Elixir
> alias Membrane.H264.FFmpeg.Parser.NALu
> 
> # Of course you can read your own file, here is just an example file from the test directory
> binaries = File.read!("test/fixtures/input-10-720p-main.h264") 
> 
> NALu.parse(binaries)
> ```
> 
> You should see the following response:
> ```
> {[
>   %{
>     metadata: %{h264: %{new_access_unit: %{key_frame?: true}, type: :sps}},
>     prefixed_poslen: {0, 29},
>     unprefixed_poslen: {4, 25}
>   },
>   %{
>     metadata: %{h264: %{type: :pps}},
>     prefixed_poslen: {29, 9},
>     unprefixed_poslen: {33, 5}
>   },
>   %{
>     metadata: %{h264: %{type: :sei}},
>     prefixed_poslen: {38, 690},
>     unprefixed_poslen: {41, 687}
>   },
>   %{
>     metadata: %{h264: %{type: :idr}},
>     prefixed_poslen: {728, 8284},
>     unprefixed_poslen: {731, 8281}
>   },
>   %{
>     metadata: %{h264: %{type: :non_idr}},
>     prefixed_poslen: {9012, 1536},
>     unprefixed_poslen: {9016, 1532}
>   },
>   ....
>   ]}
> ```
> As you can see, NALus of different types has appeard, just like:
> * SPS - *Sequence Parameter Set*, a set of parameters which rarely change, applicable to the series of consecutive coded video pictures, called the coded video sequence
> * PPS - *Picture parameter Set* - a set of parameters which are applicable to some pictures from the video sequence
> * SEI - *Supplemental Enhancement Information* - some additional information that enhance the usability of the decoded video, i.e. timing information)
> * IDR - *Instantaneous Decoding Refresh*, a VCL unit containing the I-frame (known also as `intra frame`) - a picture which can be decoded without knowledge of any other frame, in contrast to P-frames and B-frames, which might need previously presented frames or frames that need to be presented in the future. As you might guess, I-frames size is much greater than P-frame or B-frame size - that is because the whole information about the content of the picture need to be encoded in such a frame.
> * NON_IDR - *Non Instantaneous Decoding Refresh* - a VCL unit containing a P-frame or B-frame or parts of such a non-key frame. Note the size of a Non-IDR NALu (1536 B), compared to the size of IDR NALu (8284 B).
> 
> The sequence of NALus of a special form creates a **Access Unit**.
> Each access unit hold a single picture of the video. Sometimes, for the convenience of the decoding, the access units are split with another Non-VCL NALu, called *AUD* (**Access Unit Delimeter**).
> Refer [here](https://en.wikipedia.org/wiki/Network_Abstraction_Layer#Access_Units) for a more precise description of access units and its structre.
> The existence of a coded video sequence is determined by the presence of an IDR NALu in the first access unit. Each coded video sequence can be decoded independently of the other coded video sequences. 
### AAC Parser
At the same time, a similar process happens with buffers containg audio data. Since the audio track is encoded with the use of AAC, we need [AAC parser](https://github.com/membraneframework/membrane_aac_plugin) to decode it.
Audio codec tends to be less complex than video codecs. We won't sacrify them a longer description, as we need to continue our journey to the HLS converter.
### HLS converter
### HTTP server

## The client