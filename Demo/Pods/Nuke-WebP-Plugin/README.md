# Nuke-WebP-Plugin

[![CI Status](http://img.shields.io/travis/ryokosuge/Nuke-WebP-Plugin.svg?style=flat)](https://travis-ci.org/ryokosuge/Nuke-WebP-Plugin)
[![codecov](https://codecov.io/gh/ryokosuge/Nuke-WebP-Plugin/branch/master/graph/badge.svg)](https://codecov.io/gh/ryokosuge/Nuke-WebP-Plugin)
![Version](https://img.shields.io/cocoapods/v/Nuke-WebP-Plugin.svg?label=version)
![Supoprts](https://img.shields.io/badge/supports-CocoaPods%20%7C%20Carthage-green.svg)
![Platform](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)

WebP for Nuke that allows you to load and display WebP image. You can see it for yourself in a demo, included in the project.

## Usage

The plugin features a pre-configured Nuke.Manager with WebP support, and an WebPImage:

```swift
import Nuke
import NukeWebPPlugin

WebPImageDecoder.enable()

let imageView = UIImageView()
let webpimageURL = URL(string: "https://example.com/sample.webp")!
Nuke.loadImage(with: url, into: imageView)
```

## Installation

### [CocoaPods](https://cocoapods.org/)

```ruby
pod 'Nuke-WebP-Plugin'
```

### [Carthage](https://github.com/Carthage/Carthage)

```ruby
github 'ryokosuge/Nuke-WebP-Plugin'
```

## Requirements

- iOS 9+ / macOS 10.10+ / tvOS 9.0+
- Xcode9.3 / Xcode9.2
- Swift4.1 / Swift4

## Dependencies

- [Nuke >= 7.0](https://github.com/kean/Nuke)
- [libwebp = 0.6.1](https://chromium.googlesource.com/webm/libwebp)

## Author

ryokosuge, ryo.kosuge@gmail.com

## License

Nuke-WebP-Plugin is available under the MIT license. See the LICENSE file for more info.
