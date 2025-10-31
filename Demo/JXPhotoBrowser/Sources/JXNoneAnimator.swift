//
//  NoneAnimator.swift
//  JXPhotoBrowser
//

import UIKit

open class JXNoneAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    /// 是否为展示阶段动画
    public let isPresenting: Bool
    
    public init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }
    
    open func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.0 }
    
    open func animateTransition(using ctx: UIViewControllerContextTransitioning) {
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
