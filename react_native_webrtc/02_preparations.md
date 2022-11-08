## Preparations

We need to start by preparing ourselves basic React Native application and installing all tools and dependencies we need to start development. You can start a new app using different tools. Since we already know we'll need native code to run our app we are going to use a basic `react-native` library, but if you're familiar with React Native you can choose a different one.

You'll also need to have Android Studio and/or Xcode installed to build and run your app on a device. You can find a full list of requirements [here](https://reactnative.dev/docs/environment-setup).

### Let's create an application

Let's start by creating the most basic RN application:

```bash
npx react-native init MembraneRNWebRTCDemo
```

Now it's time to install Membrane's client library:

```bash
npm install @membraneframework/react-native-membrane-webrtc
```

and also it's ios native dependencies too:

```bash
cd ios
pod install
```

Now, as we've got our application set up, we can start to write some code.
