# JXPhotoBrowser 4.1 使用指南

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

## 缩放

`JXZoomImageCell` 默认在完整显示与短边铺满之间切换。固定倍率模式：

```swift
cell.scrollView.maximumZoomScale = 5
cell.doubleTapZoomScale = 4
```

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

框架不内置保存能力。iOS 14+ 使用 `.addOnly` 权限；iOS 12/13 使用旧授权接口。ActionSheet 在 iPad 上必须设置 `popoverPresentationController.sourceView` 和 `sourceRect`。

## CocoaPods 沙盒问题

仅在构建日志明确显示 CocoaPods Run Script 被 User Script Sandboxing 拒绝访问时，才针对受影响 Target 评估关闭 `ENABLE_USER_SCRIPT_SANDBOXING`。
