# Migrating from 4.0 to 4.1

## Custom Item Sizing Was Removed

`JXPhotoBrowserDelegate.photoBrowser(_:sizeForItemAt:)` was removed. Every 4.1 cell uses the browser's full-page size so paging, looping indexes, and spacing share one geometry model.

## Use the Browser Reload API

Replace:

```swift
browser.collectionView.reloadData()
```

with:

```swift
browser.reloadData()
```

To return to `initialIndex` after reloading:

```swift
browser.reloadData(preservingCurrentPage: false)
```

## Embedded Usage

Banner integrations must use view-controller containment and set:

```swift
browser.isDismissGestureEnabled = false
```

Adding only `browser.view` as a subview is no longer a supported integration.

## Auto Play

The minimum `autoPlayInterval` is 0.5 seconds. Changing it at runtime reschedules the timer, which starts only after initial positioning while the browser is visible.
