As explained in the [Architecture chapter](08_RTSP_Architecture.md), the pipeline will consist of a RTSP Source and a HLS Sink.

The initial pipeline will consist of the `RTSP Source`, which will start establishing the connection with the RTSP server, and the `HLS Sink Bin`. For now we won't connect this elements in any way, since we don't have information about what tracks we'll receive from the RTSP server which we're connecting with. 

##### lib/pipeline.ex
```elixir
@impl true
def handle_init(_context, options) do
  spec = [
    child(:source, %Membrane.RTSP.Source{
      transport: {:udp, options.port, options.port + 5},
      allowed_media_types: [:video, :audio],
      stream_uri: options.stream_url,
      on_connection_closed: :send_eos
    }),
    child(:hls, %Membrane.HTTPAdaptiveStream.SinkBin{
      target_window_duration: Membrane.Time.seconds(120),
      manifest_module: Membrane.HTTPAdaptiveStream.HLS,
      storage: %Membrane.HTTPAdaptiveStream.Storages.FileStorage{
        directory: options.output_path
      }
    })
  ]

  {[spec: spec], %{parent_pid: options.parent_pid}}
end
```

Once we receive the `{:set_up_tracks, tracks}` notification from the source we have the information what tracks have been set up during connection establishment and what we should expect. First we filter these tracks, so that we have at most one video and audio track each. Then we can create specs that will connect output pads of the source with input pads of the sink appropriately - audio to audio and video to video.

##### lib/pipeline.ex
```elixir
@impl true
def handle_child_notification({:set_up_tracks, tracks}, :source, _ctx, state) do
  track_specs =
    Enum.uniq_by(tracks, & &1.type)
    |> Enum.filter(&(&1.type in [:audio, :video]))
    |> Enum.map(fn track ->
      encoding =
        case track do
          %{type: :audio} -> :AAC
          %{type: :video} -> :H264
        end

      get_child(:source)
      |> via_out(Pad.ref(:output, track.control_path))
      |> via_in(:input,
        options: [encoding: encoding, segment_duration: Membrane.Time.seconds(4)]
      )
      |> get_child(:hls)
    end)

  {[spec: track_specs], state}
end
```

By doing this we are prepared to receive the streams when a `PLAY` request is eventually sent by the source and the server starts streaming. 
