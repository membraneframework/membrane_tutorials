# The pipeline
The heart of our application will be the pipeline - which will act as described in the previous section. 
We need to create a file where we will put the pipeline module definition. Let it be the `lib/webrtc_to_hls/pipeline.ex` file. Fulfill it with the following code:
```elixir
#FILE: lib/webrtc_to_hls/pipeline.ex

defmodule WebRTCToHLS.Pipeline do
  use Membrane.Pipeline

  require Membrane.Logger

  alias Membrane.WebRTC.{Endpoint, EndpointBin, Track}
  alias Membrane.RTC.Engine.MediaEvent

  import WebRTCToHLS.Helpers
  ...
end
```

What we did was to simply define the `WebRTCToHLS.Pipeline` module, make it `use` the `Membrane.Pipeline` module (which results in `Membrane.Pipeline` being able to modify this module so that we can i.e. override some functions defined there), as well as make elements from `Membrane.WebRTC` and `Membrane.RTC.Engine` usable in our code.
What's more ,we are importing methods defined in `WebRTCToHLS.Helpers` which are some commonly used methods used for getting the directory name for the recordings to be stored etc.

Our `Pipeline` is an OTP's `GenServer` - and we need to override methods responsible for starting its process.
That is why we begin with defining `start/2` and `start_link/2` options:
```elixir
#FILE: lib/webrtc_to_hls/pipeline.ex

defmodule WebRTCToHLS.Pipeline do
    ...
    def start(options, process_options) do
        do_start(:start, options, process_options)
    end

    def start_link(options, process_options) do
        do_start(:start_link, options, process_options)
    end
    ...
end
```

Let's introduce a naming convention - we will be name the private functions, which are called from the inside of publicly available functions with with a 'do_'- prexif. That is how we will achieve some level of encapsulation, by aggregating the functionalities in the private functions and letting the public functions simply use these functions interfaces with appropriate arguments. As in the code snippet - we are simply calling a private `do_start/3` function from the inside of these two publicly available functions which are called to instantiate the process. The whole logic concerning the starting process will be covered in this `do_start/3` function:
```elixir
#FILE: lib/webrtc_to_hls/pipeline.ex

defmodule WebRTCToHLS.Pipeline do
    ...
    defp do_start(func, options, process_options) when func in [:start, :start_link] do
        id = options[:id] || "#{UUID.uuid4()}"
        options = Keyword.put(options, :id, id)

        Membrane.Logger.info("Starting a new SFU instance with id: #{id}")

        apply(Membrane.Pipeline, func, [
        __MODULE__,
        options,
        process_options
        ])
    end
    ...
end
```

