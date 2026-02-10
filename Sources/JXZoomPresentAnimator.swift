//
//  ZoomPresentAnimator.swift
//  JXPhotoBrowser
//

import UIKit

open class JXZoomPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    open func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    open func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let container = ctx.containerView
        let duration = transitionDuration(using: ctx)

        guard let toVC = ctx.viewController(forKey: .to) as? JXPhotoBrowserViewController,
              let toView = ctx.view(forKey: .to) else {
            ctx.completeTransition(false)
            return
        }

        // 添加目标视图并强制布局，确保 collectionView 有可见 Cell
        container.addSubview(toView)
        toView.frame = ctx.finalFrame(for: toVC)
        toView.layoutIfNeeded()
        
        // 滚动到初始位置，确保目标 Cell 可见
        toVC.scrollToInitialIndexIfNeeded()
        toVC.collectionView.layoutIfNeeded()

        // 检查前置条件：需要源缩略图视图
        guard let thumbnailView = toVC.delegate?.photoBrowser(toVC, thumbnailViewAt: toVC.initialIndex) else {
            fallbackToFade(toView: toView, duration: duration, ctx: ctx)
            return
        }
        
        let visibleCell = toVC.visibleCell()
        let targetIV = visibleCell?.transitionImageView

        // 起止几何
        let startFrame = thumbnailView.convert(thumbnailView.bounds, to: container)
        
        // 计算目标 frame：优先使用 targetIV，否则基于缩略图比例计算居中位置
        let endFrame: CGRect
        if let targetIV = targetIV, targetIV.bounds.size != .zero {
            endFrame = targetIV.convert(targetIV.bounds, to: container)
        } else {
            // targetIV 不可用（图片未加载），基于缩略图的比例计算目标位置
            let containerSize = container.bounds.size
            let originSize = thumbnailView.bounds.size
            guard originSize.width > 0, originSize.height > 0 else {
                fallbackToFade(toView: toView, duration: duration, ctx: ctx)
                return
            }
            // 按 AspectFit 计算目标尺寸
            let scale = min(containerSize.width / originSize.width, containerSize.height / originSize.height)
            let targetWidth = originSize.width * scale
            let targetHeight = originSize.height * scale
            let targetX = (containerSize.width - targetWidth) / 2
            let targetY = (containerSize.height - targetHeight) / 2
            endFrame = CGRect(x: targetX, y: targetY, width: targetWidth, height: targetHeight)
        }

        // 框架自动构造临时 ZoomView（无需业务方提供）
        let zoomView = Self.makeZoomView(from: thumbnailView)

        // 隐藏真实视图，避免重影
        thumbnailView.isHidden = true
        targetIV?.isHidden = true
        toView.backgroundColor = .clear

        zoomView.frame = startFrame
        container.addSubview(zoomView)

        UIView.animate(withDuration: duration, animations: {
            zoomView.frame = endFrame
            toView.backgroundColor = .black
        }) { finished in
            // 还原
            targetIV?.isHidden = false
            thumbnailView.isHidden = false
            zoomView.removeFromSuperview()
            ctx.completeTransition(finished)
        }
    }
    
    // MARK: - Helpers
    
    /// 基于源视图自动构造转场用的临时 UIImageView
    private static func makeZoomView(from sourceView: UIView) -> UIImageView {
        let zoomIV = UIImageView()
        if let imageView = sourceView as? UIImageView {
            zoomIV.image = imageView.image
            zoomIV.contentMode = imageView.contentMode
        } else {
            // 非 UIImageView 时，截取源视图快照
            let renderer = UIGraphicsImageRenderer(bounds: sourceView.bounds)
            zoomIV.image = renderer.image { ctx in
                sourceView.drawHierarchy(in: sourceView.bounds, afterScreenUpdates: false)
            }
            zoomIV.contentMode = .scaleAspectFill
        }
        zoomIV.clipsToBounds = true
        return zoomIV
    }
    
    /// 降级为淡入动画
    private func fallbackToFade(toView: UIView, duration: TimeInterval, ctx: UIViewControllerContextTransitioning) {
        toView.alpha = 0
        UIView.animate(withDuration: duration, animations: {
            toView.alpha = 1
        }) { finished in
            ctx.completeTransition(finished)
        }
    }
}
