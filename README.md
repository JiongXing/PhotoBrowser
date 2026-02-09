# JXPhotoBrowser

JXPhotoBrowser 是一个轻量级、可定制的 iOS 图片/视频浏览器，实现 iOS 系统相册的交互体验。支持缩放、拖拽关闭、自定义转场动画等特性，架构清晰，易于集成和扩展。

## 核心设计

- **零数据模型依赖**：框架不定义任何数据模型，业务方完全使用自己的数据结构，通过 delegate 配置 Cell 内容。
- **图片加载完全开放**：框架不内置图片加载逻辑，业务方可自由选择 Kingfisher、SDWebImage 或其他任意图片加载方案。
- **极简 Cell 协议**：`JXPhotoBrowserCellProtocol` 仅包含 `browser` 和 `transitionImageView` 两个属性，将浏览器与具体 Cell 实现解耦，既可以直接使用内置的 `JXZoomImageCell`，也可以实现完全自定义的 Cell。
- **协议驱动的数据与 UI 解耦**：`JXPhotoBrowserDelegate` 只关心数量、Cell 与转场，不强制统一的数据模型。

## 功能特性

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
- **浏览体验优化**：基于 `UICollectionView` 复用机制，内存占用低，滑动流畅。
- **自定义 Cell 支持**：内置图片 `JXZoomImageCell`，也支持通过协议与注册机制接入完全自定义的 Cell（如视频播放 Cell）。
- **Overlay 组件机制**：支持按需装载附加 UI 组件（如页码指示器、关闭按钮等），默认不装载任何组件，零开销。内置 `JXPageIndicatorOverlay` 页码指示器。

## 核心架构

- **JXPhotoBrowser**：核心控制器，继承自 `UIViewController`。内部维护一个 `UICollectionView` 用于展示图片页面，负责处理全局配置（如滚动方向、循环模式）和手势交互（如下滑关闭）。
- **JXZoomImageCell**：可缩放图片展示单元，继承自 `UICollectionViewCell` 并实现 `JXPhotoBrowserCellProtocol`。内部使用 `UIScrollView` 实现缩放，负责单击、双击等交互。通过 `imageView` 属性供业务方设置图片。
- **JXImageCell**：轻量级图片展示 Cell，不支持缩放手势，适用于 Banner 等嵌入式场景。内置可选的加载指示器（默认不启用），支持样式定制。
- **JXPhotoBrowserCellProtocol**：极简 Cell 协议，仅需 `browser`（弱引用浏览器）和 `transitionImageView`（转场视图）两个属性即可接入浏览器，另提供 `photoBrowserDismissInteractionDidChange` 可选方法响应下拉关闭交互，不强制依赖特定基类。
- **JXPhotoBrowserDelegate**：代理协议，负责提供总数、Cell 实例、生命周期回调（`willDisplay`/`didEndDisplaying`）以及转场动画所需的缩略图视图等，不强制要求统一的数据模型。
- **JXPhotoBrowserOverlay**：附加视图组件协议，定义了 `setup`、`reloadData`、`didChangedPageIndex` 三个方法，用于页码指示器、关闭按钮等附加 UI 的统一接入。
- **JXPageIndicatorOverlay**：内置页码指示器组件，基于 `UIPageControl`，支持自定义位置和样式，通过 `addOverlay` 按需装载。

## 系统要求

- iOS 11.0+
- Swift 5.0+

## 安装

### CocoaPods

在你的 `Podfile` 中添加：

```ruby
pod 'JXPhotoBrowser'
```

### 手动安装

将 `Sources` 目录下的所有文件拖入你的工程中。