First, we are checking if we already have an `id` field in the `options` keywords list.
If we do not, we are generating it with `UUID.uuid4/0` function (which generates random unique identifier) and putting it to the `options` keywords list.
Then we simply call the appropriate `Membrane.Pipeline` function, designed to start the process - that might be rather `Membrane.Pipeline.start/2` or `Membrane.Pipeline.start_link/2`.
As you can see, the whole point was to ensure that we have an identifier in the `options` - and since we follow the DRY(*Don't Repeat Yourself*) rule, we needed to wrap the whole logic for that into the private `do_start/3`  method, so that we do not need to repeat code in `start_link/2` and `start/2` functions inside our `Pipeline` module.

Callbacks describing the behavior of the pipeline must return a specific object - a tuple of the following form:
```elixir
{{status, actions}, state}
```
where:
+ status - indicates whether the operation was successful or not (i.e. `:ok`)
+ actions - a list of actions to be performed (on regular basis we declare some operations which should be performed in the callback's body and then we return a list of these operations so that they can be performed once the callback returns). [Here](https://hexdocs.pm/membrane_core/Membrane.Pipeline.Action.html#content) you can see different types of actions which can be performed.
+ state - updated state of our process (for instance we can return a state with updated list of peers)
Let's go further and define the callback which will be called during the initialization of the `Pipeline`:

```elixir
#FILE: lib/webrtc_to_hls/pipeline.ex

defmodule WebRTCToHLS.Pipeline do
  ...
  @impl true
  def handle_init(options) do
    play(self())

    {{:ok, log_metadata: [sfu: options[:id]]},
     %{
       id: options[:id],
       peers: %{},
       incoming_peers: %{},
       endpoints: %{},
       options: options
     }}
  end
  ...
end
```

We start to [`play/1`](https://hexdocs.pm/membrane_core/Membrane.Pipeline.html#play/1) the `Pipeline` - which means that the data will start flowing through our pipeline (we pass our PID as the argument to that function since we need to somehow identify our process). 
We return a pair - its first element is a tuple `{:ok, log_metadata: [sfu: options[:id]]}` which indicates that the function execution was successful and we define that the action we want to take is to `log_metadata`. 
The second element is a state of our `GenServer` - since this is initialization function, the state is initialized with the empty `peers` map, the empty `incoming_peers` map,
empty `endpoints` map and the `id` and `option` set basing on the argument passed to the function.

It would be good for us to store the PID of the `Stream` process since we need to have a way to communicate with it. We will have only one `Stream` process since only one client will be streaming at the same time and we could store this PID as a global atom...but let do it in a more proper manner. The manner which you will be able to reuse when you will need to store PID associated with many peers. 
We will take advantage of the [`Registry`](https://hexdocs.pm/elixir/Registry.html) module.
Lets define a global name for our register using the [annotations system](https://elixir-lang.org/getting-started/module-attributes.html#as-annotations) and define a simple function which will return this name:
```elixir
#FILE: lib/webrtc_to_hls/pipeline.ex

defmodule WebRTCToHLS.Pipeline do
  ...
  @registry_name WebRTCToHLS.Registry
  ...
  defp get_registry_name(), do: @registry_name
  
  defp dispatch(msg, _state) do
    Registry.dispatch(get_registry_name(), self(), fn entries ->
      for {_, pid} <- entries, do: send(pid, {self(), msg})
    end)
  end

end
```
The `Registry` is created as a child of our application in the `lib/application` file and given `WebRTCToHLS.Registry` name there. By using `get_registry_name/0` we will simply refer to that `Registry` process.
`dispatch/2` method will be used to send the message to all processes registered in our registry.

Let's make use of our newest achievement and define function which will allow the `Stream` process to register of unregister itself in the pipeline:
```elixir
#FILE: lib/webrtc_to_hls/pipeline.ex

defmodule WebRTCToHLS.Pipeline do
    ...
    @impl true
    def handle_other({:register, pid}, _ctx, state) do
    Registry.register(get_registry_name(), self(), pid)
    {:ok, state}
    end

    @impl true
    def handle_other({:unregister, pid}, _ctx, state) do
    Registry.unregister_match(get_registry_name(), self(), pid)
    {:ok, state}
    end
    ...
end
```

But `:register` and `:unregister` messages are not the only message types we need to handle! Since we will be using [`Membrane.RTC.Engine.MediaEvent`](https://github.com/membraneframework/membrane_rtc_engine/blob/master/lib/membrane_rtc_engine/media_event.ex), we need to know how to behave once we receive `:media_event` message. Since media event messages are messages which bring JSON-serialized information, we need to first deserialize them so that later on we will be able to process it in proper functions, depending on the specific event type which is contained in this JSON-serialized information. Let's implement another `handle_other/3` callback: 

```elixir
#FILE: lib/webrtc_to_hls/pipeline.ex

defmodule WebRTCToHLS.Pipeline do
  ...
  @impl true
  def handle_other({:media_event, from, data}, ctx, state) do
    case MediaEvent.deserialize(data) do
      {:ok, event} ->
        {actions, state} = handle_media_event(event, from, ctx, state)
        {{:ok, actions}, state}

      {:error, :invalid_media_event} ->
        Membrane.Logger.warn("Invalid media event #{inspect(data)}")
        {:ok, state}
    end
  end
  ...
end
```
We attempt to deserialize the `:media_event` message by the use of `MediaEvent.deserialize/1` function. If we succeed, we are passing the deserialized event description to the 
`handle_media_event/4` function, which behavior will be defined later, depending on the event type. If the deserialization fails, we will log that by the use of `Membrane.Logger`.

So now what we need to do is to define `handle_media_event` for each of the event types available in `Membrane.RTC.Engine.MediaEvent`! Let's start with `:join` event, which is sent when a new peer ('the stream producer') joins the server:
```elixir
#FILE: lib/webrtc_to_hls/pipeline.ex

defmodule WebRTCToHLS.Pipeline do
    ...
    defp handle_media_event(%{type: :join, data: data}, peer_id, ctx, state) do
        dispatch({:new_peer, peer_id, data.metadata, data.tracks_metadata}, state)

        receive do
            {:accept_new_peer, ^peer_id} ->
            peer = Map.put(data, :id, peer_id)
            state = put_in(state, [:incoming_peers, peer_id], peer)
            {actions, state} = setup_peer(peer, ctx, state)

            MediaEvent.create_peer_accepted_event(peer_id, Map.delete(state.peers, peer_id))
            |> dispatch(state)

            {actions, state}

            {:accept_new_peer, _other_peer_id} ->
            Membrane.Logger.warn("Unknown peer id passed for acceptance: #{inspect(peer_id)}")
            {[], state}

            {:deny_new_peer, peer_id} ->
            MediaEvent.create_peer_denied_event(peer_id)
            |> dispatch(state)

            {[], state}
        end
    end
    ...
end
```

Don't get frightened by the size of this code snippet! The behavior described there is quite simple.
First, we send the `:new_peer` message to the `Stream` process (so that we leave for the `Stream` process the decision whether to accept or reject the peer).
Then we are waiting in the blocking manner for the response. 
If we receive `:accept_new_peer` message along with the identifier of the peer for who we asked for acceptance, we assume that everything is OK and we put the information about the new peer to the `incoming_peers` map (which is a part of our process state).
Then we are setting up the incoming peer with the use of `setup_peer/2` function, which transforms `incoming_peers` into `peers` by performing some additional operations so that the newly connected peer will be able to start streaming.
Then we are creating a new `:media_event` message which holds a serialized `:peer_accepted` event and we dispatch that message to the `Stream` which will later pass it to the client.
In case we receive `:accept_new_peer`, but the peer's identifier does not match the identifier of the peer for whose acceptance we have asked, we log that fact and do not perform any further actions.
If the `Stream` process decided to reject the peer, with `:deny_new_peer` message, we create `MediaEvent`'s `:peer_denied` event and dispatch it as a `:media_event` message to the `Stream` process registered in our `Registry` so that it will be able to pass it to the client's application.

Oh, that wasn't that bad, was it?
But we have wrapped the most important part of code into the `setup_peer/2` function and haven't said anything about it's implementation. But don't worry - that is what we will do right now. Since this function is quite vast, we will implement it part by part. First let's declare it:
```elixir
#FILE: lib/webrtc_to_hls/pipeline.ex

defmodule WebRTCToHLS.Pipeline do
    ...
    defp setup_peer(config, _ctx, state) do
        ...
    end
    ...
end
```

First, let's define what kind of tracks our pipeline will receive (so called `inbound_track`) and which track the pipeline will return (`outbound_tracks`).
```elixir
#FILE: lib/webrtc_to_hls/pipeline.ex

defp setup_peer(config, _ctx, state) do
    inbound_tracks = create_inbound_tracks(config.relay_audio, config.relay_video)
    outbound_tracks = get_outbound_tracks(state.endpoints, config.receive_media)
    ...
end

```

```elixir
#FILE: lib/webrtc_to_hls/pipeline.ex

defmodule WebRTCToHLS.Pipeline do
  ...
  defp create_inbound_tracks(relay_audio, relay_video) do
    stream_id = Track.stream_id()
    audio_track = if relay_audio, do: [Track.new(:audio, stream_id)], else: []
    video_track = if relay_video, do: [Track.new(:video, stream_id)], else: []
    audio_track ++ video_track
  end

  defp get_outbound_tracks(endpoints, true) do
    Enum.flat_map(endpoints, fn {_id, endpoint} -> Endpoint.get_tracks(endpoint) end)
  end

  defp get_outbound_tracks(_endpoints, false), do: []
  ...
end
```
`config.relay_audio` and `config.relay_video` are configuration parameters which say whether we want our pipeline to process, accordingly, audio track and video track.
Basing on these parameters we are creating a new `Membrane.WebRTC.Track` for each of tracks we want to have in our stream and return the list of tracks as our `inbound_tracks`.
Outbound tracks are defined in the `EndpointBin` which is hold in `state.endpoints` map. We simply fetch them out of that `EndpointBin` process if the `config.receive_media` parameter is set to `true`. Otherwise our `outbound_tracks` list will be empty. 


Getting back to the `setup_peer/2`:
```elixir
#FILE: lib/webrtc_to_hls/pipeline.ex

defp setup_peer(config, _ctx, state) do
    ...
    endpoint =
    Endpoint.new(config.id, :participant, inbound_tracks, %{receive_media: config.receive_media})

    endpoint_bin_name = {:endpoint, config.id}
    ...
end
```

We create a new `Endpoint` there which will be responsible for sending us media tracks from the stream.


```elixir
#FILE: lib/webrtc_to_hls/pipeline.ex
defp setup_peer(config, _ctx, state) do
    ...
    handshake_opts =
      if state.options[:network_options][:dtls_pkey] &&
           state.options[:network_options][:dtls_cert] do
        [
          client_mode: false,
          dtls_srtp: true,
          pkey: state.options.network_options.dtls_pkey,
          cert: state.options.network_options.dtls_cert
        ]
      else
        [
          client_mode: false,
          dtls_srtp: true
        ]
      end

    directory =
      self()
      |> pid_hash()
      |> hls_output_path()

    # remove directory if it already exists
    File.rm_rf(directory)
    File.mkdir_p!(directory)
    ...
end
```
That code snippet provides definition of `handshake_opts` which later will be used the while initializing the `EndpointBin`. [Here]() you can read about the handshake options.

Then we are getting the path to the directory in which the files with our stream records will be stored - as you can see, the name of that directory is created basing on the hash of our PID. That is where we are using the functions from the `Helpers` module.
Finally, we remove that directory (just in case if it has already existed) and we create it.


