# Proposal

## Why

PR #244 修复了双击和捏合使用不同缩放状态的问题，但以完整适配尺寸为基准并统一限制最大倍率，会让长图默认双击后无法铺满。采用铺满容器作为 1 倍，并允许图片在顶部开始下拉关闭，使长图阅读和混合缩放手势保持一致。

## What Changes

- 保留 PR #244 的提交与原作者信息，在当前 master 的独立分支上完善。
- **BREAKING**：`scrollView.zoomScale`、`maximumZoomScale` 和 `doubleTapZoomScale` 统一以 aspect-fill 尺寸为基准；默认最大倍率从 3 改为 2。完整适配的 `minimumZoomScale` 由图片和容器比例计算，可小于 1。
- 初始、旋转和复用恢复完整显示；默认双击在完整显示和 1 倍铺满之间切换，指定目标受宿主最大倍率约束，捏合可返回完整显示。
- **BREAKING**：内置图片 Cell 不再因放大而一律拒绝下拉；单指向下手势开始时图片已在顶部即可进入关闭。一次滚动到顶后需松手，再次下拉才关闭。
- 放大和缩小状态下关闭均跟手；取消后保留倍率、滚动偏移、图片几何和既有滚动配置。

## Capabilities

### New Capabilities

- `image-zoom`：铺满基准倍率、双击和捏合互通、图片替换与几何恢复。

### Modified Capabilities

- `browser-lifecycle`：顶部下拉准入、单指手势隔离、不同缩放状态的跟手与取消恢复。

## Impact

- 影响 `Sources/JXZoomImageCell.swift`、`Sources/JXPhotoBrowserViewController.swift`，以及 UIKit 视频子类、指南和行为验证宿主。
- 不新增依赖，不修改发布版本，不推送、发布或直接合并到远端 master，不操作原 PR 分支。
- 通过主库、UIKit/CocoaPods 和 SwiftUI/SwiftPM 构建，以及状态与系统手势回归验证；无真机或所有 iOS 版本覆盖承诺。
