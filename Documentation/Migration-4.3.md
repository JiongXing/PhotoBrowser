# 从 4.2 迁移到 4.3

4.3 保持 iOS 15.0+、Swift tools 5.4 和零第三方依赖，现有委托无需补充实现。需要检查宿主对缩放倍率和下拉准入的假设。

## 安装

```ruby
pod 'JXPhotoBrowser', '~> 4.3'
```

SwiftPM 使用 `from: "4.3.0"`，Carthage 可指定 `github "JiongXing/PhotoBrowser" ~> 4.3`。示例的系统和工具要求见 [README](../README.md)。

## 倍率基准

| 项目 | 4.2 | 4.3 |
| --- | --- | --- |
| 原生 1 倍 | 完整适配（aspect fit） | 等比例铺满（aspect fill） |
| 初始完整显示 | 最小倍率 1 | 最小倍率为 fit/fill，可小于 1 |
| 默认最大倍率 | 3，相对适配尺寸 | 2，相对铺满尺寸 |
| 默认双击 | 切换基础图片尺寸 | 从 minimum 到 1；已放大则回 minimum |
| 指定双击倍率 | 相对适配尺寸 | 相对铺满尺寸，钳制到最小/最大范围 |

例如 100 × 800 的图片放在 400 × 800 容器中，初始最小倍率为 0.25，显示 100 × 800；1 倍为 400 × 3200，默认最大 2 倍为 800 × 6400。最大倍率数值变小不代表最大显示尺寸变小，长图的默认放大上限可能高于旧版。

请将“完整显示”的 `zoomScale == 1` 判断改为与 `minimumZoomScale` 比较，并考虑浮点误差。主动还原时使用：

```swift
cell.scrollView.setZoomScale(cell.scrollView.minimumZoomScale, animated: true)
```

`doubleTapZoomScale` 与 `scrollView.maximumZoomScale` 直接采用新基准，已有固定数值需重新确认。如果希望保留旧的适配尺寸相对倍率 k，在图片及容器完成布局后，目标原生倍率为 `k * minimumZoomScale`；图片比例或容器尺寸变化后需要重新计算。默认双击目标为 1；图像比例与容器完全一致时，完整显示已经等于铺满，可显式配置目标 2 来获得双击放大。

```swift
cell.scrollView.maximumZoomScale = 4
cell.doubleTapZoomScale = 2
```

双击与捏合现在使用同一个 `UIScrollView` 缩放状态，可互相继续或还原。旋转、复用恢复完整显示；图片替换会更新比例，并保留受新范围约束的放大倍率及有效偏移。未变换的图片 bounds 表示铺满基础尺寸，获取屏幕显示尺寸应使用视图坐标转换。

## 顶部下拉关闭

内置图片 Cell 不再因放大而拒绝下拉。手指按下时已在顶部（按实际 adjusted inset 判断），单指明显向下即可进入关闭；从图片中部滚到顶的同一次触摸不会接管为关闭，须松手后再次下拉。取消保留原倍率、浏览位置及滚动配置。

双指捏合和纵向分页不会进入下拉关闭。自定义 Cell 仍可用 `canBeginDismissInteraction` 拒绝；需关闭整个浏览器的下拉功能时设置 `isDismissGestureEnabled = false`。重写准入的子类若调用 `super`，应检查其新的顶部语义。

## 容器尺寸

整页 Cell 统一以当前浏览器 `view.bounds` 计算，移除了视图尚无尺寸时的全局屏幕兜底。内嵌浏览器仍需正确设置 containment 与约束；默认浏览器仍固定竖屏。

更早版本升级还需阅读 [4.1 → 4.2](Migration-4.2.md) 和 [4.0 → 4.1](Migration-4.1.md) 迁移指南。
