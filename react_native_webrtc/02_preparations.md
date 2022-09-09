## Preparations

We need to start by preparing ourselves basic React Native application and installing all tools and dependencies we need to start development. You can start a new app using different tools. We've chosen to use [expo](https://expo.dev/) but if you're familiar with React Native you can do whatever leads you to have a 'hello-world' app set up.

### Creating a basic RN application

Let's start by creating the most basic RN application using `create-expo-app`:

```bash
create-expo-app membrane_rn_webrtc_demo
```

> We assume that you've got a basic React Native tools installed, but if not here is a good starting point what and how you should prepare to start a development: [https://reactnative.dev/docs/environment-setup](https://reactnative.dev/docs/environment-setup). 

### Installing React Native Membrane WebRTC

Let's go to the lib's GitHub page and see what needs to be done. Since we're using expo we can install it with:

```bash
expo install @membraneframework/react-native-membrane-webrtc.
```

Next, add it to `plugins` in `App.json`:

```json
{
  "expo": {
    "name": "membrane_rn_webrtc_demo",
    ...
    "plugins": [
      "@membraneframework/react-native-membrane-webrtc"
    ],
    ...
  }
}
```

Now we're ready to get some native code. We can prebuild our application with expo:

```bash
expo prebuild
```

Now you can see two new directories that appeared in your project. One is for android native code, the other for ios. Let's go into the second one and install pods:

```bash
cd ios
pod install
```

> Sometimes prebuild may fault because of missing dependencies. If it do so, install them with `npm install` or `yarn add` and try again

Now, as we've got our application set up, we can start to write some code.
