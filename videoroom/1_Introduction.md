Scope of this tutorial covers the process of creating own videoroom with the use of the Membrane framework.
# Introduction

## Motivation


  We will be building our app basing on great Phoenix application framework (???)
## Prerequisites
  Since media streaming is quite a complex topic it would be great for you to know something about how the browser can fetch user's media and how the connection is made between the peers etc. Since we will be using Phoenix framework to create our application - it will be much easier for you to understand what's going on if you will be even slightly familiar with that framework. Take your time and glance over these links:
  + [How does Phoenix work?](https://hexdocs.pm/phoenix/request_lifecycle.html)
    Phoenix, while being a great tool which allows to create complex application in considerably easy manner, requires it's user to follow a bunch of good practices and use some helpful project patterns. Most important one is MVC (Model-View-Controller) pattern, which affects the structure of project directories. The tutorial attached there provides a great introduction for Phoenix application creation and will allow you to understand the structure of our template project.

  + [How  do Phoenix sockets work and the difference between endpoint and socket/channel?](https://hexdocs.pm/phoenix/channels.html) 
    When we think about building the web application the very first thing which comes to our mind is HTTP. Surely, Phoenix allows us to send HTTP requests from the client application to the server - however, Phoenix developers have prepared for you an optional way to communicate - sockets. Sockets, in contrast to plain HTTP requests, are persistent and allow bidirectional communication, while HTTP request are stateless and work in request -> reply mode. Want to dig deeper? Feel free to read the provided part of the official Phoenix documentation!

  + [How to access user's media from the browser?](https://www.html5rocks.com/en/tutorials/webrtc/basics/)
    Ever wondered how is it possible for the browser to access your camera or a microphone? Here you will find an answer for that and many more inquiring you questions!

  + [WebRTC Connectivity (signalling, ICE etc.)](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Connectivity)
    One does not simply connect and send media! First, peers need to get in touch with each other (with a little help from a publicly available server), as well as exchange some information about themselves. This short tutorial will give you and outlook on how does this process (called 'signalling') can be performed!

  + [Why do we need STUN/TURN servers?](https://www.html5rocks.com/en/tutorials/webrtc/infrastructure/)
    Peer to peer connection can be (and in most cases is) problematic. At the same time it is also demanded - we don't want to have our media pass through some server (both due to the throughput limitations and privacy issues). While reading this tutorial you will find some tricks which allow you connect your beloved peer hidden by some firewalls and NAT!

