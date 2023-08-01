As noted above, from the NAL perspective, the H.264 stream is just a sequence of NAL units. 
But how do we know where one NAL unit ends and another one starts?
Well, the answer to that question is not straightforward, since the ITU specification does not define a single byte stream format. At the same time, one of the possible formats is described as an annex to the specification - Annex B. That format itself is usually referred to as Annex B and we will also stick to that name. 
We need to be aware that that format is not the only option - the other commonly used byte stream format is AVCC, known also as length prefix.
We will briefly discuss both of these formats.


## Annex B

Annex B is a format in which all NAL units are preceded with a so-called "start code" - one of the following byte sequences: three-byte `0x000001` or four-bytes `0x00000001`. 
In the case of that format, the H.264 stream might look as follows:
```
([0x000001][first NAL unit]) | ([0x000001][second NAL unit]) | ([0x000001][third NAL unit]) …
```
The existence of two "start codes" is dictated by the fact that the first variant is more applicable in certain situations than the second one. For a four-bytes variant, it's easy to find the start of a NAL unit sent through a serial connection, as it's easy to align the stream to 31 "0" bits followed by a single "1" bit. In other cases, to save space, it's common to use a three-byte variant.

The choice of `0x000001` and `0x00000001` as a NAL units separator wasn't unintentional - such a sequence of bytes does not encode much information (recall Shannon's formula for the amount of information) and that's why it's not frequent for the compression algorithm used in H.264 to produce such a sequence of bytes (the compression mechanism tries to encode as much information about video in the shortest bytes sequence possible). However, such a byte sequence might still appear in the stream (please also note, that some parts of the stream are metadata, which is not compressed) - and the format definition must take that into consideration. That's why an "emulation prevention" mechanism has been introduced. That mechanism is nothing more than a regular "escape character" mechanism - each of the following three-bytes sequences is not allowed to exist in the "escaped" byte stream:
* `0x000000` 
* `0x000001` 
* `0x000002`
* `0x000003`
and that's why it gets replaced correspondingly with the following sequences:
* `0x00000300`
* `0x00000301`
* `0x00000302`
* `0x00000303`
The "escape character" is 0x03 - also known as `emulation_prevention_three_byte`.

The representation with "emulation prevention three bytes" inserted is called **SODB** (*String of Data Bits*), and the representation without the "emulation prevention" bytes is called **RBSP** (*Raw Byte Sequence Payload*). Encoders need to take care of escaping the unallowed byte sequences (converting the byte stream from RBSP to SODB), while decoders are obliged with the reverse operation (converting from SODB to RBSP).


## AVCC

In this byte stream format, each NAL unit is preceded with a `nal_size` field, describing its length. That length might be stored with the use of 1, 2 or 4 bytes, and that is why a special additional header (known as "extradata", "sequence header" or "AVCDecoderConfigurationRecord") is required to be present in the stream to specify how many bytes are used to store the NAL unit's length. The stream then might look as follows: 
```
([extradata]) | ([length] NALu) | ([length] NALu) | …
```

The syntax of the extradata is described in MPEG-4 Part 15 "Advanced Video Coding (AVC) file format" section 5.2.4.1:
```
aligned(8) class AVCDecoderConfigurationRecord { 
    unsigned int(8) configurationVersion = 1; 
    unsigned int(8) AVCProfileIndication; 
    unsigned int(8) profile_compatibility; 
    unsigned int(8) AVCLevelIndication; 
    bit(6) reserved = '111111'b; 
    unsigned int(2) lengthSizeMinusOne; 
    bit(3) reserved = '111'b; 
    unsigned int(5) numOfSequenceParameterSets; 
    for (i=0; i< numOfSequenceParameterSets; i++) { 
        unsigned int(16) sequenceParameterSetLength;          
        bit(8*sequenceParameterSetLength) sequenceParameterSetNALUnit; 
    } 
    unsigned int(8) numOfPictureParameterSets; 
    for (i=0; i< numOfPictureParameterSets; i++) { 
        unsigned int(16) pictureParameterSetLength; 
        bit(8*pictureParameterSetLength) pictureParameterSetNALUnit; 
    }
}
```
The value of `lengthSizeMinusOne` field (which can be: 0, 1 or 3) determines how many bytes are used to store a length of NALu (that is, correspondingly, 1, 2 or 4 bytes). The most commonly used one is a 4-bytes size field that allows for NAL units of length up to `2^32-1` bytes.  

 
## NAL unit syntax

