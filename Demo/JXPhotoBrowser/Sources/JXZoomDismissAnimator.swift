//
//  ZoomDismissAnimator.swift
//  JXPhotoBrowser
//

import UIKit
import AVFoundation

class JXZoomDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
        func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.25 }
        
        func animateTransition(using ctx: UIViewControllerContextTransitioning) {
            let container = ctx.containerView
            let duration = transitionDuration(using: ctx)
            
            guard
                let fromVC = ctx.viewController(forKey: .from) as? JXPhotoBrowser,
                let fromView = ctx.view(forKey: .from)
            else {
                ctx.completeTransition(false)
                return
            }
            
            if let toView = ctx.view(forKey: .to) {
                container.insertSubview(toView, belowSubview: fromView)
                toView.alpha = 1
            }
            
            let srcIV = fromVC.visiblePhotoImageView()
            var startFrame: CGRect = .zero
            var endFrame: CGRect = .zero
            var destView: UIView?

            let currentIndex = fromVC.currentRealIndex()
            let zoomView = currentIndex.flatMap { fromVC.dataSource?.photoBrowser(fromVC, zoomViewForItemAt: $0, isPresenting: false) }

            if let iv = srcIV, let idx = currentIndex, let zv = zoomView {
                startFrame = iv.convert(iv.bounds, to: container)
                iv.isHidden = true
                if let origin = fromVC.dataSource?.photoBrowser(fromVC, zoomOriginViewAt: idx) {
                    destView = origin
                    endFrame = origin.convert(origin.bounds, to: container)
                    origin.isHidden = true

                    // 使用业务方提供的 ZoomView 作为临时视图
                    zv.frame = startFrame
                    container.addSubview(zv)

                    UIView.animate(withDuration: duration, animations: {
                        zv.frame = endFrame
                        fromView.alpha = 0
                    }) { _ in
                        let wasCancelled = ctx.transitionWasCancelled
                        if wasCancelled {
                            iv.isHidden = false
                            destView?.isHidden = false
                            zv.removeFromSuperview()
                            fromView.alpha = 1
                            ctx.completeTransition(false)
                        } else {
                            destView?.isHidden = false
                            zv.removeFromSuperview()
                            fromView.removeFromSuperview()
                            ctx.completeTransition(true)
                        }
                    }
                    return
                }
            }

            // 降级为 fade 动画（不缩放）
            UIView.animate(withDuration: duration, animations: {
                fromView.alpha = 0
            }) { _ in
                let wasCancelled = ctx.transitionWasCancelled
                if wasCancelled {
                    fromView.alpha = 1
                    ctx.completeTransition(false)
                } else {
                    fromView.removeFromSuperview()
                    ctx.completeTransition(true)
                }
            }
        }
}