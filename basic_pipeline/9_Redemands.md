Redemanding is a very convenient mechanism which helps you, the Membrane Developer, stick to the DRY (Don't Repeat Yourself) rule.
Generally speaking, it can be used in two situations:
+ in the source elements
+ in the filter elements

To comprehensively understand the concept behind redemanding, you need to be aware of the typical control flow which occurs in the Membrane's elements - which you could have seen in the elements we have already defined. 

# In Source elements
In the source elements, there is a "side channel", from which we can receive data. That "side channel" can be, as in the exemplary pipeline we are working on, in form of a file, from which we are reading the data. In real-life scenarios it could be also, i.e., a RTP stream received via the network. Since we have that "side channel", there is no need to receive data via the input pad (that is why we have the source element, isn't it?).
The whole logic can be put inside the `handle_demand/5` callback - once we are asked to provide the buffers, the `handle_demand/5` callback gets called and we can provide the desired number of buffers from the "side channel", inside the body of that callback. No processing occurs here - we get asked for the buffer and we provide the buffer, simple as that.
The redemand mechanism here lets you focus on providing a single buffer in the `handle_demand/5` body - later on you can simply return the `:redemand` action and that action will invoke the `handle_demand/5` once again, with the updated number of buffers which are expected to be provided. Let's see it in an example - we could have such a `handle_demand/5` definition (and it wouldn't be a mistake!):
```Elixir
@impl true
def handle_demand(:input, size, unit, context, state) do
    buffers = for x <- 1..size do
        payload = Input.get_next() #Input.get_next() is an exemplary function which could be providing data
        %Membrane.Buffer(payload: payload)
    end
    
end
```

As you can see in the snippet above, we need to generate the required `size` of buffers in the single `handle_demand/5` run. The logic of supplying the demand there is quite easy - but what if you would also need to check if there is enough data to provide a sufficient number of buffer? You would need to check it in advance (or try to read as much data as possible before supplying the desired number of buffers). And what if an exception occurs during the generation, before supplying all the buffers?
You would need to take under the consideration all these situations and your code would become larger and larger.


Wouldn't it be better to focus on a single buffer in each `handle_demand/5` call - and let the Membrane Framework automatically update the demand's size? This can be done in the following way:
```Elixir
@impl true
def handle_demand(:input, size, unit, context, state) when size>0 do
    payload = Input.get_next() #Input.get_next() is an exemplary function which could be providing data
    actions = [buffer: %Membrane.Buffer(payload: payload)]
    {{:ok, actions}, state}
end

def handle_demand(:input, size, unit, context, state), do: {:ok, state}
```


# In Filter elements