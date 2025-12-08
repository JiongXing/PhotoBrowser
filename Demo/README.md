# JXPhotoBrowser

JXPhotoBrowser 是一个轻量级、高度可定制的 iOS 图片浏览器，仿照 iOS 系统相册的交互体验设计。支持缩放、拖拽关闭、自定义转场动画等特性，架构清晰，易于集成和扩展。

## ✨ 功能特性

- **多模式浏览**：支持水平（Horizontal）和垂直（Vertical）两个方向的滚动浏览。
- **无限循环**：支持无限循环滚动（Looping），无缝切换首尾图片。
- **手势交互**：
  - **双击缩放**：支持双击放大/恢复。
  - **捏合缩放**：支持双指捏合随意缩放。
  - **拖拽关闭**：支持下滑手势（Pan）交互式关闭，伴随图片缩小和背景渐变效果。
- **转场动画**：
  - **Fade**：经典的渐隐渐现效果。
  - **Zoom**：类似微信/系统相册的缩放转场效果，无缝衔接列表与大图。
  - **None**：无动画直接显示。
- **高性能**：基于 `UICollectionView` 复用机制，内存占用低，滑动流畅。
- **网络图片**：内置 `Kingfisher` 支持，自动处理图片加载、缓存和占位图。

## 🛠 技术方案

### 核心架构
- **JXPhotoBrowser**: 核心控制器，继承自 `UIViewController`。内部维护一个 `UICollectionView` 用于展示图片页面。负责处理全局配置（如滚动方向、循环模式）和手势交互（如下滑关闭）。
- **JXPhotoCell**: 图片展示单元，继承自 `UICollectionViewCell`。内部嵌套 `UIScrollView` 实现图片的缩放功能。负责处理单击、双击手势以及图片加载逻辑。
- **JXPhotoBrowserDelegate**: 代理协议，解耦数据源和 UI 逻辑。负责提供图片资源、转场动画所需的源视图等。

### 关键实现
1.  **无限循环 (Infinite Loop)**:
    - 通过 `virtualCount = realCount * multiplier` 创建虚拟数据源，利用 `UICollectionView` 的复用机制实现视觉上的无限滚动。
    - 初始定位到中间位置，确保用户可以向前或向后滚动。

2.  **交互式转场 (Interactive Transition)**:
    - 实现了 `UIViewControllerTransitioningDelegate` 和 `UIViewControllerAnimatedTransitioning` 协议。
    - **JXZoomPresentAnimator** / **JXZoomDismissAnimator**: 计算源视图（列表中的缩略图）和目标视图（浏览器中的大图）在屏幕坐标系下的位置，通过临时的 `UIImageView` 进行插值动画，实现平滑的缩放效果。

3.  **手势冲突处理**:
    - 在 `JXPhotoCell` 中处理 `UITapGestureRecognizer`（单击/双击）与 `UIScrollView` 内置手势的冲突。
    - 在 `JXPhotoBrowser` 中处理下滑关闭的 `UIPanGestureRecognizer` 与 `UICollectionView` 滚动手势的共存与互斥逻辑。

## 📦 安装

### CocoaPods
在你的 `Podfile` 中添加：

```ruby
pod 'JXPhotoBrowser'
```

### 手动安装
将 `JXPhotoBrowser/Sources` 目录下的所有文件拖入你的工程中。

## 🚀 快速开始

### 基础用法

```swift
import JXPhotoBrowser

// 1. 创建浏览器实例
let browser = JXPhotoBrowser()
browser.delegate = self
browser.initialIndex = indexPath.item // 设置初始索引

// 2. 配置选项（可选）
browser.scrollDirection = .horizontal // 滚动方向
browser.transitionType = .zoom        // 转场动画类型
browser.isLoopingEnabled = true       // 是否开启无限循环

// 3. 展示
browser.present(from: self)
```

### 实现 Delegate

遵守 `JXPhotoBrowserDelegate` 协议，提供数据和转场支持：

```swift
extension ViewController: JXPhotoBrowserDelegate {
    // 1. 返回图片总数
    func numberOfItems(in browser: JXPhotoBrowser) -> Int {
        return items.count
    }
    
    // 2. 提供图片资源（原图 URL + 缩略图 URL）
    func photoBrowser(_ browser: JXPhotoBrowser, resourceForItemAt index: Int) -> JXPhotoResource? {
        let item = items[index]
        return JXPhotoResource(imageURL: item.originalURL, thumbnailURL: item.thumbnailURL)
    }
    
    // 3. (可选) 支持 Zoom 转场：提供列表界面的源视图
    func photoBrowser(_ browser: JXPhotoBrowser, zoomOriginViewAt index: Int) -> UIView? {
        let indexPath = IndexPath(item: index, section: 0)
        guard let cell = collectionView.cellForItem(at: indexPath) as? MyCell else { return nil }
        return cell.imageView
    }
    
    // 4. (可选) 支持 Zoom 转场：提供临时的转场视图
    func photoBrowser(_ browser: JXPhotoBrowser, zoomViewForItemAt index: Int, isPresenting: Bool) -> UIView? {
        let indexPath = IndexPath(item: index, section: 0)
        guard let cell = collectionView.cellForItem(at: indexPath) as? MyCell else { return nil }
        guard let image = cell.imageView.image else { return nil }
        
        let iv = UIImageView(image: image)
        iv.contentMode = cell.imageView.contentMode
        iv.clipsToBounds = true
        return iv
    }
}
```

## 📄 依赖

- **Kingfisher**: 用于图片的异步加载和缓存。

## ⚖️ License

本项目基于 MIT 协议开源。
