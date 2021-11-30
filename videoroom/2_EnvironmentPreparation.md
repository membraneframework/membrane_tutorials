# Getting started

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
# What do we have here?
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

 Play around...but it is not that match to do! We have better inspect what is the structure of our project.
 Does the project structure reassemble you the structure of a Phoenix project? (in fact, it should!). We will go through the directories in our project.
 + <b> assets/ </b> <br>
 You can find the front end of our application. The most interesting subdirectory here is src/ - we will be putting our typescript files there. For now, the following files should be present there: 
 + <b> consts.ts </b> - as the name suggests, you will find there some constant values - media constrains and our local peer id
 + <b> index.ts </b> - this one should be empty. It will act as an initialization point for our application and later on, we will spawn a room object there.
 + <b> room_ui.ts </b> - methods which modify DOM are put there. You will find these methods helpful while implementing your room's logic - you will be able to simply call a method in order to put a next video tile among previously present video tiles and this whole process (along with rescaling or moving the tiles so they are nicely put on the screen) will be performed automatically
 + <b> config/ </b> <br>
 Here you can find configuration files for given environments. There is nothing we should be interested in.
 + <b> deps/ </b> <br>
 Once you type ```mix deps.get``` all the dependencies listed in mix.lock file will get downloaded and be put into this directory. Once again - this is just how mix works and we do not care about this directory anyhow.
 + <b> lib/ </b> <br>
 This directory contains the server's logic. As mentioned previously, the Phoenix server implements Model-View-Controller architecture so the structure of this directory will reflect this architecture. 
 The only .ex file in this directory is `videoroom_web.ex` file - it defines the aforementioned parts of the system - **controller** and **view**. Moreover, 
 it defines ```router``` and ```channel``` - the part of the system which is used for communication. This file is generated automatically with the Phoenix project generator
 and there are not that many situations in which you should manually change it.
 + <b> videoroom/ </b> <br>
 This directory contains the business logic of our application, which stands for M (model) in MVC architecture. For now, it should only contain application.ex file which defines the Application module for our video room. As each [application](https://hexdocs.pm/elixir/1.12/Application.html), it can be loaded, started, and stopped, as well as it can bring to life its own children (which constitute the environment created by an application). Later on, we will put into this directory files which will provide some logic of our application - for instance, Videoroom.Room module will be defined there.
 + <b> videoroom_web/ </b> <br>
 This directory contains files that stand for V (view) and C (controller) in the MVC architecture.
 As you can see, there are already directories with names "views" and "controllers" present here. The aforementioned (tutorial) (the one available in the "helpful links" sections) describes the structure and contents of this directory in a really clear way so I don't think there is a need to repeat this description here. The only thing I would like to point out is the way in which we are loading our custom Javascript scripts. Take a look at lib/videoroom_web/room/index.html.eex file (as the Phoenix tutorial says, this file should contain an EEx template for your room controller ) - you will find the following line there:
 ```html
 <script src="<%= static_path(@conn, "/js/room.js") %>"></script>
 ```
 As you can see, we are loading a script which is placed in `/js/room.js` (notice, that a path provided there is passed in respect to priv/static/ directory which holds files generated from typescript scripts in assets/src/ directory)

 + <b> priv/static/ </b> <br>
 Here you will find static assets. They can be generated, for instance, from the files contained in assets/ directory (.ts which are in assets/src are converted into .js files put inside priv/static/js). Not interesting at all, despite the fact, that we needed to load /js/room.js script file from here ;)
 