## 快速开始

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
    
    // 2. 提供用于展示的 Cell
    func photoBrowser(_ browser: JXPhotoBrowser, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
        let cell = browser.dequeueReusableCell(withReuseIdentifier: JXZoomImageCell.reuseIdentifier, for: indexPath) as! JXZoomImageCell
        return cell
    }
    
    // 3. 当 Cell 将要显示时加载图片
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoBrowserAnyCell, at index: Int) {
        guard let photoCell = cell as? JXZoomImageCell else { return }
        let item = items[index]
        
        // 使用 Kingfisher 加载图片（可替换为 SDWebImage 或其他库）
        let placeholder = ImageCache.default.retrieveImageInMemoryCache(forKey: item.thumbnailURL.absoluteString)
        photoCell.imageView.kf.setImage(with: item.originalURL, placeholder: placeholder) { [weak photoCell] _ in
            photoCell?.setNeedsLayout()
        }
    }
    
    // 4. (可选) Cell 结束显示时清理资源（如取消加载、停止播放等）
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoBrowserAnyCell, at index: Int) {
        // 可用于取消图片加载、停止视频播放等
    }
    
    // 5. (可选) 支持 Zoom 转场：提供列表中的缩略图视图
    func photoBrowser(_ browser: JXPhotoBrowser, thumbnailViewAt index: Int) -> UIView? {
        let indexPath = IndexPath(item: index, section: 0)
        guard let cell = collectionView.cellForItem(at: indexPath) as? MyCell else { return nil }
        return cell.imageView
    }
    
    // 6. (可选) 控制缩略图显隐，避免 Zoom 转场时视觉重叠
    func photoBrowser(_ browser: JXPhotoBrowser, setThumbnailHidden hidden: Bool, at index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? MyCell {
            cell.imageView.isHidden = hidden
        }
    }
    
    // 7. (可选) 自定义 Cell 尺寸，默认使用浏览器全屏尺寸
    func photoBrowser(_ browser: JXPhotoBrowser, sizeForItemAt index: Int) -> CGSize? {
        return nil // 返回 nil 使用默认尺寸
    }
}
```

## JXImageCell 加载指示器

`JXImageCell` 内置了一个 `UIActivityIndicatorView` 加载指示器，**默认不启用**。适用于 Banner 等嵌入式场景下展示图片加载状态。

### 启用加载指示器

```swift
let cell = browser.dequeueReusableCell(withReuseIdentifier: JXImageCell.reuseIdentifier, for: indexPath) as! JXImageCell

// 启用加载指示器
cell.isLoadingIndicatorEnabled = true
cell.startLoading()

// 图片加载完成后停止
cell.imageView.kf.setImage(with: imageURL) { [weak cell] _ in
    cell?.stopLoading()
}
```

### 自定义样式

通过 `loadingIndicator` 属性可直接定制指示器的外观：

```swift
cell.loadingIndicator.style = .large       // 指示器尺寸
cell.loadingIndicator.color = .systemBlue  // 指示器颜色
```

## 自定义 Cell

框架支持两种方式创建自定义 Cell：

### 方式一：继承 JXZoomImageCell（推荐）

继承 `JXZoomImageCell` 可自动获得缩放、转场、手势等功能。以 Demo 中的 `VideoPlayerCell` 为例，它继承 `JXZoomImageCell` 并添加了视频播放能力：

```swift
class VideoPlayerCell: JXZoomImageCell {
    static let videoReuseIdentifier = "VideoPlayerCell"
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 自定义初始化：添加 loading 指示器等
    }
    
    /// 配置视频资源
    func configure(videoURL: URL, coverImage: UIImage? = nil) {
        imageView.image = coverImage
        // 创建播放器并开始播放...
    }
    
    /// 重写单击手势：暂停视频或关闭浏览器
    override func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        if isPlaying {
            pauseVideo()
        } else {
            browser?.dismissSelf()
        }
    }
}
```

### 方式二：实现协议（完全自定义）

直接实现 `JXPhotoBrowserCellProtocol` 协议，获得完全的自由度：

```swift
class StandaloneCell: UICollectionViewCell, JXPhotoBrowserCellProtocol {
    static let reuseIdentifier = "StandaloneCell"
    
    // 必须实现：弱引用浏览器（避免循环引用）
    weak var browser: JXPhotoBrowser?
    
    // 可选实现：用于 Zoom 转场动画，返回 nil 则使用 Fade 动画
    var transitionImageView: UIImageView? { imageView }
    
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 自定义初始化
    }
    
    // 可选实现：下拉关闭交互状态变化时调用
    // isInteracting 为 true 表示用户正在下拉（图片缩小跟随手指），false 表示交互结束（回弹恢复）
    // 适用于在拖拽关闭过程中暂停视频、隐藏附加 UI 等场景
    func photoBrowserDismissInteractionDidChange(isInteracting: Bool) {
        // 例如：下拉时暂停视频播放
    }
}
```

### 注册和使用自定义 Cell

```swift
let browser = JXPhotoBrowser()

// 注册自定义 Cell（必须在设置 delegate 之前）
browser.register(VideoPlayerCell.self, forReuseIdentifier: VideoPlayerCell.videoReuseIdentifier)

browser.delegate = self
browser.present(from: self)

