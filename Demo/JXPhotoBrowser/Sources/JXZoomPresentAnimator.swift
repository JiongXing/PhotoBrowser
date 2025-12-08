//
//  ZoomPresentAnimator.swift
//  JXPhotoBrowser
//

import UIKit
import AVFoundation

open class JXZoomPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    open func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    open func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let container = ctx.containerView
        let duration = transitionDuration(using: ctx)

        guard let toVC = ctx.viewController(forKey: .to) as? JXPhotoBrowser,
              let toView = ctx.view(forKey: .to) else {
            ctx.completeTransition(false)
            return
        }

        container.addSubview(toView)
        toView.alpha = 0
        toView.layoutIfNeeded()

        // 确保初始 Cell 已经就绪，避免目标视图为空
        toVC.prepareForPresentTransitionIfNeeded()

        // 前置条件不满足则直接降级为淡入
        guard let originView = toVC.delegate?.photoBrowser(toVC, zoomOriginViewAt: toVC.initialIndex),
              let zoomView = toVC.delegate?.photoBrowser(toVC, zoomViewForItemAt: toVC.initialIndex, isPresenting: true),
              let targetIV = toVC.visiblePhotoCell()?.transitionImageView, targetIV.bounds.size != .zero else {
            animateFadeIn(view: toView, duration: duration, ctx: ctx)
            return
        }

        // 起止几何
        let startFrame = originView.convert(originView.bounds, to: container)
        let endFrame = targetIV.convert(targetIV.bounds, to: container)

        // 隐藏真实视图，避免重影
        originView.isHidden = true
        targetIV.isHidden = true

        // 使用业务方提供的 ZoomView 作为临时视图
        zoomView.frame = startFrame
        container.addSubview(zoomView)

        UIView.animate(withDuration: duration, animations: {
            zoomView.frame = endFrame
            toView.alpha = 1
        }) { finished in
            // 还原
            targetIV.isHidden = false
            // originView.isHidden = false // 保持隐藏，交由浏览器或 Dismiss 动画处理
            zoomView.removeFromSuperview()
            ctx.completeTransition(finished)
        }
    }

    // MARK: - Helpers

    /// 降级为淡入动画（可覆写）
    open func animateFadeIn(view: UIView, duration: TimeInterval, ctx: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: duration, animations: {
            view.alpha = 1
        }) { finished in
            ctx.completeTransition(finished)
        }
    }
}
