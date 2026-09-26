# Proposal

## Why

PR #241 已修正旋转后的页面定位方向，但旧转场完成回调仍会覆盖旋转期间的 reloadData / scrollToPage 结果；开始时可见 Cell 的快照也遗漏后续出现的 Cell。接手该 PR，补齐状态协调与可重现的回归证据。

## What Changes

- 尺寸改变时保留旧布局中的居中页，程序化滚动中则保留目标页；更新的数据或导航优先。
- 在整个尺寸转场期间暂停自动轮播，完成后按最新状态恢复。
- 让新进入的图片 Cell 在布局前参与尺寸转场，结束及复用时清理状态。
- 增加针对刷新、导航、循环、缩放和旋转的验证，并定位 SwiftUI CI 构建失败。
- 不改变默认屏幕方向策略，不要求保留旋转前的缩放倍数，不增加业务数据模型或依赖。

## Capabilities

### New Capabilities

- `size-transition`: 图片浏览器尺寸转场中的页面、Cell 几何和轮播一致性。

### Modified Capabilities

无。

## Impact

主要涉及 `Sources/JXPhotoBrowserViewController.swift` 和 `Sources/JXZoomImageCell.swift`；保留作者新增的 Cell 转场方法。验证主框架、UIKit/CocoaPods 示例、SwiftUI/SwiftPM 示例及模拟器交互。只有复现出具体集成配置问题时才修改相应配置。
