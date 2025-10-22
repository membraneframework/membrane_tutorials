This time we won't create the application from the scratch nor will we be based on some kind of template.
Since most of the application's code is media-agnostic, we don't see a point in focusing on it. Instead, we will indicate the most crucial parts of the
[RTMP to HLS demo](https://github.com/membraneframework/membrane_demo/tree/master/rtmp_to_hls), one of many publicly available [Membrane demos](https://github.com/membraneframework/membrane_demo/).
The Membrane demos are supplementing the Membrane Tutorials on providing a source of knowledge in the field of multimedia processing - we warmly invite you to look at them as you may find some interesting
use cases of Membrane in real-life scenarios.

## Running the application

In order to run the demo, you need to clone the Membrane demos repository first:

```console
git clone https://github.com/membraneframework/membrane_demo
cd membrane_demo/rtmp_to_hls
```

Once in the project directory, you need to get the dependencies of the project:

```console
mix deps.get
```

Finally, you can run the application with the following command:

```console
mix phx.server
```

The server will be waiting for an RTMP stream on localhost:9009, and the client of the application will be available on localhost:4000.

## Exemplary stream generation with OBS

You can send RTMP stream onto `localhost:9006` with your favorite streaming tool. As an example, we will show you how to generate an RTMP stream with
[OBS](https://obsproject.com).
Once you have OBS installed, you can perform the following steps:

1. Open the OBS application
1. Open the `Settings` windows
1. Go to the `Stream` tab and set the value in the `Server` field to: `rtmp://localhost:9006` (the address where the server is waiting for the stream)
1. Finally, you can go back to the main window and start streaming with the `Start Streaming` button.

Below you can see how to set the appropriate settings (steps 2) and 3) from the list of steps above):
![OBS settings](assets/OBS_settings.webp)

Once the streaming has started, you can visit `localhost:4000`, where the client application should be available. After a few seconds, you should be able to play
the video you are streaming. Most likely, a kind of latency will occur and the stream played by the client application will be delayed. That latency can reach values as great as 10 seconds, which is the result
of a relatively complex processing taking place in the pipeline. Note, that the latency here is not a result of the packets traveling far via the network, as the packets do not leave our computer in that setup - in the case of a real streaming server, we would need to take into consideration the time it takes a packet to reach the destination.
