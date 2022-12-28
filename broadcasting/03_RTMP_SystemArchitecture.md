As noted previously, our system will be divided into two parts:

- the server, which is responsible for receiving the RTMP stream, converting it into HLS, and then publishing the created files as an HTTP server
- the client, responsible for playing the incoming HLS stream.

Considering our point of view, the first part will be more complex, since we will need to prepare the processing pipeline on our own. Let's start with that part.

## The server

Below you can find the desired flow of data in our application server:
![Pipeline scheme](assets/RTMP_to_HLS_pipeline.drawio.png)

As you can see, the server architecture consists of two bigger processing units - in Membrane Framework we refer to such units as 'bins'.
The following bins will be used in our solution:

- RTMP Source Bin - responsible for receiving RTMP stream
- HLS Sink Bin - responsible for "packing" the data into the container format

Each of these bins consists of some subunits (in Membrane we refer to them as _elements_), responsible for completing an atomic multimedia processing task - i.e. parsing or payloading the incoming stream.

Let's take a quick walk through the whole processing line and describe more specifically what its given parts are meant to do.

### RTMP Source

The very first element, just at the beginning of the RTMP Source Bin is the RTMP Source. It acts as an RTMP server, listening for the incoming stream. It will be exposing a TCP port, and the streamer will be able to connect and start sending RTMP packets through that channel.
The incoming packets will be demuxed - meaning, that the packets will be unpacked and split, based on the track (video or audio) which data they are transporting.

## Parsers

Buffers containing the given track data will be sent to the appropriate parser - H264 parser for video data and AAC parser for audio data.

### H264 Parser

H264 parser is quite a complex element, designed to read the incoming H264 stream. We have prepared a [separate, supplemental chapter of this tutorial](H264_codec.md) to describe the H264 codec and our parser's implementation - we invite you to read it, however, that knowledge is not necessary to successfully run the application.

### AAC Parser

At the same time, parsing happens to the buffers containing audio data. Since the audio track has been encoded with the use of AAC, we need [AAC parser](https://github.com/membraneframework/membrane_aac_plugin) to decode it.
That part of the tutorial does not describe the AAC codec itself, and in case you are interested in digging into that codec, we highly recommend visiting [that page](https://wiki.multimedia.cx/index.php/Understanding_AAC).

### HLS converter

Once data reaches the HLS bin, it needs to be put into the appropriate container files. Since we will be using Common Media Application Format (CMAF) to distribute our media, we need to put all the tracks into the `fragmented MP4` container. The first step is to payload the track's data. Payloading transforms the media encoded with a given codec into a form that is suitable to be put into the container.
The audio track is payloaded within the `Membrane.MP4.Payloader.AAC` module and the video track is payloaded with an H264 payloader, implemented by the `Membrane.MP4.Payloader.H264` module.
The payloaded streams (both the audio stream and the video stream) are then put in the result CMAF file - and the `Membrane.MP4.Muxer.CMAF` is the element responsible for that process. The name 'muxer', relates to the process
of 'muxing' - putting multiple tracks in one file, which is done by that element. Furthermore, the `CMAF muxer`, splits the streams into so-called segments - stream parts of the desired duration. Along that procedure, the manifest files, which contain metadata about the media and names of the appropriate segment file names, are generated.
Finally, the output files: '.m4s' files for each of the segments, as well as manifest files, are written on the disk.
Let's take a look at how do the generated files look like:
![Pipeline scheme](assets/output_files_structure.png)
As we can see, there are:

- index.m3u8 - the manifest file which contains metadata about the media, as well as the URI of the manifest files for both the video and audio track.

```
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-INDEPENDENT-SEGMENTS
#EXT-X-MEDIA:TYPE=AUDIO,NAME="audio_default_name",GROUP-ID="audio_default_id",AUTOSELECT=YES,DEFAULT=YES,URI="audio.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=4507734,CODECS="avc1.42e00a",AUDIO="audio_default_id"
video_g2QABXZpZGVv.m3u8
```

- audio.m3u8 - the manifest file for the audio track.

```
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-TARGETDURATION:8
#EXT-X-MEDIA-SEQUENCE:0
#EXT-X-DISCONTINUITY-SEQUENCE:0
#EXT-X-MAP:URI="audio_header_g2QABWF1ZGlv_part0_.mp4"
#EXTINF:8.0,
audio_segment_9_g2QABWF1ZGlv.m4s
#EXTINF:8.0,
audio_segment_10_g2QABWF1ZGlv.m4s
#EXTINF:8.0,
audio_segment_11_g2QABWF1ZGlv.m4s
```

That file contains some metadata (like the desired duration of the segment), along with the URI pointing to the '.mp4' header file of the fMP4 container, and the list of the segment files, in '.m4s' format.
Each segment is described with `EXTINF` directive, indicating the duration of the segment, in seconds.

- video\_<identifier>.m3u8 - the manifest file for the video track. Its structure is similar to the structure of the audio.m3u8 file. However, it is worth noting, that the desired duration of each segment is equal to 10 seconds - and the '.m4s' files are holding a video stream of that length.

```
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-TARGETDURATION:10
#EXT-X-MEDIA-SEQUENCE:0
#EXT-X-DISCONTINUITY-SEQUENCE:0
#EXT-X-MAP:URI="video_header_g2QABXZpZGVv_part0_.mp4"
#EXTINF:10.0,
video_segment_8_g2QABXZpZGVv.m4s
#EXTINF:10.0,
video_segment_9_g2QABXZpZGVv.m4s
```

- audio_header\_<identifier>_part\<part_ordering_number>_.mp4 - a binary file, the header meant to describe the audio track in the format required by the fragmented MP4 container.
- video_header\_<identifier>\_part\<part_ordering_number>.mp4 - a binary file, the header meant to describe the video track in the format required by the fragmented MP4 container.
- audio_segment\_\<segment_ordering_number>\_\<>.m4s - particular segments containing fragments of the audio stream.
- video_segment\_\<segment_ordering_number>\_\<>.m4s - particular segments containing fragments of the video stream.

### HTTP server

The HTTP server sends the requested files to the clients. Its implementation is based on the API provided by the Phoenix Framework.

## The client

When it comes to our application client, we will be using the `Hls.js` library, available in the javascript ecosystem.
We won't dig into the details of how the client application media player is implemented, however, we would like to point out some steps which take place while playing the media.
First, the client needs to request the master manifest file. Based on that file, the client asks for the appropriate audio and video track manifest files.
With these files, the client knows the MP4 header files for both the tracks, as well as knows the filenames of the particular segments, along with their duration. The client downloads the MP4 header file and starts downloading the appropriate segment files, based on which part of the media should be played in the nearest future.
