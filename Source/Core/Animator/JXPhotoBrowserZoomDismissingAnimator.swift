//
//  JXPhotoBrowserZoomDismissingAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/16.
//

import Foundation

public class JXPhotoBrowserZoomDismissingAnimator: JXPhotoBrowserZoomAnimator, UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 转场容器
        let containerView = transitionContext.containerView
        guard let zView = zoomView(),
            let sFrame = startFrame(containerView),
            let eFrame = endFrame(containerView) else {
                // 转为执行Fade动画
                fadeTransition(using: transitionContext)
                return
        }
        // 把当前视图隐藏，只显示zoomView
        if let view = transitionContext.view(forKey: .from) {
            view.isHidden = true
        }
        containerView.addSubview(zView)
        zView.frame = sFrame
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            zView.frame = eFrame
        }) { _ in
            zView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func fadeTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let duration = self.transitionDuration(using: transitionContext)
        if let view = transitionContext.view(forKey: .from) {
            UIView.animate(withDuration: duration, animations: {
                view.alpha = 0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}
