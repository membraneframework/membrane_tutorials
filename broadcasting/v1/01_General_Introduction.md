We are glad you have decided to continue your journey into the oceans of multimedia with us!
In this tutorial, you will be able to see the Membrane in action - as we will prepare a pipeline responsible for converting
the incoming RTMP stream into an HLS stream, ready to be easily served on the internet.
Later on, we will substitute the front part of our pipeline, so that to make it compatible with another popular streaming protocol - RTSP.
That is how we will try to prove the great dose of flexibility that comes with the use of the Membrane Framework!

## General tutorial's structure
As mentioned earlier, the tutorial consists of two parts:
* "RTMP to HLS" - this part describes how to create a pipeline capable of receiving RTMP stream, muxing it into CMAF files, and serving them with the use of HTTP
* "RTSP to HLS" - this part is based on the previous one and describes how to change the pipeline from the previous part so that to make it capable of handling the RTSP stream instead of the RTMP stream.

As a result of each part, you will have a web application capable of playing media streamed with the use of the appropriate protocols - RTMP and RTSP.

We strongly encourage you to follow the tutorial part by part, as the different chapters are tightly coupled. However, in case you wanted just to see the result solutions or even one of them, we invite you to take a look at the appropriate directories of the `membrane_demo` repository:
* [RTMP to HLS](https://github.com/membraneframework/membrane_demo/tree/master/rtmp_to_hls)
* [RTSP to HLS](https://github.com/membraneframework/membrane_demo/tree/master/rtsp_to_hls)