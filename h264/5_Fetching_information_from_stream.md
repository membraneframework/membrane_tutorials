Below we present some information about a stream that can be fetched out of SPS NAL units.


## SPS NAL unit structure
| seq_parameter_set_rbsp( )   | Descriptor |
| --------------------------- | ---------- |
| {                           |            |
|   seq_parameter_set_data( ) |            |
|   rbsp_trailing_bits( )     |            |
| }                           |            |

As presented above, SPS NAL unit consists of a seq_parameter_set_data()which is a description of appropriate fields in the SPS, and the rbsp_trailing_bits() which is simply a sequence of some "0" bits at the end of the SPS NALu so that to ensure that the SPS NALu is byte-alligned. 
| seq_parameter_set_data( )                                                                                                                                                                                                                                                                                                        | Descriptor |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| {                                                                                                                                                                                                                                                                                                                                |            |
|   profile_idc                                                                                                                                                                                                                                                                                                                    | u(8)       |
|   constraint_set0_flag                                                                                                                                                                                                                                                                                                           | u(1)       |
|   constraint_set1_flag                                                                                                                                                                                                                                                                                                           | u(1)       |
|   constraint_set2_flag                                                                                                                                                                                                                                                                                                           | u(1)       |
|   constraint_set3_flag                                                                                                                                                                                                                                                                                                           | u(1)       |
|   constraint_set4_flag                                                                                                                                                                                                                                                                                                           | u(1)       |
|   constraint_set5_flag                                                                                                                                                                                                                                                                                                           | u(1)       |
|   reserved_zero_2bits /\* equal to 0 \*/                                                                                                                                                                                                                                                                                         | u(2)       |
|   level_idc                                                                                                                                                                                                                                                                                                                      | u(8)       |
|   seq_parameter_set_id                                                                                                                                                                                                                                                                                                           | ue(v)      |
|   if( profile_idc == 100 or profile_idc == 110 or

       profile_idc == 122 or profile_idc == 244 or profile_idc == 44 or

       profile_idc  == 83 or profile_idc == 86 or profile_idc == 118 or

       profile_idc == 128 or profile_idc == 138 or profile_idc == 139 or

       profile_idc == 134 or profile_idc == 135 ) |            |
|   {                                                                                                                                                                                                                                                                                                                              |            |
|       chroma_format_idc                                                                                                                                                                                                                                                                                                          | ue(v)      |
|       if( chroma_format_idc = = 3 )                                                                                                                                                                                                                                                                                              |            |
|           separate_colour_plane_flag                                                                                                                                                                                                                                                                                             | u(1)       |
|       bit_depth_luma_minus8                                                                                                                                                                                                                                                                                                      | ue(v)      |
|       bit_depth_chroma_minus8                                                                                                                                                                                                                                                                                                    | ue(v)      |
|       qpprime_y_zero_transform_bypass_flag                                                                                                                                                                                                                                                                                       | u(1)       |
|       seq_scaling_matrix_present_flag                                                                                                                                                                                                                                                                                            | u(1)       |
|       if( seq_scaling_matrix_present_flag )                                                                                                                                                                                                                                                                                      |            |
|               for( i = 0; i < ( ( chroma_format_idc != 3 ) ? 8 : 12 ); i++ )                                                                                                                                                                                                                                                     |            |
|               {                                                                                                                                                                                                                                                                                                                  |            |
|                   seq_scaling_list_present_flag[ i ]                                                                                                                                                                                                                                                                             | u(1)       |
|                   if( seq_scaling_list_present_flag[ i ] )                                                                                                                                                                                                                                                                       |            |
|                       if( i < 6 )                                                                                                                                                                                                                                                                                                |            |
|                           scaling_list( ScalingList4x4[ i ], 16, UseDefaultScalingMatrix4x4Flag[ i ] )                                                                                                                                                                                                                           |            |
|                       else                                                                                                                                                                                                                                                                                                       |            |
|                           scaling_list( ScalingList8x8[ i − 6 ], 64, UseDefaultScalingMatrix8x8Flag[ i − 6 ] )                                                                                                                                                                                                                   |            |
|               }                                                                                                                                                                                                                                                                                                                  |            |
| }                                                                                                                                                                                                                                                                                                                                |            |
|   log2_max_frame_num_minus4                                                                                                                                                                                                                                                                                                      | ue(v)      |
|   pic_order_cnt_type                                                                                                                                                                                                                                                                                                             | ue(v)      |
|   if( pic_order_cnt_type == 0 )                                                                                                                                                                                                                                                                                                  |            |
|       log2_max_pic_order_cnt_lsb_minus4                                                                                                                                                                                                                                                                                          | ue(v)      |
|   else if( pic_order_cnt_type == 1 )                                                                                                                                                                                                                                                                                             |            |
|   {                                                                                                                                                                                                                                                                                                                              |            |
|       delta_pic_order_always_zero_flag                                                                                                                                                                                                                                                                                           | u(1)       |
|       offset_for_non_ref_pic                                                                                                                                                                                                                                                                                                     | se(v)      |
|       offset_for_top_to_bottom_field                                                                                                                                                                                                                                                                                             | se(v)      |
|       num_ref_frames_in_pic_order_cnt_cycle                                                                                                                                                                                                                                                                                      | ue(v)      |
|       for( i = 0; i < num_ref_frames_in_pic_order_cnt_cycle; i++ )                                                                                                                                                                                                                                                               |            |
|           offset_for_ref_frame[ i ]                                                                                                                                                                                                                                                                                              | se(v)      |
|   }                                                                                                                                                                                                                                                                                                                              |            |
|   max_num_ref_frames                                                                                                                                                                                                                                                                                                             | ue(v)      |
|   gaps_in_frame_num_value_allowed_flag                                                                                                                                                                                                                                                                                           | u(1)       |
|   pic_width_in_mbs_minus1                                                                                                                                                                                                                                                                                                        | ue(v)      |
|   pic_height_in_map_units_minus1                                                                                                                                                                                                                                                                                                 | ue(v)      |
|   frame_mbs_only_flag                                                                                                                                                                                                                                                                                                            | u(1)       |
|   if( !frame_mbs_only_flag )                                                                                                                                                                                                                                                                                                     |            |
|       mb_adaptive_frame_field_flag                                                                                                                                                                                                                                                                                               | u(1)       |
|   direct_8x8_inference_flag                                                                                                                                                                                                                                                                                                      | u(1)       |
|   frame_cropping_flag                                                                                                                                                                                                                                                                                                            | u(1)       |
|   if( frame_cropping_flag )                                                                                                                                                                                                                                                                                                      |            |
|   {                                                                                                                                                                                                                                                                                                                              |            |
|       frame_crop_left_offset                                                                                                                                                                                                                                                                                                     | ue(v)      |
|       frame_crop_right_offset                                                                                                                                                                                                                                                                                                    | ue(v)      |
|       frame_crop_top_offset                                                                                                                                                                                                                                                                                                      | ue(v)      |
|       frame_crop_bottom_offset                                                                                                                                                                                                                                                                                                   | ue(v)      |
|   }                                                                                                                                                                                                                                                                                                                              |            |
|   vui_parameters_present_flag                                                                                                                                                                                                                                                                                                    | u(1)       |
|   if( vui_parameters_present_flag )                                                                                                                                                                                                                                                                                              |            |
|       vui_parameters( )                                                                                                                                                                                                                                                                                                          |            |
| }