// 在 delegate 中使用
func photoBrowser(_ browser: JXPhotoBrowser, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
    let cell = browser.dequeueReusableCell(withReuseIdentifier: VideoPlayerCell.videoReuseIdentifier, for: indexPath) as! VideoPlayerCell
    cell.configure(videoURL: url, coverImage: thumbnail)
    return cell
}
```

## Overlay 组件

框架提供了通用的 Overlay 组件机制，用于在浏览器上层叠加附加 UI（如页码指示器、关闭按钮、标题栏等）。**默认不装载任何 Overlay，业务方按需装载**。

### 使用内置页码指示器

框架内置了 `JXPageIndicatorOverlay`（基于 `UIPageControl`），一行代码即可装载：

```swift
let browser = JXPhotoBrowser()
browser.addOverlay(JXPageIndicatorOverlay())
```

支持自定义位置和样式：

```swift
let indicator = JXPageIndicatorOverlay()
indicator.position = .bottom(padding: 20)  // 位置：底部距离 20pt（也支持 .top）
indicator.hidesForSinglePage = true         // 仅一页时自动隐藏
indicator.pageControl.currentPageIndicatorTintColor = .white
indicator.pageControl.pageIndicatorTintColor = .lightGray
browser.addOverlay(indicator)
```

### 自定义 Overlay

实现 `JXPhotoBrowserOverlay` 协议即可创建自定义组件：

```swift
class CloseButtonOverlay: UIView, JXPhotoBrowserOverlay {
    
    func setup(with browser: JXPhotoBrowser) {
        // 在此完成布局（如添加约束）
    }
    
    func reloadData(numberOfItems: Int, pageIndex: Int) {
        // 数据或布局变化时更新
    }
    
    func didChangedPageIndex(_ index: Int) {
        // 页码变化时更新
    }
}

// 装载
browser.addOverlay(CloseButtonOverlay())
```

多个 Overlay 可同时装载，互不干扰：

```swift
browser.addOverlay(JXPageIndicatorOverlay())
browser.addOverlay(CloseButtonOverlay())
```

## 保存图片/视频到相册

框架本身不内置保存功能，业务方可自行实现。Demo 中演示了通过长按手势弹出 ActionSheet 保存媒体到系统相册的完整流程。

> **前提**：需要在 `Info.plist` 中配置 `NSPhotoLibraryAddUsageDescription`（写入相册权限描述）。

### 核心步骤

1. **添加长按手势**：在自定义 Cell 中添加 `UILongPressGestureRecognizer`。
2. **弹出 ActionSheet**：通过 `browser` 属性获取浏览器控制器来 present。
3. **请求权限并保存**：使用 `PHPhotoLibrary` 请求权限，下载后写入相册。

### 示例：在自定义 Cell 中长按保存

以 Demo 中的 `VideoPlayerCell` 为例，继承 `JXZoomImageCell` 后添加长按保存能力：

```swift
import Photos

class VideoPlayerCell: JXZoomImageCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 添加长按手势
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        scrollView.addGestureRecognizer(longPress)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "保存视频", style: .default) { [weak self] _ in
            self?.saveVideoToAlbum()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 通过 browser 属性获取浏览器控制器来 present
        browser?.present(alert, animated: true)
    }
    
    private func saveVideoToAlbum() {
        guard let url = videoURL else { return }
        
        // 1. 请求相册写入权限
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            
            // 2. 下载视频（远程 URL 需先下载到本地）
            URLSession.shared.downloadTask(with: url) { tempURL, _, _ in
                guard let tempURL else { return }
                
                // 3. 写入相册
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
                }) { success, error in
                    // 处理结果...
                }
            }.resume()
        }
    }
}
```

保存图片的流程类似，将下载部分替换为图片写入即可：

```swift
// 下载图片数据
URLSession.shared.dataTask(with: imageURL) { data, _, _ in
    guard let data, let image = UIImage(data: data) else { return }
    
    PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: image)
    }) { success, error in
        // 处理结果...
    }
}.resume()
```

## 依赖

- 框架本身依赖：`UIKit`（核心），**无任何第三方依赖**。
- 图片加载：框架不内置图片加载逻辑，业务方可自由选择 Kingfisher、SDWebImage 或其他任意图片加载方案。
- 示例工程：Demo 使用 `Kingfisher` 演示图片加载。

## 常见问题 (FAQ)

### Q: Zoom 转场动画时图片尺寸不对或有闪烁现象？

**A**: 这通常是因为打开浏览器时，目标 Cell 的 `imageView` 还没有设置图片，导致其 `bounds` 为 zero。

**解决方案**：在 `willDisplay` 代理方法中，确保同步设置占位图。例如使用 Kingfisher 时：

```swift
func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoBrowserAnyCell, at index: Int) {
    guard let photoCell = cell as? JXZoomImageCell else { return }
    
    // 同步从缓存取出缩略图作为占位图
    let placeholder = ImageCache.default.retrieveImageInMemoryCache(forKey: thumbnailURL.absoluteString)
    photoCell.imageView.kf.setImage(with: imageURL, placeholder: placeholder) { [weak photoCell] _ in
        photoCell?.setNeedsLayout()
    }
}
```

这样可以确保转场动画开始时，Cell 已经有正确尺寸的图片，动画效果更加流畅。

## License

本项目基于 MIT 协议开源。
