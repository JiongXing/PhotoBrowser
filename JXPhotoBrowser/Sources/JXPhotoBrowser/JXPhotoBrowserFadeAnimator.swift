//
//  JXPhotoBrowserFadeAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/25.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

open class JXPhotoBrowserFadeAnimator: NSObject, JXPhotoBrowserTransitionAnimator {
    
    open var showDuration: TimeInterval = 0.25
    
    open var dismissDuration: TimeInterval = 0.25
    
    open func show(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
//        UIView.animate(withDuration: showDuration, animations: {
//            browser.maskView.alpha = 1.0
//            browser.browserView.alpha = 1.0
//        }) { _ in
//            completion()
//        }
    }
    
    open func dismiss(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
//        UIView.animate(withDuration: dismissDuration, animations: {
//            browser.maskView.alpha = 0
//            browser.browserView.alpha = 0
//        }) { _ in
//            completion()
//        }
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isForShow ? showDuration : dismissDuration
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        JXPhotoBrowserLog.high("执行动画!")
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
