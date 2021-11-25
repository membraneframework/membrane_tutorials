# I know you have been waiting for that moment - let's start coding!
  ## Let's prepare server's endpoint
  Do you still remember about Phoenix's sockets? Hopefully, since we will make use of them in a moment! We want to provide a communication channel between our client's application and our server.
  Sockets fit just in a place!

  ### Let's declare our socket
  First, let's create the socket module for our application. How about calling it VideoRoomWeb.UserSocket? You need to create user_socket.ex file in lib/videoroom_web directory and put the following code inside:

  ```elixir
  defmodule VideoRoomWeb.UserSocket do
    use Phoenix.Socket

    channel("room:*", VideoRoomWeb.PeerChannel)

    @impl true
    def connect(_params, socket, _connect_info) do
      {:ok, socket}
    end

    @impl true
    def id(_socket), do: nil
  end
  ```
  
  What happens here? Well, it is just a definition of our custom Phoenix's socket. Starting from the top, we are:
  + saying, that this module is a `Phoenix.Socket` and we want to be able to override Phoenix's socket methods (['use' documentation](https://elixir-lang.org/getting-started/alias-require-and-import.html#use)) - ```use Phoenix.Socket```
  + declaring our channel - ```channel("room:*", VideoRoomWeb.PeerChannel)``` . We are saying, that all messages pointing to ```"room:*"``` topic should be directed to `VideoRoomWeb.PeerChannel` module (no worries, we will declare this module later). Notice the use of a wildcard sign ```*``` in the definition - effectively speaking, we will be heading all requests whose topic start with ```"room:"``` to the aforementioned channel - that is, both the message with "room:WhereTheHellAmI" topic and "room:WhatANiceCosyRoom" topic will be directed to `VideoRoomWeb.PeerChannel` (what's more, we will be able to recover the part of the message hidden by a wildcard sign so that we will be able to distinguish between room names!)
  + implementing ```connect(params, socket, connect_info)``` callback
  + implementing ```id(socket)``` callback
  Both the callbacks are brought to us by `Phoenix.Socket` module. Since we do not need any advanced logic there, our implementation is really simple (just to match the desired callback interface).
  You can read about these two callbacks [here](https://hexdocs.pm/phoenix/Phoenix.Socket.html#callbacks).
  ### Let's make our server aware that we will be using socket
  We need to somehow register the usage of our newly created custom socket module. As you might have heard previously (and, surprisingly, as the name suggests!), VideoRoomWeb.Endpoint is responsible for declaring our application endpoints. Normally, we put there our router declaration (router will dispatch HTTP requests sent to our server basing on URI) there - but nothing will stop us from declaring other communication endpoint there - socket!
  In `lib/videoroom_web/endpoint.ex`, inside the `VideoRoomWeb.Endpoint` module, please add the socket definition:
  ```elixir
  defmodule VideoRoomWeb.Endpoint do  
    ...
    socket("/socket", VideoRoomWeb.UserSocket,
        websocket: true,
        longpoll: false
    )
    ...
  end 
  ```
  In this piece of code we are simply saying, that we are defining socket-type endpoint with path ```"/socket"```, which behavior will be described by ```VideoRoomWeb.UserSocket``` module. Those two options passed as the following arguments let us define the type of our socket - we indicate, that we want to use websocket as our Pheonix's socket base - in contrast, we could achieve the same behavior, but by longpolling HTTP requests (this could be helpful in case of websockets not being available for our clients). Do you want to know more about this two mechanisms? Feel free to stop for a moment and read [this article](https://ably.com/blog/websockets-vs-long-polling)

  ### Where is VideoRoomWeb.PeerChannel? 
  Well, for now there is no VideoRoomWeb.PeerChannel! We need to define it - in lib/videoroom_web/peer_channel.ex file.
  This module will handle messages sent on the previously created socket by implementing `Phoenix.Channel` callbacks. To achieve that we need to `use Phoenix.Channel`. The initial definition of `VideoRoomWeb.PeerChannel` should look as follows:
  ```elixir
  defmodule VideoRoomWeb.PeerChannel do
    use Phoenix.Channel

    require Logger

  end
  ```

  Let's implement our first callback!
  ```elixir
    @impl true
    def join("room:" <> room_id, _params, socket) do
      case :global.whereis_name(room_id) do
        :undefined -> Videoroom.Room.start(name: {:global, room_id})
        pid -> {:ok, pid}
      end
      |> case do
        {:ok, room} ->
          peer_id = "#{UUID.uuid4()}"
          Process.monitor(room)
          Videoroom.Room.add_peer_channel(room, self(), peer_id)
          {:ok, Phoenix.Socket.assign(socket, %{room_id: room_id, room: room, peer_id: peer_id})}

        {:error, reason} ->
          Logger.error("""
          Failed to start room.
          Room: #{inspect(room_id)}
          Reason: #{inspect(reason)}
          """)

          {:error, %{reason: "failed to start room"}}
      end
    end
  ```
  Just the beginning - note how do we fetch the room's name by using pattern matching in the argument list of `join/3`. ([pattern matching in Elixir](https://elixir-lang.org/getting-started/pattern-matching.html#pattern-matching)). <br>

  What happens here?
  `join/3` is called when the client joins the channel. First, we are looking for a process saved in the global registry under the `room_id` key. If such a process exists, we are simply returning it's pid. Otherwise, we are trying to create a new `Videoroom.Room` process on the fly (and we register it with `room_id` key in the global registry). If we are successful we return the pid of newly created room's process.
  At the entrance point of the following step we already have a `Videoroom.Room` process's pid or a `:error` notification. In case of error occurring we have a simple error handler which logs the fact, that the room has failed to start. Otherwise, we can make use of the room's process. First we start to monitor it (so that we will receive ```:DOWN``` message in case of the room's process dying). Then we notify the room's process that it should take us (peer channel) under consideration - we provide our peer_id (generated as unique id with UUID module) in the `Videoroom.Room.add_peer_channel/3) method invocation so that room will have a way to identify our process - and will be able to direct messages meant to be sent to us to our process. The last thing we do is that we are adding information about association between room's identifier, room's pid and peer's identifier to the map of socket's assigns. We will refer to this information later so we need to somehow store it.

  
  Our channel acts as a communication channel between the Room process on the backend and the client application on the frontend. The responsibility of the channel is to simply forward all `:media_event` messages from the room to the client and all `mediaEvent` messages from the client to the Room process. 
  The first one is done by implementing handle_info/2 callback as shown below:
  ```elixir
  @impl true
    def handle_in("mediaEvent", %{"data" => event}, socket) do
      send(socket.assigns.room, {:media_event, socket.assigns.peer_id, event})

      {:noreply, socket}
    end
  ```
  The second one is done by providing following implementation of handle_in/3:
  ```elixir
  @impl true
  def handle_info({:media_event, event}, socket) do
  push(socket, "mediaEvent", %{data: event})

  {:noreply, socket}
  end

  ```
  Note the use of `push` method provided by Phoenix.Channel. 

  Great job! You have just implemented server's side of our communication channel. How about doing it for our client?
