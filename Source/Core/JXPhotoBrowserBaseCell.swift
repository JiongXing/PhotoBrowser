//
//  JXPhotoBrowserBaseCell.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import UIKit

open class JXPhotoBrowserBaseCell: UICollectionViewCell {
    /// ImageView
    open var imageView = UIImageView()
    
    /// 图片缩放容器
    open var imageContainer = UIScrollView()
    
    /// 图片允许的最大放大倍率
    open var imageMaximumZoomScale: CGFloat = 2.0
    
    /// 单击时回调
    open var clickCallback: ((UITapGestureRecognizer) -> Void)?
    
    /// 长按时回调
    open var longPressedCallback: ((UILongPressGestureRecognizer) -> Void)?
    
    /// 图片拖动时回调
    open var panChangedCallback: ((_ scale: CGFloat) -> Void)?
    
    /// 图片拖动松手回调。isDown: 是否向下
    open var panReleasedCallback: ((_ isDown: Bool) -> Void)?
    
    /// 是否需要添加长按手势。子类可重写本属性，返回`false`即可避免添加长按手势
    open var isNeededLongPressGesture: Bool {
        return true
    }
    
    /// 记录pan手势开始时imageView的位置
    private var beganFrame = CGRect.zero
    
    /// 记录pan手势开始时，手势位置
    private var beganTouch = CGPoint.zero
    
    //
    // MARK: - Life Cycle
    //
    
    /// 初始化
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageContainer)
        imageContainer.maximumZoomScale = imageMaximumZoomScale
        imageContainer.delegate = self
        imageContainer.showsVerticalScrollIndicator = false
        imageContainer.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            imageContainer.contentInsetAdjustmentBehavior = .never
        }
        
        imageContainer.addSubview(imageView)
        imageView.clipsToBounds = true
        
        // 长按手势
        if isNeededLongPressGesture {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(_:)))
            contentView.addGestureRecognizer(longPress)
        }
        
        // 双击手势
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(onDoubleClick(_:)))
        doubleTap.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTap)
        
        // 单击手势
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(onClick(_:)))
        contentView.addGestureRecognizer(singleTap)
        singleTap.require(toFail: doubleTap)
        
        // 拖动手势
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        pan.delegate = self
        // 必须加在图片容器上。不能加在contentView上，否则长图下拉不能触发
        imageContainer.addGestureRecognizer(pan)
        // 子类作进一步初始化
        didInit()
    }
    
    /// 初始化完成时调用，空实现。子类可重写本方法以作进一步初始化
    open func didInit() {
        // 子类重写
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        imageContainer.frame = contentView.bounds
        imageContainer.setZoomScale(1.0, animated: false)
        imageView.frame = fitFrame
        imageContainer.setZoomScale(1.0, animated: false)
    }
}

//
// MARK: - Private
//

extension JXPhotoBrowserBaseCell {
    /// 计算图片复位坐标
    private var resettingCenter: CGPoint {
        let deltaWidth = bounds.width - imageContainer.contentSize.width
        let offsetX = deltaWidth > 0 ? deltaWidth * 0.5 : 0
        let deltaHeight = bounds.height - imageContainer.contentSize.height
        let offsetY = deltaHeight > 0 ? deltaHeight * 0.5 : 0
        return CGPoint(x: imageContainer.contentSize.width * 0.5 + offsetX,
                       y: imageContainer.contentSize.height * 0.5 + offsetY)
    }
    
    /// 计算图片适合的size
    private var fitSize: CGSize {
        guard let image = imageView.image else {
            return CGSize.zero
        }
        var width: CGFloat
        var height: CGFloat
        if imageContainer.bounds.width < imageContainer.bounds.height {
            // 竖屏
            width = imageContainer.bounds.width
            height = (image.size.height / image.size.width) * width
        } else {
            // 横屏
            height = imageContainer.bounds.height
            width = (image.size.width / image.size.height) * height
            if width > imageContainer.bounds.width {
                width = imageContainer.bounds.width
                height = (image.size.height / image.size.width) * width
            }
        }
        return CGSize(width: width, height: height)
    }
    
