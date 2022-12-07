# Server's room

## Let's create The Room! ;)

We are still missing probably the most important part - the heart of our application - the implementation of the room.
The room should dispatch messages sent from RTC Engine to appropriate peer channels - and at the same time, it should direct all the messages sent to it via peer channel to the RTC Engine.
Let's start by creating `lib/videoroom/room.ex` file with a declaration of Videoroom.Room module:

**_`lib/videoroom/room.ex`_**

```elixir
defmodule Videoroom.Room do
@moduledoc false

use GenServer
alias Membrane.RTC.Engine
alias Membrane.RTC.Engine.Message
alias Membrane.RTC.Engine.Endpoint.WebRTC
require Membrane.Logger

@mix_env MIX.env()

#we will put something here ;)
end
```

We will be using OTP's [GenServer](https://elixir-lang.org/getting-started/mix-otp/genserver.html) to describe the behavior of this module.

Let's start by adding wrappers for GenServer's `start` and `start_link` functions:

**_`lib/videoroom/room.ex`_**

```elixir
def start(init_arg, opts) do
 GenServer.start(__MODULE__, init_arg, opts)
end

def start_link(opts) do
 GenServer.start_link(__MODULE__, [], opts)
end
```

Then we are providing the implementation of `init/1` callback:

**_`lib/videoroom/room.ex`_**

```elixir
@impl true
def init(room_id) do
 Membrane.Logger.info("Spawning room proces: #{inspect(self())}")

 rtc_engine_options = [
  id: room_id
 ]

 mock_ip = Application.fetch_env!(:membrane_videoroom_demo, :external_ip)
 external_ip = if @mix_env == :prod, do: {0, 0, 0, 0}, else: mock_ip
 port_range = Application.fetch_env!(:membrane_videoroom_demo, :port_range)

 integrated_turn_options = [
   ip: external_ip,
   mock_ip: mock_ip,
   port_range: port_range
 ]

 network_options = [
  integrated_turn_options: integrated_turn_options,
  dtls_pkey: Application.get_env(:membrane_videoroom_demo, :dtls_pkey),
  dtls_cert: Application.get_env(:membrane_videoroom_demo, :dtls_cert)
 ]

 {:ok, pid} = Membrane.RTC.Engine.start(rtc_engine_options, [])
 Engine.register(pid, self())

 {:ok, %{rtc_engine: pid, peer_channels: %{}, network_options: network_options}}
end
```

