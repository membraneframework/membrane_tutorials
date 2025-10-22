As explained in the [Architecture chapter](08_RTSP_Architecture.md), the pipeline will consist of a RTSP Source and a HLS Sink.

The initial pipeline will consist only of the `RTSP Source` and it'll start establishing the connection with the RTSP server.

<!--The flow of the pipeline will consist of three steps. First, when the pipeline is initialized we will start the Connection Manager, which will set up the RTP stream via the RTSP.-->
<!--Once that is finished, we will set up two initial elements in the pipeline - the `UDP Source` and `RTP SessionBin`, which will allow us to receive RTP packets and process them.-->
<!--When the SessionBin detects that the RTP stream has been started, it will notify the pipeline with the `:new_rtp_stream` notification. Later on, we will add the remaining elements to the pipeline, allowing for the whole conversion process to take place.-->

<!--Those steps take place, respectively, in the: `handle_init/1`, `handle_other/3` and `handle_notification/4` callbacks. While the `handle_init/1` is rather intuitive, we will describe in detail what's happening in the other callbacks.-->

<!--Let us explain what's going on in the `handle_other` callback:-->

##### lib/pipeline.ex
```elixir
@impl true
def handle_init(_context, options) do
Logger.debug("Source handle_init options: #{inspect(options)}")

spec = [
  child(:source, %Membrane.RTSP.Source{
    transport: {:udp, options.port, options.port + 5},
    allowed_media_types: [:video, :audio],
    stream_uri: options.stream_url,
    on_connection_closed: :send_eos
  })
]

{[spec: spec],
  %{
    output_path: options.output_path,
    parent_pid: options.parent_pid,
    tracks_left_to_link: nil,
    track_specs: []
  }}
end
```

Once we receive the `{:set_up_tracks, tracks}` notification from the source we have the information what tracks have been set up during connection establishment and what we should expect. We take this information and store it, so that we link the source to the `HLS Sink Bin` correctly.

```elixir
@impl true
def handle_child_notification({:set_up_tracks, tracks}, :source, _ctx, state) do
  tracks_left_to_link =
    [:audio, :video]
    |> Enum.filter(fn media_type -> Enum.any?(tracks, &(&1.type == media_type)) end)

  {[], %{state | tracks_left_to_link: tracks_left_to_link}}
end
```

When a `PLAY` request is eventually sent by the source, we should be prepared to receive streams that have been set up. When a new RTP stream is received and identified by the source, a message is set to the parent - the pipeline in our case - containing information necessary to handle the stream.
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
