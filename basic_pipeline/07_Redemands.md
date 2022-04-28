# Redemands
Redemanding is a very convenient mechanism that helps you, the Membrane Developer, stick to the DRY (Don't Repeat Yourself) rule.
Generally speaking, it can be used in two situations:
+ in the source elements
+ in the filter elements

To comprehensively understand the concept behind redemanding, you need to be aware of the typical control flow which occurs in the Membrane's elements - which you could have seen in the elements we have already defined. 

## In Source elements
In the source elements, there is a "side-channel", from which we can receive data. That "side-channel" can be, as in the exemplary pipeline we are working on, in form of a file, from which we are reading the data. In real-life scenarios it could be also, i.e. an RTP stream received via the network. Since we have that "side-channel", there is no need to receive data via the input pad (that is why we don't have it in the source element, do we?).
The whole logic of fetching the data can be put inside the `handle_demand/5` callback - once we are asked to provide the buffers, the `handle_demand/5` callback gets called and we can provide the desired number of buffers from the "side-channel", inside the body of that callback. No processing occurs here - we get asked for the buffer and we provide the buffer, simple as that.
The redemand mechanism here lets you focus on providing a single buffer in the `handle_demand/5` body - later on, you can simply return the `:redemand` action and that action will invoke the `handle_demand/5` once again, with the updated number of buffers which are expected to be provided. Let's see it in an example - we could have such a `handle_demand/5` definition (and it wouldn't be a mistake!):
```Elixir
@impl true
def handle_demand(:output, size, _unit, _context, state) do
 actions = for x <- 1..size do
   payload = Input.get_next() #Input.get_next() is an exemplary function which could be providing data
   {:buffer, %Membrane.Buffer(payload: payload)}
 end
 { {:ok, actions}, state}
end
```

As you can see in the snippet above, we need to generate the required `size` of buffers in the single `handle_demand/5` run. The logic of supplying the demand there is quite easy - but what if you would also need to check if there is enough data to provide a sufficient number of buffer? You would need to check it in advance (or try to read as much data as possible before supplying the desired number of buffers). And what if an exception occurs during the generation, before supplying all the buffers?
You would need to take under the consideration all these situations and your code would become larger and larger.


Wouldn't it be better to focus on a single buffer in each `handle_demand/5` call - and let the Membrane Framework automatically update the demand's size? This can be done in the following way:
```Elixir
@impl true
def handle_demand(:output, _size, unit, context, state) do
 payload = Input.get_next() #Input.get_next() is an exemplary function which could be providing data
 actions = [buffer: %Membrane.Buffer(payload: payload), redemand: :output]
 { {:ok, actions}, state}
end

```


## In Filter elements
In the filter element, the situation is quite different. 
Since the filter's responsibility is to process the data sent via the input pads and transmit it through the output pads, there is no 'side-channel' from which we could take data. That is why in normal circumstances you would transmit the buffer through the output pad in the `handle_process/4` callback (which means - once your element receives a buffer, you process it, and then you 'mark' it as ready to be output with the `:buffer` action). When it comes to the `handle_demand/5` action on the output pad, all you need to do is to demand the appropriate number of buffers on the element's input pad. The behavior which is easy to specify when we exactly know how many input buffers correspond to the one output buffer (recall the situation in the Depayloader of our pipeline, where we *a priori* knew, that each output buffer (frame) consists of a given number of input buffers (packets), becomes impossible to define if the output buffer might be a combination of a discretionary set number of input buffers. However, we have dealt with an unknown number of required buffers in the OrderingBuffer implementation, where we didn't know how many input buffers do we need to demand to fulfill the missing spaces between the packets ordered in the list. How did we manage to do it?
We simply used the `:redemand` action! In case there was a missing space between the packets, we returned the `:redemand` action, which immediately called the `handle_demand/5` callback (implemented in a way to request for a buffer on the input pad). The fact, that that callback invocation was immediate, which means - the callback was called synchronously, right after returning from the `handle_process/4` callback, before processing any other message from the element's mailbox - might be crucial in some situations, since it makes us sure, that the demand will be done before handling any other event.
Recall the situation in the Mixer, where we were producing the output buffers right in the `handle_demand/5` callback. We needed to attempt to create the output buffer after:
+ updating the buffers' list in the `handle_process/4`
+ updating the status of the track in the `handle_end_of_stream/3`
Therefore, we were simply returning the `:redemand` action, and the `handle_demand/5` was called sequentially after on, trying to produce the output buffer.

As you can see, redemand mechanism in filters helps us deal with situations, where we do not know how many input buffers to demand in order to be able to produce an output buffer/buffers.

With that knowledge let's carry on with the next element in our pipeline - `Depayloader`.