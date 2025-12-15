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

        // 前置条件不满足则直接降级为淡入
        guard let originView = toVC.delegate?.photoBrowser(toVC, zoomOriginViewAt: toVC.initialIndex),
              let zoomView = toVC.delegate?.photoBrowser(toVC, zoomViewForItemAt: toVC.initialIndex, isPresenting: true),
              let targetIV = toVC.visiblePhotoCell()?.transitionImageView, targetIV.bounds.size != .zero else {
            toView.alpha = 0
            UIView.animate(withDuration: duration, animations: {
                toView.alpha = 1
            }) { finished in
                ctx.completeTransition(finished)
            }
            return
        }

        // 起止几何
        let startFrame = originView.convert(originView.bounds, to: container)
        let endFrame = targetIV.convert(targetIV.bounds, to: container)

        // 隐藏真实视图，避免重影
        // 仍需隐藏起点视图以避免动画期间的重影；业务方若有外部控制可同步处理
        originView.isHidden = true
        targetIV.isHidden = true

        // 使用业务方提供的 ZoomView 作为临时视图
        zoomView.frame = startFrame
        container.addSubview(zoomView)

        UIView.animate(withDuration: duration, animations: {
            zoomView.frame = endFrame
//            toView.alpha = 1
        }) { finished in
            // 还原
            targetIV.isHidden = false
            originView.isHidden = false
            zoomView.removeFromSuperview()
            ctx.completeTransition(finished)
        }
    }
}
