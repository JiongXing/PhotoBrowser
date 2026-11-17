# Mixed zoom gesture validation

Sections through “Running” document PR #244 historically. Current behavior and evidence are recorded under [Fill-based zoom and top dismissal](#fill-based-zoom-and-top-dismissal-2026-11-17).

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

## Fill-based zoom and top dismissal (2026-11-17)

The earlier sections record PR #244's original fit-based implementation and its historical zoom veto. This section records the subsequent `fill-based-zoom-dismiss` change, locally integrated from master `f725644` and PR head `7511edc` with merge commit `22004b0`.

Native `zoomScale == 1` now means aspect fill; initial complete-image display uses `minimumZoomScale = fitScale / fillScale`. The default maximum is 2. The guides document migration of native maximum and configured double-tap targets. Dismissal is admitted at touch receipt only when already at the inset-adjusted top; a drag that reaches the top must end before another pull dismisses.

New numeric fixtures first failed against the integrated PR (2 tests, 11 assertions), then passed: a 100 × 800 image in a 400 × 800 container has minimum 0.25, fill size 400 × 3200, and maximum size 800 × 6400. The panorama fixture verifies a host maximum of 4 survives layout and rotation.

Additional regressions caught and fixed an automatic-inset position jump when disabling scrolling and an image-bounds mutation on cancellation with a pre-existing image transform. The follow-finger test verifies screen displacement and exact restoration at both minimum and 2×, including image bounds/center, transform, native zoom and offset. A separate failing test reproduced a touch starting 5 points below the top reaching it before pan recognition; admission is now captured before that scroll. Deferred image replacement during dismissal is also covered.

Environment: Xcode 27.0 (27A266a), iPhone 18 Pro Max simulator, iOS 27.0 (24A434). Main framework, UIKit/CocoaPods and SwiftUI/SwiftPM device builds passed with signing disabled; no deployment-target overrides were needed. Final build logs: `/tmp/PhotoBrowser-FillZoom/{framework,uikit,swiftui}-final.log`.

The focused zoomed-top cancellation/completion UI test passed, with its screenshot inspected for 2× scale and preserved top offset: `/tmp/PhotoBrowser-FillZoom-Baseline/GreenRestore.xcresult`. Long-image width-fill/top-repull and pinch-isolation UI tests also passed. An overlapping diagnostic test invocation terminated a UI host during an earlier exploratory run; the affected scenario subsequently passed in isolation. Final suite execution is serial.

Independent read-only review covered the full master-to-working-tree change, specifications and tests. It reported no Critical/Important findings and requested the current validation record already planned here. Its delivery condition is a passing full suite and final builds.

No physical-device, iPad or older-iOS verification is claimed. No remote push, approval or merge of PR #244 was performed.

The first complete suite passed 65/67 tests. Two inherited UI inputs required migration: an implicit landscape double-tap point could land at the top (where dismissal is now allowed), and pinching a configured 2× image by 0.2 only reaches 0.4, still above the fixture's new minimum. The updated test explicitly taps the image middle and asserts non-top before scrolling; the mixed-gesture test pinches by 0.1 to reach complete fit. Both passed in a focused rerun: `/tmp/PhotoBrowser-FillZoom-Full/AdjustedGestures.xcresult`. These corrections changed test inputs, without additional production changes.

Final complete run: **67/67 passed, zero failures and zero skips** (51 state/file tests and 16 system UI tests), using `Validation/run-tests.sh /tmp/PhotoBrowser-FillZoom-Final`. Result bundle: `/tmp/PhotoBrowser-FillZoom-Final/Results.xcresult`; logs: `build.log` and `test.log` in the same directory. Mixed-gesture, long-image, cancellation and landscape-fit screenshots were inspected.

OpenSpec archive `2026-11-17-fill-based-zoom-dismiss` synchronized the image-zoom and browser-lifecycle contracts. Strict validation passed for all six main specs after archive, with no active change remaining; `git diff --check` passed. Independent review has no deferred findings.
