## Let's implement the client's endpoint!
 We will put whole logic into `assets/src/room.ts`. Methods aimed to change user's interface are already in `assets/src/room_ui.ts` and we will use them along the room's logic implementation. So first, let's import all necessary dependencies concerning UI to our newly created file:
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
 We have basically imported all the methods defined in `room_ui.ts`. For more details on how these methods work and what is their interface please refer to the source file.
 Take a look at our `assets/package.json` file which defines outer dependencies for our project. We have put there the following dependency:
 ```JSON
 "membrane_rtc_engine": "file:../deps/membrane_rtc_engine/"
 ```
 which is a client library provided by the RTC engine plugin from the Membrane Framework.
 Let's import some constructs from this library (their name should be self-explanatory and you can read about them in [the official Membrane's RTC engine documentation](https://hexdocs.pm/membrane_rtc_engine/js/index.html):
 ```ts
 import {
    MembraneWebRTC,
    Peer,
    SerializedMediaEvent,
 } from "membrane_rtc_engine";
 ```

 Later on, let's import interesting constructs from the Phoenix - `Push` and `Socket` classes (can you guess what is the purpose of using them? ;) )
 ```ts
 import { Push, Socket } from "phoenix";
 ```

 We will also need ```parse``` method from ```"query-string"``` dependency - to nicely get our display name from the URL. Let's import it here:
 ```ts
 import { parse } from "query-string";
 ```

 It might be worth to somehow wrap our room's client logic into a class - so at the very beginning let's simply define `Room` class:
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
 Let's start with a constructor to define how our room will be created. First, we need to declare some member fields initialized in the constructor, in the class body:
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

 What happens at the beginning of the constructor? We are creating a new Phoenix Socket with `/socket` path (must be the same as we have defined on the server-side!) and right after that, we are starting a connection. 
 Later on, we are retrieving the display name from the URL (the user has set it in the UI while joining the room and it was passed to the next view as the URL param) - that's why we need ```this.parseUrl()``` method. Its implementation might look as follows:
 ```ts
 private parseUrl = (): string => {
    const { display_name: displayName } = parse(document.location.search);

    // remove query params without reloading the page
    window.history.replaceState(null, "", window.location.pathname);

    return displayName as string;
 };
 ```
 Then we are connecting to the Phoenix's channel on the topic `room:<room name>`. The room name is fetched from the UI. 


 Following on the constructor implementation:
 ```ts
 const socketErrorCallbackRef = this.socket.onError(this.leave);
 const socketClosedCallbackRef = this.socket.onClose(this.leave);
 this.webrtcSocketRefs.push(socketErrorCallbackRef);
 this.webrtcSocketRefs.push(socketClosedCallbackRef);
 ```
 This structure might look a little bit ambiguous. What we are storing in ```this.webrtcSocketRefs```? Well, we are storing references...to the callbacks we have just defined.
 We have passed what method should be invoked in case our Phoenix socket is closed or has experienced an error of some type - that is, `this.leave()` method. We will define this method later.
 However, we want to keep track of those callbacks so that we will be able to turn them off ("unregister " those callbacks).
 Where will we be unregistering the callbacks? Inside `this.leave()` method!
 

 Now let's get back to the constructor. Let's create a MembraneWebRTC object! Declare it as a Room class member field:
 ```ts
 private webrtc: MembraneWebRTC
 ```

 and initialize it within constructor:
 ```ts
 this.webrtc = new MembraneWebRTC({callbacks: callbacks});
 ```
 
 According to MembraneWebRTC [documentation](https://hexdocs.pm/membrane_rtc_engine/js/interfaces/callbacks.html) we need to specify the behavior of the RTC engine client by the mean of passing the proper callbacks during the construction. 

 We will go through the callbacks list one by one, providing the desired implementation for each of them. All you need to do later is to gather them together into one JS object called ```callbacks``` before initializing ```this.webrtc``` object.



 ### Callbacks
 #### onSendMediaEvent
 ```ts
 onSendMediaEvent: (mediaEvent: SerializedMediaEvent) => {
    this.webrtcChannel.push("mediaEvent", { data: mediaEvent });
 },
 ```
 If `mediaEvent` from our client Membrane Library appears (this event can be one of many types - for instance it can be message containing information about an ICE candidate in a form of SDP attribute)
  we need to pass it to the server. That is why we are making use of our Phoenix channel which has a second endpoint on the server-side - and we are simply pushing data through that channel. The form of the event pushed: ```("mediaEvent", { data: mediaEvent })``` is the one we are expecting on the server-side - recall the implementation of ```VideoRoomWeb.PeerChannel.handle_in("mediaEvent", %{"data" => event}, socket)```
 #### onConnectionError
 ```ts
 onConnectionError: setErrorMessage,
 ```
 This one is quite easy - if the error occurs on the client-side of our library, we are simply setting an error message.
 In our template `setErrorMessage` method is already provided, but take a look at this method - `onConnectionError` callback forces us to 
 provide a method with a given signature (because it is passing some parameters which might be helpful to track the reason of the error).
 #### onJoinSuccess

 Firstly let's add a member field responsible for holding the list of peers:
 ```ts
 private peers: Peer[] = [];
 ```

 And here is `onJoinSuccess` callback implementation:
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
 Once we have successfully joined the room, we add each of the tracks from our `this.localStream` (do you remember that we have audio and video track?) to MembraneWebRTC object (we are also passing the reference to the whole local stream). 
 Later on, we are adding video element () per each of the peers (we want to see a video from each of the peers in our room, don't we?).
 The last thing we do is invoking the method which will update participants list (we want to have the list of all the participants in our room be nicely displayed) - let's wrap this functionality into another method:
 ```ts
 private updateParticipantsList = (): void => {
    const participantsNames = this.peers.map((p) => p.metadata.displayName);

    if (this.displayName) {
        participantsNames.push(this.displayName);
    }

    setParticipantsList(participantsNames);
 };
 ```
 We are simply putting all the peers' display names into the list and later on, we are adding our own name on top of this list. The last thing to do is to inform UI that the participants' list has changed - and we do it by invoking ```setParticipantsList(participantsNames)``` from ```assets/src/room_ui.ts```.


 How about you trying to implement the rest of the callbacks on your own? Please refer to the [documentation]() and think where you can use methods from ```./assets/src/room_ui.ts```.
 Below you will find the expected result (callback implementation) for each of the methods - it might not be the best implementation...but it is the implementation can afford!
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
 You could have guessed - we will implement another callback:
 ```ts
 this.webrtcChannel.on("mediaEvent", (event) =>
      this.webrtc.receiveMediaEvent(event.data)
 );
 ```
 Once we receive `mediaEvent` from the server (which can be, for instance, a notification that a peer has left), we are simply passing it to the `MembraneWebRTC` object to take care of it.

 Now we have the `Room`'s constructor defined! But we cannot say that all the operations allowing us to connect to the server have been performed inside the constructor.
 

 Further initialization might take some time. That's why it might be a good idea to define an asynchronous method `join()`:
 ```ts
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
 

 Let's provide the implementation of ```this.init()``` used in the `this.join()` method.
 As noticed previously, this method will initialize the user's media stream handlers - so let's add a member field to hold a reference to our localStream (webRTC stream):
 ```ts
 private localStream: MediaStream | undefined;
 ```

 This is how the implementation of `this.init()` can look like:
 ```ts
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
 Later on, we are dealing with the UI - we are adding a video element to our DOM (and we are identifying it with `LOCAL_PEER_ID`) and attaching our local media stream to this newly 
 added video element (this is the first time we will be using PEER_ID as a handler to a proper element - as you can see, attachStream() method distinguishes between all video elements,
 which we will be having many - one for us and one for each of the peers - basing on this id).
 The last thing we do here is that we are waiting for a result of `this.webrtcChannel.join()` method (can you guess what happens on the server side once we are running this method?).
```this.phoenixChannelPushResult``` is simply wrapping this result:

 ```ts
 private phoenixChannelPushResult = async (push: Push): Promise<any> => {
    return new Promise((resolve, reject) => {
        push
        .receive("ok", (response: any) => resolve(response))
        .receive("error", (response: any) => reject(response));
    });
 };
 ```

 Oh, we would have almost forget! We need to define `this.leave()` method:
 ```ts
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
 Why not create this object! Go to ```assets/src/index.js``` file (do you remember that this is the file which is loaded in template .eex file for our room's template?)
 Until now this file is probably empty. Let's create ```Room``` instance there!
 ```ts
 import { Room } from "./room";

 let room = new Room();
 room.join()
 ```
 The first thing we do is to import the appropriate class. Then we are creating a new Room's instance (the ```constructor()``` gets called). 
 Later on, we are joining the server (which might take some time as it needs to get access to the user's media - that is why this method is asynchronous). 
 That's it! We have our client defined! In case something does not work properly (or in case we have forgotten to describe some crucial part of code ;) ) 
 feel free to refer to the implementation of the video room's client-side available 
 [here](https://github.com/membraneframework/membrane_demo/tree/master/webrtc/videoroom/assets/src).

