# Migrating from 4.2 to 4.3

4.3 retains iOS 15.0+, Swift tools 5.4 and zero third-party dependencies. Existing delegates require no additional implementation. Review assumptions about native zoom scales and dismissal eligibility.

## Installation

```ruby
pod 'JXPhotoBrowser', '~> 4.3'
```

Use `from: "4.3.0"` with SwiftPM, or `github "JiongXing/PhotoBrowser" ~> 4.3` with Carthage. Demo OS and tool requirements are listed in the [README](../README_EN.md).

## Zoom scale basis

| Setting | 4.2 | 4.3 |
| --- | --- | --- |
| Native 1× | Aspect fit | Aspect fill |
| Initial full-image display | Minimum 1 | Minimum fit/fill, potentially below 1 |
| Default maximum | 3, relative to fit | 2, relative to fill |
| Default double tap | Changes the base image size | Minimum to 1; enlarged images return to minimum |
| Configured double-tap target | Relative to fit | Relative to fill, clamped to the minimum/maximum range |

A 100 × 800 image in a 400 × 800 container starts at minimum 0.25, displaying 100 × 800. At 1× it displays 400 × 3200; the default maximum of 2× displays 800 × 6400. A lower numerical maximum does not imply a smaller displayed image; tall images may enlarge further than before by default.

Replace full-image checks against `zoomScale == 1` with comparisons against `minimumZoomScale`, allowing for floating-point error. To reset explicitly:

```swift
cell.scrollView.setZoomScale(cell.scrollView.minimumZoomScale, animated: true)
```

Both `doubleTapZoomScale` and `scrollView.maximumZoomScale` use the new basis; review existing fixed values. To retain an old fit-relative multiplier k, the native target is `k * minimumZoomScale` after the image and container have been laid out. Recalculate when image proportions or container dimensions change. The default double-tap target is 1; if the image exactly matches the container's aspect ratio, fit already equals fill. Configure a target of 2 to enlarge on double tap in that case.

```swift
cell.scrollView.maximumZoomScale = 4
cell.doubleTapZoomScale = 2
```

Double tap and pinch now share the same native scroll-view zoom state and can continue or undo each other. Rotation and reuse restore complete fit. Image replacement updates proportions while preserving the multiplier and offset within the new limits. Untransformed image bounds describe the fill base; use view coordinate conversion for displayed dimensions.

## Dismissal from the top

The built-in image cell allows dismissal while enlarged. A single-finger downward drag can begin dismissal if the image is at the inset-adjusted top when the touch starts. A drag starting in the middle remains an image scroll even after reaching the top; lift and pull again to dismiss. Cancellation preserves zoom, browsing position and scroll configuration.

Pinches and vertical paging do not dismiss. Custom cells can still reject through `canBeginDismissInteraction`; use `isDismissGestureEnabled = false` to disable browser dismissal. Subclasses that call `super` for admission should account for its new top-edge semantics.

## Container geometry

Full-page cells use the browser's current `view.bounds`, without falling back to global screen dimensions before layout. Embedded browsers still need correct containment and constraints. The default orientation remains portrait.

For earlier releases, also read the [4.1 → 4.2](Migration-4.2_EN.md) and [4.0 → 4.1](Migration-4.1_EN.md) migration guides.
