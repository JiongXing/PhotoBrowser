//
//  JXPhotoBrowserTransitioning.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/15.
//

import Foundation

open class JXPhotoBrowserTransitioning: NSObject, JXPhotoBrowserTransitioningDelegate {
    
    /// 弱引用 PhotoBrowser
    public weak var browser: JXPhotoBrowser?
    
    public var maskAlpha: CGFloat {
        set {
            presentCtrl?.maskView.alpha = newValue
        }
        get {
            return presentCtrl?.maskView.alpha ?? 0
        }
    }
    
    /// present转场动画
    open var presentingAnimator: UIViewControllerAnimatedTransitioning?
    
    /// dismiss转场动画
    open var dismissingAnimator: UIViewControllerAnimatedTransitioning?
    
    private weak var presentCtrl: JXPhotoBrowserPresentationController?
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presentingAnimator
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissingAnimator
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let ctrl = JXPhotoBrowserPresentationController(presentedViewController: presented, presenting: presenting)
        presentCtrl = ctrl
        return ctrl
    }
}
