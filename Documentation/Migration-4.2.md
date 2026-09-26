# 从 4.1 迁移到 4.2

## 系统与依赖

4.2 将库最低系统从 iOS 12.0 提升到 iOS 15.0。请同步提高宿主的 deployment target；如果仍需支持 iOS 12–14，请固定使用 `4.1.0`，不要使用允许升级至 4.2+ 的版本范围。

```ruby
platform :ios, '15.0'
pod 'JXPhotoBrowser', '~> 4.2'
```

SwiftPM 使用 `from: "4.2.0"`。库仍无第三方依赖，Swift tools 声明仍为 5.4。UIKit / SwiftUI 示例使用 Kingfisher 8.13.0，需要 Xcode 26+；SwiftUI 示例最低 iOS 16.0，不代表库要求 iOS 16。

## 自定义 Cell 与委托

新增协议要求均提供默认实现，已有实现无需仅为满足协议而补充方法：

- `canBeginDismissInteraction` 默认返回 `true`；自定义媒体可根据缩放、滚动或编辑状态禁止下拉。
- `thumbnailRestorationAt` 默认返回 `nil`；使用自定义 alpha / 容器显隐且数据可能替换时，应返回捕获原始视图和状态的恢复闭包。详见[使用指南](Guides.md#zoom-缩略图恢复)。

`photoBrowserDismissInteractionDidChange(false)` 现在也会在交互被中断和关闭后的清理中调用。自定义 Cell 应恢复交互前的状态，不要将该回调仅理解为用户取消关闭，也不要依赖关闭后不回调的旧行为。

## 尺寸变化

默认浏览器仍固定竖屏。允许旋转的子类或发生尺寸变化的容器中，拖拽/减速保留最近页，程序化滚动保留目标页。尺寸转场期间的刷新或有效跳页更新最终目标，`scrollToPage(animated: true)` 此时即时选中目标，由尺寸转场统一定位。

## 导航容器关闭修复

4.2.0 已修复浏览器包裹在 `UINavigationController` 中时，宿主关闭整个导航容器后缩略图仍隐藏的问题，覆盖动画和无动画关闭。另一个全屏页面临时遮挡后返回会保留浏览状态和恢复责任，不会被当作退出。无需新增宿主回调。

从 4.0 或更早版本升级时，还需阅读 [4.0 → 4.1 迁移指南](Migration-4.1.md)。
