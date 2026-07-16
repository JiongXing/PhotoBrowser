# JXPhotoBrowser 4.1 Usage Guide

## Programmatic Paging and Data Changes

`scrollToPage(at:animated:)` accepts a real data index. Looping mode chooses the nearest virtual destination; out-of-range requests are ignored.

```swift
browser.scrollToPage(at: 4, animated: true)
```

After changing the backing array, call:

```swift
browser.reloadData()
```

This reloads the delegate count, clamps the current page, rebuilds the looping position, refreshes overlays, and reevaluates auto play. Do not call `browser.collectionView.reloadData()` directly.

## Zooming

`JXZoomImageCell` toggles between full-image display and short-edge fill by default. To use a fixed double-tap scale:

```swift
cell.scrollView.maximumZoomScale = 5
cell.doubleTapZoomScale = 4
```

## Custom Cells

Subclass `JXZoomImageCell` to inherit all zoom and gesture behavior. When implementing the protocol directly, keep `browser` weak:

```swift
final class MediaCell: UICollectionViewCell, JXPhotoBrowserCellProtocol {
    static let reuseIdentifier = "MediaCell"
    weak var browser: JXPhotoBrowserViewController?
    let imageView = UIImageView()
    var transitionImageView: UIImageView? { imageView }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentView.addSubview(imageView)
    }
}
```

Every cell uses the browser's full-page size. Register it before dequeuing:

```swift
browser.register(MediaCell.self, forReuseIdentifier: MediaCell.reuseIdentifier)
```

## Overlays

```swift
let indicator = JXPageIndicatorOverlay()
indicator.position = .bottom(padding: 20)
indicator.hidesForSinglePage = true
browser.addOverlay(indicator)
```

The same instance is not added twice. Adding it to another browser first removes it from the previous host.

## SwiftUI

For full-screen presentation, use a Presenter retained by SwiftUI to own delegate data. For an embedded banner, use `UIViewControllerRepresentable`; after updating its coordinator in `updateUIViewController`, call `browser.reloadData()`.

Because `browser.delegate` is weak, the Presenter or Coordinator needs an external strong reference.

## Saving to the Photo Library

Saving is intentionally outside the framework. Use `.addOnly` authorization on iOS 14+ and the legacy API on iOS 12/13. On iPad, configure the ActionSheet's `popoverPresentationController.sourceView` and `sourceRect`.

## CocoaPods Sandboxing

Only consider disabling `ENABLE_USER_SCRIPT_SANDBOXING` for an affected target when the build log explicitly reports that CocoaPods Run Script access was denied by User Script Sandboxing.
