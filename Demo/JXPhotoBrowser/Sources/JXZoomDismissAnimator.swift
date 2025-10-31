//
//  ZoomDismissAnimator.swift
//  JXPhotoBrowser
//

import UIKit
import AVFoundation

class JXZoomDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    // 获取动画源的当前展示 Cell

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
            toView.layoutIfNeeded()
        }
        
        let srcCell = fromVC.visiblePhotoCell()
        let srcIV = srcCell?.imageView
        var startFrame: CGRect = .zero
        var endFrame: CGRect = .zero
        var originView: UIView?

        // 转场展示用的 ZoomView
        var zoomIV: UIImageView?
        if let tmplIV = srcIV {
            let copy = UIImageView()
            copy.image = tmplIV.image
            copy.contentMode = tmplIV.contentMode
            copy.clipsToBounds = tmplIV.clipsToBounds
            copy.layer.cornerRadius = tmplIV.layer.cornerRadius
            copy.backgroundColor = tmplIV.backgroundColor
            zoomIV = copy
        }
        
        if let iv = srcIV, let idx = srcCell?.currentIndex, let zv = zoomIV {
            startFrame = iv.convert(iv.bounds, to: container)
            iv.isHidden = true
            if let ov = fromVC.dataSource?.photoBrowser(fromVC, zoomOriginViewAt: idx) {
                originView = ov
                endFrame = ov.convert(ov.bounds, to: container)
                ov.isHidden = true
                
                zv.frame = startFrame
                container.addSubview(zv)
                
                UIView.animate(withDuration: duration, animations: {
                    zv.frame = endFrame
                    fromView.alpha = 0
                }) { _ in
                    originView?.isHidden = false
                    zv.removeFromSuperview()
                    fromView.removeFromSuperview()
                    ctx.completeTransition(true)
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
