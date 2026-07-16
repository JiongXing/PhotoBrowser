# JXPhotoBrowser

[![CocoaPods](https://img.shields.io/cocoapods/v/JXPhotoBrowser.svg)](https://cocoapods.org/pods/JXPhotoBrowser) [![SPM Supported](https://img.shields.io/badge/SPM-supported-brightgreen)](https://swift.org/package-manager/) [![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage) [![License](https://img.shields.io/github/license/JiongXing/PhotoBrowser)](LICENSE)

[中文文档](README.md)

JXPhotoBrowser is a lightweight, customizable iOS photo/video browser. Its UIKit and `UICollectionView` core supports zooming, drag-to-dismiss, looping, auto play, Zoom/Fade transitions, and custom cells without imposing a data model or image-loading library.

| Home List | Photo Browsing | Pull Down to Close |
| :---: | :---: | :---: |
| ![Home List](readme_assets/homepage.png) | ![Photo Browsing](readme_assets/browsing.png) | ![Pull Down](readme_assets/pull_down.png) |

## Features

- UIKit core with a SwiftUI bridging path
- Horizontal/vertical full-page browsing and infinite looping
- Double-tap and pinch zoom, including a fixed double-tap scale
- Drag-to-dismiss and Zoom/Fade/None transitions
- Programmatic paging, auto play, and page spacing
- Custom cell and overlay extension points
- CocoaPods, SwiftPM, and Carthage distribution
- iOS 12.0+ and Swift 5.4+

## Installation

### CocoaPods

```ruby
pod 'JXPhotoBrowser', '~> 4.1'
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/JiongXing/PhotoBrowser", from: "4.1.0")
]
```

### Carthage

```text
github "JiongXing/PhotoBrowser" ~> 4.1
```

```bash
carthage update --use-xcframeworks --platform iOS
```

All three integrations include `PrivacyInfo.xcprivacy`. The framework does not track users, collect data, or use Required Reason APIs.

## Quick Start

```swift
import JXPhotoBrowser

let browser = JXPhotoBrowserViewController()
browser.delegate = self
browser.initialIndex = indexPath.item
browser.transitionType = .zoom
browser.isLoopingEnabled = true
browser.addOverlay(JXPageIndicatorOverlay())
browser.present(from: self)
```

```swift
extension ViewController: JXPhotoBrowserDelegate {
    func numberOfItems(in browser: JXPhotoBrowserViewController) -> Int {
        items.count
    }

    func photoBrowser(
        _ browser: JXPhotoBrowserViewController,
        cellForItemAt index: Int,
        at indexPath: IndexPath
    ) -> JXPhotoBrowserAnyCell {
        browser.dequeueReusableCell(
            withReuseIdentifier: JXZoomImageCell.reuseIdentifier,
            for: indexPath
        )
    }

    func photoBrowser(
        _ browser: JXPhotoBrowserViewController,
        willDisplay cell: JXPhotoBrowserAnyCell,
        at index: Int
    ) {
        guard let cell = cell as? JXZoomImageCell else { return }
        // Set cell.imageView.image with your image-loading library.
    }

    func photoBrowser(
        _ browser: JXPhotoBrowserViewController,
        thumbnailViewAt index: Int
    ) -> UIView? {
        let indexPath = IndexPath(item: index, section: 0)
        return collectionView.cellForItem(at: indexPath)?.contentView
    }
}
```

Reload changed data through the browser instead of its internal collection view:

```swift
browser.reloadData()                              // Preserve and clamp the current page.
browser.reloadData(preservingCurrentPage: false) // Return to initialIndex.
```

## Embedded Banner

Embedded usage requires standard view-controller containment and must disable drag-to-dismiss:

```swift
let browser = JXPhotoBrowserViewController()
browser.delegate = self
browser.transitionType = .none
browser.isDismissGestureEnabled = false
browser.autoPlayInterval = 3
browser.isAutoPlayEnabled = true

addChild(browser)
containerView.addSubview(browser.view)
// Add constraints for browser.view.
browser.didMove(toParent: self)
```

When removing it, call `willMove(toParent: nil)`, remove the view, then call `removeFromParent()`.

## Documentation

- [Detailed usage guide](Documentation/Guides_EN.md)
- [4.0 → 4.1 migration guide](Documentation/Migration-4.1_EN.md)
- [Technical design (Chinese)](TECHNICAL_SOLUTION.md)
- [Change log](CHANGELOG.md)

## Known Limitations

- The browser is portrait-only and does not support device rotation.
- Drag-to-dismiss is unavailable in vertical scrolling mode.
- Every cell uses the browser's full-page size; per-item custom sizing was removed in 4.1.

## CocoaPods Troubleshooting

If Xcode User Script Sandboxing produces an explicit sandbox access error in CocoaPods resource-copy or framework-embedding scripts, evaluate setting `ENABLE_USER_SCRIPT_SANDBOXING` to `NO` for the affected target. Do not change it when no such error exists.

## License

MIT License
