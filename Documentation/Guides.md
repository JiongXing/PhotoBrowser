# JXPhotoBrowser 使用指南

## 程序化翻页与动态数据

`scrollToPage(at:animated:)` 接收真实数据索引。循环模式会选择距离当前虚拟页最近的方向；越界请求会被忽略。

```swift
browser.scrollToPage(at: 4, animated: true)
```

数据数组变化后调用：

```swift
browser.reloadData()
```

框架会重新读取 delegate 数量、钳制当前页、重建循环位置、刷新 Overlay 并重新评估自动轮播。不要直接调用 `browser.collectionView.reloadData()`。

### Zoom 缩略图恢复

4.2.0 修复了浏览器包裹在 `UINavigationController` 中时的缩略图恢复：宿主动画或无动画关闭导航容器后恢复原状态；另一个全屏页面临时遮挡浏览器时继续保持缩略图隐藏，返回后仍可翻页和正常关闭。

浏览器保存隐藏前的缩略图视图和 `isHidden`，在换页、刷新及关闭（含无动画关闭）时恢复。旧的 `setThumbnailHidden` 接口继续可用；恢复回调仅在索引有效且仍对应原视图时调用，避免旧索引访问新数据。

自定义 alpha 或容器显隐且数据可能更新时，实现 `thumbnailRestorationAt`。框架会在隐藏前取得闭包，并在恢复时调用一次，替代 `setThumbnailHidden(false)`。闭包应捕获原始对象和状态，不能再按旧索引查找数据，也不要强持有浏览器：

```swift
func photoBrowser(_ browser: JXPhotoBrowserViewController, thumbnailRestorationAt index: Int) -> (() -> Void)? {
    guard let view = photoBrowser(browser, thumbnailViewAt: index) else { return nil }
    let alpha = view.alpha
    return { [weak view] in view?.alpha = alpha }
}
```

## 缩放

`JXZoomImageCell` 的捏合与双击共用原生 `scrollView.zoomScale`，以图片等比例铺满容器（aspect fill）为 **1 倍**。初始完整显示的倍率为 `minimumZoomScale`，由图片和容器比例计算，可小于 1。默认最大倍率为 **2**，布局和旋转不会覆盖宿主设置的上限。

例如，100 × 800 图片在 400 × 800 容器中：完整显示为 0.25 倍（100 × 800），双击到 1 倍铺满（400 × 3200），最大 2 倍（800 × 6400）。极长、极宽图片也可在默认配置下双击铺满。

默认双击从完整显示放大到 1 倍，已放大时双击回到完整显示；捏合可在最小、最大倍率之间连续缩放。指定双击目标仍以铺满为基准，并受滚动视图的缩放范围约束：

```swift
cell.scrollView.maximumZoomScale = 5
cell.doubleTapZoomScale = 4
```

迁移注意：`doubleTapZoomScale` 和 `maximumZoomScale` 以前相对完整适配尺寸，现在相对铺满尺寸。检测完整显示应将 `zoomScale` 与 `minimumZoomScale` 比较，不再假定初始倍率为 1。图片的未变换 bounds 表示铺满基础尺寸；需要屏幕中的实际显示尺寸时，使用视图坐标转换。

## 自定义 Cell

继承 `JXZoomImageCell` 可复用全部缩放和手势行为。直接实现协议时，`browser` 必须为弱引用：

```swift
final class MediaCell: UICollectionViewCell, JXPhotoBrowserCellProtocol {
    static let reuseIdentifier = "MediaCell"
    weak var browser: JXPhotoBrowserViewController?
    let imageView = UIImageView()
    var transitionImageView: UIImageView? { imageView }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentView.addSubview(imageView)
    }
}
```

所有 Cell 都使用浏览器整页尺寸。注册后在 delegate 中 dequeue：

```swift
browser.register(MediaCell.self, forReuseIdentifier: MediaCell.reuseIdentifier)
```

`canBeginDismissInteraction` 默认返回 `true`。自定义 Cell 可返回 `false` 阻止下拉，例如正在编辑；在 `photoBrowserDismissInteractionDidChange` 内暂停并恢复自己的滚动容器。

内置 `JXZoomImageCell` 在图片到顶后允许单指向下关闭，放大状态也适用；双指捏合不触发关闭。手势开始时若未到顶，本次只滚动图片，即使途中到顶也需松手后重新下拉才关闭。顶部判断考虑实际内容边距；取消关闭后恢复原倍率、偏移和滚动/裁剪配置。纵向分页继续禁用下拉关闭。

下拉及回弹期间自动轮播暂停，回弹结束后按当前显示、数据和尺寸转场状态恢复。刷新、有效跳页和尺寸变化会先结束旧下拉交互。

## Overlay

```swift
let indicator = JXPageIndicatorOverlay()
indicator.position = .bottom(padding: 20)
indicator.hidesForSinglePage = true
browser.addOverlay(indicator)
```

同一实例不会重复添加；添加到另一个浏览器时会先从旧宿主移除。

## SwiftUI

全屏展示可由一个被 SwiftUI 强引用的 Presenter 创建并持有 delegate 数据。内嵌 Banner 推荐使用 `UIViewControllerRepresentable`，在 `updateUIViewController` 中更新 coordinator 后调用 `browser.reloadData()`。

由于 `browser.delegate` 为弱引用，Presenter 或 Coordinator 必须有外部强引用。

## 保存到相册

框架不内置保存能力。最低支持 iOS 15，保存图片和视频统一使用 `.addOnly` 权限。ActionSheet 在 iPad 上必须设置 `popoverPresentationController.sourceView` 和 `sourceRect`。

UIKit 示例的 `VideoSaveService` 共用视频保存流程：在下载回调返回前接管临时文件，保存完成或失败后清理下载副本；调用方提供的本地文件始终保留，UI/Cell 释放不影响文件清理。工具不属于发布库。

## CocoaPods 沙盒问题

仅在构建日志明确显示 CocoaPods Run Script 被 User Script Sandboxing 拒绝访问时，才针对受影响 Target 评估关闭 `ENABLE_USER_SCRIPT_SANDBOXING`。
