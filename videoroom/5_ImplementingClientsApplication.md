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
  Let's start with a constructor to define how our room will be created. We need to declare member fields used in this part of the constructor in the class body first:
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

  What happens at the beginning of the constructor? We are creating new Phoenix Socket with ```/socket``` path (must be the same as we have defined on the server side!) and right after that we are starting a connection. 
  Later on, we are retrieving the display name from the URL (the user has set it in the UI while joining the room and it was passed to the next view as the URL param) - that's why we need ```this.parseUrl()``` method. Its implementation might look as follows:
  ```ts
  private parseUrl = (): string => {
    const { display_name: displayName } = parse(document.location.search);

    // remove query params without reloading the page
    window.history.replaceState(null, "", window.location.pathname);

    return displayName as string;
  };
  ```
  Then we are connecting to the Phoenix's channel on the topic `room <room name>`. Room name is fetched from the UI. 


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
  
  According to MembraneWebRTC [documentation](https://hexdocs.pm/membrane_rtc_engine/js/interfaces/callbacks.html) we need to specify the behavior of the RTC engine client by passing the proper callbacks during the construction. 

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




  Firstly let's add a member field responsible for holding the list of peers:
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

