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

### Restoring Zoom Thumbnails

The browser retains the original thumbnail identity and `isHidden` value for restoration on paging, reload, and dismissal, including nonanimated dismissal. The existing `setThumbnailHidden` callback remains supported; restoration only calls it when the index is valid and still refers to the original view.

If custom visibility uses alpha or a container and the data can change, implement `thumbnailRestorationAt`. The browser obtains the closure before hiding and invokes it once instead of `setThumbnailHidden(false)`. Capture the original object and state, without looking up an old index or strongly capturing the browser:

```swift
func photoBrowser(_ browser: JXPhotoBrowserViewController, thumbnailRestorationAt index: Int) -> (() -> Void)? {
    guard let view = photoBrowser(browser, thumbnailViewAt: index) else { return nil }
    let alpha = view.alpha
    return { [weak view] in view?.alpha = alpha }
}
```

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

`canBeginDismissInteraction` defaults to `true`. A custom cell can return `false` while zoomed or editing, and suspend/restore its own scrolling in `photoBrowserDismissInteractionDidChange`. `JXZoomImageCell` already handles zoom/top-edge eligibility and preserves its original scrolling and clipping settings.

Auto play pauses throughout dismiss dragging and rebound, then resumes when visibility, data, and size-transition state allow. Reload, valid navigation, and size changes first end the old dismiss interaction.

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

Saving is intentionally outside the framework. With iOS 15 as the minimum, use `.addOnly` authorization for saving images and videos. On iPad, configure the ActionSheet's `popoverPresentationController.sourceView` and `sourceRect`.

The UIKit demo shares `VideoSaveService` for video saving. It takes ownership of downloaded files before the download callback returns and removes its copy after success or failure. Caller-owned local files are preserved, and cleanup does not depend on the cell or UI surviving. This helper is not part of the published library.

## CocoaPods Sandboxing

Only consider disabling `ENABLE_USER_SCRIPT_SANDBOXING` for an affected target when the build log explicitly reports that CocoaPods Run Script access was denied by User Script Sandboxing.
