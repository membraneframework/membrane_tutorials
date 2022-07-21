# System architecture

As noted previously, our system will be devided into two parts:
* the server, responsible for receiving RTMP stream, converting it into HLS and then publishing the created files as a HTTP server
* the client, responsible for playing the incoming HLS stream.

Considering our point of view, the first part will be more complex, since we will need to prepare the processing pipeline on our own. Let's start with that part.

## The server
Below you can find the desired flow of data in our application server:
![Pipeline scheme](assets/RTMP_to_HLS_pipeline.drawio.png)
 
As you can see, the server architecture consists of two bigger processing units - in Membrane Framework we refer to such units as 'bins'.
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
H264 parser is quite a complex element, designed to read the incoming H264 stream. We have prepared a [separate, suplemental chapter of this tutorial]ś(H264_codec.md) for the purpose of describing H264 codec and our parser's implementation - we invite you to read it, however, the that knowledge is not neccesary to sucessfully run the application.
### AAC Parser
At the same time,a parsing happens to the buffers containg audio data. Since the audio track has been encoded with the use of AAC, we need [AAC parser](https://github.com/membraneframework/membrane_aac_plugin) to decode it.
For a better understanding why do we need to encode audio data, as well as how it is done, feel free to visit [a part of our Multimedia Introduction Tutorial](), divagating on audio processing.
That part of tutorial does not describe AAC codec itself, and in case of you being interestred in digging into that codec, we highly recommend visiting [that page](https://wiki.multimedia.cx/index.php/Understanding_AAC).

### HLS converter
### HTTP server

## The client