---
title: 6. Client's application
description: >-
Create your very own videoconferencing room with a little help from the Membrane Framework!

<div>
<br> <b>Page:</b> <a style="color: white" href=https://www.membraneframework.org/>Membrane Framework</a>
<br> <b>Forum:</b> <a style="color: white" href=https://elixirforum.com/c/elixir-framework-forums/membrane-forum/104/>Membrane Forum</a>
</div>
---

# Client's application
## Let's implement the client's endpoint!
We will put the whole logic into `assets/src/room.ts`. Methods responsible for handling UI are already in `assets/src/room_ui.ts`, let's import them:
```ts
//FILE: assets/src/room.ts

import {
addVideoElement,
getRoomId,
removeVideoElement,
setErrorMessage,
setParticipantsList,
attachStream,
setupDisconnectButton,
} from "./room_ui";

````
We have basically imported all the methods defined in `room_ui.ts`. For more details on how these methods work and what is their interface please refer to the source file.
Take a look at our `assets/package.json` file which defines outer dependencies for our project. We have put there the following dependency:
```JSON
//FILE: assets/package.json

"dependencies": {
  "membrane_rtc_engine": "file:../deps/membrane_rtc_engine/",
  ...
}
````

which is a client library provided by the RTC engine plugin from the Membrane Framework.
Let's import some constructs from this library (their name should be self-explanatory and you can read about them in [the official Membrane's RTC engine documentation](https://hexdocs.pm/membrane_rtc_engine/js/index.html) along with some other dependencies which we will need later:

```ts
//FILE: assets/src/room.ts

import {MEDIA_CONSTRAINTS, LOCAL_PEER_ID} from './consts';
import {
  MembraneWebRTC,
  Peer,
  SerializedMediaEvent,
} from "membrane_rtc_engine";
import { Push, Socket } from "phoenix";
import { parse } from "query-string";
```

Once we are ready with the imports, it might be worth to somehow wrap our room's client logic into a class - so at the very beginning let's simply define `Room` class:

```ts
//FILE: assets/src/room.ts

export class Room {

  private socket;
  private webrtcSocketRefs: string[] = [];
  private webrtcChannel;
  private displayName: String;
  private webrtc: MembraneWebRTC;
  private peers: Peer[] = [];
  private localStream: MediaStream | undefined;

  constructor(){
  }

  private init = async () => {
  };

  public join = () => {
  };

  private leave = () => {
  };

  private updateParticipantsList = (): void => {
  };

  private phoenixChannelPushResult = async (push: Push): Promise<any> => {
  };


//no worries, we will put something into these functions :)
}
```

Let's start with the constructor that will initialize the member fields:

```ts
//FILE: assets/src/room.ts

constructor(){
  this.socket = new Socket("/socket");
  this.socket.connect();
  const { display_name: displayName } = parse(document.location.search);
  this.displayName = displayName as string;
  window.history.replaceState(null, "", window.location.pathname);
  this.webrtcChannel = this.socket.channel(`room:${getRoomId()}`);
  ...
}
```

What happens at the beginning of the constructor? We are creating a new Phoenix Socket with `/socket` path (must be the same as we have defined on the server-side!) and right after that, we are starting a connection.
Later on, we are retrieving the display name from the URL (the user has set it in the UI while joining the room and it was passed to the next view as the URL param).
Then we are connecting to the Phoenix's channel on the topic `room:<room name>`. The room name is fetched from the UI.
Following on the constructor implementation:

```ts
//FILE: assets/src/room.ts

constructor(){
  ...
  const socketErrorCallbackRef = this.socket.onError(this.leave);
  const socketClosedCallbackRef = this.socket.onClose(this.leave);
  this.webrtcSocketRefs.push(socketErrorCallbackRef);
  this.webrtcSocketRefs.push(socketClosedCallbackRef);
  ...
}
```

This structure might look a little bit ambiguous. What we are storing in `this.webrtcSocketRefs`? Well, we are storing references...to the callbacks we have just defined.
We have passed what method should be invoked in case our Phoenix socket is closed or has experienced an error of some type - that is, `this.leave()` method. We will define this method later.
However, we want to keep track of those callbacks so that we will be able to turn them off ("unregister " those callbacks).
Where will we be unregistering the callbacks? Inside `this.leave()` method!

Now let's get back to the constructor. Let's initialize a MembraneWebRTC object!

```ts
//FILE: assets/src/room.ts

constructor(){
  ...
  this.webrtc = new MembraneWebRTC({callbacks: callbacks});
  ...
}
```

According to MembraneWebRTC [documentation](https://hexdocs.pm/membrane_rtc_engine/js/interfaces/callbacks.html) we need to specify the behavior of the RTC engine client by the mean of passing the proper callbacks during the construction.

We will go through the callbacks list one by one, providing the desired implementation for each of them. All you need to do later is to gather them together into one JS object called `callbacks` before initializing `this.webrtc` object.

### Callbacks

#### onSendMediaEvent

```ts
onSendMediaEvent: (mediaEvent: SerializedMediaEvent) => {
  this.webrtcChannel.push("mediaEvent", { data: mediaEvent });
},
```

If `mediaEvent` from our client Membrane Library appears (this event can be one of many types - for instance it can be message containing information about an ICE candidate in a form of SDP attribute)
we need to pass it to the server. That is why we are making use of our Phoenix channel which has a second endpoint on the server-side - and we are simply pushing data through that channel. The form of the event pushed: `("mediaEvent", { data: mediaEvent })` is the one we are expecting on the server-side - recall the implementation of `VideoRoomWeb.PeerChannel.handle_in("mediaEvent", %{"data" => event}, socket)`

#### onConnectionError

```ts
onConnectionError: setErrorMessage,
```

This one is quite easy - if the error occurs on the client-side of our library, we are simply setting an error message.
In our template `setErrorMessage` method is already provided, but take a look at this method - `onConnectionError` callback forces us to
provide a method with a given signature (because it is passing some parameters which might be helpful to track the reason of the error).

#### onJoinSuccess

We will manipulate the list of peers in this method.
Here is `onJoinSuccess` callback implementation:

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

Once we have successfully joined the room, we make `MembraneWebRTC` object aware of our `this.localStream` tracks (do you remember that we have audio and video track?).
Later on, we are adding a video element for each of the peers (we want to see a video from each of the peers in our room, don't we?).
The last thing we do is invoking the method which will update participants list (we want to have the list of all the participants in our room to be nicely displayed) - let's wrap this functionality into another method:

```ts
private updateParticipantsList = (): void => {
  const participantsNames = this.peers.map((p) => p.metadata.displayName);

  if (this.displayName) {
    participantsNames.push(this.displayName);
  }

  setParticipantsList(participantsNames);
};
```

We are simply putting all the peers' display names into the list and later on, we are adding our own name on top of this list. The last thing to do is to inform UI that the participants' list has changed - and we do it by invoking `setParticipantsList(participantsNames)` from `assets/src/room_ui.ts`.

How about you trying to implement the rest of the callbacks on your own? Please refer to the [documentation](<>) and think where you can use methods from `./assets/src/room_ui.ts`.
Below you will find the expected result (callback implementation) for each of the methods - it might not be the best implementation...but this is the implementation you can afford!
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

Once we are ready with `MembraneWebRTC`'s callbacks implementation, let's specify how to behave when the server sends us a message on the channel.
We need to implement an event handler:

```ts
//FILE: assets/src/room.ts

constructor(){
  ...
  this.webrtcChannel.on("mediaEvent", (event) =>
        this.webrtc.receiveMediaEvent(event.data)
  );
}
```

Once we receive `mediaEvent` from the server (which can be, for instance, a notification that a peer has left), we are simply passing it to the `MembraneWebRTC` object to take care of it.

Now we have the `Room`'s constructor defined! But we cannot say that all the operations allowing us to connect to the server have been performed inside the constructor.

Further initialization might take some time. That's why it might be a good idea to define an asynchronous method `join()`:

```ts
//FILE: assets/src/room.ts

public join = async () => {
  try {
    await this.init();
    setupDisconnectButton(() => {
      this.leave();
      window.location.replace("");
    });
    this.webrtc.join({ displayName: this.displayName });
  } catch (error) {
    console.error("Error while joining to the room:", error);
  }
};
```

First, we are waiting for `this.init()` to complete. This method will be responsible for initializing media streams.
Then we are setting up the disconnect button (which means we are making the button call `this.leave()` once it gets clicked).
Later on, we are making our MembraneWebRTC [`join()`](https://hexdocs.pm/membrane_rtc_engine/js/classes/membranewebrtc.html#join) the room with our display name.

Let's provide the implementation of `this.init()` used in the `this.join()` method.
As noticed previously, this method will initialize the user's media stream handlers.
This is how the implementation of `this.init()` can look like:

```ts
//FILE: assets/src/room.ts

private init = async () => {
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

In the code snippet shown above, we are doing a really important thing - we are getting a reference to the user's media. `navigator.mediaDevices.getUserMedia()` method is an
asynchronous method allowing the browser to fetch tracks of the user's media. We can pass some media constraints which will limit the tracks available in the stream.
Take a look at `assets/src/consts.ts` file where you will find `MEDIA_CONSTRAINTS` definition - it says that we want to get both audio data and video data (but in a specified format!).
Later on, we are dealing with the UI - we are adding a video element to our DOM.
Due to the fact that we need to distinguish between many video tiles in the DOM, we associate each of them with an ID.
In case of this newly added video element (which will be displaying the stream from our local camera) the ID is a `LOCAL_PEER_ID` constant.
We specify that we want our local stream to be displayed in the video element with `LOCAL_PEER_ID` identifier by using `attachStream()` method.
The last thing we do here is that we are waiting for a result of `this.webrtcChannel.join()` method (calling this method will invoke `VideoRoomWeb.PeerChannel.join()` function on the server side).
`this.phoenixChannelPushResult` is simply wrapping this result:

```ts
//FILE: assets/src/room.ts

private phoenixChannelPushResult = async (push: Push): Promise<any> => {
  return new Promise((resolve, reject) => {
    push
    .receive("ok", (response: any) => resolve(response))
    .receive("error", (response: any) => reject(response));
  });
};
```

Oh, we would have almost forgotten! We need to define `this.leave()` method:

```ts
//FILE: assets/src/room.ts

private leave = () => {
  this.webrtc.leave();
  this.webrtcChannel.leave();
  this.socket.off(this.webrtcSocketRefs);
  this.webrtcSocketRefs = [];
};
```

What we do here is that we are using methods aimed at leaving for both our MembraneWebRTC object and Phoenix's channel. Then we are calling `this.socket.off(refs)` method ([click here for documentation](https://hexdocs.pm/phoenix/js/#off))
\- which means we are unregistering all the callbacks. The last thing we need to do is to empty the references list.

Ok, it seems that we have already defined the process of creating and initializing `Room` class's object.
Why not create this object! Go to `assets/src/index.ts` file (do you remember that this is the file which is loaded in template .eex file for our room's template?)
Until now this file is probably empty. Let's create `Room` instance there!

```ts
//FILE: assets/src/index.ts

import { Room } from "./room";

let room = new Room();
room.join()
```

The first thing we do is to import the appropriate class. Then we are creating a new Room's instance (the `constructor()` gets called).
Later on, we are joining the server (which might take some time as it needs to get access to the user's media - that is why this method is asynchronous).
That's it! We have our client defined! In case something does not work properly (or in case we have forgotten to describe some crucial part of code ;) )
feel free to refer to the implementation of the video room's client-side available
[here](https://github.com/membraneframework/membrane_demo/tree/master/webrtc/videoroom/assets/src).

Now, finally, you should be able to check the fruits of your labor!
Please run:

```
mix phx.server
```

visit the following page in your browser:
<br>
[http://localhost:4000](http://localhost:4000)
<br>
and then join a room with a given name!
Later on, you can visit your video room's page once again, from another browser's tab or from another browser's window (or even another browser - however the recommended browsers to use are Chrome and Firefox) and join the same room as before - you should start seeing two participants in the same room!
<br><br>
[NEXT - Further steps](7_FurtherSteps.md)<br>
[PREV - Server's room process](5_ImplementingServerRoom.md)<br>
[List of contents](index.md)<br>
[List of tutorials](../../index.md)
