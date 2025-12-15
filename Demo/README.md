# JXPhotoBrowser

JXPhotoBrowser 是一个轻量级、高度可定制的 iOS 图片/视频浏览器，仿照 iOS 系统相册的交互体验设计。支持缩放、拖拽关闭、自定义转场动画等特性，架构清晰，易于集成和扩展。

## 🌟 核心设计亮点

- **协议驱动的数据与 UI 解耦**：`JXPhotoBrowserDelegate` 只关心数量、Cell 与转场，不再要求提供统一的数据模型，业务方可以完全使用自己的数据结构。
- **Cell 协议抽象**：通过 `JXPhotoBrowserCellProtocol` 将浏览器与具体 Cell 实现解耦，既可以直接使用内置的 `JXPhotoCell` / `JXVideoCell`，也可以实现完全自定义的 Cell。
- **图片加载可插拔**：提供 `JXPhotoBrowserImageLoader` 协议与默认实现 `JXDefaultImageLoader`，框架本身不强依赖任何第三方图片库，业务可以按需接入 Kingfisher、SDWebImage 等。
- **默认实现与深度定制兼顾**：开箱即用的默认 Cell + 转场动画 + 手势交互，同时保留足够的扩展点，适合从简单集成到复杂自定义的多种场景。

## ✨ 功能特性

- **多模式浏览**：支持水平（Horizontal）和垂直（Vertical）两个方向的滚动浏览。
- **无限循环**：支持无限循环滚动（Looping），无缝切换首尾图片。
- **手势交互**：
  - **双击缩放**：仿系统相册支持双击切换缩放模式。
  - **捏合缩放**：支持双指捏合随意缩放（1.0x - 3.0x）。
  - **拖拽关闭**：支持下滑手势（Pan）交互式关闭，伴随图片缩小和背景渐变效果。
- **转场动画**：
  - **Fade**：经典的渐隐渐现效果。
  - **Zoom**：类似微信/系统相册的缩放转场效果，无缝衔接列表与大图。
  - **None**：无动画直接显示。
- **浏览体验优化**：基于 `UICollectionView` 复用机制，内存占用低，滑动流畅，支持无限循环滑动。
- **自定义 Cell 支持**：内置图片 `JXPhotoCell` 与视频 `JXVideoCell`，也支持通过协议与注册机制接入完全自定义的 Cell。

## 🛠 技术方案

### 核心架构
- **JXPhotoBrowser**：核心控制器，继承自 `UIViewController`。内部维护一个 `UICollectionView` 用于展示图片/视频页面，负责处理全局配置（如滚动方向、循环模式）和手势交互（如下滑关闭）。
- **JXPhotoCell / JXVideoCell**：默认图片与视频展示单元，继承自 `UICollectionViewCell` 并实现 `JXPhotoBrowserCellProtocol`。内部使用 `UIScrollView` 实现缩放，负责单击、双击、长按等交互。
- **JXPhotoBrowserCellProtocol**：Cell 协议抽象，自定义 Cell 只需实现 `browser` 与 `currentIndex` 等必要属性即可接入浏览器，不强制依赖特定基类。
- **JXPhotoBrowserDelegate**：代理协议，负责提供总数、Cell 实例以及转场动画所需的源视图等，不再强制要求统一的数据模型。
- **JXPhotoBrowserImageLoader**：图片加载协议，默认实现基于系统 `URLSession` 与内存缓存，业务方可替换为任意图片加载框架。

### 关键实现
1.  **无限循环 (Infinite Loop)**:
    - 通过 `virtualCount = realCount * multiplier` 创建虚拟数据源，利用 `UICollectionView` 的复用机制实现视觉上的无限滚动。
    - 初始定位到中间位置，确保用户可以向前或向后滚动。

2.  **图片/视频缩放 (Image/Video Scaling)**:
    - **初始显示模式**：图片/视频默认采用 `scaleAspectFit` 方式显示，即长边铺满容器，短边等比例缩放，居中展示。确保图片完整可见，不会裁剪。
    - **双击切换模式**：
      - 在初始缩放状态下双击，可在两种模式间切换：
        - **长边铺满模式**（scaleAspectFit）：长边铺满容器，短边等比例缩放，居中显示。适合查看完整图片。
        - **短边铺满模式**（scaleAspectFill）：短边铺满容器，长边等比例缩放，可能裁剪部分内容。适合填充屏幕查看细节。
      - 在捏合缩放后的任意状态下双击，快速切换回初始的长边铺满模式。
    - **捏合缩放**：基于 `UIScrollView` 的 `viewForZooming` 机制，支持 1.0x - 3.0x 的连续缩放，双击可快速恢复。
    - **居中处理**：通过 `contentInset` 和 `contentOffset` 的组合使用，确保图片在任何缩放状态下都能正确居中显示。

3.  **交互式转场 (Interactive Transition)**:
    - 实现了 `UIViewControllerTransitioningDelegate` 和 `UIViewControllerAnimatedTransitioning` 协议。
    - **JXZoomPresentAnimator** / **JXZoomDismissAnimator**: 计算源视图（列表中的缩略图）和目标视图（浏览器中的大图）在屏幕坐标系下的位置，通过临时的 `UIImageView` 进行插值动画，实现平滑的缩放效果。

4.  **手势冲突处理**:
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
    
    // 2. 提供用于展示的 Cell（业务方自己管理数据和加载逻辑）
    func photoBrowser(_ browser: JXPhotoBrowser, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
        let cell = browser.collectionView.dequeueReusableCell(withReuseIdentifier: JXPhotoCell.reuseIdentifier, for: indexPath) as! JXPhotoCell
        let item = items[index]
        cell.currentResource = JXPhotoResource(imageURL: item.originalURL, thumbnailURL: item.thumbnailURL)
        return cell
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

- 框架本身依赖：`UIKit`、`AVFoundation`。
- 图片加载：通过 `JXPhotoBrowserImageLoader` 协议抽象，默认实现基于系统 `URLSession` 和内存缓存。
- 示例工程：为方便演示列表缩略图加载，Demo 中额外使用了 `Kingfisher`，但这不是框架的强制依赖。

## ⚖️ License

本项目基于 MIT 协议开源。
