# KingfisherWebP

[![CI Status](http://img.shields.io/travis/Yeatse/KingfisherWebP.svg?style=flat)](https://travis-ci.org/Yeatse/KingfisherWebP)
[![Version](https://img.shields.io/cocoapods/v/KingfisherWebP.svg?style=flat)](http://cocoapods.org/pods/KingfisherWebP)
[![License](https://img.shields.io/cocoapods/l/KingfisherWebP.svg?style=flat)](http://cocoapods.org/pods/KingfisherWebP)
[![Platform](https://img.shields.io/cocoapods/p/KingfisherWebP.svg?style=flat)](http://cocoapods.org/pods/KingfisherWebP)

# Description

KingfisherWebP is an extension of the popular library [Kingfisher](https://github.com/onevcat/Kingfisher), providing an ImageProcessor and CacheSerializer for you to conveniently handle the [WebP format](https://developers.google.com/speed/webp/).

The library works seamlessly with `Kingfisher`. To display the webp images from network, simply add `WebPProcessor` and `WebPSerializer` to your `KingfisherOptionsInfo`:

```swift
let url = URL(string: "url_of_your_webp_image")
imageView.kf.setImage(with: url, options: [.processor(WebPProcessor.default), .cacheSerializer(WebPSerializer.default)])
```

For convenience, you may set it as a global default option to all `KingfisherManager` related methods:

```swift
// somewhere after your application launches...
KingfisherManager.shared.defaultOptions = [.processor(WebPProcessor.default), .cacheSerializer(WebPSerializer.default)]

// You can now use webp in Kingfisher like any other format
imageView.kf.setImage(with: url)
```

If the image data is not in webp format, the default processor and serializer in `Kingfisher` will be used.


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

iOS 8 or above

## Installation

KingfisherWebP is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "KingfisherWebP"
```

## Author

Yang Chao, iyeatse@gmail.com

## License

KingfisherWebP is available under the MIT license. See the LICENSE file for more info.
