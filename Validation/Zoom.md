# Mixed zoom gesture validation

Base: upstream `57b8414` (4.2.0). This is a focused repair of mixed zoom gestures; no public API is added.

## Reproduction

On unchanged upstream, display a landscape image in a portrait cell, double tap to enlarge it, then pinch inward. The image cannot return to its original fitted size because the base content has been enlarged while the scroll view remains at minimum zoom.

`ZoomTests.testDoubleTapThenPinchBackToFit` reproduces this against unchanged upstream: three assertions fail (zoom scale stays 1, base size changes from 390 × 260 to 1266 × 844, and returning to minimum zoom leaves the image wider than the cell).

Baseline result: `/tmp/PhotoBrowser-Zoom-Baseline/Results.xcresult`.

## Coverage

- `ZoomTests`: real UIKit cell and animated double-tap handler; scroll-view scale/delegate calls cover the pinch state path, without claiming to synthesize a pinch gesture. Covers both orders, repeated toggles, unchanged base size, maximum limits, tall/wide images, centering, layout, rotation, reuse, and dismissal eligibility.
- `RotationUITests.testMixedZoomGestures`: actual XCTest double tap and pinch, in both orders, using default and fixed double-tap targets; repeats double tap after returning to fit and saves screenshots.
- Existing rotation state tests cover incoming cells, navigation/reload during rotation, looping, spacing, autoplay and reuse. Existing dismissal UI tests cover zoom veto, cancellation and completion.

## Local results (2026-11-13)

Xcode 27.2 (27B52). Main framework, UIKit/CocoaPods demo and SwiftUI/SwiftPM demo device builds passed with signing disabled.

On iPhone Duo / iOS 27.2: all 4 zoom state tests, 12 rotation state tests, 5 dismissal UI tests and the mixed-gesture UI test passed. Two system rotation UI checks failed because this host stayed in portrait (`preserved=-1`, no transition callback); these are recorded as failures, not passes. Mixed-gesture screenshots were inspected for final image layout; this is not a full animation review.

Result: `/tmp/PhotoBrowser-Zoom-Fixed/Results.xcresult`.

On iPhone 18 Pro / iOS 27.2: all 3 selected UI tests passed — mixed pinch/double-tap gestures, vertical paging with default double-tap zoom across rotation, and fixed double-tap zoom with rotation/autoplay recovery. This confirms the two rotation checks on a conventional iPhone host.

Result: `/tmp/PhotoBrowser-Zoom-iPhone.xcresult`.

No physical-device, iPad or older-iOS verification is claimed. Remote CI status has not been verified.

## Branch review (2026-11-13)

Additional regression tests reproduced two edge cases in the first fix:

- An aspect-fill target less than 1% above minimum triggered the old near-minimum layout path, shrinking the unscaled image bounds. The same tolerance made the next double tap zoom in again instead of resetting. Zoom completion now only recenters; double tap resets any scale above minimum.
- Replacing an image while zoomed retained the old image proportions because the image observer skipped layout above minimum. Image changes now update unscaled bounds and the corresponding scaled scroll content size, preserving zoom.

The expanded tests also check the exact uncapped fill target and reuse during an unfinished double-tap animation. Before the corrections, 2 of 8 zoom tests failed: `/tmp/PhotoBrowser-Zoom-Review/Results.xcresult`.

After the corrections, on iPhone 18 Pro / iOS 27.2, all 37 state tests (8 zoom, 12 rotation, 17 lifecycle) and 4 selected UI tests (mixed gestures, vertical paging/double-tap rotation, fixed zoom/rotation/autoplay, and zoom dismissal veto/completion) passed. Main framework, UIKit demo and SwiftUI demo device builds also passed. Result: `/tmp/PhotoBrowser-Zoom-Review/Fixed.xcresult`.

## Running

The existing `Validation/run-tests.sh` entry point includes these tests. For a focused run, generate the project using `Validation/Rotation/generate_project.rb`, then select `RotationTests/ZoomTests` and `RotationUITests/RotationUITests/testMixedZoomGestures` with `xcodebuild`. Use a conventional iPhone simulator for the system rotation tests.
