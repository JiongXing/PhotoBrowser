//
//  JXPhotoBrowserNoneAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

open class JXPhotoBrowserNoneAnimator: NSObject, JXPhotoBrowserAnimatedTransitioning {
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        transitionContext.completeTransition(transitionContext.transitionWasCancelled)
    }
    
    
    open func show(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
        completion()
    }
    
    open func dismiss(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
        completion()
    }
}
