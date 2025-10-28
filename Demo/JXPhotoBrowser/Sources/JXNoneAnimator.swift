//
//  NoneAnimator.swift
//  JXPhotoBrowser
//

import UIKit

class JXNoneAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }
    
    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.0 }
    
    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let container = ctx.containerView
        if isPresenting {
            if let toView = ctx.view(forKey: .to) { container.addSubview(toView) }
            ctx.completeTransition(true)
        } else {
            if let fromView = ctx.view(forKey: .from) { fromView.removeFromSuperview() }
            ctx.completeTransition(true)
        }
    }
}
