Now let's focus on how the Connection Manager works. As mentioned previously its role is to establish the RTSP connection with the RTSP server.

The `ConnectionManager` module will use the [`Connection`](https://hexdocs.pm/connection/Connection.html) behaviour, which provides additional callbacks to [`GenServer`](https://hexdocs.pm/elixir/GenServer.html) behaviour, aiding with building a connection process.

First of all we are defining the `ConnectionStatus` struct, which we will use to keep the state of the ConnectionManager:

##### lib/connection_manager.ex
```elixir
defmodule ConnectionStatus do
  @moduledoc false
  @type t :: %__MODULE__{
          stream_url: binary(),
          rtsp_session: pid(),
          pipeline: pid(),
          keep_alive: pid(),
          pipeline_options: keyword()
          }

  @enforce_keys [
      :stream_url,
      :pipeline,
      :pipeline_options
  ]

  defstruct @enforce_keys ++
              [
                  :rtsp_session,
                  :keep_alive
              ]
end
```

It holds the `rtsp_session`, which is the pid of a process started with `Membrane.RTSP.start/1`. The `Membrane.RTSP` allows us to execute RTSP client commands. You can read more about  [here](https://hexdocs.pm/membrane_rtsp/readme.html).
The `pipeline` field is the pid of the pipeline, we will need it to notify the pipeline, that the RTSP connection is ready together with `pipeline_options`, which contain necessary information about the stream.
The `keep_alive` is a process which repeatedly sends a dummy message to the RTSP server, in order to keep the connection alive and prevent a timeout.

Let's take a look at the `connect/2` callback, which is called immediately after the `init/1`:

##### lib/connection_manager.ex
```elixir
def connect(_info, %ConnectionStatus{} = connection_status) do
  rtsp_session = start_rtsp_session(connection_status)
  connection_status = %{connection_status | rtsp_session: rtsp_session}

  if is_nil(rtsp_session) do
    {:backoff, @delay, connection_status}
  else
    with {:ok, connection_status} <- get_rtsp_description(connection_status),
          :ok <- setup_rtsp_connection(connection_status),
          {:ok, connection_status} <- start_keep_alive(connection_status),
          :ok <- play(connection_status) do    

      send(
        connection_status.pipeline,
        {:rtsp_setup_complete, connection_status.pipeline_options}
      )

      {:ok, connection_status}
    else
      {:error, error_message} ->
        {:backoff, @delay, connection_status}
    end
  end
end
```

In the callback we go through the whole process of establishing RTSP connection - first starting the RTSP session, then getting the video parameters with, setting up the session, starting the keep alive process and finally playing the stream.
If all those steps succeed we can notify the pipeline, otherwise we back off and try to set up the connection after a `@delay` amount of time.

What might seem unclear to you is the `get_sps_pps` function.
It is responsible for getting the [sps and pps](https://www.cardinalpeak.com/blog/the-h-264-sequence-parameter-set) parameters from the RTSP DESCRIBE method. In short, sps and pps are parameters used by the H.264 codec and are required to decode the stream. Once the RTSP connection is complete we are sending them to the pipeline.