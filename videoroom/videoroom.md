Scope of this tutorial covers the process of creating own videroom with the use of the Membrane framework.
# Introduction

## Motivation


We will be building our app basing on great Phoenix application framework
## Prerequisites
Since media streaming is quite a complex topic it would be great for you to know something about how the connection is made between the peers etc.
Helpful links:
+ [How does Phoenix work?](https://hexdocs.pm/phoenix/request_lifecycle.html)
  Phoenix, while being a great tool which allows to create complex application in considerably easy manner, requires it's user to follow a bunch of good practices and use some helpful project patterns. Most important one is MVC (Model-View-Controller) pattern, which affects the structure of project directories. The tutorial attached there provides a great introduction for Phoenix application creation and will allow you to understand the structure of our template project.

+ [How  do Phoenix sockets work and the difference between endpoint and socket/channel?](https://hexdocs.pm/phoenix/channels.html) 
  When we think about building the web application the very first thing which comes to our mind is HTTP. Surely, Phoenix allows us to send HTTP requests from the client application to the server - however, Phoenix developers have prepared for you an optional way to communicate - sockets. Sockets, in contrast to plain HTTP requests, are persistent and allow bidirectional communication, while HTTP request are stateless and work in request -> reply mode. Want to dig deeper? Feel free to read the provided part of official Phoenix documentation!

+ [How to access user's media from the browser?](https://www.html5rocks.com/en/tutorials/webrtc/basics/)
  Ever wondered how is it possible for the browser to access your camera or a microphone? Here you will find an answer for that and many more inquisting you questions!

+ [WebRTC Connectivity (signalling, ICE etc.)](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Connectivity)
  One does not simply connect and send media! First, peers need to get in touch with each other (with a litle help from a publicly available server), as well as exchange some information about themselfs. This short tutorial will give you and outlook on how does this proccess (called 'signalling') can be performed!

+ [Why do we need STUN/TURN servers?](https://www.html5rocks.com/en/tutorials/webrtc/infrastructure/)
  Peer to peer connection can be (and in most cases is) problematic. At the same time it is also demanded - we don't want to have our media pass through some server (both due to the throughput limitations and privacy issues). While reading this tutorial you will find some tricks which allow you connect your beloved peer hidden by some firewalls and NAT!


   




# Getting started

## Elixir installation
I don't think I can describe it any better: [How to install Elixir](https://elixir-lang.org/install.html).
But to not forget to add the elixir bin to your PATH variable!
After the installation you should be able to print Elixir's version with the following commnad:
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

Pay attention to the difference in files format (.ex vs .exs) since Elixir distinguishes between .ex files, which are expected to be compiled with Elixir compiler (```elixirc``` command) and .exs script files (which are executed inline with ```elixir``` command). In our project we will use both types of the files - the main differece is that .ex files will also be stored in compiled version.

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
Later on you can use the generator in order to create new Phoenix application:
```bash
mix phx.new
```

Inspect the structure which was created by the use of the command since our project will be based on the same structure (in fact it was also generated using this generator ;) )
## Template downloading
Once we have the development environment set up properly (let's hope so!) we can start the work on our project. We don't want you to do it from the scratch as the development requires some dull playing around with UI, setting the dependencies etc. - we want to provide you only the meat! That is why we would like you to download the template project with core parts of the code missing. You can do it by typing:

```bash
git clone https://github.com/membraneframework/membrane_videoroom_demo
```

and then changing directory to the freshly cloned repository and switching to the branch which provides the unfulfiled template:

```bash
cd membrane_videoroom_demo
git checkout start
```

# What do we have here?
Let's make some reconnaissance. Does the project structure reassembles you the structure of a Phoenix project? (in fact it should!)
## assets

## lib

### videoroom

### videoroom_web



# Planning is always a good idea
Hang on for a moment! I know that after slipping through the tons of the documentation you are really eager to start coding, but let's think for a moment before taking any actions. How do we want our application to look like?
Can we somehow decomposit our application?

Sure we can - as in each web application we have two independent subsystems:
+ server (backend) - written in Elixir, one and the only for the whole system. It will host the signalling service.
+ client application (frontend) - the one written in form of JS code and executed on each client's machine (to be precise - by his web browser). It will be responsible for fetching user's media stream as well as displaying the stream from the peers.

## We might need something else than the plain Elixir standard library...
Ugh...I am sure till now on you have already found out that media streaming is not that easy. It covers many topic which originates to the nature of the reality. We need to deal with some limitations brought to us by the physics of the surrounding universe, we want to compress the data being sent with the great tools mathematics has equiped us with, we are taking an advantage of imperfections of our perception system...
All this stuff is both complex and complicated - and that is why we don't want to code it from the very scratch. We will be using some tools which provde some level of abstraction for working with media streaming. Ledies and gents - let me introduce to you -  the Membrane framework.
## What does Membrane framework do?

## Membrane framework structure
Membrane framework consists from the following parts:
+ Core
+ Plugins


## Client 
In the client application we will be dealing with webRTC. ...

## Server
...
![Server Scheme](assets/server_scheme.png "Server scheme")

# I know you have been waiting for that moment - let's start coding!
## Let's connect our client with the server
Do you still remember about Phoenix's sockets? Hopefully, since we will make use of them in a moment! We want to provide a communication channel between our client's application (run by internet browser) and our server.
Sockets fit just in a place!

### Let's declare our socket
First, let's create the socket module for our application. How about calling it VideoRoomWeb.UserSocket? Remember to put it in the right place, according to modules' naming convention (oh, just for this first time, I will give you a small tip - you need to create user_socket.ex file in lib/videoroom_web directory and put the following code inside)

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
+ saying, that this module is a Phoenix.Socket and we want to be able to override Phoenix's socket methods - ```use Phoenix.Socket```
+ declaring our channel - ```channel("room:*", VideoRoomWeb.PeerChannel)``` . We are saying, that all messages pointing to ```"room:*"``` topic should be directed to VideoRoomWeb.PeerChannel module (no worries, we will declare this module later). Notice the use of a wildcard sign ```*``` in the definition - effectively speaking, we will be heading all requests whose topic start with ```"room:"``` to the beforementioned channel - that is, both the message with "room: WhereTheHellAmI" topic and "room: WhatANiceCosyRoom" topic will be directed to VideoRoomWeb.PeerChannel (what's more, we will be able to recover the part of the message hidden by a wildcard sign so that we will be able to distinguish between room names!)
+ implementing ```connect(params, socket, connect_info)``` callback
+ implementing ```id(socket)``` callback
 Both the callbacks are brought to us by Phoenix.Socket module. Since we do not need any advanced logic there, our implementation is really simple (just to match the desired callback interface).
You can read about these two callbacks [here](https://hexdocs.pm/phoenix/Phoenix.Socket.html#callbacks)
### Let's make our server aware that we will be using socket
We need to somehow register the usage of our newly created custom socket module. As you might have heard previously (and, surprisingly, as the name suggests!), VideoRoomWeb.Endpoint is responsible for declaring our application endpoints. Normally, we put there our router declaration (router will dispatch HTTP requests sent to our server basing on URI) there - but nothing will stop us from declaring other communication endpoint there - socket!
in lib/videoroom_web/endpoint.ex, inside the VideoRoomWeb.Endpoint module, please put the following piece of code:
```elixir  
socket("/socket", VideoRoomWeb.UserSocket,
    websocket: true,
    longpoll: false
  )
```

In this piece of code we are simply saying, that we are defining socket-type endpoint with name ```"/socket"```, which behaviour will be described by ```VideoRoomWeb.UserSocket``` module. Those two options passed as the following arguments let us define the type of our socket - we indicate, that we want to use websocket as our Pheonix's socket base - in contrast, we could achieve the same behaviour, but by longpolling HTTP requests (this could be helpful in case of websockets not being available for our clients). Do you want to know more about this two mechanisms? Feel free to stop for a moment and read [this article](https://ably.com/blog/websockets-vs-long-polling)

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
Let's impor our first callback!
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
See? We can fetch room name by using pattern match here! We make use of pattern matching for
```join(topic, params, socket)```  callback signature so that we are splliting the ```topic``` into ```"room:"<>room_id``` - and this way we will be able to use room_id in our callback's implementation!
Let's go step by step through the code:
+ First, we are trying to find process with ```room_id``` identifier in ```:global``` registry (this process will be an instance of Videoroom.Room):
  + if we cannot find it, we are starting ```Videoroom.Room``` genserver and we are rgistering it in ```:global``` registry with ```room_id``` as it's identificator 
  + in case there is entry with ```room_id``` identificator in the ```:global``` registry, we can simply return pid of this process
+ Right now we have a tuple {status, pid|reason} in our flow. Let's distinguish between this situation:
  + If status is :ok, we will have ```Videoroom.Room``` pid for a room with given ```room_id```. We can start monitoring that room's process (so that we will receive ```:DOWN``` message in case of room process dying) and notify room's procces that we would like him to take us (peer channel) under consideration. In this process we are providing our peer_id (generated as unique id with UUID module) so that room will have a way to identify our process (and will be able to direct messages meant to be sent to us to our peer channel process)
  + Otherwise, the status is ```:error```, so let's simply log that fact and return ```:error``` tuple.

There you go! You might wonder when will this code be invoked (which means - when the ```join(topic, params, socket)``` gets called) - well, the trigger is client's application connecting to the given channel! 
How about client sending some events? What should we do then?
Let's define another callback - ```handle_in``` which will get called once "mediaEvent" is sent:
```elixir
 @impl true
  def handle_in("mediaEvent", %{"data" => event}, socket) do
    send(socket.assigns.room, {:media_event, socket.assigns.peer_id, event})

    {:noreply, socket}
  end
```
We are simply sending a message to the room process assigned to given socket. The body of this message is as follows:
+ ```:media_event``` - message type (room will route messages basing on message type)
+ ```socket.assigns.peer_id``` - our peer id (generated previously with UUID)
+ ```event``` - event, available under "data" key in event's body map

And now - let's do it another way around. This means that we want to send to the socket (and via the socket to the client) information from our room process. In order to do so we can implement another callback - ```def handle_info(event, socket)``` this way:
```elixir
@impl true
def handle_info({:media_event, event}, socket) do
push(socket, "mediaEvent", %{data: event})

{:noreply, socket}
end

```
Here, we are only making use out of ```push``` method provided by Phoenix.Channel. we are pusshing all events signed with ```:media_event``` type to the socket (and socket will later on send them to the client).

Great job! You have just implemented server's side of our communication channel. How about doing it for our client?

### Let's implement client's endpoint for communication purpose 
We will put whole logic into assets/src/room.ts. Methods aimed to change user's interface are already in assets/src/room_ui.ts and we will use them along the room's logic implementation. So first, let's import all neccessary dependencies concerning UI to our newly created file:
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
Take a look at our assets/packae.json file which defines outer dependecies for our project. We have put there the following dependency:
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

It might be worth for us to somehow wrap our room's client logic into a class - so at the very beggining let's simply define Room class:
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


//no worries, we will put something into this functions :) 
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

this.webrtcSocketRefs.push(this.socket.onError(this.leave));
this.webrtcSocketRefs.push(this.socket.onClose(this.leave));
```

What happens at the beggining of the constructor? We are creating new Phoenix Socket with ```/socket``` name (must be the same as we have defined on the server side!) and right after that we are starting a connection. 
Then we are creating Phoenix's channel (which is, ofcourse, associated with the socket we have just created!) and setting it's name to the ```"room< room name>"```. Room name is fetched from the UI. Since the room object will be created once the user clicks "connect" button, the room's name will be the one passed to the input label on the page.
Later on we are putting ...

Now let's create  MembraneWebRTC object! Declare it as a Room class member field:
```ts
private webrtc: MembraneWebRTC
```

and initialize it within constructor:
```ts
this.webrtc = new MembraneWebRTC({callbacks: callbacks});
```
What the hell callbacks are? Well, it's complicated...we need to define them first.
According to MembraneWebRTC [documentation](https://hexdocs.pm/membrane_rtc_engine/js/interfaces/callbacks.html) we need to specify the behaviour of client's part of RTC engine by passing the proper callbacks during the construction. 

We will go through callbacks list one by one, providing the desired implementation for each of them. All you need to do later is to gather them together into one JS object called ```callbacks``` before initializing ```this.webrtc``` object.
### Callbacks
#### onSendMediaEvent
```ts
 onSendMediaEvent: (mediaEvent: SerializedMediaEvent) => {
          this.webrtcChannel.push("mediaEvent", { data: mediaEvent });
        },
```

#### onConnectionError
```ts
onConnectionError: setErrorMessage,
```

#### onJoinSuccess


Let's add member field representing localStream (webRTC stream) to our Room class:
```ts
private localStream: MediaStream | undefined;
```


and provide implementation of ```init``` method our class:
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
In the code snippet shown above we are doing really important thing - we are getting a reference to users media. ```await navigator.mediaDevices.getUserMedia()``` method is a method defined by webRTC standard. We cann pass some media constraints which will limit the tracks available in the stream. Take a look to assets/src/consts.ts file where you will find MEDIA_CONSTRAINTS definition - it says that we want to get both autio data and video data (but in a specified format!). Latr on we are dealing with UI - we are adding video element do our DOM (and we are identifying it with LOCAL_PEER_ID) and attaching our local media stream to this newly added video element (this is the first time we will be using PEER_ID as a handler to a proper element - as you can see, attachStream() method distinguishes between all video elements, which we will be having many - one for us and one for each of the peers - basing on this id).
The last thing we do here is that we are waiting for a result of this.webrtcChannel.join() method (can you guess what happens on the server side once we are running this method?). ```this.phoenixChannelPushResult``` is simply wrapping this result ...

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