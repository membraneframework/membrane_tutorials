## Running our Videoconfernce

Now it's time to see our Viedeoroom in action. There are many methods to run React Native applications. You can run it on an iOS or Android simulator or connect your mobile device to the computer and run an app from Xcode or Android Studio (You can use options provided by [expo](https://expo.dev/) too). Unfortunately, simulators won't show us if our chat is working, as simulated devices don't have cameras or microphones (obviously), and usage of computer ones is not always possible.

So if we want to see and hear ourselves we need a real device.

> There are dozens of tutorials and troubleshooting articles about how to run react native (or generally mobile) app but let's stick to official documentation:
> [https://reactnative.dev/docs/running-on-device](https://reactnative.dev/docs/running-on-device) (swith between expected enviroment and your operating system to see detailed instructions)
> [https://help.apple.com/xcode/mac/current/#/devdc0193470c](https://help.apple.com/xcode/mac/current/#/devdc0193470c) (and following chapters)
> There's no point to copy those here so find time to read those and follow steps you'll find there. At the end you'll finish with our app starting on your device

### How I can talk to myself?

After having videoroom started on your device you'll be prompted about permissions to use a camera and a microphone (Agree of course :) ). You also have to insert your name to finally see your face in the app. Now, let's go to the next level and check if you can see it on another device. To do it, firstly let's get a quick look what is the server URL our app is using. You'll find it at the very start of `VideoChat` component:

```jsx
const  serverUrl = 'https://videoroom.membrane.stream/socket';
const  roomName = 'important_meeting';
```

OK, so let's go to the new tab of your browser and connect to [https://videoroom.membrane.stream](https://videoroom.membrane.stream/socket) (without `/socket` endpoint) and join the 'important_meeting' room. Can you both see yourselves? 

### Postscriptum

This is the most basic app, so it's a bit ugly, and we haven't set up screen sharing properly. If you want to add it to your demo use the instructions from [here](https://github.com/membraneframework/react-native-membrane-webrtc#ios)

There are also native WebRTC clients written to use with Membrane Videoroom. You can find them here: [iOS](https://github.com/membraneframework/membrane-webrtc-ios), [Android](https://github.com/membraneframework/membrane-webrtc-android)




