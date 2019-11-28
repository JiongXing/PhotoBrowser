//
//  JXPhotoBrowserZoomAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

open class JXPhotoBrowserZoomAnimator: JXPhotoBrowserTransitionAnimator {
    
    public typealias PreviousViewAtIndexClosure = (_ index: Int) -> UIView?
    
    /// 转场动画的前向视图
    open var previousViewClosure: PreviousViewAtIndexClosure = { _ in nil }
    
    open var showDuration: TimeInterval = 0.25
    
    open var dismissDuration: TimeInterval = 0.25
    
    public init(previousView: @escaping PreviousViewAtIndexClosure) {
        previousViewClosure = previousView
    }
    
    open func show(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
        guard let (snap1, snap2, preFrame, bigFrame) = snapshotsAndFrames(browser: browser) else {
            return
        }
        snap1.frame = preFrame
        snap2.frame = preFrame
        snap2.alpha = 0
        browser.view.addSubview(snap2)
        browser.view.addSubview(snap1)
        UIView.animate(withDuration: showDuration, animations: {
            browser.maskView.alpha = 1.0
            snap1.frame = bigFrame
            snap2.frame = bigFrame
            snap1.alpha = 0
            snap2.alpha = 1.0
        }) { _ in
            snap1.removeFromSuperview()
            snap2.removeFromSuperview()
            completion()
        }
    }
    
    open func dismiss(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
        guard let (snap1, snap2, preFrame, bigFrame) = snapshotsAndFrames(browser: browser) else {
            return
        }
        snap1.frame = bigFrame
        snap2.frame = bigFrame
        snap1.alpha = 0
        browser.view.addSubview(snap2)
        browser.view.addSubview(snap1)
        browser.browserView.alpha = 0
        UIView.animate(withDuration: dismissDuration, animations: {
            browser.maskView.alpha = 0
            snap1.frame = preFrame
            snap2.frame = preFrame
            snap1.alpha = 1.0
            snap2.alpha = 0
        }) { _ in
            snap1.removeFromSuperview()
            snap2.removeFromSuperview()
            completion()
        }
    }
    
    private func snapshotsAndFrames(browser: JXPhotoBrowser) -> (UIView, UIView, CGRect, CGRect)? {
        let browserView = browser.browserView
        let view = browser.view
        let closure = previousViewClosure
        guard let previousView = closure(browserView.pageIndex), let cell = browserView.visibleCells[browserView.pageIndex] as? JXPhotoBrowserZoomSupportedCell else {
            return nil
        }
        let showContentView = cell.showContentView
        let preFrame = previousView.convert(previousView.bounds, to: view)
        let intersection = cell.bounds.intersection(showContentView.frame)
        let bigFrame = cell.convert(intersection, to: view)
        guard let snap1 = previousView.resizableSnapshotView(from: previousView.bounds, afterScreenUpdates: false, withCapInsets: .zero),
            let snap2 = cell.resizableSnapshotView(from: bigFrame, afterScreenUpdates: true, withCapInsets: .zero) else {
                return nil
        }
        return (snap1, snap2, preFrame, bigFrame)
    }
}
