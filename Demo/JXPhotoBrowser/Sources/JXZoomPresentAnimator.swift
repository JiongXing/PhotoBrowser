//
//  ZoomPresentAnimator.swift
//  JXPhotoBrowser
//

import UIKit
import AVFoundation

class JXZoomPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let container = ctx.containerView
        let duration = transitionDuration(using: ctx)
        
        guard
            let toVC = ctx.viewController(forKey: .to) as? JXPhotoBrowser,
            let toView = ctx.view(forKey: .to)
        else {
            ctx.completeTransition(false)
            return
        }
        
        container.addSubview(toView)
        toView.alpha = 0
        toView.layoutIfNeeded()
        
        // 确保初始 Cell 已经就绪，避免目标视图为空
        toVC.prepareForPresentTransitionIfNeeded()
        
        // 业务方提供的缩略图源视图（用于计算起点几何）
        let originView: UIView? = toVC.dataSource?.photoBrowser(toVC, zoomOriginViewAt: toVC.initialIndex)
        // 业务方提供的临时 ZoomView（用于整个动画过程展示，结束即移除）
        let zoomView: UIView? = toVC.dataSource?.photoBrowser(toVC, zoomViewForItemAt: toVC.initialIndex, isPresenting: true)
        
        // 起止几何
        var startFrame: CGRect = .zero
        let destIV = toVC.visiblePhotoCell()?.imageView
        var endFrame: CGRect = .zero
        
        if let ov = originView, let targetIV = destIV, let zv = zoomView {
            startFrame = ov.convert(ov.bounds, to: container)
            endFrame = targetIV.convert(targetIV.bounds, to: container)
            
            // 隐藏真实视图，避免重影
            ov.isHidden = true
            targetIV.isHidden = true
            
            // 使用业务方提供的 ZoomView 作为临时视图
            zv.frame = startFrame
            container.addSubview(zv)
            
            UIView.animate(withDuration: duration, animations: {
                zv.frame = endFrame
                toView.alpha = 1
            }) { finished in
                // 还原
                targetIV.isHidden = false
                ov.isHidden = false
                zv.removeFromSuperview()
                ctx.completeTransition(finished)
            }
        } else {
            // 缺少 ZoomView 或几何信息，降级为 fade 动画
            UIView.animate(withDuration: duration, animations: {
                toView.alpha = 1
            }) { finished in
                ctx.completeTransition(finished)
            }
        }
    }
}
