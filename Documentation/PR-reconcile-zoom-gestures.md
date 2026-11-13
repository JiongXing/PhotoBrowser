# PR title

fix: reconcile double-tap and pinch zoom

# PR description

Default double tap previously enlarged the base content frame while leaving `UIScrollView.zoomScale` at its minimum. Pinching inward could therefore not restore the original fitted image. Mixing pinch and double tap could also switch between different base sizes.

This change keeps one aspect-fit base size and uses `UIScrollView` zooming for both gestures:

- Double tap from the fitted state zooms toward aspect fill, or to the configured `doubleTapZoomScale`, around the tapped point.
- Pinch can zoom back out after double tap, and double tap returns a pinched image to the fitted state.
- Default and configured double-tap targets respect `maximumZoomScale`. Very wide or tall images may need a higher maximum to reach aspect fill; the default maximum remains 3.
- Rotation and cell reuse continue to reset zoom. Removing the separate frame animation also avoids an independent completion callback changing later layout.

Regression coverage includes both gesture orders with default and configured zoom, repeated toggles, zoom limits, portrait/panorama images, layout, rotation, reuse, and dismissal eligibility. The UI host measures the rendered image rectangle so its fit assertions include scroll-view zoom transforms.

Validation with Xcode 27.2 / iOS 27.2 simulators:

- The new regression fails on unchanged upstream and passes with this fix.
- 4 zoom state tests and 12 existing rotation state tests pass; 5 existing dismissal UI tests pass.
- Real mixed-gesture tests pass on iPhone Duo and iPhone 18 Pro. Vertical paging/double-tap rotation and fixed zoom/rotation/autoplay tests pass on iPhone 18 Pro.
- Main framework, UIKit/CocoaPods demo and SwiftUI/SwiftPM demo builds pass.

The Duo host stayed in portrait in two rotation UI tests; those failures and the successful conventional-iPhone rerun are documented in `Validation/Zoom.md`. Physical devices, iPad and older iOS versions have not been verified. CI still needs to run.
