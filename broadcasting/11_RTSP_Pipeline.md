As explained in the [Architecture chapter](07_RTSP_Architecture.md), the pipeline will consist of a couple of elements, that will be processing the RTP stream.

The flow of the pipeline will consist of three steps. First, when the pipeline is initialized we will start the Connection Manager, which will set up the RTP stream via the RTSP.
Once that is finished, we will set up two initial elements in the pipeline - the `UDP Source` and `RTP SessionBin`, which will allow us to receive RTP packets and process them.
When the SessionBin detects that the RTP stream has been started, it will notify the pipeline with the `:new_rtp_stream` notification. Later on, we will add the remaining elements to the pipeline, allowing for the whole conversion process to take place.

Those steps take place, respectively, in the: `handle_init/1`, `handle_other/3` and `handle_notification/4` callbacks. While the `handle_init/1` is rather intuitive, we will describe in detail what's happening in the other callbacks.

Let us explain what's going on in the `handle_other` callback:

##### lib/pipeline.ex
```elixir
@impl true
def handle_other({:rtsp_setup_complete, options}, _ctx, state) do
  children = %{
    app_source: %Membrane.UDP.Source{
      local_port_no: state[:port],
      recv_buffer_size: 500_000
    },
    rtp: %Membrane.RTP.SessionBin{
      fmt_mapping: %{96 => {:H264, 90_000}}
    },
    hls: %Membrane.HTTPAdaptiveStream.Sink{
      manifest_module: Membrane.HTTPAdaptiveStream.HLS,
      target_window_duration: 120 |> Membrane.Time.seconds(),
      target_segment_duration: 4 |> Membrane.Time.seconds(),
      storage: %Membrane.HTTPAdaptiveStream.Storages.FileStorage{
        directory: state[:output_path]
      }
    }
  }

  links = [
    link(:app_source)
    |> via_in(Pad.ref(:rtp_input, make_ref()))
    |> to(:rtp)
  ]

  spec = %ParentSpec{children: children, links: links}
  { {:ok, spec: spec}, %{state | video: %{sps: options[:sps], pps: options[:pps]}} }
end
```

When we receive the `rtsp_setup_complete` message, we first define the new children for the pipeline, and links between them - the UDP Source and the RTP SessionBin. We also create the HLS Sink, however we won't be linking it just yet. With the message we receive the sps and pps inside the options, and we add them to the pipeline's state.

Only after we receive the `:new_rtp_stream` notification we add the rest of the elements and link them with each other:

##### lib/pipeline.ex
```elixir
@impl true
def handle_notification({:new_rtp_stream, ssrc, 96, _extensions}, :rtp, _ctx, state) do
  actions =
    if Map.has_key?(state, :rtp_started) do
      []
    else
      children = %{
        video_nal_parser: %Membrane.H264.FFmpeg.Parser{
          sps: state.video.sps,
          pps: state.video.pps,
          skip_until_keyframe?: true,
          framerate: {30, 1},
          alignment: :au,
          attach_nalus?: true
        },
        video_payloader: Membrane.MP4.Payloader.H264,
        video_cmaf_muxer: Membrane.MP4.Muxer.CMAF
      }

      links = [
        link(:rtp)
        |> via_out(Pad.ref(:output, ssrc),
          options: [depayloader: Membrane.RTP.H264.Depayloader]
        )
        |> to(:video_nal_parser)
        |> to(:video_payloader)
        |> to(:video_cmaf_muxer)
        |> via_in(:input)
        |> to(:hls)
      ]

      [spec: %ParentSpec{children: children, links: links}]
    end

  { {:ok, actions}, Map.put(state, :rtp_started, true) }
end
```

First we check, if the stream hasn't started yet. That's because if we are restarting the pipeline there might be a previous RTP stream still being sent, so we might receive the `:new_rtp_stream` notification twice - once for the old and then for the new stream. We want to ignore any notification after the first one, as we want only a single copy of each media processing element.
Notice the sps and pps being passed to the H264 parser - they are necessary for decoding the stream.
