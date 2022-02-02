# Introduction
In this tutorial, we will create our very own Membrane Framework [pipeline]() consisting of our custom [elements]() which will fulfill the multimedia processing task.
Despite the fact that the multimedia processing task we will be facing will be really simple, we will need to deal with some problems occurring in real-life scenarios.
At the same time, we will make ourselves comfortable with some concepts of multimedia streaming as well as get in touch with the nomenclature used in this field. 
Prepare for an adventure! 
# Environment preparation
In order to be able to proceed with the tutorial, you need to have Elixir installed: [How to install Elixir](https://elixir-lang.org/install.html).

Once you are ready with the Elixir, you can get the project template we have prepared for you:
```
git clone https:/github.com/membraneframework/membrane_getting_started_tutorial
cd membrane_getting_started_tutorial
git checkout template/start
```
As you can see, the template's code is put on the `template/start` branch of the repository.
In the repository, there is also a `template/end` branch, where you can find the fulfilled template.
If you find yourself lost during the tutorial feel free to check the implementation proposed by us, put on this branch.

# Use Case
Imagine that there is a conversation occurring between two peers and the chat is based on a question-answer scheme.
Each of the peers sends its part of the conversation (that means - the first peer sends questions and the second peers sends the answers to them).
However, due to network limitations text sent by each of the peers is fragmented since only a few chars can be sent at the same time - that means, each word is sent in a form of a packet. 
Each packet consists of the *header* (describing where the particular word it transports should be put) and the *body* - aforementioned single word.
## Packet format
Here is what each packet looks like:
```
[seq:<sequence_id>][frameid:<frame_id>][timestamp:<timestamp>]<text>
```
where:
+ sequence_id - the ordering number of the packet (relative to each of the peers). Based on this number we will be able to assemble the particular frame.
+ frame_id - the identifier which consists of the number of the frame to which the body of a given packet belongs, optionally followed by a single character **'s'** (meaning that this packet is a **s**tarting packet of a frame) or by **'e'** character (meaning that the packet is the **e**nding packet of the frame). Note that frames are numbered relatively to each peer in that conversation and that frame_id does not describe the global order of the frames in the final file.
+ timestamp - a number indicating where the given frame should be put in the final file. Timestamp describes the order of the frames from both peers. 
+ text - the proper body of the packet, in our case - a single word.

## Packets generator
We have equipped you with the tool which produces the packets in the format described previously, based on the input conversation. In the template, you will be able to find a 
`InputFilesGenerator` module (placed in `lib/InputFilesGenerator.ex` file). You can access its functionalities by typing the following command in the projects directory:
```
iex -S mix
```
which will launch the interactive Elixir shell with projects modules loaded.
Once you are in the shell, you can type the following command:
```
InputFilesGenerator.generate(<input_file_path>, "result_files_prefix")
```
where: 
+ *input_file_path* is a path to the file which contains the text of the conversation
+ *result_files_prefix* is a prefix of a path of the files which will contain the result packets

Based on the input file content, that command will create two files, `<result_files_prefix>1.txt` and `<result_files_prefix>2.txt`.
The first file will contain the shuffled list of packets made from the odd lines from the input file and the second file will contain a shuffled list of packets made out of the even lines of the input file. That `shuffle` is a way to simulate the imperfectness of the network - in real-life scenario, the order in which the packets are received is not always the same as the order in which they were sent.
# Task description
Your task is to assemble the conversation together - that means, at first you need to reproduce the sentences sent by each of the peers (that means - you need to gather the words sent in packets in the appropriate order). In multimedia processing, we would say that you need to reproduce the *frame* out of the *transport layer packets*. Later on, you need to put those *frames* in the correct order, producing the *raw data stream*.
The resulting file should be the same as the input file from which you have created two packets list with the use of the `InputFilesGenerator`.