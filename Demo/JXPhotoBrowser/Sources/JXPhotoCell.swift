//
//  JXPhotoCell.swift
//  JXPhotoBrowser
//

import UIKit
import Kingfisher
import AVFoundation

/// 支持图片捏合缩放查看的 Cell
open class JXPhotoCell: UICollectionViewCell, UIScrollViewDelegate {
    // MARK: - Static
    public static let reuseIdentifier = "JXPhotoCell"
    
    // MARK: - UI
    /// 承载图片并支持捏合缩放的滚动视图
    public let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 3.0
        sv.bouncesZoom = true
        sv.alwaysBounceVertical = false
        sv.alwaysBounceHorizontal = false
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.decelerationRate = .fast
        sv.backgroundColor = .clear
        return sv
    }()

    /// 展示图片内容的视图（参与缩放与转场）
    public let imageView: UIImageView = {
        let iv = UIImageView()
        // 使用非 AutoLayout 的 frame 布局以配合缩放
        iv.translatesAutoresizingMaskIntoConstraints = true
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    /// 视频播放按钮（当资源为视频时显示）
    public let playButton: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        iv.isUserInteractionEnabled = true // 允许点击
        return iv
    }()
    
    // MARK: - Video Properties
    
    /// 双击手势：在初始缩放状态下切换缩放模式（长边铺满 ↔ 短边铺满），在非初始缩放状态下切换回初始状态
    public private(set) lazy var doubleTapGesture: UITapGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        g.numberOfTapsRequired = 2
        g.numberOfTouchesRequired = 1
        return g
    }()

    // 单击手势：用于关闭浏览器（与双击互斥）
    public private(set) lazy var singleTapGesture: UITapGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        g.numberOfTapsRequired = 1
        g.numberOfTouchesRequired = 1
        g.delaysTouchesBegan = false
        return g
    }()
    
    /// 长按手势：用于触发业务方弹窗（下载等）
    public private(set) lazy var longPressGesture: UILongPressGestureRecognizer = {
        let g = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        g.minimumPressDuration = 0.5
        return g
    }()
    
    // MARK: - State
    /// 弱引用的浏览器（用于调用关闭）
    public weak var browser: JXPhotoBrowser?

    /// 当前关联的真实索引（变更即触发内容加载）
    public var currentIndex: Int? {
        didSet {
            print("🔄 [JXPhotoCell] currentIndex changed: \(oldValue ?? -1) -> \(currentIndex ?? -1), bounds: \(bounds.size), scrollView.bounds: \(scrollView.bounds.size)")
            reloadContent()
        }
    }
    
    /// 当前 Cell 对应的资源（图片 / 视频）
    public private(set) var currentResource: JXPhotoResource?
    
    // MARK: - Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        // ScrollView 承载 imageView 以支持捏合缩放
        contentView.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        scrollView.delegate = self
        scrollView.addSubview(imageView)
        
        // 添加播放按钮
        contentView.addSubview(playButton)
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 60),
            playButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // 添加双击缩放
        scrollView.addGestureRecognizer(doubleTapGesture)
        // 添加单击关闭，并与双击冲突处理
        scrollView.addGestureRecognizer(singleTapGesture)
        singleTapGesture.require(toFail: doubleTapGesture)
        // 添加长按
        scrollView.addGestureRecognizer(longPressGesture)
        backgroundColor = .clear
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Layout State
    /// 上一次布局的容器尺寸（用于旋转时重置缩放）
    private var lastBoundsSize: CGSize = .zero
    
    /// 缩放模式：true 表示短边铺满（scaleAspectFill），false 表示长边铺满（scaleAspectFit）
    private var isShortEdgeFit: Bool = false
    
    // MARK: - Lifecycle
    open override func prepareForReuse() {
        super.prepareForReuse()
        print("🧹 [JXPhotoCell] prepareForReuse - oldIndex: \(currentIndex ?? -1), bounds: \(bounds.size), scrollView.bounds: \(scrollView.bounds.size), zoomScale: \(scrollView.zoomScale), contentOffset: \(scrollView.contentOffset), contentInset: \(scrollView.contentInset), lastBoundsSize: \(lastBoundsSize)")
        
        // 取消正在进行的下载任务
        imageView.kf.cancelDownloadTask()
        
        // 清空旧图像与状态
        imageView.image = nil
        currentResource = nil
        currentIndex = nil
        // 重置缩放与偏移
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
        scrollView.contentOffset = .zero
        scrollView.contentInset = .zero
        
        // 重置缩放模式为初始状态（长边铺满）
        isShortEdgeFit = false
        
        // 重置布局状态，确保复用Cell时使用正确的尺寸信息
        lastBoundsSize = .zero
        
        // 恢复初始布局
        adjustImageViewFrame()
        
        // 视频重置
        playButton.isHidden = true
        
        print("🧹 [JXPhotoCell] prepareForReuse - after reset, bounds: \(bounds.size), scrollView.bounds: \(scrollView.bounds.size), imageView.frame: \(imageView.frame)")
    }
    
    // MARK: - Transition Helper
    /// 若调用方提供的是 UIImageView，则可参与几何匹配 Zoom 动画
    open var transitionImageView: UIImageView? { imageView }

    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let sizeChanged = lastBoundsSize != bounds.size
        print("📐 [JXPhotoCell] layoutSubviews - index: \(currentIndex ?? -1), bounds: \(bounds.size), lastBoundsSize: \(lastBoundsSize), sizeChanged: \(sizeChanged), zoomScale: \(scrollView.zoomScale), scrollView.bounds: \(scrollView.bounds.size), imageView.frame: \(imageView.frame)")
        
        if sizeChanged {
            lastBoundsSize = bounds.size
            print("📐 [JXPhotoCell] layoutSubviews - size changed, resetting zoom and frame")
            // 旋转后重置缩放和缩放模式，避免旧尺寸导致的缩放计算错误
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
            isShortEdgeFit = false
            adjustImageViewFrame()
        } else if scrollView.zoomScale == scrollView.minimumZoomScale || imageView.frame.isEmpty {
            // 在未缩放状态下，根据图片比例调整 imageView.frame
            // 或者如果 imageView 大小为 0 (异常状态)，也强制调整
            print("📐 [JXPhotoCell] layoutSubviews - adjusting frame (zoomScale at min or frame empty)")
            adjustImageViewFrame()
        }
        // 任何时候（包括缩放时），都通过 inset 进行居中处理
        centerImageIfNeeded()
        
        print("📐 [JXPhotoCell] layoutSubviews completed - imageView.frame: \(imageView.frame), contentSize: \(scrollView.contentSize), contentOffset: \(scrollView.contentOffset), contentInset: \(scrollView.contentInset)")
    }

    // MARK: - Layout Helper
    
    /// 获取有效的容器尺寸（兼容 ScrollView 尚未布局的情况）
    /// 优先使用 Cell 的 bounds，因为 scrollView.bounds 在旋转时可能更新滞后
    private var effectiveContentSize: CGSize {
        // 优先使用 Cell 的 bounds，确保在旋转时能获取到正确的尺寸
        let cellSize = bounds.size
        if cellSize.width > 0 && cellSize.height > 0 {
            return cellSize
        }
        // 如果 Cell bounds 无效，再尝试使用 scrollView.bounds
        let scrollSize = scrollView.bounds.size
        return (scrollSize.width > 0 && scrollSize.height > 0) ? scrollSize : cellSize
    }

    /// 根据图片实际尺寸，调整 imageView 的 frame（原点保持 (0,0)）
    /// 根据 isShortEdgeFit 状态选择缩放方式：
    /// - false: scaleAspectFit（长边铺满容器，短边等比例缩放，居中展示）
    /// - true: scaleAspectFill（短边铺满容器，长边等比例缩放）
    open func adjustImageViewFrame() {
        let containerSize = effectiveContentSize
        print("🖼️ [JXPhotoCell] adjustImageViewFrame - index: \(currentIndex ?? -1), containerSize: \(containerSize), bounds: \(bounds.size), scrollView.bounds: \(scrollView.bounds.size), isShortEdgeFit: \(isShortEdgeFit)")
        
        guard containerSize.width > 0, containerSize.height > 0 else {
            print("🖼️ [JXPhotoCell] adjustImageViewFrame - containerSize invalid, returning")
            return
        }
        
        guard let image = imageView.image, image.size.width > 0, image.size.height > 0 else {
            // 图片未加载时，不再先铺满容器，避免先拉伸后收缩的闪动
            print("🖼️ [JXPhotoCell] adjustImageViewFrame - image not loaded, setting frame to zero")
            imageView.frame = .zero
            scrollView.contentSize = containerSize
            return
        }
        
        let widthScale = containerSize.width / image.size.width
        let heightScale = containerSize.height / image.size.height
        
        let scale: CGFloat
        if isShortEdgeFit {
            // scaleAspectFill 逻辑：选择较大的缩放比例，确保短边铺满容器，长边等比例缩放
            scale = max(widthScale, heightScale)
        } else {
            // scaleAspectFit 逻辑：选择较小的缩放比例，确保长边铺满容器，短边等比例缩放
            scale = min(widthScale, heightScale)
        }
        
        // 计算缩放后的尺寸
        let scaledWidth = image.size.width * scale
        let scaledHeight = image.size.height * scale
        
        let oldFrame = imageView.frame
        imageView.frame = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
        scrollView.contentSize = imageView.frame.size
        
        print("🖼️ [JXPhotoCell] adjustImageViewFrame - image.size: \(image.size), scale: \(scale), oldFrame: \(oldFrame), newFrame: \(imageView.frame), contentSize: \(scrollView.contentSize)")
    }

    // MARK: - UIScrollViewDelegate
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageIfNeeded()
    }

    // MARK: - Helpers
    /// 在内容小于容器时居中展示（通过 contentInset 处理，避免 frame 偏移残留）
    open func centerImageIfNeeded() {
        // 优先使用 Cell 的 bounds，因为 scrollView.bounds 在旋转时可能更新滞后
        var containerSize = bounds.size
        if containerSize.width <= 0 || containerSize.height <= 0 {
            // 如果 Cell bounds 无效，再尝试使用 scrollView.bounds
            containerSize = scrollView.bounds.size
        }
        
        let imageSize = imageView.frame.size
        if containerSize.width <= 0 || containerSize.height <= 0 {
            print("🎯 [JXPhotoCell] centerImageIfNeeded - containerSize invalid: \(containerSize), returning")
            return
        }
        if imageSize.width <= 0 || imageSize.height <= 0 {
            print("🎯 [JXPhotoCell] centerImageIfNeeded - imageSize invalid: \(imageSize), returning")
            return
        }
        
        // 使用 contentInset 而非调整 frame，避免分页复用时的偏移遗留
        let horizontalInset = max(0, (containerSize.width - imageSize.width) * 0.5)
        let verticalInset = max(0, (containerSize.height - imageSize.height) * 0.5)
        
        let newInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
        let insetChanged = scrollView.contentInset != newInset
        
        let oldInset = scrollView.contentInset
        let oldOffset = scrollView.contentOffset
        
        if insetChanged {
            scrollView.contentInset = newInset
        }
        
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            // 让内容视觉上居中，需要把 offset 调整到 inset 的负值
            let targetOffset = CGPoint(x: -horizontalInset, y: -verticalInset)
            if scrollView.contentOffset != targetOffset {
                scrollView.contentOffset = targetOffset
            }
        }
        
        print("🎯 [JXPhotoCell] centerImageIfNeeded - index: \(currentIndex ?? -1), containerSize: \(containerSize), imageSize: \(imageSize), horizontalInset: \(horizontalInset), verticalInset: \(verticalInset), zoomScale: \(scrollView.zoomScale), oldInset: \(oldInset) -> newInset: \(newInset), oldOffset: \(oldOffset) -> newOffset: \(scrollView.contentOffset)")
    }

    @objc open func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let currentScale = scrollView.zoomScale
        let isInitialScale = abs(currentScale - scrollView.minimumZoomScale) < 0.01
        
        if isInitialScale {
            // 在初始缩放状态下，切换缩放模式（长边铺满 <-> 短边铺满）
            isShortEdgeFit.toggle()
            // 先计算新的 frame
            let oldFrame = imageView.frame
            adjustImageViewFrame()
            let newFrame = imageView.frame
            let newContentSize = imageView.frame.size
            
            // 恢复旧 frame 用于动画起点
            imageView.frame = oldFrame
            scrollView.contentSize = oldFrame.size
            centerImageIfNeeded()
            
            // 使用动画平滑切换
            UIView.animate(withDuration: 0.3, animations: {
                self.imageView.frame = newFrame
                self.scrollView.contentSize = newContentSize
                self.centerImageIfNeeded()
            })
        } else {
            // 在非初始缩放状态下，切换回初始状态（长边铺满模式）
            isShortEdgeFit = false
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            // 动画完成后调整 frame
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                self.adjustImageViewFrame()
                self.centerImageIfNeeded()
            }
        }
    }

    /// 计算目标缩放矩形
    open func zoomRect(for scale: CGFloat, centeredAt center: CGPoint) -> CGRect {
        // 以 scrollView 的可视尺寸反推在内容坐标系下应显示的区域尺寸
        let boundsSize = scrollView.bounds.size
        let width = boundsSize.width / scale
        let height = boundsSize.height / scale
        let originX = center.x - (width * 0.5)
        let originY = center.y - (height * 0.5)
        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    @objc open func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        browser?.dismissSelf()
    }
    
    @objc open func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        browser?.handleLongPress(from: self)
    }
    
    // MARK: - Content Loading
    /// 从浏览器委托获取资源并加载到 imageView
    open func reloadContent() {
        guard let browser = browser, let index = currentIndex else {
            print("📥 [JXPhotoCell] reloadContent - no browser or index, clearing image")
            imageView.image = nil
            return
        }

        print("📥 [JXPhotoCell] reloadContent - index: \(index), bounds: \(bounds.size), scrollView.bounds: \(scrollView.bounds.size), lastBoundsSize: \(lastBoundsSize)")

        // 重置布局状态，确保使用当前bounds尺寸进行布局计算
        lastBoundsSize = .zero

        // 取消上一次可能的下载任务
        imageView.kf.cancelDownloadTask()

        // 请求业务资源：直接加载原图，若缩略图已在缓存，则作为占位图
        if let res = browser.delegate?.photoBrowser(browser, resourceForItemAt: index) {
            currentResource = res
            let placeholder: UIImage? = {
                guard let thumbURL = res.thumbnailURL else { return nil }
                return ImageCache.default.retrieveImageInMemoryCache(forKey: thumbURL.absoluteString)
            }()

            imageView.kf.setImage(with: res.imageURL, placeholder: placeholder) { [weak self] result in
                guard let self = self else { return }
                print("📥 [JXPhotoCell] image loaded - index: \(index), bounds: \(self.bounds.size), scrollView.bounds: \(self.scrollView.bounds.size), image.size: \(self.imageView.image?.size ?? .zero)")
                // 强制重置布局状态，确保使用当前bounds尺寸
                self.lastBoundsSize = .zero
                self.adjustImageViewFrame()
                self.centerImageIfNeeded()
                self.setNeedsLayout()
                // 再走一帧保证容器尺寸有效后重新居中
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    print("📥 [JXPhotoCell] async layout - index: \(index), bounds: \(self.bounds.size), scrollView.bounds: \(self.scrollView.bounds.size)")
                    self.setNeedsLayout()
                    self.layoutIfNeeded()
                    self.centerImageIfNeeded()
                }
            }
            
            // 初始布局调整（即便异步完成前也保证基本布局）
            adjustImageViewFrame()
            centerImageIfNeeded()
        } else {
            imageView.image = nil
            playButton.isHidden = true
        }
    }
}
