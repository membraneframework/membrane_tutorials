---
title: 2. Environment preparation
description: >-
  Create your very own videoconferencing room with a little help from the Membrane Framework!
  <div>
  <br> <b>Page:</b> <a style="color: white" href=https://www.membraneframework.org/>Membrane Framework</a>
  <br> <b>Forum:</b> <a style="color: white" href=https://elixirforum.com/c/elixir-framework-forums/membrane-forum/104/>Membrane Forum</a>
  </div>
---
# Environment preparation

## Elixir installation
I don't think I can describe it any better: [How to install Elixir](https://elixir-lang.org/install.html).
But do not forget to add the elixir bin to your PATH variable!

Take your time and make yourself comfortable with Elixir. Check if you can run Elixir's interactive terminal and if you can compile Elixir's source files with the Elixir compiler.
You can also try to create a new Mix project - we will be using [Mix](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) as the build automation tool all along with the tutorial.

## Template downloading
Once we have the development environment set up properly (let's hope so!) we can start to work on our project. We don't want you to do it from scratch as the development requires some dull playing around with UI, setting the dependencies, etc. - we want to provide you only the meat! That is why we would like you to download the template project with core parts of the code missing. You can do it by typing:

```bash
git clone https://github.com/membraneframework/membrane_videoroom_tutorial
```

and then changing directory to the freshly cloned repository and switching to the branch which provides the unfulfilled template:

```bash
cd membrane_videoroom_tutorial
git checkout template/start
```

In case you find yourself lost along with the tutorial, feel free to check the suggested implementation provided by us, which is available on the `template/end` branch of this repository.

## Native dependencies installing
First, some native dependencies are needed. Here is how you can install them and setup the required environment variables.

### Mac OS with M1
```
brew install node srtp libnice clang-format ffmpeg
export C_INCLUDE_PATH=/opt/homebrew/Cellar/libnice/0.1.18/include:/opt/homebrew/Cellar/opus/1.3.1/include:/opt/homebrew/Cellar/openssl@1.1/1.1.1l_1/include
export LIBRARY_PATH=/opt/homebrew/Cellar/opus/1.3.1/lib
export PKG_CONFIG_PATH=/opt/homebrew/Cellar/openssl@1.1/1.1.1l_1/lib/pkgconfig/
```

### Mac OS with Intel
```
brew install node srtp libnice clang-format ffmpeg
export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"
```

### Ubuntu

```
sudo apt-get install npm build-essential pkg-config libssl-dev libopus-dev libsrtp2-dev libnice-dev libavcodec-dev libavformat-dev libavutil-dev
export PKG_CONFIG_PATH="/usr/local/ssl/lib/pkgconfig"
```

If you installed Elixir from ESL repo, make sure the following erlang packages are present
```
sudo apt-get install erlang-dev erlang-parsetools erlang-src
```

### Setting environment with the use of Docker
Alternatively to the steps described in the section above, you can make use of the docker image we have prepared for the purpose of this tutorial.
You won't need to install any native dependencies there nor export environmental variables - however **your computer cannot be running on M1 processor**.

If you are using VS Code for your code development, you can make use of the [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension. Among the files you have just cloned from the repository there should be a `.devcontainer.json` configuration file placed in the root directory of the project. It contains information about which image from the Docker Hub should be cloned and how the ports should be redirected between the container and the host.
After the installation of the Remote - Containers extension you will be able to start the container by clicking on the green button in the left-down corner of VS Code windows and the selecting "Reopen in the Container" option.
This will cause all the files in the project's root directory to be shared between your host OS and the container - therefore any changes made to them on your local machine will be immediately reflected in the container.
At the same time, you will be able to run the project from the inside of the container - with the terminal launched in the VS Code window (`Terminal -> New Terminal`).

If you are not using VS Code, you can still take advantage of the virtualization and use the image provided by us - however, you will need to create the shared filesystem volume and bridge the networks on your own. Here is the command which will make this for you:
```
docker run -p 4000:4000 -it -v <path_to_cloned_templates>:/videoroom membraneframeworklabs/docker_membrane
```
where `<path_to_cloned_templates>` is the **absolute** path to the root directory of the project on your local system.

If you have just cloned the repo and your current directory is the repo's root, you can use `pwd` to get that path:
```
docker run -p 4000:4000 -it -v `pwd`:/videoroom membraneframeworklabs/docker_membrane
```

After running the command, a container terminal will be attached to your terminal. You will be able to find the project code inside the container in the `/videoroom` directory.

## What do we have here?
Let's make some reconnaissance.
First, let's run the template.
Before running the template we need to install the dependencies using:
```
mix deps.get
npm ci --prefix=assets
```

Then you can simply run the Phoenix server with the following command:
```
mix phx.server
```
If everything went well the application should be available on [http://localhost:4000](http://localhost:4000/).

Play around...but it is not that much to do! We have better inspect what is the structure of our project.
Does the project structure reassemble you the structure of a Phoenix project? (in fact, it should!). We will go through the directories in our project.
+ **assets/** <br>
You can find the front end of our application. The most interesting subdirectory here is src/ - we will be putting our typescript files there. For now, the following files should be present there:
  + **consts.ts** - as the name suggests, you will find there some constant values - media constrains and our local peer id
  + **index.ts** - this one should be empty. It will act as an initialization point for our application and later on, we will spawn a room object there.
  + **room_ui.ts** - methods which modify DOM are put there. You will find these methods helpful while implementing your room's logic - you will be able to simply call a method in order to put a next video tile among previously present video tiles and this whole process (along with rescaling or moving the tiles so they are nicely put on the screen) will be performed automatically
+ **config/** <br>
Here you can find configuration files for given environments. There is nothing we should be interested in.
+ **deps/** <br>
Once you type ```mix deps.get``` all the dependencies listed in mix.lock file will get downloaded and be put into this directory. Once again - this is just how mix works and we do not care about this directory anyhow.
+ **lib/** <br>
This directory contains the server's logic. As mentioned previously, the Phoenix server implements Model-View-Controller architecture so the structure of this directory will reflect this architecture.
The only .ex file in this directory is `videoroom_web.ex` file - it defines the aforementioned parts of the system - **controller** and **view**. Moreover,
it defines ```router``` and ```channel``` - the part of the system which is used for communication. This file is generated automatically with the Phoenix project generator
and there are not that many situations in which you should manually change it.
  + **videoroom/** <br>
  This directory contains the business logic of our application, which stands for M (model) in MVC architecture. For now, it should only contain application.ex file which defines the Application module for our video room. As each [application](https://hexdocs.pm/elixir/1.12/Application.html), it can be loaded, started, and stopped, as well as it can bring to life its own children (which constitute the environment created by an application). Later on, we will put into this directory files which will provide some logic of our application - for instance, Videoroom.Room module will be defined there.
  + **videoroom_web/**<br>
  This directory contains files that stand for V (view) and C (controller) in the MVC architecture.
  As you can see, there are already directories with names "views" and "controllers" present here. The aforementioned (tutorial) (the one available in the "helpful links" sections) describes the structure and contents of this directory in a really clear way so I don't think there is a need to repeat this description here. The only thing I would like to point out is the way in which we are loading our custom Javascript scripts. Take a look at lib/videoroom_web/room/index.html.eex file (as the Phoenix tutorial says, this file should contain an EEx template for your room controller ) - you will find the following line there:
  ```html
  <script src="<%= static_path(@conn, "/js/room.js") %>"></script>
  ```
  As you can see, we are loading a script which is placed in `/js/room.js` (notice, that a path provided there is passed in respect to priv/static/ directory which holds files generated from typescript scripts in assets/src/ directory)

+ **priv/static/** <br>
Here you will find static assets. They can be generated, for instance, from the files contained in assets/ directory (.ts which are in assets/src are converted into .js files put inside priv/static/js). Not interesting at all, despite the fact, that we needed to load /js/room.js script file from here ;)
<br><br>
[NEXT - System architecture](3_SystemArchitecture.md)<br>
[PREV - Introduction](1_Introduction)<br>
[List of contents](index.md)<br>
[List of tutorials](../../index.md)
