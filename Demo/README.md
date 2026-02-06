# JXPhotoBrowser

JXPhotoBrowser 是一个轻量级、可定制的 iOS 图片/视频浏览器，仿照 iOS 系统相册的交互体验设计。支持缩放、拖拽关闭、自定义转场动画等特性，架构清晰，易于集成和扩展。

## 🌟 核心设计

- **零数据模型依赖**：框架不定义任何数据模型，业务方完全使用自己的数据结构，通过 delegate 配置 Cell 内容。
- **图片加载完全开放**：框架不内置图片加载逻辑，业务方可自由选择 Kingfisher、SDWebImage 或其他任意图片加载方案。
- **极简 Cell 协议**：`JXPhotoBrowserCellProtocol` 仅包含 `browser` 和 `transitionImageView` 两个属性，将浏览器与具体 Cell 实现解耦，既可以直接使用内置的 `JXPhotoCell` / `JXVideoCell`，也可以实现完全自定义的 Cell。
- **协议驱动的数据与 UI 解耦**：`JXPhotoBrowserDelegate` 只关心数量、Cell 与转场，不强制统一的数据模型。
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
- **JXPhotoCell / JXVideoCell**：默认图片与视频展示单元，继承自 `UICollectionViewCell` 并实现 `JXPhotoBrowserCellProtocol`。内部使用 `UIScrollView` 实现缩放，负责单击、双击、长按等交互。提供 `setImage(_:)` 和 `setPlaceholder(_:)` 方法供业务方设置图片。
- **JXBasicImageCell**：轻量级图片展示 Cell，不支持缩放手势，适用于 Banner 等嵌入式场景。
- **JXPhotoBrowserCellProtocol**：极简 Cell 协议，仅需 `browser`（弱引用浏览器）和 `transitionImageView`（转场视图）两个属性即可接入浏览器，不强制依赖特定基类。
- **JXPhotoBrowserDelegate**：代理协议，负责提供总数、Cell 实例以及转场动画所需的缩略图视图等，不强制要求统一的数据模型。Zoom 转场的临时视图由框架自动构造，业务方只需提供缩略图视图即可。

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
    - **JXZoomPresentAnimator** / **JXZoomDismissAnimator**: 计算源视图（列表中的缩略图）和目标视图（浏览器中的大图）在屏幕坐标系下的位置，框架自动基于缩略图构造临时 `UIImageView` 进行插值动画，业务方无需手动创建转场视图。
    - **Zoom 动画注意事项**：为确保 Zoom 转场动画效果最佳，建议在 `cellForItemAt` 中同步设置占位图（如从缓存中取出缩略图），使 Cell 的 `imageView` 在转场时有正确的尺寸。

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
import Kingfisher // 示例使用 Kingfisher，可替换为任意图片加载库

extension ViewController: JXPhotoBrowserDelegate {
    // 1. 返回图片总数
    func numberOfItems(in browser: JXPhotoBrowser) -> Int {
        return items.count
    }
    
    // 2. 提供用于展示的 Cell，并使用业务方选择的图片加载库加载图片
    func photoBrowser(_ browser: JXPhotoBrowser, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
        let cell = browser.dequeueReusableCell(withReuseIdentifier: JXPhotoCell.reuseIdentifier, for: indexPath) as! JXPhotoCell
        let item = items[index]
        
        // 使用 Kingfisher 加载图片（可替换为 SDWebImage 或其他库）
        cell.imageView.kf.setImage(with: item.thumbnailURL) { [weak cell] result in
            if case .success(let value) = result {
                cell?.setPlaceholder(value.image)
            }
        }
        cell.imageView.kf.setImage(with: item.originalURL) { [weak cell] result in
            if case .success(let value) = result {
                cell?.setImage(value.image)
            }
        }
        return cell
    }
    
    // 3. (可选) 支持 Zoom 转场：提供列表中的缩略图视图
    //    框架会自动基于此视图构造转场动画，无需手动创建临时视图
    func photoBrowser(_ browser: JXPhotoBrowser, thumbnailViewAt index: Int) -> UIView? {
        let indexPath = IndexPath(item: index, section: 0)
        guard let cell = collectionView.cellForItem(at: indexPath) as? MyCell else { return nil }
        return cell.imageView
    }
    
    // 4. (可选) 控制缩略图显隐，避免 Zoom 转场时视觉重叠
    func photoBrowser(_ browser: JXPhotoBrowser, setThumbnailHidden hidden: Bool, at index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? MyCell {
            cell.imageView.isHidden = hidden
        }
    }
}
```

## 📄 依赖

- 框架本身依赖：`UIKit`（核心）、`AVFoundation`（仅 `JXVideoCell` 需要），**无任何第三方依赖**。
- 图片加载：框架不内置图片加载逻辑，业务方可自由选择 Kingfisher、SDWebImage 或其他任意图片加载方案。
- 示例工程：Demo 使用 `Kingfisher` 演示图片加载。

## ❓ 常见问题 (FAQ)

### Q: Zoom 转场动画时图片尺寸不对或有闪烁现象？

**A**: 这通常是因为打开浏览器时，目标 Cell 的 `imageView` 还没有设置图片，导致其 `bounds` 为 zero。

**解决方案**：在 `cellForItemAt` 代理方法中，确保同步设置占位图。例如使用 Kingfisher 时：

```swift
func photoBrowser(_ browser: JXPhotoBrowser, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
    let cell = browser.dequeueReusableCell(withReuseIdentifier: JXPhotoCell.reuseIdentifier, for: indexPath) as! JXPhotoCell
    
    // 同步从缓存取出缩略图作为占位图
    let placeholder = thumbnailURL.flatMap { ImageCache.default.retrieveImageInMemoryCache(forKey: $0.absoluteString) }
    cell.imageView.kf.setImage(with: imageURL, placeholder: placeholder) { [weak cell] result in
        if case .success(let value) = result {
            cell?.setImage(value.image)
        }
    }
    return cell
}
```

这样可以确保转场动画开始时，Cell 已经有正确尺寸的图片，动画效果更加流畅。

## ⚖️ License

本项目基于 MIT 协议开源。
