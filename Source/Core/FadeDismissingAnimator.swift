//
//  FadeDismissingAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/16.
//

import Foundation

extension JXPhotoBrowser {
    public class FadeDismissingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
        public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 0.25
        }
        
        public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
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
}
