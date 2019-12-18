//
//  JXPhotoBrowserFadeAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/25.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

open class JXPhotoBrowserFadeAnimator: NSObject, JXPhotoBrowserAnimatedTransitioning {
    
    open var showDuration: TimeInterval = 0.25
    
    open var dismissDuration: TimeInterval = 0.25
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isForShow ? showDuration : dismissDuration
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let browser = photoBrowser else {
            transitionContext.completeTransition(false)
            return
        }
        if isForShow {
            browser.maskView.alpha = 0
            browser.browserView.alpha = 0
            if let toView = transitionContext.view(forKey: .to) {
                transitionContext.containerView.addSubview(toView)
            }
        }
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            browser.maskView.alpha = self.isForShow ? 1.0 : 0
            browser.browserView.alpha = self.isForShow ? 1.0 : 0
        }) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
