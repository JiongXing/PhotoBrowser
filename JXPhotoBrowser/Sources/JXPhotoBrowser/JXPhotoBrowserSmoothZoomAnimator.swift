//
//  JXPhotoBrowserSmoothZoomAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

/// 更丝滑的Zoom动画
open class JXPhotoBrowserSmoothZoomAnimator: NSObject, JXPhotoBrowserTransitionAnimator {
    
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
        guard let (transitionView, thumbnailFrame, destinationFrame) = transitionViewAndFrames(with: browser) else {
            JXPhotoBrowserLog.high("取不到Frames!")
            substituteAnimator.isForShow = isForShow
            substituteAnimator.photoBrowser = photoBrowser
            substituteAnimator.animateTransition(using: transitionContext)
            return
        }
        browser.browserView.isHidden = true
        if isForShow {
            browser.maskView.alpha = 0
            if let toView = transitionContext.view(forKey: .to) {
                transitionContext.containerView.addSubview(toView)
            }
        }
        transitionView.frame = isForShow ? thumbnailFrame : destinationFrame
        transitionContext.containerView.addSubview(transitionView)
        UIView.animate(withDuration: showDuration, animations: {
            browser.maskView.alpha = self.isForShow ? 1.0 : 0
            transitionView.frame = self.isForShow ? destinationFrame : thumbnailFrame
        }) { _ in
            browser.browserView.isHidden = false
            transitionView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    public typealias TransitionViewAndFrame = (transitionView: UIView, thumbnailFrame: CGRect)
    public typealias TransitionViewAndFrameProvider = (_ index: Int, _ destinationView: UIView) -> TransitionViewAndFrame?
    
    /// 获取转场缩放的视图与前置Frame
    open var transitionViewAndFrameProvider: TransitionViewAndFrameProvider = { _, _ in nil }
    
    /// 替补的动画方案
    open lazy var substituteAnimator: JXPhotoBrowserTransitionAnimator = JXPhotoBrowserFadeAnimator()
    
    public init(transitionViewAndFrame: @escaping TransitionViewAndFrameProvider) {
        transitionViewAndFrameProvider = transitionViewAndFrame
    }
    
    private func transitionViewAndFrames(with browser: JXPhotoBrowser) -> (UIView, CGRect, CGRect)? {
        let browserView = browser.browserView
        let destinationView = browser.view!
        guard let transitionContext = transitionViewAndFrameProvider(browser.pageIndex, destinationView) else {
            return nil
        }
        guard let cell = browserView.visibleCells[browserView.pageIndex] as? JXPhotoBrowserZoomSupportedCell else {
            return nil
        }
        let showContentView = cell.showContentView
        let destinationFrame = showContentView.convert(showContentView.bounds, to: destinationView)
        return (transitionContext.transitionView, transitionContext.thumbnailFrame, destinationFrame)
    }
    
    open func show(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
        guard let (transitionView, thumbnailFrame, destinationFrame) = transitionViewAndFrames(with: browser) else {
            substituteAnimator.show(browser: browser, completion: completion)
            return
        }
        transitionView.frame = thumbnailFrame
        browser.view.addSubview(transitionView)
        UIView.animate(withDuration: showDuration, animations: {
            browser.maskView.alpha = 1.0
            transitionView.frame = destinationFrame
        }) { _ in
            transitionView.removeFromSuperview()
            completion()
        }
    }
    
    open func dismiss(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
        guard let (transitionView, thumbnailFrame, destinationFrame) = transitionViewAndFrames(with: browser) else {
            substituteAnimator.dismiss(browser: browser, completion: completion)
            return
        }
        transitionView.frame = destinationFrame
        browser.view.addSubview(transitionView)
        browser.browserView.alpha = 0
        UIView.animate(withDuration: dismissDuration, animations: {
            browser.maskView.alpha = 0
            transitionView.frame = thumbnailFrame
        }) { _ in
            transitionView.removeFromSuperview()
            completion()
        }
    }
}
