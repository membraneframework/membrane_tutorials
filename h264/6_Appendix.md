| nal_unit_type | Content of NAL unit & RBSP syntax structure                                                              | NAL unit type class [Annex A] |
| ------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------ |
| 0             | Unspecified                                                                                              | non-VCL                        |
| 1             | Coded slice of a non-IDR picture *slice_layer_without_partitioning_rbsp()*                               | VCL                            |
| 2             | Coded slice data partition A *slice_data_partition_a_layer_rbsp()*                                       | VCL                            |
| 3             | Coded slice data partition B *slice_data_partition_b_layer_rbsp()*                                       | VCL                            |
| 4             | Coded slice data partition C *slice_data_partition_c_layer_rbsp()*                                       | VCL                            |
| 5             | Coded slice of an IDR picture *slice_layer_without_partitioning_rbsp()*                                  | VCL                            |
| 6             | Supplemental enhancement information (SEI) *sei_rbsp()*                                                  | non-VCL                        |
| 7             | Sequence parameter set *seq_parameter_set_rbsp()*                                                        | non-VCL                        |
| 8             | Picture parameter set *pic_parameter_set_rbsp()*                                                         | non-VCL                        |
| 9             | Access unit delimiter *access_unit_delimiter_rbsp()*                                                     | non-VCL                        |
| 10            | End of sequence *end_of_seq_rbsp()*                                                                      | non-VCL                        |
| 11            | End of stream *end_of_stream_rbsp()*                                                                     | non-VCL                        |
| 12            | Filler data *filler_data_rbsp()*                                                                         | non-VCL                        |
| 13            | Sequence parameter set extension *seq_parameter_set_extension_rbsp()*                                    | non-VCL                        |
| 14            | Prefix NAL unit *prefix_nal_unit_rbsp()*                                                                 | non-VCL                        |
| 15            | Subset sequence parameter set *subset_seq_parameter_set_rbsp()*                                          | non-VCL                        |
| 16 - 18       | Reserved                                                                                                 | non-VCL                        |
| 19            | Coded slice of an auxiliary coded picture without partitioning *slice_layer_without_partitioning_rbsp()* | non-VCL                        |
| 20            | Coded slice extension *slice_layer_extension_rbsp()*                                                     | non-VCL                        |
| 21            | Coded slice extension for depth view components *slice_layer_extension_rbsp()* (specified in Annex I)    | non-VCL                        |
| 22 - 23       | Reserved                                                                                                 | non-VCL                        |
| 24 - 31       | Unspecified                                                                                              | non-VCL                        |