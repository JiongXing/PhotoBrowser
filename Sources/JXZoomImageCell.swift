//
//  JXZoomImageCell.swift
//  JXPhotoBrowser
//

import UIKit

private final class JXObservedImageView: UIImageView {
    var onImageChange: (() -> Void)?

    override var image: UIImage? {
        didSet {
            onImageChange?()
        }
    }
}

/// 支持图片捏合缩放查看的 Cell
/// 内部使用 UIScrollView 实现缩放，支持单击关闭、双击切换缩放模式等手势交互
open class JXZoomImageCell: UICollectionViewCell, UIScrollViewDelegate, JXPhotoBrowserCellProtocol {
    // MARK: - Static
    public static let reuseIdentifier = "JXZoomImageCell"
    
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

    /// 承载实际缩放内容的容器视图，由 UIScrollView 负责缩放几何
    private let zoomContentView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    /// 展示图片内容的视图（参与缩放与转场）
    public let imageView: UIImageView = {
        let iv = JXObservedImageView()
        // 使用非 AutoLayout 的 frame 布局以配合缩放
        iv.translatesAutoresizingMaskIntoConstraints = true
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
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
    
    // MARK: - State

    /// 弱引用的浏览器（用于调用关闭）
    public weak var browser: JXPhotoBrowserViewController?

    /// 双击放大倍数（相对适配尺寸，需大于 1.0）。为 nil 时保持默认行为（长边铺满 ↔ 短边铺满模式切换）
    /// 该值受 `scrollView.maximumZoomScale` 上限约束：若需双击放大到超过默认上限（3.0），请自行调高 `scrollView.maximumZoomScale`
    public var doubleTapZoomScale: CGFloat?
    
    // MARK: - Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    /// 两个 init 共用的初始化逻辑，确保从 XIB/Storyboard 实例化时同样完成 setup
    private func commonInit() {
        // ScrollView 承载 imageView 以支持捏合缩放
        contentView.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        scrollView.delegate = self
        scrollView.addSubview(zoomContentView)
        zoomContentView.addSubview(imageView)
        (imageView as? JXObservedImageView)?.onImageChange = { [weak self] in
            self?.handleImageDidChange()
        }

        // 添加双击缩放
        scrollView.addGestureRecognizer(doubleTapGesture)
        // 添加单击关闭，并与双击冲突处理
        scrollView.addGestureRecognizer(singleTapGesture)
        singleTapGesture.require(toFail: doubleTapGesture)
        backgroundColor = .clear
    }
    
    // MARK: - Layout State
    /// 上一次布局的容器尺寸（用于旋转时重置缩放）
    private var lastBoundsSize: CGSize = .zero
    
    /// 缩放模式：true 表示短边铺满（scaleAspectFill），false 表示长边铺满（scaleAspectFit）
    private var isShortEdgeFit: Bool = false

    private var isPerformingLayoutUpdate = false
    
    // MARK: - Lifecycle
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        // 清空旧图像
        imageView.image = nil
        
        // 重置缩放与偏移
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
        scrollView.contentOffset = .zero
        scrollView.contentInset = .zero
        scrollView.contentSize = .zero
        zoomContentView.frame = .zero
        
        // 重置缩放模式为初始状态（长边铺满）
        isShortEdgeFit = false
        
        // 重置布局状态，确保复用Cell时使用正确的尺寸信息
        lastBoundsSize = .zero
        
        // 恢复初始布局
        adjustImageViewFrame()
    }
    
    // MARK: - JXPhotoBrowserCellProtocol
    
    /// 若调用方提供的是 UIImageView，则可参与几何匹配 Zoom 动画
    open var transitionImageView: UIImageView? { imageView }

    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let sizeChanged = lastBoundsSize != bounds.size
        if sizeChanged {
            lastBoundsSize = bounds.size
            // 旋转后重置缩放和缩放模式，避免旧尺寸导致的缩放计算错误
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
            scrollView.contentOffset = .zero
            isShortEdgeFit = false
            adjustImageViewFrame()
        } else if scrollView.zoomScale == scrollView.minimumZoomScale || zoomContentView.bounds.isEmpty {
            // 在未缩放状态下，根据图片比例调整基础内容尺寸
            // 或者如果基础内容大小为 0 (异常状态)，也强制调整
            adjustImageViewFrame()
        }
        centerZoomContentViewIfNeeded()
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

    /// 根据图片实际尺寸，更新基础内容尺寸。
    /// 根据 isShortEdgeFit 状态选择缩放方式：
    /// - false: scaleAspectFit（长边铺满容器，短边等比例缩放，居中展示）
    /// - true: scaleAspectFill（短边铺满容器，长边等比例缩放）
    open func adjustImageViewFrame() {
        let containerSize = effectiveContentSize
        guard containerSize.width > 0, containerSize.height > 0 else { return }
        
        guard let image = imageView.image, image.size.width > 0, image.size.height > 0 else {
            // 图片未加载时不再先铺满容器，避免先拉伸后收缩的闪动
            zoomContentView.frame = .zero
            imageView.frame = .zero
            scrollView.contentSize = .zero
            return
        }

        let contentSize = baseContentSize(for: containerSize, imageSize: image.size)
        zoomContentView.frame = CGRect(origin: .zero, size: contentSize)
        imageView.frame = zoomContentView.bounds
        scrollView.contentSize = contentSize
        centerZoomContentViewIfNeeded()
    }

