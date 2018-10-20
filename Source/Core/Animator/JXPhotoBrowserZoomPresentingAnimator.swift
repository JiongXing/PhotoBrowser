//
//  JXPhotoBrowserZoomPresentingAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/16.
//

import Foundation

public class JXPhotoBrowserZoomPresentingAnimator: JXPhotoBrowserZoomAnimator, UIViewControllerAnimatedTransitioning {
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
        containerView.addSubview(zView)
        zView.frame = sFrame
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            zView.frame = eFrame
        }) { _ in
            // presentation转场时，需要把目标视图添加到视图栈
            if let presentedView = transitionContext.view(forKey: .to) {
                containerView.addSubview(presentedView)
            }
            zView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func fadeTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let duration = self.transitionDuration(using: transitionContext)
        if let view = transitionContext.view(forKey: .to) {
            // presentation转场，需要把目标视图添加到视图栈
            containerView.addSubview(view)
            view.alpha = 0
            UIView.animate(withDuration: duration, animations: {
                view.alpha = 1.0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}
