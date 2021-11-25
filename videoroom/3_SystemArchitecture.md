# Planning is always a good idea
  Hang on for a moment! I know that after slipping through the tons of the documentation you are really eager to start coding, but let's think for a moment before taking any actions. How do we want our application to look like?
  Can we somehow decompose our application?

  Sure we can - as in each web application we have two independent subsystems:
  + server (backend) - written in Elixir, one and the only for the whole system. It will host the signalling service and work as SFU engine.
  + client application (frontend) - the one written in form of JS code and executed on each client's machine (to be precise - by client's web browser). It will be responsible for fetching user's media stream as well as displaying the stream from the peers.

  ## We might need something else than the plain Elixir standard library...
  Ugh...I am sure till now on you have already found out that media streaming is not that easy. It covers many topic which originates to the nature of the reality. We need to deal with some limitations brought to us by the physics of the surrounding universe, we want to compress the data being sent with the great tools mathematics has equipped us with, we are taking an advantage of imperfections of our perception system...
  All this stuff is both complex and complicated - and that is why we don't want to design it from the very scratch. Fortunately, we have an access to the protocols - as somebody has already inspected the problem and created a protocol which defines how should we behave. But that's not enough - those protocols are also complicated and implementing them on our own would still oblige us to dig into it's fundamentals. That is why we will be using tools which provide some level of abstraction on top of these protocols. Ladies and gents - let me introduce to you - the Membrane framework.
  ## What does Membrane framework do?
  Seek at the root! [Membrane documentation](https://membraneframework.org/guide/v0.7/introduction.html)
  ## Membrane framework structure
  It would be good for you to know that the Membrane Framework consists of the following parts:
  + Core
  + Plugins
  
  We will be using one of its plugins - [RTC Engine plugin](https://github.com/membraneframework/membrane_rtc_engine), which has both the server part (written in Elixir) and the client's library (written in Javascript). This plugin provides the implementation of the [Selective Forwarding Unit (SFU)](https://github.com/membraneframework/membrane_rtc_engine) and is adjusted to be used with WebRTC (so it deals with ICE-styled signalling etc.).

  ## System scheme
  The diagram below describes the desired architecture of our system: <br>
  ![Application Scheme](assets/images/total_scheme.png)

  ## Server
  Our server will have two responsibilities - the first one is that it will act as a signalling server. The second one is that it will be a Selective Forwarding Unit (SFU).
  Why do we want our server to be a Selective Forwarding Unit? The reason is that such a model of streaming data among peers allows us to balance between server's and client's bandwidth.
  The server will consist of two components holding the logic and two components needed for communication.
  The communication will be done with the use of Phoenix sockets and that is why we will need to define the `socket` itself and a `channel` for each of the rooms.
  The "heart" of the server will be `SFU Engine` - it will deal with all the dirty stuff connected with signalling and streaming. We will also have a separate `Room` process (one per each of the videorooms) whose responsibility will be to aggregate information about peers in the particular room.
  `SFU Engine` will send signalling messages to the `Room`, which will dispatch them to the appropriate peer's `channel`. `Channel` will then send those messages to the client via the `socket`.
  Signalling messages coming on the `socket` will be dispatched to the appropriate `channel`. Then the `channel` will send them to the `Room`'s process, which finally will pass them to the `SFU Engine`.
  Media transmission will be done with the use of stream protocols. The way in which this will be performed is out the scope of this tutorial. The only thing you need to know is that SFU Engine will also take care of it. 

  ## Client 
  Each client's application will have a structure reassembling the structure of the server.
  We will have a `socket` who will receive signalling messages sent from the server. These messages will then be passed to the `channel`. 
  The `channel` will send these messages to the `Room` object, which will later send them to the `MembraneWebRTC` object. `MembraneWebRTC` object methods will also be directly called from the `Room` object. 
  `MembraneWebRTC` will be able to change the `Room`'s state by invoking the callbacks provided during construction of this object. These callbacks as well as the `Room` object itself will be able to update user's interface. 
  
  Be aware that MembraneWebRTC will also care about the incoming media stream.