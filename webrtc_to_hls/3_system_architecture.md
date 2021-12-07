

# Custom Pipeline
Here is how the flow our custom pipeline element should implement:
![Pipeline Flow Scheme](assets/images/webrtc_to_hls_pipeline.drawio.png)

The whole Pipeline will consist of elements which are already existing in the Membrane Framework. What we need to do is to put them in correct order.
We will receive multimedia stream via UDP socket implemented as a part of `EndpointBin` (which in fact is an abstract made on top of communication channel which provides multimedia stream). This element has two pads: `:audio` pad and `:video` pad. We need to connect the appropriate output pad to the sequence of elements processing the given media type.
## Video processing
Video is already sent in a form supported by H264 format. First, we need to split it into fragments - that is what [`Video parser`]() is responsible for. Then we add some additional information to each of the fragments so that fragments will be able to be identified withing the container file. [`Video Payloader`](https://github.com/membraneframework/membrane_mp4_plugin/blob/master/lib/membrane_mp4/payloader/h264.ex) does all of that stuff for us. 
After such a preparation, [`Video CMAF Muxer`]() is putting the video track into the CMAF container file.
## Audio processing
Since WebRTC standard says, that audio should be sent with the use of OPUS codec, we first need to decode incoming audio stream with [`OPUS decoder`](https://github.com/membraneframework/membrane_opus_plugin/blob/master/lib/membrane_opus/decoder.ex).
As the output of this element we get raw audio representation. 
Then we encode the audio with the use of [`AAC encoder`](). That s how we get audio in AAC codec format. Later on we need to parse it - which means, we need to split it into chunks which later on will be put as a fragments in the container file. Here is where [`AAC parser`](https://github.com/membraneframework/membrane_aac_plugin/blob/master/lib/membrane/aac/parser.ex) is helpful. But chunked AAC is not enough for us to be put in the container file - that is why we first add some additional information to each of audio fragments with the use of [`Audio Payloader`](https://github.com/membraneframework/membrane_mp4_plugin/blob/master/lib/membrane_mp4/payloader/aac.ex). Finally, such a processed fragments can be put in the container file - and this is done with a help from [`Audio CMAF Muxer`](), which simply puts previously payloaded audio track into CMAF container file. 


Once we have both the tracks processed, we can write them together in a container file. There is where [`HLS Sink`]() is used - this elements has two input pads for video and audio track. Out of these input tracks `HLS Sink` is making .ts and .m3u8 files which can be written to the given storage (e.g. on the file system).
These files can be then sent via HTTP.