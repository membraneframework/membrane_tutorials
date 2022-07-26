In this really short chapter we will take a look at how one can play the video delivered with HLS on the website.

In our demo, we are taking advantage of the HLS.js player.
With such a tool onboard, creation of the player is simple as that:
**_`lib/rtmp_to_hls_web/templates/page/index.html.heex`_**
```js
<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>

<div class="container">
  <video id="player" controls autoplay class="Player"></video>
</div>
<script>
  var video = document.getElementById('player');
  var videoSrc = window.location.origin + `/video/index.m3u8`;
  if (Hls.isSupported()) {
    var hls = new Hls();
    hls.loadSource(videoSrc);
    hls.attachMedia(video);
  } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
    video.src = videoSrc;
  }
</script>
```

First, we load a `hls.js` script.
Then, in the DOM we add a div holding a video element of a class `Player`.
Finally, we add our custom script, which decorates the video player element with the functionalities 
provided by the `hls.js` library.
The `videoSrc` is a URL of the manifest file of the HLS playlist. As described in the previous chapter, the files from playlist are available
at `/video/<filename>`.
If the HLS is supported by the client's browser, we create an object of type `Hls` (that class is a part of the `hls.js` library), set it's source manifest file and a DOM element which acts as a video player. For more options which can be specified for the player, see the [documentation](https://github.com/video-dev/hls.js/blob/master/docs/API.md).