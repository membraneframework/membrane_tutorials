# Bins

Bins, similarly to pipelines, are containers for elements. However, at the same time, they can be placed and linked within pipelines. Although a bin is a separate Membrane entity, it can be perceived as a pipeline within an element. Bins can also be nested within one another, though we don't recommend too much nesting, as it may end up hard to maintain. For an example of a bin, have a look at the [RTMP source bin](https://github.com/membraneframework/membrane_rtmp_plugin/blob/master/lib/membrane_rtmp_plugin/rtmp/source/bin.ex) or [HTTP adaptive stream sink bin](https://github.com/membraneframework/membrane_http_adaptive_stream_plugin/blob/master/lib/membrane_http_adaptive_stream/sink_bin.ex).

The main use cases for a bin are:
- creating reusable element groups,
- encapsulating children's management logic, for instance, dynamically spawning or replacing elements as the stream changes.

## Bin's pads

Bin's pads are defined and linked similarly to element's pads. However, their role is limited to proxy the stream to other elements and bins inside (inputs) or outside (outputs). To achieve that, each input pad of a bin needs to be linked to both an output pad from the outside of a bin and an input pad of its child inside. Accordingly, each bin's output should be linked to output inside and input outside of the bin.

## Bin and the stream

Although the bin passes the stream through its pads, it does not access it directly, so callbacks such as `handle_process` or `handle_event` are not found there. This is because the responsibility of the bin is to manage its children, not to process the stream. Whatever the bin needs to know about the stream, it should get through notifications from the children.

## Bin as a black box

Bins are designed to take as much responsibility for their children as possible so that pipelines (or parent bins) don't have to depend on bins' internals. That's why notifications from the children are sent to their direct parents only. Also, messages received by a bin or pipeline can be forwarded only to its direct children.
