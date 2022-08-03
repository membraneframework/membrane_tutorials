# Architecture

Now let's discuss how the architecture of our solution will look like.

The main component of the transcoder will be the pipeline, in which the RTP stream will be converted into an HLS.
That will take place only after the RTSP connection has been set up.