Each of the NAL units that we can find in the stream consists of a number of fields. Each field occupies a particular number of bytes and its value has a given semantics. ITU specifications define a syntax to describe NAL units' structure. We will become familiar with some field types defined within that syntax, as well see some exemplary NAL unit descriptions using that syntax.

### Data types

These are some of the types that can be met in the NAL units syntax (for all of the types available, please refer to chapter 7.2 of the ITU Specification):
* **f(N)** - "fixed pattern" sequence of N bits. I.e. f(8) might be some particular pattern of 8 bits - just like `00001111`. For information on how the pattern looks, you need to look in the semantics description of a given field. 
* **u(N)** - an unsigned integer written with the use of N bits - i.e. u(16) means an unsigned integer written with the use of 16 bits.
* **u(v)** - an unsigned integer written with the use of some number of bits. That number is usually specified by the value of some other, previously read field. In order to find out which field that is, you need to refer to the description of the semantics of that field.
* **ue(v)** - unsigned integer of variable size written with *Exponential-Golomb* coding. For more information about that coding you can refer [here](https://en.wikipedia.org/wiki/Exponential-Golomb_coding).
* **se(v)** - same as above, but this time the integer is signed.


### General NAL unit structure

Below there is a description of each NAL unit's structure. The structure description that you can find in chapter 7.3.1 of the ITU Specification is slightly different (and much more complicated). That is because it also covers the fact that there is a need to get rid of emulation_prevention_bytes. In order to simplify things, we assume that in the structure description we use, the byte stream has already been converted to RBSP. 

| nal_unit( NumBytesInNALunit )                          | Descriptor |
|------------------------------------------------------- |------------|
|{                                                       |            |
|   &nbsp;&nbsp;&nbsp;&nbsp; forbidden_zero_bit          |f(1)        |
|   &nbsp;&nbsp;&nbsp;&nbsp; nal_ref_idc                 |u(2)        |
|   &nbsp;&nbsp;&nbsp;&nbsp; nal_unit_type               |u(5)        |
|   &nbsp;&nbsp;&nbsp;&nbsp; nal_unit_data()             |            |
|}                                                       |            |

As you can see, each NAL unit starts with a single byte being a kind of a NAL unit header. Its first bit (`forbidden_zero_bit`) is always equal to 0, then comes a `nal_ref_idc` field consisting of two bits, and finally `nal_unit_type` - an unsigned integer written with the use of 5 bits, which determines the type of NAL unit. 

## NALu types

Each NAL unit can be of a different type. In this chapter we will describe only some of the NAL units types, while all the possible types are listed in the table available in "Appendix/NALu types".

There are two "classes" of NAL units types defined in ITU-T Specification's Annex A - **VCL** and **non-VCL** NAL units. The first one holds the encoded video, while the other does not contain video data at all. In our case, we found the following NAL unit types especially helpful:
* VCL:
    * *Coded slice of a non-IDR picture* (**non-IDR**) - contains a part or a complete non-keyframe (that is: P-frame or a B-frame)
    * *Coded slice of an IDR picture* (**IDR**) -  contains a part or a complete keyframe (also known as I-frame). The name IDR (that stands for *instantaneous decoding refresh*) originates from the fact that the decoder can "forget" the previous frames when the new keyframe appears, since it contains the complete information about the frame. 
* non-VCL:
    * *Sequence parameter set* (**SPS**) - contains metadata that is applicable to one or more *coded video sequences*. In that NALu you will find information allowing you to calculate the video resolution or H.264 profile.
    * *Picture parameter set* (**PPS**) - contains metadata applicable to one or more *coded pictures* 
    * *Access unit delimiter* (**AUD**) - just a separator between *access units*
    * *Supplemental enhancement information* (**SEI**) - contains some additional metadata that "assist in processes related to decoding, display or other purposes". At the same time, information stored in SEI is not required to restore the picture during the decoding process, so the decoders are not obliged to process SEI. In fact, SEI is defined as Annex D to the ITU specification. 

Some of the terms used in these (especially the ones written with *curved* font) might not be known to you yet - don't worry, keep on reading as they will be explained later. Once that happens, we invite you to go back to that section to reread it ;)
