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
            var animImageView: UIImageView?
            var startFrame: CGRect = .zero
            var destView: UIView?
            var endFrame: CGRect = .zero
            var canZoom = false
            if let iv = srcIV, let img = iv.image, img.size.width > 0 && img.size.height > 0 {
                let fit = AVMakeRect(aspectRatio: img.size, insideRect: iv.bounds)
                startFrame = iv.convert(fit, to: container)
                let aiv = UIImageView(image: img)
                aiv.frame = startFrame
                aiv.contentMode = iv.contentMode
                aiv.clipsToBounds = true
                animImageView = aiv
                iv.isHidden = true
                if let currentIndex = fromVC.currentRealIndex(), let origin = fromVC.originViewProvider?(currentIndex) {
                    destView = origin
                    endFrame = origin.convert(origin.bounds, to: container)
                    origin.isHidden = true
                    canZoom = true
                }
            }
            
            if canZoom, let animIV = animImageView {
                container.addSubview(animIV)
                UIView.animate(withDuration: duration, animations: {
                    animIV.frame = endFrame
                    fromView.alpha = 0
                }) { _ in
                    let wasCancelled = ctx.transitionWasCancelled
                    if wasCancelled {
                        srcIV?.isHidden = false
                        destView?.isHidden = false
                        animIV.removeFromSuperview()
                        fromView.alpha = 1
                        ctx.completeTransition(false)
                    } else {
                        destView?.isHidden = false
                        animIV.removeFromSuperview()
                        fromView.removeFromSuperview()
                        ctx.completeTransition(true)
                    }
                }
            } else {
                // 降级为 fade 动画（不缩放），保持黑屏修复
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
}