<br>                                                                                                                                                                                                                                                                                                                          |            |
We won't dig any further - of course, there are still  vui_parameters() to be parsed, but their structure is described in the same way as the beginning of the SPS NALu shown just above.

## Fetching resolution of a video

In order to calculate the resolution of a video (by which we mean - height and width in pixels), the following sequence of operations need to be done:
```python
if sps.separate_colour_plane_flag == 0 then:
    chroma_array_type = sps.chroma_format_idc 
else:
    chroma_array_type = 0


case sps.chroma_format_idc of 
    1: sub_width_c = 2, sub_height_c = 2 
    2: sub_width_c = 2, sub_height_c = 1 
    3: sub_width_c = 1, sub_height_c = 1 
    _other: sub_width_c = nil, sub_height_c = nil 

if chroma_array_type == 0 then:
    crop_unit_x = 1
    crop_unit_y = 2 - sps.frame_mbs_only_flag
else 
    crop_unit_x = sub_width_c
    crop_unit_y = sub_height_c * (2 - sps.frame_mbs_only_flag) 


if sps.frame_cropping_flag == 1 then:
    width_offset = (sps.frame_crop_right_offset + sps.frame_crop_left_offset) * crop_unit_x 
    height_offset = (sps.frame_crop_top_offset + sps.frame_crop_bottom_offset) * crop_unit_y 
else: 
    width_offset = 0
    height_offset = 0 


width_in_mbs = sps.pic_width_in_mbs_minus1 + 1 
width = width_in_mbs * 16 - width_offset
 
height_in_map_units = sps.pic_height_in_map_units_minus1 + 1 
height_in_mbs = (2 - sps.frame_mbs_only_flag) * height_in_map_units 
height = height_in_mbs * 16 - height_offset
```


## Fetching H.264 profile

There are a bunch of possible H.264 profiles - sets of features used by encoders/decoders to provide higher or lower levels of compression, i.e. some profiles (*baseline* and *constrained baseline*) don't use B-frames, while the other profiles do. If your decoder cannot deal with B-frames, you are obliged to use the baseline or constrained baseline stream. You can read more about H.264 profiles and differences between them [here](https://en.wikipedia.org/wiki/Advanced_Video_Coding#Profiles), but generally speaking you need to be aware that the knowledge of the profile might be helpful in many cases.
The H.264 profile is determined by the values of fields fetched from the SPS. Below there is a table showcasing the conditions that are met when a given stream is using a particular profile.


| Profile              | Fields values                                                     |
| -------------------- | ----------------------------------------------------------------- |
| BASELINE             | profile_idc = 66                                                  |
| CONSTRAINED BASELINE | profile_idc = 66, constraint_set1_flag=1                          |
| MAIN                 | profile_idc = 77                                                  |
| EXTENDED             | profile_idc = 88                                                  |
| HIGH                 | profile_idc = 100                                                 |
| PROGRESSIVE HIGH     | profile_idc = 100, constraint_set4_flag=1                         |
| CONSTRAINED HIGH     | profile_idc = 100, constraint_set4_flag=1, constraint_set5_flag=1 |
| HIGH 10              | profile_idc = 110                                                 |
| HIGH 4:2:2           | profile_idc = 122                                                 |