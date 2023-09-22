# Flow Control

Once we have linked the elements together, there comes a moment when they can start sending buffers through the pads. However, how to control the flow of buffers between elements?

Membrane solves this problem using its own backpressure mechanism and demands.

## Types of `flow_control`

When defining a pad od an element, you can pass one of 3 values in the `flow_control` field: `auto`, `push`, or `manual`. They determine how the backpressure mechanism works on the pad they relate to.

- Input pad with `flow_control: :push` - an element with such a pad must always be ready to receive a new buffer on that pad. The output pad linked with such an input pad must also have `flow control` set to `:push`. It is not advised to use `flow_control: :push` in input pads, as it makes them prone to overflow.

- Output pad with `flow_control: :push` - the element decides for itself when to send how many buffers via a given pad.

- Input pad with `flow_control: :manual` - the element directly, using the `demand` action, requests how much data it wants to receive from this pad. Membrane guarantees that more data will never come to the input pad than was demanded.

- Output pad with `flow_control: :manual` - the element gets the information, through the `c:Membrane.Element.WithOutputPads.handle_demand/5` callback, how much data a specific output pad needs. An element having an output pad with `flow_control: :manual` is obligated to satisfy the demand on it.

- Input pad with `flow_control: :auto` - unlike in manual demands, the element doesn't have to directly specify the demand value on the input pad to receive buffers on it. In `:auto` `flow control`, the framework will manage the demand value itself. In the case of Sources and Endpoints, it will make sure that the demand on the input pad is positive as long as the number of buffers waiting for processing in the mailbox is not too large. In the case of filters, Membrane will take care of a positive demand under one additional condition - the demand value on all output pads with `flow_control: :auto` of this element must also be positive.

- Output pad with `flow_control: :auto` - an auto output pad does not require from the element to implement the `handle_demand` callback. The demand value on this pad only matters when the framework itself calculates the value of the auto demand on the input pads. The only type of Membrane Element that can have output pads with `flow_control: :auto` is a `Membrane.Filter`. 

`flow_control: :manual` is useful in cases, when element wants to get a specific amount of data on each pad (e.g. to satisfy demand on 1 buffer on pad `:output`, element need 1 buffer from pad `:input_a`, 10 buffers from pad `:input_b` and 100 bytes from pad `:input_c`). Comparing to `flow_control: :auto`, `flow_control: :manual` can solve a broader class of problems, but, on the other hand, it requires more code in your element and is less performant.

`flow_control: :auto` is the best solution, when you want to provide a backpressure mechanism, but your element has only one input pad or it doesn't care about the proportion of the amount of data incoming on each input pad. A good example might be a pipeline made of filters linked one after the other, with a sink or a source on each end. In such a case, using `flow_control: :auto` in filters would ensure, that the pipeline would adapt its processing pace to the slowest element, without the necessity to implement `c:Membrane.Element.WithOutputPads.handle_demand/5` in every element. Additionally, the whole pipeline will be faster, because of the lack of performance overhead caused by `flow_control: :manual`.

## Linking pads with different `flow_control`

Two pads with the same type of `flow_control` can always be linked together. `flow_control: auto` can also always be linked with `flow_control: manual`. However, the situation becomes complicated when we try to link two pads with different types of `flow_control`, where one of them has `flow_control: push`.

When the input pad has `flow_control: push`, the output pad linked to it must also have `flow_control: push`. An attempt to link different type of an output pad will cause an error to be thrown.

Output pads with `flow_control: push` can be linked with input pads having `flow control` `:auto` or `:manual`. The demand value on such an input pad does not affect the behavior of the element with the push output pad.

When an element with a push output pad sends amount of data, that exceeds demands on the input pad, when input pad `flow_control` is: 
- `manual`, these buffers will wait in line until the element raises the demand on its input by returning the `demand` action.
- `auto`, these buffers will be processed, and the demand value on the input pad will drop below zero.

```elixir
get_child(:mixer)
|> via_in(:input, toilet_capacity: 500)
|> get_child(:sink)
```