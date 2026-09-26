# Migrating from 4.1 to 4.2

## Platform and Dependencies

4.2 raises the library's minimum deployment target from iOS 12.0 to iOS 15.0. Update your app's deployment target accordingly. Apps that still support iOS 12–14 should pin `4.1.0` rather than allowing an upgrade to 4.2+.

```ruby
platform :ios, '15.0'
pod 'JXPhotoBrowser', '~> 4.2'
```

Use `from: "4.2.0"` with SwiftPM. The library remains free of third-party dependencies and retains its Swift tools 5.4 declaration. The UIKit / SwiftUI demos use Kingfisher 8.13.0 and require Xcode 26+. The SwiftUI demo requires iOS 16.0; the library itself requires iOS 15.0.

## Custom Cells and Delegates

New protocol requirements have default implementations, so existing conformances do not need extra methods just to compile:

- `canBeginDismissInteraction` defaults to `true`. Custom media cells can reject dismissal based on zoom, scrolling, or editing state.
- `thumbnailRestorationAt` defaults to `nil`. When custom alpha or container visibility can outlive data replacement, return a closure capturing the original view and state. See the [usage guide](Guides_EN.md#restoring-zoom-thumbnails).

`photoBrowserDismissInteractionDidChange(false)` is now also called when an interaction is interrupted or cleaned up after dismissal. Restore the cell's prior state; do not treat this callback solely as cancellation or rely on its previous absence after dismissal.

## Size Transitions

The default browser remains portrait-only. In rotating subclasses or resizing containers, dragging/deceleration preserves the nearest page, while programmatic scrolling preserves its destination. Reloads and valid navigation during a size transition update the final destination. During that transition, `scrollToPage(animated: true)` selects the target immediately and lets the size transition handle alignment.

## Navigation Container Dismissal Fix

4.2.0 fixes thumbnails remaining hidden after the host dismisses a `UINavigationController` wrapping the browser, with or without animation. A temporary full-screen cover preserves browsing state and restoration responsibility when returning; it is not treated as an exit. No additional host callback is required.

When upgrading from 4.0 or earlier, also read the [4.0 → 4.1 migration guide](Migration-4.1_EN.md).
