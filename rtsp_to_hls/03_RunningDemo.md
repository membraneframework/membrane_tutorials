In the tutorial we won't explain how to implement the solution from the ground up - instead, we will run the existing code from [Membrane demos](https://github.com/membraneframework/membrane_demo).

To run the RTSP to HLS converter first clone the demos repo:
```console
git clone https://github.com/membraneframework/membrane_demo.git
```

```console
cd membrane_demo/rtsp_to_hls
```

Install the dependencies
```console
mix deps.get
```

Make sure you have those libraries installed as well:
- gcc
- libc-dev
- ffmpeg

On ubuntu:
```console
apt-get install gcc libc-dev ffmpeg
```

Take a look inside the `lib/application.ex` file. It's responsible for starting the pipeline.
We need to give a few arguments to the pipeline:
```elixir
@rtsp_stream_url "rtsp://rtsp.membrane.work:554/testsrc.264"
@output_path "hls_output"
@rtp_port 20000
```

The `@output_path` attribute defines the storage directory for hls files and the `@rtp_port` defines on which port we will be expecting the rtp stream, once the RTSP connection is established.

The `@rtsp_stream_url` attribute contains the address of the stream, which we will be converting. It is a sample stream prepared for the purpose of the demo. 

Now we can start the application:
```console
mix run --no-halt
```

The pipeline will start playing, after a couple of seconds the HLS files should appear in the `@output_path` directory. In order to play the stream we need to first serve them. We can do it using simple python server.

```console
python3 -m http.server 8000
```

Then we can play the stream using [ffmpeg](https://ffmpeg.org/):
```console
ffplay http://YOUR_MACHINE_IP:8000
```
