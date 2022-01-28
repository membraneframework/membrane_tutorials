---
title: Further steps
description: >-
  Create your very own videoconferencing room with a little help from the Membrane Framework!
  <div>
  <br> <b>Page:</b> <a style="color: white" href=https://www.membraneframework.org/>Membrane Framework</a>
  <br> <b>Forum:</b> <a style="color: white" href=https://elixirforum.com/c/elixir-framework-forums/membrane-forum/104/>Membrane Forum</a>
  </div>
---
# What to do next?
We can share with you inspiration for further improvements!
## Voice activation detection
Wouldn't it be great to have a feature that would somehow mark a person who is currently speaking in the room? That's where voice activation detection (VAD) joins the game!
There is a chance that you remember that the SFU engine was sending some other messages which we purposely didn't handle (once again you can refer to the [documentation](https://hexdocs.pm/membrane_rtc_engine/Membrane.RTC.Engine.html#module-messages]). One of these messages sent from SFU to the client is ```{:vad_notification, val, peer_id}``` - the message which is sent once the client starts or stops speaking. We need to simply pass this message from SFU to the client's application and take some actions once it is received - for instance, you can change the user's name displayed under the video panel so that instead of the plain user's name (e.g. "John") we would be seeing "<user> is speaking now" message.
Below you can see what is the expected result:


![VAD example](assets/records/vad.webp "VAD example")

Hopefully, you will find the diagram placed below helpful as it describes the flow of the VAD notification and shows which component's of the system need to be changed:

![VAD Flow Scheme](assets/images/vad_flow_scheme.png "VAD flow scheme")

## Muting/unmuting
It's not necessary for each peer to hear everything...
Why not allow users of our video room to mute themselves when they want to?
This simple feature has nothing to do with the server-side of our system. Everything you need to do in order to disable the voice stream being sent can be found in (WebRTC MediaStreamTrack API documentation)[https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack]. You need to find a way to disable and reenable the audio track from your local media stream and then add a button that would set you in a "muted" or "unmuted" state. The expected result is shown below:
![Mute example](assets/records/mute.webp "mute example")



You can also conduct some experiments on how to disable the video track (so that the user can turn off and on camera while being in the room).
Our suggested implementation of these two features is available at the [template repository](https://github.com/membrane_framework/membrane_videoroom_tutorial/), on `template/additional_features` branch.

Here our journey ends! I modestly hope that you have enjoyed the tutorial and have fetched out of it that much interesting information and skills as possible. Or maybe you have even found yourself passionate about media streaming? Goodbye and have a great time playing with the tool you have just created!
