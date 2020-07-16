# Core Image by Example

#### A hands-on approach for getting to know all things Apple's Core Image framework can do

This repository will showcases and explains how Apple's Core Image framework can be used for image and video processing. The goal is to explain all basic and advanced concepts in detail as well as providing concisely documented example code  for all use cases.

**⚠️ Note**:
This is very much work in progress. Right now, the project only covers the following topics:
* getting live video frames from the camera
* applying a built-in filter to those frames
* render the result using Core Image and Metal on the screen in real-time
* integration with SwiftUI

If you have any suggestions what I should cover here, please let me know via [Twitter](https://twitter.com/frankschlegel) or by creating an issue. 🙂

Please also note that I'm very much new to SwiftUI and I'm also using this project to learn more about it and how `AVFoundation` and Core Image can integrate with it. If something could be improved on this end, please also let me know! 


## What is Core Image?

Let me quote the documentation here:

>Core Image is an image processing and analysis technology that provides high-performance processing for still and video images. Use the many built-in image filters to process images and build complex effects by chaining filters. [...] 
>
>You can also create new effects with custom filters and image processors. […]

In other words, if you need to do any image or video processing, like applying filters or transformations, on an Apple platform, Core Image is the framework of choice. It provides a high-level abstraction so you can easily leverage the power of the GPU and multi-core processing without needing to know details about OpenGL, Metal, or Grand Central Dispatch<sup>[1](#footnote1)</sup>.



## Why this Repository?

Core Image is a very powerful framework, but unfortunately, it receives little attention from Apple at the moment: the [Core Image Filter Reference](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html#//apple_ref/doc/uid/TP40004346) and the [Core Image Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_intro/ci_intro.html#//apple_ref/doc/uid/TP30001185) received their last updates in 2016 (the latter is even in the Archives now). All example code is still written in Objective-C. The "new" way to write custom filters in Metal<sup>[2](#footnote2)</sup> is only really mentioned in WWDC sessions.

I think Core Image is a really cool framework, but I also see a lot of confusion when it comes to using it in practice. That's why I decided to write down the knowledge I acquired while using it in the last couple of years alongside with up-to-date demo code. I hope it will provide you with a better understanding of the framework so that you can write awesome apps for all of us! 🙂

… And also to nudge Apple and show them that there are still people out there who care about image and video processing on their platform. 😏



## License

Core Image by Example is available under the MIT license. See the LICENSE file for more info.



<a name="footnote1">1</a>: Though you can also get quite low in the stack when you want to write your own filter or custom image processor.\
<a name="footnote2">2</a>: Available since 2017.

