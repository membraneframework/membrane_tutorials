We assume that you have followed the first tutorial and have the Elixir environment already installed. 
In case this is not happening, you can simply refer to the [second chapter of the aforementioned tutorial]() and learn how to prepare an Elixir environment needed for the development as well as find out what is the structure of a Phoenix directory.

## Template downloading
Just as in the first part of the tutorial, we have equipped you with a template of the application. 
With the use of it you will be able to focus only on the most important and hopefully most interesting parts
of the system! 
Here is how you can get your template:
```bash
git clone https://github.com/membraneframework/membrane_webrtc_to_hls_tutorial
```

Then you can change directory to the freshly cloned repository and switch to the branch which provides the unfulfilled template:

```bash
cd membrane_webrtc_to_hls_tutorial
git checkout template/start
```

The suggested implementation provided by us is available on the `template/end` branch of this repository.

# Install native dependencies
Here is how you install native dependencies:
## Mac OS X
```
brew install srtp libnice clang-format ffmpeg opus fdk-aac
```

If you have followed the first part of the tutorial, most of these dependencies should already be installed on your computer.
# Running the application
 We need to install project dependencies using:
 ```
 mix deps.get
 npm ci --prefix=assets
 ```

 Then you can simply run the Phoenix server with the following command:
 ```
 mix phx.server
 ```
 If everything went well the application should be available on [http://localhost:4000](http://localhost:4000/).