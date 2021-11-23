Scope of this tutorial covers the process of creating own videoroom with the use of the Membrane framework.
# Introduction

## Motivation


  We will be building our app basing on great Phoenix application framework (???)
## Prerequisites
  Since media streaming is quite a complex topic it would be great for you to know something about how the browser can fetch user's media and how the connection is made between the peers etc. Since we will be using Phoenix framework to create our application - it will be much easier for you to understand what's going on if you will be even slightly familiar with that framework. Take your time and glance over these links:
  + [How does Phoenix work?](https://hexdocs.pm/phoenix/request_lifecycle.html)
    Phoenix, while being a great tool which allows to create complex application in considerably easy manner, requires it's user to follow a bunch of good practices and use some helpful project patterns. Most important one is MVC (Model-View-Controller) pattern, which affects the structure of project directories. The tutorial attached there provides a great introduction for Phoenix application creation and will allow you to understand the structure of our template project.

  + [How  do Phoenix sockets work and the difference between endpoint and socket/channel?](https://hexdocs.pm/phoenix/channels.html) 
    When we think about building the web application the very first thing which comes to our mind is HTTP. Surely, Phoenix allows us to send HTTP requests from the client application to the server - however, Phoenix developers have prepared for you an optional way to communicate - sockets. Sockets, in contrast to plain HTTP requests, are persistent and allow bidirectional communication, while HTTP request are stateless and work in request -> reply mode. Want to dig deeper? Feel free to read the provided part of the official Phoenix documentation!

  + [How to access user's media from the browser?](https://www.html5rocks.com/en/tutorials/webrtc/basics/)
    Ever wondered how is it possible for the browser to access your camera or a microphone? Here you will find an answer for that and many more inquiring you questions!

  + [WebRTC Connectivity (signalling, ICE etc.)](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Connectivity)
    One does not simply connect and send media! First, peers need to get in touch with each other (with a little help from a publicly available server), as well as exchange some information about themselves. This short tutorial will give you and outlook on how does this process (called 'signalling') can be performed!

  + [Why do we need STUN/TURN servers?](https://www.html5rocks.com/en/tutorials/webrtc/infrastructure/)
    Peer to peer connection can be (and in most cases is) problematic. At the same time it is also demanded - we don't want to have our media pass through some server (both due to the throughput limitations and privacy issues). While reading this tutorial you will find some tricks which allow you connect your beloved peer hidden by some firewalls and NAT!


# Getting started

## Elixir installation
  I don't think I can describe it any better: [How to install Elixir](https://elixir-lang.org/install.html).
  But to not forget to add the elixir bin to your PATH variable!
  After the installation you should be able to print Elixir's version with the following command:
  ```bash
  elixir --version
  ```
  At the same time you should have an access to IEx (Interactive Elixir Shell) by typing:
  ```bash
  iex
  ```
  Feel free to experiment with the language in the interactive shell if you haven't done it before!

  Elixir compilation can be done with:
  ```bash
  elixirc < .ex files to compile >
  ```

  And elixir script execution can be done with:
  ```bash
  elixir < .exs file to execute >  
  ```

  Pay attention to the difference in files format (`.ex` vs `.exs`) since Elixir distinguishes between `.ex` files, which are expected to be compiled with Elixir compiler (```elixirc``` command) and `.exs` script files (which are executed inline with ```elixir``` command). In our project we will use both types of the files - the main difference is that .ex files will also be stored in compiled version.

  After Elixir installation you should also have an access to mix build automation tool. For instance you can create new mix project with:
  ```bash
  mix new <your project name>
  ```

  and then build your project with:
  ```
  mix run
  ```


## Phoenix application generator
You can also install Phoenix application generator with the following command:
```bash
mix archive.install hex phx_new
```
The template you are going to use in this tutorial was created using:
```bash
mix phx.new
```
If you are curious about what this command does, run it in some temporary directory and inspect the created directory structure. Afterwards, you can safely delete that directory - in the very next step you are going to download the proper template.

## Template downloading
Once we have the development environment set up properly (let's hope so!) we can start the work on our project. We don't want you to do it from the scratch as the development requires some dull playing around with UI, setting the dependencies etc. - we want to provide you only the meat! That is why we would like you to download the template project with core parts of the code missing. You can do it by typing:

```bash
git clone https://github.com/membraneframework/membrane_videoroom_demo
```

and then changing directory to the freshly cloned repository and switching to the branch which provides the unfulfilled template:

```bash
cd membrane_videoroom_demo
git checkout start
```

# What do we have here?
  Let's make some reconnaissance. 
  First, let's run the template.
  Before running the template we need to install the dependencies using:
  ```
  mix deps.get
  npm ci --prefix=assets
  ```
  Then you can simply run the Phoenix server with the following command:
  ```
  mix phx.server
  ```
  If everything went well the application should be available on [http://localhost:4000](http://localhost:4000/).

  Play around...but it is not that match to do! We have better inspect what is the structure of our project.
  Does the project structure reassembles you the structure of a Phoenix project? (in fact it should!). We will go through the directories in our project.
  + <b> assets/ </b> <br>
  You can find the frontend of our application. The most interesting subdirectory here is src/ - we will be putting our typescript files there. For now, the following files should be present there: 
    + <b> consts.ts </b> - as the name suggests, you will find there some constant values - media constrains and our local peer id
    + <b> index.ts </b> - this one should be empty. It will act as an initialization point for our application and later on we will spawn a room object there.
    + <b> room_ui.ts </b> - methods which modify DOM are put there. You will find these methods helpful while implementing your room's logic - you will be able to simply call a method in order to put a next video tile among previously present video tiles and this whole process (along with rescaling or moving the tiles so they are nicely put on the screen) will be performed automatically
  + <b> config/ </b> <br>
  Here you can find Phoenix configuration files for given environments. There is nothing we should be interested in.
  + <b> deps/ </b> <br>
  Once you type ```mix deps.get``` all the dependencies listed in mix.lock file will get downloaded and be put into this directory. Once again - this is just how mix works and we do not care about this directory anyhow.
  + <b> lib/ </b> <br>
  This directory contains server's logic. As mentioned previously, the Phoenix server implements Model-View-Controller architecture so the structure of this directory will reflect this architecture. The only .ex file in this directory is videoroom_web.ex file - it defines the aforementioned parts of the system - ```controller``` and ```view```. Moreover, it defines ```router``` and ```channel``` - the part of the system which are used for communication. This file is generated automatically with Phoenix project generator and there are not that many situations in which you should manually change it.
    + <b> videoroom/ </b> <br>
      This directory contains the business logic of our application, which stands for M (model) in MVC architecture. For now it should only contain application.ex file which defines the Application module for our videoroom. As each [application](https://hexdocs.pm/elixir/1.12/Application.html), it can be loaded, started and stopped, as well as it can bring to life its own children (which constitute the environment created by an application). Later on we will put into this directory files which will provide some logic of our application - for instance Videoroom.Room module will be defined there.
    + <b> videoroom_web/ </b> <br>
      This directory contains files which stand for V (view) and C (controller) in the MVC architecture.
      As you can see, there are already directories with names "views" and "controllers" present here. The aforementioned (tutorial) (the one available in "helpful links" sections) describes the structure and contents of this directory in a really clear way so I don't think there is a need to repeat this description here. The only think I would like to point out is the way in which we are loading our custom Javascript's scripts. Take a look at lib/videoroom_web/room/index.html.eex file (as the Phoenix tutorial says, this file should contain EEx template for your room controller ) - you will find the following line there:
  ```html
  <script src="<%= static_path(@conn, "/js/room.js") %>"></script>
  ```
  As you can see, we are loading a script which is placed in ```/js/room.js``` (notice, that a path provided there is passed in respect to priv/static/ directory which holds files generated from typescript scripts in assets/src/ directory)

  + <b> priv/static/ </b> <br>
  Here you will find static assets. They can be generated, for instance, from the files contained in assets/ directory (.ts which are in assets/src are converted into .js files put inside priv/static/js). Not interesting at all, despite the fact, that we needed to load /js/room.js script file from here ;)
  
  # Planning is always a good idea
  Hang on for a moment! I know that after slipping through the tons of the documentation you are really eager to start coding, but let's think for a moment before taking any actions. How do we want our application to look like?
  Can we somehow decompose our application?

  Sure we can - as in each web application we have two independent subsystems:
  + server (backend) - written in Elixir, one and the only for the whole system. It will host the signalling service and work as SFU engine.
  + client application (frontend) - the one written in form of JS code and executed on each client's machine (to be precise - by his web browser). It will be responsible for fetching user's media stream as well as displaying the stream from the peers.

  ## We might need something else than the plain Elixir standard library...
  Ugh...I am sure till now on you have already found out that media streaming is not that easy. It covers many topic which originates to the nature of the reality. We need to deal with some limitations brought to us by the physics of the surrounding universe, we want to compress the data being sent with the great tools mathematics has equipped us with, we are taking an advantage of imperfections of our perception system...
  All this stuff is both complex and complicated - and that is why we don't want to design it from the very scratch. Fortunately, we have an access to the protocols - as somebody has already inspected the problem and created a protocol which defines how should we behave. But that's not enough - those protocols are also complicated and implementing them on our own would still oblige us to dig into it's fundamentals. That is why we will be using tools which provide some level of abstraction on top of these protocols. Ladies and gents - let me introduce to you - the Membrane framework.
  ## What does Membrane framework do?
  (???)
  ## Membrane framework structure
  Membrane framework consists from the following parts:
  + Core
  + Plugins
  (???)

  ## Client 
  In the client's application we need to get user's media stream as well as display streams coming from other users. We will receive one stream per each of the users (the streams will be coming from the server rather then directly from peers but we do not care about this at the moment - the most important thing is that we will have a separate stream for each of the peers). We need to provide a way to communicate with the server so that the server will be able to talk with us while signalling and while sending peer's streams events. A good choice for such a communication mean is to use Phoenix's sockets - using them will allow us to launch a persistent and bidirectional connection.
  Take a look at one of the flows we are about to implement:
  ![Client Flow 1](assets/images/client_flow1.png "Client flow 1")
  <br>
  The diagram above describes behavior of the client's application when an event from the server is received. 
  Channel, who is the recipient of the event's message, fires one of the callbacks, depending on the message type. Such a callback can directly update the user's interface or pass the event to the MembraneWebRTC who knows how to handle it because of a set of callbacks defined for a particular event types. 
  The second flow looks somehow like as shown below: <br>
  ![Client Flow 2](assets/images/client_flow2.png "Client flow 2")
  <br>
  When our local media tracks produce an event, it is pushed to the MembraneWebRTC object. MembraneWebRTC has a set of callbacks defined so that it knows how to behave when an event of a particular type occurs. Basing on the event type MembraneWebRTC object either updates user's interface or pushes the event to the server via the socket's channel.
  ## Server
  Our server will have two responsibilities - the first one is that it will act as a signalling server. The second one is that it will be a Selective Forwarding Unit (SFU).
  Why do we want our server to be a Selective Forwarding Unit? The reason is that such a model of streaming data among peers allows us to provide a  
  ![Server Scheme](assets/images/server_scheme.png "Server scheme")

# I know you have been waiting for that moment - let's start coding!
  ## Let's prepare server's endpoint
  Do you still remember about Phoenix's sockets? Hopefully, since we will make use of them in a moment! We want to provide a communication channel between our client's application (run by internet browser) and our server.
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
  This one will be more complex than the previous pieces of code - so we will cut it into smaller parts.
  First, let's define the module:
  ```elixir
  defmodule VideoRoomWeb.PeerChannel do
    use Phoenix.Channel

    require Logger

  end
  ```

  Is there anything left to explain? Well, we are defining our ```VideoRoomWeb.PeerChannel``` and making it use Phoenix.Channel (we will be able to implements its callbacks then!). We are also "importing" Logger module.
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

  ## Let's implement client's endpoint!
  We will put whole logic into assets/src/room.ts. Methods aimed to change user's interface are already in assets/src/room_ui.ts and we will use them along the room's logic implementation. So first, let's import all necessary dependencies concerning UI to our newly created file:
  ```ts
  import {
    addVideoElement,
    getRoomId,
    removeVideoElement,
    setErrorMessage,
    setParticipantsList,
    attachStream,
    setupDisconnectButton,
  } from "./room_ui";
  ```
  We have basically imported all the methods defined in room_ui.ts. For more details on how these methods work and what is their interface please refer to the source file.
  Take a look at our assets/package.json file which defines outer dependencies for our project. We have put there the following dependency:
  ```json
  "membrane_rtc_engine": "file:../deps/membrane_rtc_engine/"
  ```
  which is a client library provided by rtc engine plugin from membrane framework.
  Let's import some constructs from this library (the name should be self-explanatory and you can read about them in [the official membrane's rtc engine documentation](https://hexdocs.pm/membrane_rtc_engine/js/index.html):
  ```ts
  import {
    MembraneWebRTC,
    Peer,
    SerializedMediaEvent,
  } from "membrane_rtc_engine";
  ```

  Later on, let's import interesting constructs from Phoenix - Push and Socket classes (can you guess where will we be using them? ;) )
  ```ts
  import { Push, Socket } from "phoenix";
  ```

  We will also need ```parse``` method from ```"query-string"``` dependency - to nicely get our display name from the url. Let's import it here:
  ```ts
  import { parse } from "query-string";
  ```

  It might be worth for us to somehow wrap our room's client logic into a class - so at the very beginning let's simply define Room class:
  ```ts
  export class Room {
    constructor(){
      
    }
    
    public init = async () => {
    
    };

    public join = () => {
    
    };

    private leave = () => {

    };

    private parseUrl = (): string => {
    };

    private updateParticipantsList = (): void => {
    };

    private phoenixChannelPushResult = async (push: Push): Promise<any> => {
    };


  //no worries, we will put something into these functions :) 
  }
  ```
  Let's start with a constructor to define what how our room will be created. We need to declare member fields used in this part of the constructor in the class body first:
  ```ts
    private socket;
    private webrtcSocketRefs: string[] = [];
    private webrtcChannel;
  ```
  and then pass the constructor code into ```constructor()``` method:
  ```ts
  this.socket = new Socket("/socket");
  this.socket.connect();
  this.displayName = this.parseUrl();
  this.webrtcChannel = this.socket.channel(`room:${getRoomId()}`);

  ``` 

  What happens at the beginning of the constructor? We are creating new Phoenix Socket with ```/socket``` name (must be the same as we have defined on the server side!) and right after that we are starting a connection. 
  Later on we are setting our display name (we have set it in UI while joining the room, so we need to fetch it from the URL as it had set up URL parameter) - that's why we need ```this.parseUrl()``` method. It's implementation might look as follows:
  ```ts
  private parseUrl = (): string => {
    const { display_name: displayName } = parse(document.location.search);

    // remove query params without reloading the page
    window.history.replaceState(null, "", window.location.pathname);

    return displayName as string;
  };
  ```

  Then we are creating Phoenix's channel (which is, of course, associated with the socket we have just created!) and setting it's name to the ```"room< room name>"```. Room name is fetched from the UI. Since the room object will be created once the user clicks "connect" button, the room's name will be the one passed to the input label on the page.


  Following on the constructor implementation - wouldn't it be great to hold references to the socket?
  ```ts
  const socketErrorCallbackRef = this.socket.onError(this.leave);
  const socketClosedCallbackRef = this.socket.onClose(this.leave);
  this.webrtcSocketRefs.push(socketErrorCallbackRef);
  this.webrtcSocketRefs.push(socketClosedCallbackRef);
  ```
  This structure might look a little bit ambiguous. What we are storing in ```this.webrtcSocketRefs```? Well, we are storing references...to the callbacks we have just defined.
  We have passed what method should be invoked in case our Phoenix socket is closed or has experienced error of some type.
  However, we want to keep track of those callbacks so that we will be able to turn them off ("unregister " those callbacks).
  Where will we be unregistering the callbacks? Inside ```this.leave()``` method!
  ```ts
  private leave = () => {
      this.webrtc.leave();
      this.webrtcChannel.leave();
      this.socket.off(this.webrtcSocketRefs);
      while (this.webrtcSocketRefs.length > 0) {
        this.webrtcSocketRefs.pop();
      }
    };
  ```
  What we do here is that we are using methods aimed for leaving for both our MembraneWebRTC object and Phoenix's channel. Then we are calling the aforementioned ```this.socket.off(refs)``` method ([click here for documentation](https://hexdocs.pm/phoenix/js/#off)) - which means we are unregistering all the callbacks. The last thing we need to do it to empty references list.

  Let's leave constructor for a moment - we will fulfil it's implementation in a moment (we need to create MembraneWebRTC object which is a heart of our client's side system!).
  For now on let's focus on providing more things which might be useful while creating the room. Let's gather them in one method, called ```init()```. 
  We will be dealing with user media - so let's add a member field to hold a reference to our localStream (webRTC stream):
  ```ts
  private localStream: MediaStream | undefined;
  ```


  Later on let's provide implementation of ```init``` method for our class:
  ```ts
  public init = async () => {
      try {
        this.localStream = await navigator.mediaDevices.getUserMedia(
          MEDIA_CONSTRAINTS
        );
      } catch (error) {
        console.error(error);
        setErrorMessage(
          "Failed to setup video room, make sure to grant camera and microphone permissions"
        );
        throw "error";
      }

      addVideoElement(LOCAL_PEER_ID, "Me", true);
      attachStream(this.localStream!, LOCAL_PEER_ID);

      await this.phoenixChannelPushResult(this.webrtcChannel.join());
    };

  ```
  In the code snippet shown above we are doing really important thing - we are getting a reference to users media. ```await navigator.mediaDevices.getUserMedia()``` method is a method defined by webRTC standard. We can pass some media constraints which will limit the tracks available in the stream. Take a look to assets/src/consts.ts file where you will find MEDIA_CONSTRAINTS definition - it says that we want to get both audio data and video data (but in a specified format!). Later on we are dealing with the UI - we are adding video element do our DOM (and we are identifying it with LOCAL_PEER_ID) and attaching our local media stream to this newly added video element (this is the first time we will be using PEER_ID as a handler to a proper element - as you can see, attachStream() method distinguishes between all video elements, which we will be having many - one for us and one for each of the peers - basing on this id).
  The last thing we do here is that we are waiting for a result of this.webrtcChannel.join() method (can you guess what happens on the server side once we are running this method?). ```this.phoenixChannelPushResult``` is simply wrapping this result:

  ```ts
  private phoenixChannelPushResult = async (push: Push): Promise<any> => {
      return new Promise((resolve, reject) => {
        push
          .receive("ok", (response: any) => resolve(response))
          .receive("error", (response: any) => reject(response));
      });
    };
  ```

  (???)




  Now let's get back to the constructor. Let's create  MembraneWebRTC object! Declare it as a Room class member field:
  ```ts
  private webrtc: MembraneWebRTC
  ```

  and initialize it within constructor:
  ```ts
  this.webrtc = new MembraneWebRTC({callbacks: callbacks});
  ```
  What the hell callbacks are? Well, it's complicated...we need to define them first.
  According to MembraneWebRTC [documentation](https://hexdocs.pm/membrane_rtc_engine/js/interfaces/callbacks.html) we need to specify the behavior of client's part of RTC engine by passing the proper callbacks during the construction. 

  We will go through callbacks list one by one, providing the desired implementation for each of them. All you need to do later is to gather them together into one JS object called ```callbacks``` before initializing ```this.webrtc``` object.



  ### Callbacks
  #### onSendMediaEvent
  ```ts
  onSendMediaEvent: (mediaEvent: SerializedMediaEvent) => {
            this.webrtcChannel.push("mediaEvent", { data: mediaEvent });
          },
  ```
  If mediaEvent from our client Membrane Library appears (this event can be one of many types - for instance it can be an event which is trying to setup connection with other peers) we need to pass it to the server. That is why we are making use of our Phoenix channel which has a second endpoint on the server side - and we are simply pushing data through that channel. The form of the event pushed: ```("mediaEvent", { data: mediaEvent })``` is the one we are expecting on the server side - recall the implementation of ```VideoRoomWeb.PeerChannel.handle_in("mediaEvent", %{"data" => event}, socket)```
  #### onConnectionError
  ```ts
  onConnectionError: setErrorMessage,
  ```
  This one is quite easy - if the error occurs on the client side of our library, we are simply setting error message. In our template ```setErrorMessage``` method is already provided, but take a look on this method - onConnectionError callback forces us to provide method with a given signature (because it is passing some parameters which might be helpful to track the reason of the error).
  #### onJoinSuccess





  We might need a member field where we will be holding the list of the peers - why don't you add such a field to our class definition:
  ```ts
  private peers: Peer[] = [];
  ```

  Finally, let's provide our onJoinSuccess callback implementation:
  ```ts
  onJoinSuccess: (peerId, peersInRoom) => {
            this.localStream!.getTracks().forEach((track) =>
              this.webrtc.addTrack(track, this.localStream!)
            );

            this.peers = peersInRoom;
            this.peers.forEach((peer) => {
              addVideoElement(peer.id, peer.metadata.displayName, false);
            });
            this.updateParticipantsList();
          },
  ```
  Once we have successfully joined the room, we add each of the tracks from our ```this.localStream``` (do you remember that we have audio and video track?) to MembraneWebRTC object (we are also passing the reference to the whole local stream). 
  Later on we are adding video element () per each of the peers (we want to see a video from each of the peers in our room, don't we?).
  The last think we do is to invoke method which will update participants list (we want to have the list of all the participants in our room be nicely displayed) - let's wrap this functionality into another method:
  ```ts
  private updateParticipantsList = (): void => {
    const participantsNames = this.peers.map((p) => p.metadata.displayName);

    if (this.displayName) {
      participantsNames.push(this.displayName);
    }

    setParticipantsList(participantsNames);
  };
  ```
  We are simply putting all the peers display names into the list and later on we are adding there our own name. The last thing to do is to inform UI that the participants list has changed - and we do it by invoking ```setParticipantsList(participantsNames)``` from ```assets/src/room_ui.ts```.


  How about you trying to implement the rest of the callbacks on your own? Please refer to the [documentation]() and think where you can use methods from ```./assets/src/room_ui.ts```.
  Below you will find the expected result (callback implementation) for each of the methods - it might not be the best implementation...but it is the implementation you have payed for!
  Seriously speaking - we have split some of these callbacks implementation into multiple functions, according to some good practices and we consider it to be a little bit...cleaner ;) 

  #### onJoinError
  ```ts
  onJoinError: (metadata) => {
            throw `Peer denied.`;
          },
  ```
  #### onTrackReady
  ```ts
  onTrackReady: ({ stream, peer, metadata }) => {
            attachStream(stream!, peer.id);
          },
  ```
  #### onTrackAdded
  ```ts
  onTrackAdded: (ctx) => {},
  ```
  #### onTrackRemoved
  ```ts
  onTrackRemoved: (ctx) => {},
  ```
  #### onPeerJoined
  ```ts
  onPeerJoined: (peer) => {
            this.peers.push(peer);
            this.updateParticipantsList();
            addVideoElement(peer.id, peer.metadata.displayName, false);
          },
  ```
  #### onPeerLeft
  ```ts
  onPeerLeft: (peer) => {
            this.peers = this.peers.filter((p) => p.id !== peer.id);
            removeVideoElement(peer.id);
            this.updateParticipantsList();
          },
  ```
  #### onPeerUpdated
  ```ts
  onPeerUpdated: (ctx) => {},
  ```



  Since initialization might take some time we might want to perform some actions when it is completed. That's why it might be a good idea to define ```join()``` method which will be invoked once ```init()``` returns successfully:
  ```ts
  public join = () => {
      setupDisconnectButton(() => {
        this.leave();
        window.location.replace("");
      });
      this.webrtc.join({ displayName: this.displayName });
    };
  ```
  We are setting up disconnect button (which means we are making the button call ```this.leave()``` once it gets clicked.
  Then we are making our MembraneWebRTC [```join()```](https://hexdocs.pm/membrane_rtc_engine/js/classes/membranewebrtc.html#join) the room with our display name.


  Ok, it seems the we have already defined the process of creating and initializing ```Room``` class's object.
  Why not to create this object! Go to ```assets/src/index.js``` file (do you remember that this is the file which is loaded in template .eex file for our room's template?)
  Until now this file is probably empty. Let's create ```Room``` instance there!
  ```ts
  import { Room } from "./room";

  let room = new Room();
  room.init().then(() => room.join());
  ```
  First thing we do is to import the appropriate class. Then we are creating new Room's instance (the ```constructor()``` get's called). Later on we are initializing newly created room with ```init()``` method (which might take some times as it need to get an access to user's media - that is why this method is asynchronous). Once the ```init()``` method returns successfully, we are making our local room instance join the real room (where we might meet other peers!). And that's it! We have our client defined! In case something does not work properly (or in case we have forgotten to describe some crucial part of code ;) ) feel free to refer to the implementation of the videoroom's client side available [here](https://github.com/membraneframework/membrane_demo/tree/master/webrtc/videoroom/assets/src).


  ## Let's create The Room! ;)
  We are still missing probably the most important part - the heart of our application - implementation of the room.
  Room should dispatch messages sent from SFU Engine to appropriate peer channels - and at the same time it should direct all the messages sent to him via peer channel to the SFU Engine.
  Let's start by creating /lib/videoroom/room.ex file with a declaration of Videoroom.Room module:
  ```elixir
  defmodule Videoroom.Room do
  @moduledoc false

  use GenServer

  require Membrane.Logger

  #we will put something here ;)
  end
  ```
  We will be using OTP's [GenServer](https://elixir-lang.org/getting-started/mix-otp/genserver.html) to describe the behavior of this module.


  Let's start by adding methods which will be used to create the module (it is a part of GenServer's interface - no magic happens here)
  ```elixir
  def start(opts) do
    GenServer.start(__MODULE__, [], opts)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end
  ```


  Then we are providing the implementation of ```init(opts)``` callback:
  ```elixir
  @impl true
  def init(opts) do
    Membrane.Logger.info("Spawning room process: #{inspect(self())}")

    engine_options = [
      id: opts[:room_id],
      network_options: [
        stun_servers: [
          %{server_addr: "stun.l.google.com", server_port: 19_302}
        ],
        turn_servers: [],
        dtls_pkey: Application.get_env(:membrane_videoroom_demo, :dtls_pkey),
        dtls_cert: Application.get_env(:membrane_videoroom_demo, :dtls_cert)
      ],
      packet_filters: %{
        OPUS: [silence_discarder: %Membrane.RTP.SilenceDiscarder{vad_id: 1}]
      },
      payload_and_depayload_tracks?: false
    ]

    {:ok, pid} = Membrane.RTC.Engine.start(engine_options, [])
    send(pid, {:register, self()})
    {:ok, %{sfu_engine: pid, peer_channels: %{}}}
  end
  ```
  (???) - poor documentation of these options
  For the description of ```engine_options``` please refer to [Membrane's documentation](https://hexdocs.pm/membrane_rtc_engine/Membrane.RTC.Engine.html#content)

  We are starting ```Membrane.RTC.Engine``` process (we will refer to this process using ```pid```) which will be serving as SFU server.
  Then we send a message to this process saying that we want to register ourself (so that SFU engine will be aware that we are the process responsible for dispatching the messages sent from SFU engine to the clients).

  The last thing we do is returning the current state of the GenServer - in our state we are holding a reference to ```:sfu_engine``` which is the id of this process and ```peer_channels``` - the map of the following form: (peer_uuid -> peer_channel_pid). For now this map is empty.

  What's next? We need to handle the callbacks in order to properly react for the incoming events. Once again - please take a look at the [plugin documentation](https://hexdocs.pm/membrane_rtc_engine/Membrane.RTC.Engine.html#module-messages) in order to find out what types of messages SFU sends and what types of messages SFU expects to receive.
  We won't implement handling all of these messages - only the ones which are crucial to setup the connection between peers, start the process of media streaming and take proper actions when participant disconnect. After finishing reading of this tutorial you can try to implement handling of other messages (for instance those connected with voice activation detection - ```:vad_notification```). 
  Let's start with handling message sent to us by SFU.
  ```elixir
  @impl true
  def handle_info({_sfu_engine, {:sfu_media_event, :broadcast, event}}, state) do
    for {_peer_id, pid} <- state.peer_channels, do: send(pid, {:media_event, event})
    {:noreply, state}
  end
  ```
  Here comes the first one - once we receive ```:sfu_media_event``` from SFU engine with :broadcast specifier, we will send this event to all peers' channels which are currently saved in the ```state.peer_channels``` map in the state of our GenServer. We need to "reformat" the event description so that the message sent to peer channel matches the interface defined by us previously, in VideoroomWeb.PeerChannel. If you are new to GenServers you might wonder what are we returning in this function - in fact, we are returning the state updated while handling this message. In our case the state will be the same so we do not change anything. ```:no_reply``` means that we do not need to send the response to the sender (who, in our case, is the SFU engine process). The updated state will be then passed to the next callback while handling the next message - and will be updated during the process of handling that message. And so on and so on :) 

  Here comes the next method:
  ```elixir
  @impl true
  def handle_info({_sfu_engine, {:sfu_media_event, to, event}}, state) do
    if state.peer_channels[to] != nil do
      send(state.peer_channels[to], {:media_event, event})
    end

    {:noreply, state}
  end
  ```
  The idea here is very similar to the one in code snippet described previously - we want to direct the messages sent by SFU Engine's server to the SFU Engine's client.
  The only difference is that not the event is about to be send to a particular user - that is why instead of ```:broadcast``` atom as the second element of event's tuple we have ```to``` - which is a peer unique id. Since we precisely know to who we should send the message there is nothing else to do than to find the peer channel's process id associated with the given peer id (we are holding the (peer_id -> peer_channel_pid) mapping in the state of the GenServer!) and to send the message there. Once again the state do not need to change.


  There we go with another message sent by SFU engine:
  ```elixir
  @impl true
  def handle_info({sfu_engine, {:new_peer, peer_id, _metadata}}, state) do
    # get node the peer with peer_id is running on
    peer_channel_pid = Map.get(state.peer_channels, peer_id)
    peer_node = node(peer_channel_pid)
    send(sfu_engine, {:accept_new_peer, peer_id, peer_node})
    {:noreply, state}
  end
  ```
  That one might seem a little bit tricky. What is the deal here? Be aware that it is our process (based on Videoroom.Room module) who is the only one holding the mapping (peer_id->peer_channel_id). Once new peer joins, the SFU Engine is not aware of any mapping between ```peer_id```and ```peer_channel_pid```. That is why SFU Engine, which is only aware of ```peer_id``` is asking our room process to give him some information about new peer - especially, the ```Kernel.node``` it belongs to (notice that due to use of BEAM virtual machine our application can be distributed - and server can be put on many machines working in the same cluster). To retrieve the information about the node on which peer channel exists, we need to refer to the process id of peer channel process - and it is the room process who is aware of this process id.

  And once we receive ```:peer_left``` message from SFU we simply ignore that fact (we could of course remove the peer_id from the (peer_id->peer_channel_pid) mapping...but do we need to?):
  ```elixir
  @impl true
  def handle_info({_sfu_engine, {:peer_left, _peer_id}}, state) do
    {:noreply, state}
  end
  ```

  That's it! In case of SFU sending us some messages we know how to react...but how about doing it another way around?
  We need to define callbacks for messages sent to us by peer channels, which we should direct to SFU engine. 
  ```elixir
  @impl true
  def handle_info({:media_event, _from, _event} = msg, state) do
    send(state.sfu_engine, msg)
    {:noreply, state}
  end
  ```
  Again - no magic tricks there. We are receiving ```:media_event``` - we are sending it to our SFU engine process. 
  And here come the callback for a ```:add_peer_channel``` message:
  ```elixir
  @impl true
  def handle_call({:add_peer_channel, peer_channel_pid, peer_id}, _from, state) do
    state = put_in(state, [:peer_channels, peer_id], peer_channel_pid)
    Process.monitor(peer_channel_pid)
    {:reply, :ok, state}
  end
  ```

  It is a great example to show how does state updating looks like. We are putting into our (peer_id->peer_channel_pid) the new entry - and we are returning the state updated this way. Meanwhile we also start monitoring the process with id ```peer_channel_pid``` - to receive ```:DOWN``` message when the peer channel process will be down.

  You might wonder why sometimes do we override ```handle_info``` method, and sometimes we override ```handle_call``` - it is defined by GenServer's behavior. ```handle_info``` gets invoked when our process receives inter-process message sent to it. SFU engine sends us such a messages - and that is why we are about overriding this method since we are expecting it to be invoked. ```handle_call``` is designed to be invoked when somebody would invoke a method on our GenServer - with ```GenServer.call``` method. Let's create a wrapper for such a function calling:
  ```elixir
  def add_peer_channel(room, peer_channel_pid, peer_id) do
    GenServer.call(room, {:add_peer_channel, peer_channel_pid, peer_id})
  end
  ```
  Do your recall this method? We were using it in ```VideoroomWeb.PeerChannel.join```. Each peer, once his peer channel is created and ```join``` method is called on this channel, invokes ```Videoroom.Room.add_peer_channel``` method which sends calls GenServers ```handle_call``` callback (which is putting (peer_id->peer_channel_pid) to the map).
  We are almost done! We are monitoring all the peer channels processes. Once they die, we receive ```:DOWN``` message. Let's handle this event!
  ```elixir
  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {peer_id, _peer_channel_id} =
      state.peer_channels
      |> Enum.find(fn {_peer_id, peer_channel_pid} -> peer_channel_pid == pid end)

    send(state.sfu_engine, {:remove_peer, peer_id})
    {_elem, state} = pop_in(state, [:peer_channels, peer_id])
    {:noreply, state}
  end
  ```
  First, we find the id of a peer whose channel has died. Then we send a message to the SFU engine telling it to remove peer with given peer_id.
  The last thing we do is to update the state - we remove the mapping (peer_id->peer_channel_pid) from our ```:peer_channels``` map.

  Great job! We are done with that! Now, finally, you should be able to check the fruits of your labour!
  Please run:
  ```
  mix phx.server
  ```
  visit the following page in your browser:
  <br>
  [Your videoroom on http://localhost:4000](http://localhost:4000)
  <br>
  and then join a room with a given name!
  Later on you can visit your videoroom's page once again, from another browser's tab or from the another browser's window (or even another browser - however the recommended browsers to use are Chrome and Firefox) and join the same room as before - you should start seeing two participants in the same room!

  # What to do next?
  We can share with you an inspiration for a further improvements!
  ## Voice activation detection
  Wouldn't it be great to have a feature which would somehow mark a person who is currently speaking in the room? That's where voice activation detection (VAD) joins the game!
  There is a chance that you remember that SFU engine was sending some other messages which we purposely didn't handle (once again you can refer to the (documentation)[https://hexdocs.pm/membrane_rtc_engine/Membrane.RTC.Engine.html#module-messages]). One of these messages sent from SFU to the client is ```{:vad_notification, val, peer_id}``` - the message which is sent once the client starts or stops speaking. We need to simply pass this message from SFU to the client's application and take some actions once it is received - for instance, you can change the user's name displayed under the video panel so that instead of plain user's name (i.e. "John") we would be seeing "<user> is speaking now" message. 
  Below you can see what is the expected result:


  ![VAD example](assets/records/vad.gif "VAD example")

  Hopefully you will find the diagram placed below helpful as it describes the flow of the VAD notification and shows which component's of the system need to be changed:
    
  ![VAD Flow Scheme](assets/images/vad_flow_scheme.png "VAD flow scheme")
    
    
  



  ## Muting/unmuting
  It's not necessary for each peer to hear everything...
  Why not to allow users of our videoroom to mute themselves when they want to?
  This simple feature has nothing to do with the server side of our system. Everything you need to do in order to disable the voice stream being sent can be found in (WebRTC MediaStreamTrack API documentation)[https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack]. You need to find a way to disable and reenable the audio track from your local media stream and then add a button which would set you in "muted" or "unmuted" state. The expected result is shown below:
  ![Mute example](assets/records/mute.gif "mute example")



  You can also conduct some experiments on how to disable the video track (so that the user can turn off and on his camera while being in the room).
