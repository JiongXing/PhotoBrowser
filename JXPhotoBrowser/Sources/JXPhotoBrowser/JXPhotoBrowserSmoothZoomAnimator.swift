//
//  JXPhotoBrowserSmoothZoomAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

/// 更丝滑的Zoom动画
open class JXPhotoBrowserSmoothZoomAnimator: JXPhotoBrowserTransitionAnimator {
    
    public typealias TransitionContext = (transitionView: UIView, thumbnailFrame: CGRect)
    public typealias TransitionContextAtIndexClosure = (_ index: Int, _ destinationView: UIView) -> TransitionContext?
    
    /// 获取转场缩放的视图与前置Frame
    open var transitionContextClosure: TransitionContextAtIndexClosure = { _, _ in nil }
    
    open var showDuration: TimeInterval = 0.25
    
    open var dismissDuration: TimeInterval = 0.25
    
    /// 替补的动画方案
    open lazy var substituteAnimator: JXPhotoBrowserTransitionAnimator = JXPhotoBrowserFadeAnimator()
    
    public init(transitionContext: @escaping TransitionContextAtIndexClosure) {
        transitionContextClosure = transitionContext
    }
    
    private func transitionViewAndFrames(with browser: JXPhotoBrowser) -> (UIView, CGRect, CGRect)? {
        let browserView = browser.browserView
        let destinationView = browser.view!
        guard let transitionContext = transitionContextClosure(browser.pageIndex, destinationView) else {
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
