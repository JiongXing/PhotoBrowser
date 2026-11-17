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
        sv.maximumZoomScale = 2.0
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
    
    /// 双击手势：在基础适配与放大之间切换，与捏合共用 UIScrollView 的缩放状态
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

    /// 双击目标倍数，以铺满容器的尺寸为 1 倍；nil 时使用 1 倍。
    /// 目标受 scrollView 的最小、最大倍率约束，默认最大为 2 倍。
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
    
    private var isPerformingLayoutUpdate = false
    private var isUpdatingZoomGeometry = false

    private var isAtMinimumZoom: Bool {
        abs(scrollView.zoomScale - scrollView.minimumZoomScale)
            <= max(scrollView.minimumZoomScale * 0.000001, CGFloat.ulpOfOne)
    }

    /// 是否处于外部驱动的尺寸过渡中（如设备旋转）。期间几何更新由外部按过渡进度显式驱动，
    /// layoutSubviews 的默认重置逻辑需让位，避免两者相互竞争产生跳变
    private var isTransitioningSize = false

    private var dismissInteractionState: (scrollEnabled: Bool, pinchEnabled: Bool, clips: [Bool], zoomScale: CGFloat, contentOffset: CGPoint)?
    private var imageChangedDuringDismiss = false

    // MARK: - Lifecycle
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        isTransitioningSize = false
        
        // 清空旧图像
        imageView.image = nil
        
        // 重置缩放与偏移
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
        scrollView.contentOffset = .zero
        scrollView.contentInset = .zero
        scrollView.contentSize = .zero
        zoomContentView.frame = .zero
        
        // 重置布局状态，确保复用Cell时使用正确的尺寸信息
        lastBoundsSize = .zero
        
        // 恢复初始布局
        adjustImageViewFrame()
    }
    
    // MARK: - JXPhotoBrowserCellProtocol
    
    /// 若调用方提供的是 UIImageView，则可参与几何匹配 Zoom 动画
    open var transitionImageView: UIImageView? { imageView }

    open var canBeginDismissInteraction: Bool {
        let isAtTop = scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 1.0
        let pinchState = scrollView.pinchGestureRecognizer?.state
        return !isTransitioningSize && !scrollView.isZooming && !scrollView.isZoomBouncing
            && pinchState != .began && pinchState != .changed && isAtTop
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        // 尺寸过渡期间，几何更新完全由 applySizeTransition/finishSizeTransition 驱动，
        // 跳过默认重置逻辑，避免与过渡动画竞争造成跳变
        guard !isTransitioningSize, dismissInteractionState == nil else { return }

        let sizeChanged = lastBoundsSize != bounds.size
        if sizeChanged {
            lastBoundsSize = bounds.size
            // 旋转后重置缩放，避免旧尺寸导致的缩放计算错误
            updateZoomGeometry(in: bounds.size, resettingZoom: true)
        } else if isAtMinimumZoom || zoomContentView.bounds.isEmpty {
            // 在未缩放状态下，根据图片比例调整基础内容尺寸
            // 或者如果基础内容大小为 0 (异常状态)，也强制调整
            adjustImageViewFrame()
        }
        centerZoomContentViewIfNeeded()
    }

    /// 尺寸过渡（如设备旋转）开始前调用：锁定 layoutSubviews 的默认重置逻辑，交由外部显式驱动几何更新
    open func prepareForSizeTransition() {
        isTransitioningSize = true
    }

    /// 在 UIViewControllerTransitionCoordinator 的动画块内调用，使几何变化随外部过渡动画一起插值，
    /// 而不是使用独立计时的动画块，保证与系统过渡动画同步
    open func applySizeTransition(to newSize: CGSize) {
        updateZoomGeometry(in: newSize, resettingZoom: true)
    }

    /// 尺寸过渡结束后调用：以实际 bounds 做最终校正，并恢复 layoutSubviews 的正常行为
    open func finishSizeTransition() {
        isTransitioningSize = false
        lastBoundsSize = bounds.size
        updateZoomGeometry(in: bounds.size, resettingZoom: true)
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

    /// 更新以铺满为 1 倍的基础内容，完整显示使用按图片比例计算的最小倍率。
    open func adjustImageViewFrame() {
        guard !isTransitioningSize, dismissInteractionState == nil else { return }
        updateZoomGeometry(in: effectiveContentSize, resettingZoom: false)
    }

    private func updateZoomGeometry(in containerSize: CGSize, resettingZoom: Bool) {
        guard containerSize.width > 0, containerSize.height > 0 else { return }
        let wasAtMinimum = isAtMinimumZoom
        let previousScale = scrollView.zoomScale
        let previousOffset = scrollView.contentOffset
        isUpdatingZoomGeometry = true
        defer { isUpdatingZoomGeometry = false }

        guard let image = imageView.image, image.size.width > 0, image.size.height > 0 else {
            // 图片未加载时不再先铺满容器，避免先拉伸后收缩的闪动
            scrollView.minimumZoomScale = 1
            scrollView.setZoomScale(1, animated: false)
            zoomContentView.bounds = .zero
            imageView.frame = .zero
            scrollView.contentSize = .zero
            return
        }

        let widthScale = containerSize.width / image.size.width
        let heightScale = containerSize.height / image.size.height
        let minimumScale = min(widthScale, heightScale) / max(widthScale, heightScale)
        let contentSize = baseContentSize(for: containerSize, imageSize: image.size)
        // 更新未缩放的 bounds，避免在非单位 transform 下修改 frame 反向改变基础尺寸。
        zoomContentView.bounds = CGRect(origin: .zero, size: contentSize)
        imageView.frame = zoomContentView.bounds
        scrollView.minimumZoomScale = minimumScale
        let targetScale = resettingZoom || wasAtMinimum
            ? minimumScale
            : min(max(previousScale, minimumScale), scrollView.maximumZoomScale)
        scrollView.setZoomScale(targetScale, animated: false)
        scrollView.contentSize = zoomContentView.frame.size
        zoomContentView.frame.origin = centeredOrigin(forContentSize: zoomContentView.frame.size, in: containerSize)

        let inset = scrollView.adjustedContentInset
        let minimumOffset = CGPoint(x: -inset.left, y: -inset.top)
        let maximumOffset = CGPoint(x: max(minimumOffset.x, scrollView.contentSize.width - containerSize.width + inset.right),
                                    y: max(minimumOffset.y, scrollView.contentSize.height - containerSize.height + inset.bottom))
        scrollView.contentOffset = resettingZoom ? minimumOffset : CGPoint(
            x: min(max(previousOffset.x, minimumOffset.x), maximumOffset.x),
            y: min(max(previousOffset.y, minimumOffset.y), maximumOffset.y)
        )
    }

    // MARK: - UIScrollViewDelegate
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomContentView
    }

    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerZoomContentViewIfNeeded()
    }

    open func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        centerZoomContentViewIfNeeded()
    }

    // MARK: - Helpers
    /// 在内容小于容器时居中展示，缩放中由 UIScrollView 负责几何，静态居中由容器视图承担。
    open func centerImageIfNeeded() {
        centerZoomContentViewIfNeeded()
    }

    private func centerZoomContentViewIfNeeded() {
        guard !isTransitioningSize, !isUpdatingZoomGeometry else { return }
        let scrollBounds = CGRect(origin: .zero, size: effectiveContentSize)
        let contentFrame = zoomContentView.frame
        guard scrollBounds.width > 0, scrollBounds.height > 0 else { return }
        guard contentFrame.width > 0, contentFrame.height > 0 else { return }

        let targetOrigin = centeredOrigin(forContentSize: contentFrame.size, in: scrollBounds.size)
        if zoomContentView.frame.origin != targetOrigin {
            zoomContentView.frame.origin = targetOrigin
        }
    }

    private func baseContentSize(for containerSize: CGSize, imageSize: CGSize) -> CGSize {
        let widthScale = containerSize.width / imageSize.width
        let heightScale = containerSize.height / imageSize.height
        let scale = max(widthScale, heightScale)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    /// 内容小于容器时居中，否则贴齐原点
    private func centeredOrigin(forContentSize contentSize: CGSize, in containerSize: CGSize) -> CGPoint {
        CGPoint(
            x: contentSize.width < containerSize.width ? (containerSize.width - contentSize.width) * 0.5 : 0,
            y: contentSize.height < containerSize.height ? (containerSize.height - contentSize.height) * 0.5 : 0
        )
    }

    @objc open func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard !isTransitioningSize, dismissInteractionState == nil else { return }
        if !isAtMinimumZoom {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            return
        }

        let containerSize = effectiveContentSize
        guard let image = imageView.image,
              image.size.width > 0, image.size.height > 0,
              containerSize.width > 0, containerSize.height > 0 else { return }

        // 基础布局始终为 aspectFill；1 倍铺满，捏合可返回小于 1 的完整适配倍率。
        let requestedScale = doubleTapZoomScale.flatMap { $0.isFinite && $0 > 0 ? $0 : nil } ?? 1
        let targetScale = min(max(requestedScale, scrollView.minimumZoomScale), scrollView.maximumZoomScale)
        let tap = gesture.location(in: zoomContentView)
        let zoomSize = CGSize(width: containerSize.width / targetScale,
                              height: containerSize.height / targetScale)
        let zoomRect = CGRect(x: tap.x - zoomSize.width * 0.5,
                              y: tap.y - zoomSize.height * 0.5,
                              width: zoomSize.width,
                              height: zoomSize.height)
        scrollView.zoom(to: zoomRect, animated: true)
    }

    @objc open func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        browser?.dismissSelf()
    }

    open func photoBrowserDismissInteractionDidChange(isInteracting: Bool) {
        let views = [self, contentView, scrollView, zoomContentView]
        if isInteracting {
            guard dismissInteractionState == nil else { return }
            let contentOffset = scrollView.contentOffset
            imageChangedDuringDismiss = false
            dismissInteractionState = (scrollView.isScrollEnabled, scrollView.pinchGestureRecognizer?.isEnabled ?? false,
                                       views.map { $0.clipsToBounds }, scrollView.zoomScale, contentOffset)
            scrollView.isScrollEnabled = false
            scrollView.pinchGestureRecognizer?.isEnabled = false
            // 禁用滚动可能改变 automatic inset；保持图片在开始交互时的屏幕位置。
            scrollView.contentOffset = contentOffset
            views.forEach { $0.clipsToBounds = false }
        } else if let state = dismissInteractionState {
            dismissInteractionState = nil
            scrollView.isScrollEnabled = state.scrollEnabled
            scrollView.pinchGestureRecognizer?.isEnabled = state.pinchEnabled
            scrollView.setZoomScale(state.zoomScale, animated: false)
            scrollView.contentOffset = state.contentOffset
            zip(views, state.clips).forEach { $0.0.clipsToBounds = $0.1 }
            if imageChangedDuringDismiss {
                imageChangedDuringDismiss = false
                adjustImageViewFrame()
            }
        }
    }

    private func handleImageDidChange() {
        guard !isPerformingLayoutUpdate else { return }
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.handleImageDidChange()
            }
            return
        }

        guard dismissInteractionState == nil else {
            imageChangedDuringDismiss = true
            setNeedsLayout()
            return
        }

        guard bounds.width > 0, bounds.height > 0 else {
            setNeedsLayout()
            return
        }

        isPerformingLayoutUpdate = true
        defer { isPerformingLayoutUpdate = false }

        adjustImageViewFrame()
    }
}
