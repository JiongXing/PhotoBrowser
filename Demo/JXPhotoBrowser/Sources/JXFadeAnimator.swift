//
//  FadeAnimator.swift
//  JXPhotoBrowser
//

import UIKit

class JXFadeAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }
    
    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.25 }
    
    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let container = ctx.containerView
        if isPresenting {
            guard let toView = ctx.view(forKey: .to) else {
                ctx.completeTransition(false)
                return
            }
            container.addSubview(toView)
            toView.alpha = 0
            UIView.animate(withDuration: transitionDuration(using: ctx), animations: {
                toView.alpha = 1
            }) { finished in
                ctx.completeTransition(finished)
            }
        } else {
            guard let fromView = ctx.view(forKey: .from) else {
                ctx.completeTransition(false)
                return
            }
            if let toView = ctx.view(forKey: .to) {
                container.insertSubview(toView, belowSubview: fromView)
                toView.alpha = 1
            }
            UIView.animate(withDuration: transitionDuration(using: ctx), animations: {
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
