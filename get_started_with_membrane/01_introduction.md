# Getting started

Hello there, and a warm welcome to the Membrane tutorials. We're glad you chose to learn Membrane; and we'd like to invite you on a journey around multimedia with us, where we explore how to utilize the Membrane Framework to build applications that process audio, video, and other multimedia content in interesting ways.

## What is Membrane?

Membrane is a multimedia processing framework that focuses on reliability, concurrency, and scalability. It is primarily written in Elixir, while some platform-specific or time-constrained parts are written in Rust C. With a range of existing packages and an easy-to-use interface for writing your own, Membrane can be used to process almost any type of multimedia, for example:
- stream via WebRTC, RTSP, RTMP, HLS, HTTP and other protocols,
- transcode, mix and apply custom processing of video & audio,
- accept and generate / record to MP4, MKV, FLV and other containers,
- handle dynamically connecting and disconnecting streams,
- seamlessly scale and recover from errors,
- do whatever you imagine if you implement it yourself :D Membrane makes it easy to plug in your code at almost any point of processing.

If the abbreviations above don't ring any bells, don't worry - this tutorial doesn't require any multimedia-specific knowledge. Then, [other tutorials](https://membrane.stream/learn) and [demos](https://github.com/membraneframework/membrane_demo) will introduce you to the multimedia world!

## Structure of the framework

The most basic media processing entities of Membrane are `Element`s. An element might be able, for example, to mux incoming audio and video streams into MP4, or play raw audio using your sound card. You can create elements yourself, or choose from the ones provided by the framework.

Elements can be organized into a pipeline - a sequence of linked elements that perform a specific task. For example, a pipeline might receive an incoming RTSP stream from a webcam and convert it to an HLS stream, or act as a selective forwarding unit (SFU) to implement your own videoconferencing room. You'll see how to create a pipeline in the subsequent chapter.

### Membrane packages

To embrace modularity, Membrane is delivered to you in multiple packages, including plugins, formats, core and standalone libraries. The list of all Membrane packages is available [here](https://github.com/membraneframework/membrane_core/#All-packages). It contains all the packages maintained by the Membrane team and some third-party packages.

**Plugins**

Plugins provide elements that you can use in your pipeline. Each plugin lives in a `membrane_X_plugin` repository, where `X` can be a protocol, codec, container or functionality, for example [mebrane_opus_plugin](github.com/membraneframework/membrane_opus_plugin). Plugins wrapping a tool or library are named `membrane_X_LIBRARYNAME_plugin` or just `membrane_LIBRARYNAME_plugin`, like [membrane_mp3_mad_plugin](github.com/membraneframework/membrane_mp3_mad_plugin). Plugins are published on [hex.pm](hex.pm), for example [hex.pm/packages/membrane_opus_plugin](hex.pm/pakcages/membrane_opus_plugin) and docs are at [hexdocs](hexdocs.pm), like [hexdocs.pm/membrane_opus_plugin](hexdocs.pm/membrane_opus_plugin). Some plugins require native libraries installed in your OS. Those requirements, along with usage examples are outlined in each plugin's readme.

**Formats**

Apart from plugins, Membrane has stream formats, which live in `membrane_X_format` repositories, where `X` is usually a codec or container, for example, [mebrane_opus_format](github.com/membraneframework/mebrane_opus_format). Stream formats are published the same way as packages and are used by elements to define what kind of stream can be sent or received. They also provide utility functions to deal with a given codec/container.

**Core**

[Membrane Core](https://github.com/membraneframework/membrane_core) is the heart and soul of the Membrane Framework. It is written entirely in Elixir and provides the internal mechanisms and API that allow you to prepare processing elements and link them together in a convenient yet reliable way. Note that Membrane Core does not contain any multimedia-specific logic. 
The documentation for the developer's API is available at [hexdocs](https://hexdocs.pm/membrane_core/readme.html).

**Standalone libraries**

Last but not least, Membrane provides tools and libraries that can be used standalone and don't depend on the `membrane_core`, for example, [video_compositor](github.com/membraneframework/video_compositor), [ex_sdp](github.com/membraneframework/ex_sdp) or [unifex](github.com/membraneframework/unifex).

## Where can I learn Membrane?
There are a number of resources available for learning about Membrane:

### This guide
The following sections in that guide will introduce the main concepts of creating Membrane elements and pipelines, without focusing on the specific details of multimedia processing.

### Demos
The [membrane_demo](https://github.com/membraneframework/membrane_demo) repository contains many projects, scripts and livebooks that cover different use cases of the framework. It's a good place to learn by example.

### Tutorials
For a step-by-step guide to implementing a specific system using Membrane, check out our [tutorials](https://membrane.stream/learn).

### Documentation
For more detailed information, you can refer to the Membrane Core documentation and the documentation for the Membrane packages maintained by the Membrane team, both of which can be accessed [here](https://hex.pm/orgs/membraneframework).

If you see something requiring improvement in this guide, feel free to create an issue or open a PR in the [membrane_tutorials](https://github.com/membraneframework/membrane_tutorials) repository.