    // MARK: - UIScrollViewDelegate
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomContentView
    }

    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerZoomContentViewIfNeeded()
    }

    open func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        let isAtMinimumZoom = scrollView.zoomScale <= scrollView.minimumZoomScale + 0.01
        if isAtMinimumZoom {
            adjustImageViewFrame()
        } else {
            centerZoomContentViewIfNeeded()
        }
    }

    // MARK: - Helpers
    /// 在内容小于容器时居中展示，缩放中由 UIScrollView 负责几何，静态居中由容器视图承担。
    open func centerImageIfNeeded() {
        centerZoomContentViewIfNeeded()
    }

    private func centerZoomContentViewIfNeeded() {
        let scrollBounds = CGRect(origin: .zero, size: effectiveContentSize)
        let contentFrame = zoomContentView.frame
        guard scrollBounds.width > 0, scrollBounds.height > 0 else { return }
        guard contentFrame.width > 0, contentFrame.height > 0 else { return }

        let targetOrigin = CGPoint(
            x: contentFrame.width < scrollBounds.width ? (scrollBounds.width - contentFrame.width) * 0.5 : 0,
            y: contentFrame.height < scrollBounds.height ? (scrollBounds.height - contentFrame.height) * 0.5 : 0
        )
        if zoomContentView.frame.origin != targetOrigin {
            zoomContentView.frame.origin = targetOrigin
        }
    }

    private func baseContentSize(for containerSize: CGSize, imageSize: CGSize) -> CGSize {
        let widthScale = containerSize.width / imageSize.width
        let heightScale = containerSize.height / imageSize.height
        let scale = isShortEdgeFit ? max(widthScale, heightScale) : min(widthScale, heightScale)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    @objc open func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let currentScale = scrollView.zoomScale
        let isInitialScale = abs(currentScale - scrollView.minimumZoomScale) < 0.01
        
        // 获取点击位置用于计算放大时的目标偏移
        let tapInScrollView = gesture.location(in: scrollView)
        let tapInZoomContentView = gesture.location(in: zoomContentView)
        let containerSize = effectiveContentSize
        
        if isInitialScale {
            // 指定了双击放大倍数时，以点击点为中心放大到指定倍数（保持长边铺满的基础布局）
            // 目标倍数受 maximumZoomScale 上限约束，不会突破捏合缩放天花板
            if let zoomScale = doubleTapZoomScale, zoomScale > 1 {
                let targetScale = min(zoomScale, scrollView.maximumZoomScale)
                let zoomSize = CGSize(width: containerSize.width / targetScale,
                                      height: containerSize.height / targetScale)
                let zoomRect = CGRect(x: tapInZoomContentView.x - zoomSize.width * 0.5,
                                      y: tapInZoomContentView.y - zoomSize.height * 0.5,
                                      width: zoomSize.width,
                                      height: zoomSize.height)
                scrollView.zoom(to: zoomRect, animated: true)
                return
            }

            // 在初始缩放状态下，切换缩放模式（长边铺满 <-> 短边铺满）
            let oldContentSize = zoomContentView.bounds.size
            isShortEdgeFit.toggle()
            guard
                let image = imageView.image,
                image.size.width > 0,
                image.size.height > 0,
                containerSize.width > 0,
                containerSize.height > 0
            else {
                adjustImageViewFrame()
                return
            }

            let newContentSize = baseContentSize(for: containerSize, imageSize: image.size)
            
            // 计算基于点击位置的目标 contentOffset（仅在放大到 aspectFill 时需要）
            var tapBasedOffset: CGPoint?
            if isShortEdgeFit, oldContentSize.width > 0, oldContentSize.height > 0 {
                let scaleRatioX = newContentSize.width / oldContentSize.width
                let scaleRatioY = newContentSize.height / oldContentSize.height
                let newTapInContent = CGPoint(
                    x: tapInZoomContentView.x * scaleRatioX,
                    y: tapInZoomContentView.y * scaleRatioY
                )
                let rawOffsetX = newTapInContent.x - tapInScrollView.x
                let rawOffsetY = newTapInContent.y - tapInScrollView.y
                let maxOffsetX = max(0, newContentSize.width - containerSize.width)
                let maxOffsetY = max(0, newContentSize.height - containerSize.height)
                tapBasedOffset = CGPoint(
                    x: min(max(0, rawOffsetX), maxOffsetX),
                    y: min(max(0, rawOffsetY), maxOffsetY)
                )
            }

            UIView.animate(withDuration: 0.3, animations: {
                self.zoomContentView.frame.size = newContentSize
                self.imageView.frame = self.zoomContentView.bounds
                self.scrollView.contentSize = newContentSize
                self.centerZoomContentViewIfNeeded()
                if let offset = tapBasedOffset {
                    self.scrollView.contentOffset = offset
                }
            })
        } else {
            // 在非初始缩放状态下，切换回初始状态（长边铺满模式）
            isShortEdgeFit = false
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                guard let self = self else { return }
                self.adjustImageViewFrame()
            }
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            CATransaction.commit()
        }
    }

    @objc open func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        browser?.dismissSelf()
    }

    open func photoBrowserDismissInteractionDidChange(isInteracting: Bool) {
        clipsToBounds = !isInteracting
        contentView.clipsToBounds = !isInteracting
        scrollView.clipsToBounds = !isInteracting
        zoomContentView.clipsToBounds = !isInteracting
    }

    private func handleImageDidChange() {
        guard !isPerformingLayoutUpdate else { return }
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.handleImageDidChange()
            }
            return
        }

        guard bounds.width > 0, bounds.height > 0 else {
            setNeedsLayout()
            return
        }

        isPerformingLayoutUpdate = true
        defer { isPerformingLayoutUpdate = false }

        if scrollView.zoomScale <= scrollView.minimumZoomScale + 0.01 || zoomContentView.bounds.isEmpty {
            adjustImageViewFrame()
        } else {
            centerZoomContentViewIfNeeded()
        }
    }
}
