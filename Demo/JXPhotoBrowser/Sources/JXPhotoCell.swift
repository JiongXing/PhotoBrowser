//
//  JXPhotoCell.swift
//  JXPhotoBrowser
//

import UIKit

public protocol JXPhotoCellLifecycleDelegate: AnyObject {
    /// 即将被复用
    func photoCellWillReuse(_ cell: JXPhotoCell, lastIndex: Int?)
    
    /// 单击图片（关闭Browser）
    func photoCellDidSingleTap(_ cell: JXPhotoCell)
}

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

    // 双击手势：小于 1.1 放大到 2x，否则还原
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
    
    // MARK: - Lifecycle Delegate & State
    /// 生命周期代理（复用/点击等回调）
    public weak var lifecycleDelegate: JXPhotoCellLifecycleDelegate?

    /// 当前关联的真实索引
    public var currentIndex: Int?
    
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
        // 初始采用 frame 等于 scrollView 边界，缩放时由 UIScrollView 管理 contentSize
        imageView.frame = scrollView.bounds
        scrollView.contentSize = imageView.frame.size
        // 添加双击缩放
        scrollView.addGestureRecognizer(doubleTapGesture)
        // 添加单击关闭，并与双击冲突处理
        scrollView.addGestureRecognizer(singleTapGesture)
        singleTapGesture.require(toFail: doubleTapGesture)
        backgroundColor = .black
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    open override func prepareForReuse() {
        super.prepareForReuse()
        // 通知即将复用（携带上一次的 index）
        lifecycleDelegate?.photoCellWillReuse(self, lastIndex: currentIndex)
        // 清空旧图像与状态
        imageView.image = nil
        currentIndex = nil
        // 重置缩放与偏移
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
        scrollView.contentOffset = .zero
        // 恢复初始布局
        imageView.frame = scrollView.bounds
        scrollView.contentSize = imageView.frame.size
    }
    
    // MARK: - Transition Helper
    /// 若调用方提供的是 UIImageView，则可参与几何匹配 Zoom 动画
    open var transitionImageView: UIImageView? { imageView }

    open override func layoutSubviews() {
        super.layoutSubviews()
        // 在未缩放状态下，根据图片比例调整 imageView.frame
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            adjustImageViewFrame()
        }
        // 任何时候（包括缩放时），都对图片做居中处理
        centerImageIfNeeded()
    }

    // MARK: - Layout Helper
    /// 根据图片实际尺寸，调整 imageView 的 frame
    /// 根据图片实际尺寸，调整 imageView 的 frame（可覆写）
    open func adjustImageViewFrame() {
        guard let image = imageView.image else {
            // 无图时，重置为容器大小
            imageView.frame = scrollView.bounds
            scrollView.contentSize = imageView.frame.size
            return
        }
        let containerSize = scrollView.bounds.size
        // 容器或图片尺寸无效时，不做处理
        guard containerSize.width > 0, containerSize.height > 0, image.size.width > 0 else {
            return
        }
        
        // 宽度与容器一致，高度等比缩放
        let imageRatio = image.size.height / image.size.width
        let newWidth = containerSize.width
        let newHeight = newWidth * imageRatio
        
        imageView.frame = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
        scrollView.contentSize = imageView.frame.size
    }

    // MARK: - UIScrollViewDelegate
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageIfNeeded()
    }

    // MARK: - Helpers
    /// 在内容小于容器时居中展示（可覆写）
    open func centerImageIfNeeded() {
        let boundsSize = scrollView.bounds.size
        var frameToCenter = imageView.frame

        // 计算水平/垂直偏移以在内容小于可视区域时居中
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) * 0.5
        } else {
            frameToCenter.origin.x = 0
        }

        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) * 0.5
        } else {
            frameToCenter.origin.y = 0
        }

        imageView.frame = frameToCenter
    }

    @objc open func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let currentScale = scrollView.zoomScale
        if currentScale < 1.1 {
            let targetScale = min(2.0, scrollView.maximumZoomScale)
            let tapPointInScroll = gesture.location(in: scrollView)
            let tapPointInImage = imageView.convert(tapPointInScroll, from: scrollView)
            let rect = zoomRect(for: targetScale, centeredAt: tapPointInImage)
            scrollView.zoom(to: rect, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }

    /// 计算目标缩放矩形（可覆写）
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
        lifecycleDelegate?.photoCellDidSingleTap(self)
    }
}