For the description of `engine_options` please refer to [Membrane's documentation](https://hexdocs.pm/membrane_rtc_engine/Membrane.RTC.Engine.html#content)

We are starting `Membrane.RTC.Engine` process (we will refer to this process using `pid`) which will be serving as an RTC server.
Then we send a message to this process saying that we want to register ourselves (so that the RTC engine will be aware that we are the process responsible for dispatching the messages sent from the RTC engine to the clients).

The last thing we do is return the current state of the GenServer - in our state we are holding a reference to `:rtc_engine` which is the id of this process and `peer_channels` - the map of the following form: (peer_uuid -> peer_channel_pid). For now, this map is empty.

What's next? We need to handle the callbacks to properly react to the incoming events. Once again - please take a look at the [plugin documentation](https://hexdocs.pm/membrane_rtc_engine/Membrane.RTC.Engine.html#module-messages) to find out what types of messages RTC sends and what types of messages RTC expects to receive.
We won't implement handling all of these messages - only the ones which are crucial to set up the connection between peers, start the process of media streaming and take proper actions when participants disconnect. After finishing the reading of this tutorial you can try to implement handling of other messages (for instance you could turn on voice activation detection messages - `:vad_notification`, but you can read more about those in chapter 7).
Let's start with handling messages sent to us by RTC.

**_`lib/videoroom/room.ex`_**
```elixir
@impl true
def handle_info(%Message.MediaEvent{to: :broadcast, data: data}, state) do
 for {_peer_id, pid} <- state.peer_channels, do: send(pid, {:media_event, data})

 {:noreply, state}
end
```

Here comes the first one - once we receive `%Message.MediaEvent{}` from the RTC engine with the `:broadcast` specifier, we will send this event to all peers' channels which are currently saved in the `state.peer_channels` map in the state of our GenServer. We need to "reformat" the event description so that the message sent to the peer channel matches the interface defined by us previously, in `VideoroomWeb.PeerChannel`. If you are new to GenServers you might wonder what are we returning in this function - in fact, we are returning the state updated while handling this message. In our case, the state will be the same so we do not change anything. `:no_reply` means that we do not need to send the response to the sender (who, in our case, is the RTC engine process). The updated state will be then passed to the next callback while handling the next message - and will be updated during the process of handling that message. And so on and so on :)

Here comes the next method:

**_`lib/videoroom/room.ex`_**
```elixir
@impl true
def handle_info(%Message.MediaEvent{to: to, data: data}, state) do
 if state.peer_channels[to] != nil do
  send(state.peer_channels[to], {:media_event, data})
 end

 {:noreply, state}
end
```

The idea here is very similar to the one in the code snippet described previously - we want to direct the messages sent by RTC Engine's server to the RTC Engine's client.
The only difference is that the event is about to be sent to a particular user - that is why instead of `:broadcast` atom as the second element of event's tuple we have `to` - which is a peer unique id. Since we precisely know to who we should send the message there is nothing else to do than to find the peer channel's process id associated with the given peer id (we are holding the (peer_id -> peer_channel_pid) mapping in the state of the GenServer!) and to send the message there. Once again the state does not need to change.

There we go with another message sent by RTC engine:

**_`lib/videoroom/room.ex`_**
```elixir
@impl true
def handle_info(%Message.NewPeer{rtc_engine: rtc_engine, peer: peer}, state) do
 Membrane.Logger.info("New peer: #{inspect(peer)}. Accepting.")
 # get node the peer with peer_id is running on
 peer_channel_pid = Map.get(state.peer_channels, peer.id)
 peer_node = node(peer_channel_pid)

 handshake_opts =
 if state.network_options[:dtls_pkey] &&
  state.network_options[:dtls_cert] do
  [
    client_mode: false,
    dtls_srtp: true,
    pkey: state.network_options[:dtls_pkey],
    cert: state.network_options[:dtls_cert]
  ]
 else
  [
    client_mode: false,
    dtls_srtp: true
  ]
 end

 endpoint = %WebRTC{
  rtc_engine: rtc_engine,
  ice_name: peer.id,
  extensions: %{},
  owner: self(),
  integrated_turn_options: state.network_options[:integrated_turn_options],
  handshake_opts: handshake_opts,
  log_metadata: [peer_id: peer.id]
 }

 Engine.accept_peer(rtc_engine, peer.id)

 :ok = Engine.add_endpoint(rtc_engine, endpoint,
  peer_id: peer.id,
  node: peer_node
 )

 {:noreply, state}
end
```

That one might seem a little bit tricky. What is the deal here? Be aware that it is our room's process who is the only one holding the mapping between peer's id and peer channel's PID. Once a new peer joins, the RTC Engine is not aware of this peer channel's PID. That is it is asking our room process to give him some information about the new peer.
Apart from sending just peer channel's PID, the room process is also sending the identifier of a node on which the peer channel's process is located (notice that due to the use of BEAM virtual machine our application can be distributed - and server can be put on many different nodes working in the same cluster).
Later on, there comes a bunch of option definitions that will be used while defining a WebRTC endpoint.
Then we create an endpoint corresponding to the peer who is trying to join. If you are interested in the options available in the WebRTC endpoint, you can read about them [here](https://hexdocs.pm/membrane_rtc_engine/Membrane.RTC.Engine.Endpoint.WebRTC.html) but in most cases, all you would ever want to do with them is to simply copy-paste ;)
Finally, we accept the peer and add his endpoint to the RTC Engine.

Here comes the next callback!
Once we receive `%Message.PeerLeft{}` message from RTC we simply ignore that fact (we could of course remove the peer_id from the (peer_id->peer_channel_pid) mapping...but do we need to?):

**_`lib/videoroom/room.ex`_**
```elixir
@impl true
def handle_info(%Message.PeerLeft{peer: peer}, state) do
 Membrane.Logger.info("Peer #{inspect(peer.id)} left RTC Engine")
 {:noreply, state}
end
```

In case RTC Engine wants to communicate with the client during the [signaling](../glossary/glossary.md#signaling) process, we know how to react - we are simply passing the message to the appropriate `PeerChannel`.
How about messages coming from the client, via the `PeerChannel`? We need to pass them to the RTC Engine!

**_`lib/videoroom/room.ex`_**
```elixir
@impl true
def handle_info({:media_event, _from, _event} = msg, state) do
 Engine.receive_media_event(state.rtc_engine, msg)
 {:noreply, state}
end
```

Again - no magic tricks there. We are receiving `:media_event` - we are sending it to our RTC engine process.
And here come the callback for a `:add_peer_channel` message:

**_`lib/videoroom/room.ex`_**
```elixir
@impl true
def handle_info({:add_peer_channel, peer_channel_pid, peer_id}, state) do
 state = put_in(state, [:peer_channels, peer_id], peer_channel_pid)
 Process.monitor(peer_channel_pid)
 {:noreply, state}
end
```

It is a great example to show how does state updating look like. We are putting into our (peer_id->peer_channel_pid) the new entry - and we are returning
the state updated this way. Meanwhile, we also start monitoring the process with id `peer_channel_pid` - to receive `:DOWN` message when the peer channel process will be down.

We are almost done! We are monitoring all the peer channels processes. Once they die, we receive `:DOWN` message. Let's handle this event!

**_`lib/videoroom/room.ex`_**
```elixir
@impl true
def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
 {peer_id, _peer_channel_id} = state.peer_channels
  |> Enum.find(fn {_peer_id, peer_channel_pid} -> peer_channel_pid == pid end)

 Engine.remove_peer(state.rtc_engine, peer_id)
 {_elem, state} = pop_in(state, [:peer_channels, peer_id])
 {:noreply, state}
end
```

First, we find the id of a peer whose channel has died. Then we send a message to the RTC engine telling it to remove peer with given peer_id.
The last thing we do is to update the state - we remove the mapping (peer_id->peer_channel_pid) from our `:peer_channels` map.

After all of this hard work our server is finally ready. But we still need a client application.
