In this chapter, we will discuss the multimedia-specific part of the application.

## The pipeline

Let's start with `lib/rtmp_to_hls/pipeline.ex` file. All the logic is put inside the [`Membrane.Pipeline.handle_init/1`](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#c:handle_init/1) callback,
which is invoked once the pipeline is initialized.

**_`lib/rtmp_to_hls/pipeline.ex`_**

```elixir
@impl true
def handle_init(_opts) do
  ...
  spec = [
    child(:src, %Membrane.RTMP.SourceBin{socket: 9009})
    |> via_out(:audio)
    |> via_in(Pad.ref(:input, :audio),
      options: [encoding: :AAC, segment_duration: Membrane.Time.seconds(4)]
    )
    |> child(:sink, %Membrane.HTTPAdaptiveStream.SinkBin{
      manifest_module: Membrane.HTTPAdaptiveStream.HLS,
      target_window_duration: :infinity,
      persist?: false,
      storage: %Membrane.HTTPAdaptiveStream.Storages.FileStorage{directory: "output"}
    }),
    get_child(:src)
    |> via_out(:video)
    |> via_in(Pad.ref(:input, :video),
      options: [encoding: :H264, segment_duration: Membrane.Time.seconds(4)]
    )
    |> get_child(:sink)
  ]
  ...
end
```

First, we define the list of children. The following children are defined:

- `:src` - a `Membrane.RTMP.SourceBin` RTMP server, which, according to its `:port` configuration, will be listening on port `9009`. This bin will be acting as a source for our pipeline. For more information on RTMP Source Bin please visit [the documentation](https://hexdocs.pm/membrane_rtmp_plugin/Membrane.RTMP.SourceBin.html).
- `:sink` - a `Membrane.HTTPAdaptiveStream.SinkBin`, acting as a sink of the pipeline. The full documentation of that bin is available [here](https://hexdocs.pm/membrane_http_adaptive_stream_plugin/Membrane.HTTPAdaptiveStream.SinkBin.html). We need to specify some of its options:
- `:manifest_module` - a module which implements [`Membrane.HTTPAdaptiveStream.Manifest`](https://hexdocs.pm/membrane_http_adaptive_stream_plugin/Membrane.HTTPAdaptiveStream.Manifest.html#c:serialize/1) behavior. A manifest allows aggregate tracks (of a different type, i.e. an audio track and a video track as well as many tracks of the same type, i.e. a few video tracks with different resolutions). For each track, the manifest holds a reference to a list of segments, which form that track. Furthermore, the manifest module is equipped with the `serialize/1` method, which allows transforming that manifest to a string (which later on can be written to a file). In that case, we use a built-in implementation of a manifest module - the `Membrane.HTTPAdaptiveStream.HLS`, designed to serialize a manifest into a form required by HLS.
- `:target_window_duration` - determines the minimal manifest's duration. The oldest segments of the tracks will be removed whenever possible if persisting them would result in exceeding the manifest duration.
- `:storage` - the sink element, the module responsible for writing down the HLS playlist and manifest files. In our case, we use a pre-implemented `Membrane.HTTPAdaptiveStream.FileStorage` module, designed to write the files to the local filesystem. We configure it so that the directory where the files will be put in the `output/` directory (make sure that that directory exists as the storage module won't create it itself).

The fact that the configuration of a pipeline, which performs relatively complex processing, consists of just two elements, proves the power of [bins](/basic_pipeline/12_Bin.md). Feel free to stop for a moment and read about them if you haven't done it yet.

At the same time, we configure the pads linking the two bins. 
`:src` has two output pads: the `:audio` pad and the `:video` pad, transferring the appropriate media tracks.
The source's `:audio` pad is linked to the input `:audio` pad of the sink - along with an `:encoding` option and a `:segment_duration`.
- `:encoding` is an atom, describing the codec which is used to encode the media data - when it comes to audio data, we will be using the AAC codec.
- `:segment_duration` specifies the maximal duration of a segment. Each segment of each track shouldn't exceed that value. In our case, we have decided to limit the length of each segment to 4 seconds.

At the time of writing, the available codecs accepted by `:encoding` are `:H264` and `:H265` for video, and `:AAC` for audio.

We refer to previously defined elements using `get_child` to also configure the `:video` pads, using `:H264` as the preferred encoding and a segment duration of 4 seconds.

The final thing that is done in the `handle_init/1` callback's implementation is returning the pipeline structure through the `:spec` action:
**_`lib/rtmp_to_hls/pipeline.ex`_**

```elixir
@impl true
def handle_init(_opts) do
  ...
  {[spec: spec], %{}}
end
```

## Starting the pipeline

The pipeline is started with `Supervisor.start_link`, as a child of the application, inside the `lib/rtmp_to_hls/application.ex` file:

**_`lib/rtmp_to_hls/application.ex`_**

```elixir
@impl true
def start(_type, _args) do
  children = [
    # Start the Pipeline
    Membrane.Demo.RtmpToHls,
    ...
  ]
  opts = [strategy: :one_for_one, name: RtmpToHls.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## HLS controller

The files produced with the pipeline are written down to the `output/` directory. We need to make them accessible via HTTP.
The Phoenix Framework provides tools to achieve that - take a look at `RtmpToHlsWeb.Router`:
**_`lib/rtmp_to_hls_web/router.ex`_**

```elixir
scope "/", RtmpToHlsWeb do
  pipe_through :browser

  get "/", PageController, :index
  get "/video/:filename", HlsController, :index
end
```

We are directing HTTP requests on `/video/:filename` to the HlsController, whose implementation is shown below:
**_`lib/rtmp_to_hls_web/controllers/hls_controller.ex`_**

```elixir
defmodule RtmpToHlsWeb.HlsController do
  use RtmpToHlsWeb, :controller

  alias Plug

  def index(conn, %{"filename" => filename}) do
    path = "output/#{filename}"

    if File.exists?(path) do
        conn |> Plug.Conn.send_file(200, path)
    else
        conn |> Plug.Conn.send_resp(404, "File not found")
    end
  end
end
```

This part of the code is responsible for sending the file `output/<filename>` to the HTTP request sender.
