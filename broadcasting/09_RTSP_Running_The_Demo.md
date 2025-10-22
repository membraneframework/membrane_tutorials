In the tutorial we won't explain how to implement the solution from the ground up - instead, we will run the existing code from [Membrane demos](https://github.com/membraneframework/membrane_demo).

To run the RTSP to HLS converter first clone the demos repo:
```bash
git clone https://github.com/membraneframework/membrane_demo.git
```

```bash
cd membrane_demo/rtsp_to_hls
```

Install the dependencies
```bash
mix deps.get
```

Take a look inside the `lib/application.ex` file. It's responsible for starting the pipeline.
We need to give a few arguments to the pipeline:
```elixir
rtsp_stream_url = "rtsp://localhost:30001"
output_path = "hls_output"
rtp_port = 20000
```

The `output_path` attribute defines the storage directory for hls files and the `rtp_port` defines on which port we will be expecting the rtp stream, once the RTSP connection is established.

The `rtsp_stream_url` attribute contains the address of the stream, which we will be converting. If you want to receive a stream from some accessible RTSP server, you can pass it's URL here. In this demo we'll run our own, simple server: 

```bash
mix run server.exs
```

Now we can start the application:
```bash
mix run --no-halt
```

The pipeline will start playing, after a couple of seconds the HLS files should appear in the `@output_path` directory.

Then we can play the stream using [ffmpeg](https://ffmpeg.org/), by pointing to the location of the manifest file:
```bash
ffplay http://YOUR_MACHINE_IP:8000/rtsp_to_hls/hls_output/index.m3u8
```
