## Creating Videochat App

The first you need to do is to create a component that will be responsible for connecting to Media Server and displaying VideoChat. Let's name it 'VideoChat':

```jsx
import  React, { useState, useEffect } from  'react';
import { StyleSheet, Text, View } from  'react-native';

export  const  VideoChat = ({ displayName }) => {

  return (
    <View  style={styles.flex}>
    </View>
  );
};

const  styles = StyleSheet.create({
  flex: {
    flex:  1,
  },
  displayName: {
    backgroundColor:  'black',
    position:  'absolute',
    color:  "white",
    left:  0,
    bottom:  0,
    padding:  5,
  }
});
```

In the above example, we've already added some styling for yet non-existing parts of the component but as we're not focusing on the app's appearance you can copy it directly.

### Connecting to Media Server

To be able to connect with other devices we need to have a media server. In this demo, we're going to use the existing Membrane's Videoroom server that you can find [here](https://videoroom.membrane.stream).

>If you can use your own instance of it. Here you can find tutorial that will show you how to create a Videoroom server with Membrane.

Let's start with importing `MembraneWebRTC` and declare some constants:
```jsx
import  React, { useState, useEffect } from  'react';
import { StyleSheet, Text, View } from  'react-native';
import  *  as  MembraneWebRTC  from  "@membraneframework/react-native-membrane-webrtc";

export  const  VideoChat = ({ displayName }) => {
  const  serverUrl = 'https://videoroom.membrane.stream/socket';
  const  roomName = 'important_meeting';
  const  webRTC = MembraneWebRTC.useMembraneServer();
  const  participants = MembraneWebRTC.useRoomParticipants();

  return (
    <View  style={styles.flex}>
    </View>
  );
};
```
A `serverUrl` is an address of a socket endpoint of our media server. A `roomName` is the name of our chat room. We can lately type it into Videoroom's browser client to chat with ourselves. We also created `participants` constant that gives us access to iterate through all clients connected to the room.

Now it's to use those constants. To set up a connection we'll use hook `useEffect()`:

```jsx
useEffect(() => {
  const  setup = async () => {
    await  webRTC.connect(
	  serverUrl,
	  roomName,
	  { userMetadata: { displayName:  displayName } }
	);
	await  webRTC.joinRoom();
  }
  setup();
  return  webRTC.disconnect;
}, []);
```

A `useEffect()` is a function that will be executed when the component is mounted or updated and a return value of it is a function that will be executed when the component is unmounted.

So now we're almost ready to set up a connection with our server, but before that, we need to do one more thing...

### Permissions

Any application that is going to use sensitive pieces of information from a user's device needs to ask for the user's permission first. Our app will need permission to use the device's camera and microphone. To manage those permissions we can use [Expo's Camera library](https://docs.expo.dev/versions/latest/sdk/camera/). Let's install it:
```bash
npm install expo-camera
```
Now we need to add permission prompting functions to our component. First, we need to import it:
```
import { Camera } from  'expo-camera';
```
 Then we need to find the best moment to ask for the user's permission. We want to do it before we connect to our server, so we're going to place it inside our `useEffect()` hook:

```jsx
useEffect(() => {
  const  setup = async () => {
    await  Camera.requestCameraPermissionsAsync();
    await  Camera.requestMicrophonePermissionsAsync();
    await  webRTC.connect(
	  serverUrl,
	  roomName,
	  { userMetadata: { displayName:  displayName } }
	);
	await  webRTC.joinRoom();
  }
  setup();
  return  webRTC.disconnect;
}, []);
```
We used asynchronous functions to prevent connecting to the server before the user granted or declined requested permissions.

> When requesting permissions you also need to declare them in native configuration files to be able to publish your app in the store. To do it go to the file:
> - For Android:
> `android/app/src/main/AndroidManifest.xml` 
> and add:
> `<uses-permission  android:name="android.permission.CAMERA"/>`
> `<uses-permission  android:name="android.permission.RECORD_AUDIO"/>`
> 
> - For iOS
> `ios/membranernwebrtcdemo/Info.plist`
> and add:
> `<key>NSCameraUsageDescription</key>`
> `<string>Allow $(PRODUCT_NAME) to access your camera</string>`
> `<key>NSMicrophoneUsageDescription</key>`
> `<string>Allow $(PRODUCT_NAME) to access your microphone</string>`

To make sure we'll notice a connection error let's add one more hook to the component:
```jsx
useEffect(() => {
  if (webRTC.error) {
    console.warn(webRTC.error);
  }
}, [webRTC.error]);
```
This hook will run when the value of `webRTC.error` changes.

### Appearance
Last but not least part of our `VideoChat` component will be to render something after the connection is ready:

```jsx
return (
  <View  style={styles.flex}>
    {
      participants.map((participant) => (
        <View  style={styles.flex}  key={participant.id}>
          <MembraneWebRTC.VideoRendererView participantId={participant.id} style={styles.flex}  />
          <Text style={styles.displayName}>{participant.metadata.displayName}</Text>
        </View>
      ))
    }
  </View>
);
```
That's the simplest we can do to see our app in action. We're iterating through room participants, and creating a `<View>` box for each one. A `<View>` contains 
predefined `<MembraneWebRTC.VideoRendererView>` and a caption with the participant's name.

With this step behind us we should have a full `VideoChat` component code looking like this:

```jsx
import  React, { useState, useEffect } from  'react';
import { StyleSheet, Text, View } from  'react-native';
import { Camera } from  'expo-camera';
import  *  as  MembraneWebRTC  from  "@membraneframework/react-native-membrane-webrtc";

export  const  VideoChat = ({ displayName }) => {
  const  serverUrl = 'https://videoroom.membraneframework.org/socket';
  const  roomName = 'important_meeting';
  const  webRTC = MembraneWebRTC.useMembraneServer();
  const  participants = MembraneWebRTC.useRoomParticipants();

  useEffect(() => {
    const  setup = async () => {
      await  Camera.requestCameraPermissionsAsync();
      await  Camera.requestMicrophonePermissionsAsync();
      await  webRTC.connect(
        serverUrl,
        roomName,
        { userMetadata: { displayName:  displayName } }
      );
      await  webRTC.joinRoom();
    };
    setup();
    return  webRTC.disconnect;
  }, []);

  useEffect(() => {
    if (webRTC.error) {
      console.warn(webRTC.error);
    }
  }, [webRTC.error]);

  return (
    <View  style={styles.flex}>
      {
        participants.map((participant) => (
          <View style={styles.flex} key={participant.id}>
            <MembraneWebRTC.VideoRendererView participantId={participant.id} style={styles.flex}/>
            <Text style={styles.displayName}>{participant.metadata.displayName}</Text>
          </View>
        ))
      }
    </View>
  );
};

const  styles = StyleSheet.create({
  flex: {
    flex:  1,
  },
  displayName: {
    backgroundColor:  'black',
    position:  'absolute',
    color:  "white",
    left:  0,
    bottom:  0,
    padding:  5,
  }
});
```
Now we can return to `App.js` and use it.

### Managing Chat

Before importing our `VideoChat` component we need to set up a logic responsible for managing it. We want users to be able to enter and exit the chat room. Also, they need to be able to set their `name`. The first thing we need to do to achieve that is a state:

```jsx
const [userName, setUserName] = useState("")
const [videoChatPresent, setVideoChatPresent] = useState(false);
```
Now we can create a form to enter the chat that will be displayed instead of 'hello world':

```jsx
return (
  <View style={styles.container}>
    <Text style={styles.header}>Membrane Demo Chat</Text>
    <TextInput value={userName} placeholder="Insert user name"  onChangeText={setUserName} style={styles.textInput} />
    <Button onPress={() => setVideoChatPresent(true)} title="open video chat" />
  </View  >
);
```
After our user presses a button we want to show our `VideoChat` component. Let's create a statement for it:

```jsx
if (videoChatPresent) {
  return (
    <View style={styles.flex}>
      <Text style={styles.header}>Membrane Demo Chat</Text>
      <VideoChat displayName={userName} />
      <Button onPress={() => setVideoChatPresent(false)} title="close video chat" />
    </View  >
  );
}
```

The last thing we need to make our code complete is to add missing imports and stylesheets so that our code looks like this:

```jsx
import React, { useState } from 'react';

import { Button, StyleSheet, View, Text, TextInput } from 'react-native';
import { VideoChat } from './VideoChat';

export default function App() {
  const [userName, setUserName] = useState("")
  const [videoChatPresent, setVideoChatPresent] = useState(false);

  if (videoChatPresent) {
    return (
      < View style={styles.flex} >
        <Text style={styles.header}>Membrane Demo Chat</Text>
        <VideoChat displayName={userName} />
        <Button onPress={() => setVideoChatPresent(false)} title="close video chat" />
      </View >
    );
  }
  return (
    < View style={styles.container} >
      <Text style={styles.header}>Membrane Demo Chat</Text>
      <TextInput value={userName} placeholder="Insert user name" onChangeText={setUserName} style={styles.textInput} />
      <Button onPress={() => setVideoChatPresent(true)} title="open video chat" />
    </View >
  );
}

const styles = StyleSheet.create({
  flex: {
    flex: 1,
  },
  container: {
    flex: 1,
    padding: 50,
    fontSize: 20
  },
  header: {
    fontSize: 50,
    marginBottom: 20
  },
  textInput: {
    borderWidth: 2,
    borderColor: "gray",
    marginBottom: 20,
    fontSize: 20,
    padding: 10,
  },
});
```