    /// 计算图片适合的frame
    private var fitFrame: CGRect {
        let size = fitSize
        let y = imageContainer.bounds.height > size.height
            ? (imageContainer.bounds.height - size.height) * 0.5 : 0
        let x = imageContainer.bounds.width > size.width
            ? (imageContainer.bounds.width - size.width) * 0.5 : 0
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
    
    /// 复位ImageView
    private func resetImageView() {
        // 如果图片当前显示的size小于原size，则重置为原size
        let size = fitSize
        let needResetSize = imageView.bounds.size.width < size.width
            || imageView.bounds.size.height < size.height
        UIView.animate(withDuration: 0.25) {
            self.imageView.center = self.resettingCenter
            if needResetSize {
                self.imageView.bounds.size = size
            }
        }
    }
}

//
// MARK: - Events
//

extension JXPhotoBrowserBaseCell {
    /// 响应拖动
    @objc private func onPan(_ pan: UIPanGestureRecognizer) {
        guard imageView.image != nil else {
            return
        }
        switch pan.state {
        case .began:
            beganFrame = imageView.frame
            beganTouch = pan.location(in: imageContainer)
        case .changed:
            let result = panResult(pan)
            imageView.frame = result.0
            panChangedCallback?(result.1)
        case .ended, .cancelled:
            imageView.frame = panResult(pan).0
            let isDown = pan.velocity(in: self).y > 0
            self.panReleasedCallback?(isDown)
            if !isDown {
                resetImageView()
            }
        default:
            resetImageView()
        }
    }
    
    /// 计算拖动时图片应调整的frame和scale值
    private func panResult(_ pan: UIPanGestureRecognizer) -> (CGRect, CGFloat) {
        // 拖动偏移量
        let translation = pan.translation(in: imageContainer)
        let currentTouch = pan.location(in: imageContainer)
        
        // 由下拉的偏移值决定缩放比例，越往下偏移，缩得越小。scale值区间[0.3, 1.0]
        let scale = min(1.0, max(0.3, 1 - translation.y / bounds.height))
        
        let width = beganFrame.size.width * scale
        let height = beganFrame.size.height * scale
        
        // 计算x和y。保持手指在图片上的相对位置不变。
        // 即如果手势开始时，手指在图片X轴三分之一处，那么在移动图片时，保持手指始终位于图片X轴的三分之一处
        let xRate = (beganTouch.x - beganFrame.origin.x) / beganFrame.size.width
        let currentTouchDeltaX = xRate * width
        let x = currentTouch.x - currentTouchDeltaX
        
        let yRate = (beganTouch.y - beganFrame.origin.y) / beganFrame.size.height
        let currentTouchDeltaY = yRate * height
        let y = currentTouch.y - currentTouchDeltaY
        
        return (CGRect(x: x.isNaN ? 0 : x, y: y.isNaN ? 0 : y, width: width, height: height), scale)
    }
    
    /// 响应单击
    @objc private func onClick(_ tap: UITapGestureRecognizer) {
        clickCallback?(tap)
    }
    
    /// 响应双击
    @objc private func onDoubleClick(_ tap: UITapGestureRecognizer) {
        // 如果当前没有任何缩放，则放大到目标比例，否则重置到原比例
        if imageContainer.zoomScale == 1.0 {
            // 以点击的位置为中心，放大
            let pointInView = tap.location(in: imageView)
            let width = imageContainer.bounds.size.width / imageContainer.maximumZoomScale
            let height = imageContainer.bounds.size.height / imageContainer.maximumZoomScale
            let x = pointInView.x - (width / 2.0)
            let y = pointInView.y - (height / 2.0)
            imageContainer.zoom(to: CGRect(x: x, y: y, width: width, height: height), animated: true)
        } else {
            imageContainer.setZoomScale(1.0, animated: true)
        }
    }
    
    /// 响应长按
    @objc private func onLongPress(_ press: UILongPressGestureRecognizer) {
        if press.state == .began {
            longPressedCallback?(press)
        }
    }
}

//
// MARK: - UIScrollViewDelegate
//

extension JXPhotoBrowserBaseCell: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = resettingCenter
    }
}


//
// MARK: - UIGestureRecognizerDelegate
//

extension JXPhotoBrowserBaseCell: UIGestureRecognizerDelegate {
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 只响应pan手势
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let velocity = pan.velocity(in: self)
        // 向上滑动时，不响应手势
        if velocity.y < 0 {
            return false
        }
        // 横向滑动时，不响应pan手势
        if abs(Int(velocity.x)) > Int(velocity.y) {
            return false
        }
        // 向下滑动，如果图片顶部超出可视区域，不响应手势
        if imageContainer.contentOffset.y > 0 {
            return false
        }
        // 响应允许范围内的下滑手势
        return true
    }
}

