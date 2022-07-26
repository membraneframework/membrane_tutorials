 In this chapter you will learn about H264 codec and how it's processing is done with Membrane Framework plugin - the [H264 plugin](https://github.com/membraneframework/membrane_h264_ffmpeg_plugin).

 In H264 we can distinguish two layers of abstraction - the video coding layer (VCL), focused on the visual representation of the video, and the network abstraction layer (NAL), focused on how to structurize the stream so that it can be send via the network. 
 
 When it comes to VCL, a video encoded with H264 codec is represented as a sequence of pictures. Each picture consists of many **macroblocks**.
 The macroblock is simply a part of the picture (in context of some spatial dependence) - i.e. the top left corner of the picture.
 The macroblocks are grouped together into so called **slices**. Each slice consists of some macroblocks, which share the same **slice header**, containing some metadata common for all these macroblocks.

Each slice (which in fact is a part of a video picture), can be packed into a single
**NALu** (*Network Abstraction Layer unist*). As the name suggest, here is where we start to deal with NAL. NALu is just an atomic piece of information sent throught the network - it might contain some visual data (i.e. a list of macroblocks forming a part of a video frame), but it is not limited to the visual data - within NALus a metadata used to properly decode the stream is also sent. We can distinguish two types of NAL units:
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
> * SPS - *Sequence Parameter Set*, a Non-VCL NALu, with a set of parameters which rarely change, applicable to the series of consecutive coded video pictures, called the **coded video sequence**. Each coded video sequence can be decoded independently of any other coded video sequence.
> * PPS - *Picture parameter Set* - a set of parameters which are applicable to some pictures from the coded video sequence. Furthermore, inside a PPS NALu there is a reference to SPS. 
> * SEI - *Supplemental Enhancement Information* - some additional information that enhance the usability of the decoded video, i.e. timing information
> * IDR - *Instantaneous Decoding Refresh*, a VCL unit containing the I-frame (known also as `intra frame`) - a picture which can be decoded without knowledge of any other frame, in contrast to P-frames and B-frames, which might need previously presented frames or frames that need to be presented in the future. As you might guess, I-frames size is much greater than P-frame or B-frame size - that is because the whole information about the content of the picture need to be encoded in such a frame.
> * NON_IDR - *Non Instantaneous Decoding Refresh* - a VCL unit containing a P-frame or B-frame or parts of such a non-key frame. Note the size of a Non-IDR NALu (1536 B), compared to the size of IDR NALu (8284 B).

The sequence of NALus of a special form creates a **Access Unit**.
Each access unit hold a single picture of the video. Sometimes, for the convenience of the decoding, the access units are separated with the use of another Non-VCL NALu, called *AUD* (**Access Unit Delimeter**).
Below you can find a diagram showing the structure of an access unit:
[Access Unit structure](assets/au_structure.png)

A parser needs to be aware that some of the NALus are optional are might not appear in the stream.


The existence of a coded video sequence is determined by the presence of an IDR NALu in the first access unit. Each coded video sequence can be decoded independently of the other coded video sequences. 

As a summary we would like to present an diagram showing an exemplary NALus stream, along with the structures we can distinguish in that stream:
[H264 NALus stream](assets/h264_structure.png)

The first NALu is the SPS NALu, followed by two PPS NALus. As shown, the PPS NALus hold a reference to the SPS. Then come the SEI, which contains some more specific metada.
After the metadata, there is an IDR NALu. It's existence determines the coded video sequence. All the NALus
