---
title: 4. Server's communication channels
description: >-
  Create your very own videoconferencing room with a little help from the Membrane Framework!
  <div>
  <br> <b>Page:</b> <a style="color: white" href=https://www.membraneframework.org/>Membrane Framework</a>
  <br> <b>Forum:</b> <a style="color: white" href=https://elixirforum.com/c/elixir-framework-forums/membrane-forum/104/>Membrane Forum</a>
  </div>
---

# I know you have been waiting for that moment - let's start coding!
## Let's prepare the server's endpoint
Do you still remember about Phoenix's sockets? Hopefully, since we will make use of them in a moment! We want to provide a communication channel between our client's application and our server.
Sockets fit just in a place - but be aware, that it is not the only possible option. Neither WebRTC nor Membrane Framework expects you to use any particular mean of communication between
the server and the client - they just want you to communicate.

### Socket's declaration
Socket's declaration is already present in our template. Take a quick glance at the `lib/videoroom_web/user_socket.ex` file.
You will find the following code there:

```elixir
#FILE: lib/videoroom_web/user_socket.ex

defmodule VideoRoomWeb.UserSocket do
  use Phoenix.Socket

  channel("room:*", VideoRoomWeb.PeerChannel)

  ...
end
```

What happens here? Well, it is just a definition of our custom Phoenix socket. Starting from the top, we are:
+ saying, that this module is a `Phoenix.Socket` and we want to be able to override Phoenix's socket functions (['use' documentation](https://elixir-lang.org/getting-started/alias-require-and-import.html#use)) - ```use Phoenix.Socket```
+ declaring our channel - ```channel("room:*", VideoRoomWeb.PeerChannel)``` . We are saying, that all messages pointing to ```"room:*"``` topic should be directed to `VideoRoomWeb.PeerChannel` module (no worries, we will declare this module later). Notice the use of a wildcard sign ```*``` in the definition - effectively speaking, we will be heading all requests whose topic start with ```"room:"``` to the aforementioned channel - that is, both the message with "room:WhereTheHellAmI" topic and "room:WhatANiceCosyRoom" topic will be directed to `VideoRoomWeb.PeerChannel` (what's more, we will be able to recover the part of the message hidden by a wildcard sign so that we will be able to distinguish between room names!)

The rest is an implementation of `Phoenix.Socket` interface \- you can read about it [here](https://hexdocs.pm/phoenix/Phoenix.Socket.html#callbacks).

### How does the server know that we are using the socket?
That's quite easy - we defined the usage of our socket in `lib/videoroom_web/endpoint.ex`, inside the `VideoRoomWeb.Endpoint` module:
```elixir
#FILE: lib/videoroom_web/endpoint.ex

defmodule VideoRoomWeb.Endpoint do
  ...
  socket("/socket", VideoRoomWeb.UserSocket,
    websocket: true,
    longpoll: false
  )
  ...
end
```
In this piece of code we are simply saying, that we are defining socket-type endpoint with path ```"/socket"```, which behavior will be described by
```VideoRoomWeb.UserSocket``` module.

### Where is VideoRoomWeb.PeerChannel?
It is in `lib/videoroom_web/peer_channel.ex` file! However, for now on, this file is only declaring the `VideoRoomWeb.PeerChannel` module, but does not provide any implementation.
```elixir
#FILE: lib/videoroom_web/peer_channel.ex

defmodule VideoRoomWeb.PeerChannel do
  use Phoenix.Channel

  require Logger

end
```

The module will handle messages sent and received on the previously created socket by implementing `Phoenix.Channel` callbacks. To achieve that we need to `use Phoenix.Channel`.

Let's implement our first callback!
```elixir
#FILE: lib/videoroom_web/peer_channel.ex

@impl true
def join("room:" <> room_id, _params, socket) do
  case :global.whereis_name(room_id) do
    :undefined -> Videoroom.Room.start(room_id, name: {:global, room_id})
    pid -> {:ok, pid}
  end
  |> case do
    {:ok, room_pid} ->
        do_join(socket, room_pid, room_id)

      {:error, {:already_started, room_pid}} ->
        do_join(socket, room_pid, room_id)

      {:error, reason} ->
        Logger.error("""
          Failed to start room.
          Room: #{inspect(room_id)}
          Reason: #{inspect(reason)}
        """)

        {:error, %{reason: "failed to start room"}}
  end
end


defp do_join(socket, room_pid, room_id) do
  peer_id = "#{UUID.uuid4()}"
  Process.monitor(room_pid)
  send(room_pid, {:add_peer_channel, self(), peer_id})
  {:ok,
  Phoenix.Socket.assign(socket, %{room_id: room_id, room_pid: room_pid, peer_id: peer_id})}
end
```
Just the beginning - note how do we fetch the room's name by using pattern matching in the argument list of `join/3`. ([pattern matching in Elixir](https://elixir-lang.org/getting-started/pattern-matching.html#pattern-matching)). <br>

What happens here?
`join/3` is called when the client joins the channel. First, we are looking for a `Videoroom.Room` process saved in the `:global` registry under the `room_id` key.
(`Videoroom.Room` module will hold the whole business logic of the video room - we will implement this module in the next chapter).
If videoroom process is already registered, we are simply returning its PID. Otherwise, we are trying to create
a new `Videoroom.Room` process on the fly (and we register it with `room_id` key in the global registry).
If we are successful we return the PID of the newly created room's process.
At the entrance point of the following step, we already have a `Videoroom.Room` process's pid or an `:error` notification.
Errors can occur due to multiple reasons. One of them is a situation in which a race condition between peers trying to create a room takes place.
Imagine a situation, that two users are trying to join a non-existent room in the exactly same moment. Since they are working asynchroniously, there is a probability, that both of them will 
get an answer from the `:global.whereis_name(room_id)` saying that the room with given name does not exists. Both them will then try to create such a room. The request from one of these users will come to the `:global` registry first, the room will be 
registered - and the second user will receive an `:already_started` error, along with the PID of that room process, since the process already exists. Handling of that error is quite straightforward - the user can safely join the room with the provided PID.
Ofcourse, some other errors might also occur, but we do not distinguish between them and we simply log the fact that there was a problem with the room creation.
In case we retrieve a PID of the room process, we call the `do_join/3` support function.  
`do_join/3` holds some repeatable parts of code concerning the joining process.
Inside that function, we start to monitor the room process (so that we will receive ```:DOWN``` message in case of the room's process crash/failure). Then we notify the room's process that
it should take us (peer channel) under consideration - we send our peer_id (generated as unique id with UUID module) along with the peer channel's PID to
the room process in the `:add_peer_channel` message so that the room will have a way to identify our process. The last thing we do is that we are adding information about the association between
room's identifier, room's PID, and peer's identifier to the map of socket's assigns. We will refer to this information later so we need to store it somehow.


Our channel acts as a communication channel between the Room process on the backend and the client application on the frontend. The responsibility of the channel is to simply forward all `:media_event` messages from the room to the client and all `mediaEvent` messages from the client to the Room process.
The first one is done by implementing `handle_info/2` callback as shown below:
```elixir
#FILE: lib/videoroom_web/peer_channel.ex

@impl true
def handle_info({:media_event, event}, socket) do
  push(socket, "mediaEvent", %{data: event})
  {:noreply, socket}
end
```
The second one is done by providing following implementation of `handle_in/3`:
```elixir
#FILE: lib/videoroom_web/peer_channel.ex

@impl true
def handle_in("mediaEvent", %{"data" => event}, socket) do
  send(socket.assigns.room_pid, {:media_event, socket.assigns.peer_id, event})
  {:noreply, socket}
end
```
Note the use of `push` method provided by Phoenix.Channel.

Great job! You have just implemented the server's side of our communication channel. How about adding our server's business logic?
<br><br>
[NEXT - Server's room process](5_ImplementingServerRoom.md)<br>
[PREV - System architecture](3_SystemArchitecture.md)<br>
[List of contents](index.md)<br>
[List of tutorials](../../index.md)
