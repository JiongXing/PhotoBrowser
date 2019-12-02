//
//  JXPhotoBrowserZoomAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

/// Zoom动画
open class JXPhotoBrowserZoomAnimator: JXPhotoBrowserTransitionAnimator {
    
    public typealias PreviousViewAtIndexClosure = (_ index: Int) -> UIView?
    
    /// 转场动画的前向视图
    open var previousViewClosure: PreviousViewAtIndexClosure = { _ in nil }
    
    open var showDuration: TimeInterval = 0.25
    
    open var dismissDuration: TimeInterval = 0.25
    
    /// 替补的动画方案
    open lazy var substituteAnimator: JXPhotoBrowserTransitionAnimator = JXPhotoBrowserFadeAnimator()
    
    public init(previousView: @escaping PreviousViewAtIndexClosure) {
        previousViewClosure = previousView
    }
    
    open func show(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
        guard let (snap1, snap2, thumbnailFrame, destinationFrame) = snapshotsAndFrames(browser: browser) else {
            substituteAnimator.show(browser: browser, completion: completion)
            return
        }
        // 为了衔接内容展现方式可能不一致的缩略图和大图，
        // 分别取两端的截图，并同时改变它们的alpha值。
        snap1.frame = thumbnailFrame
        snap2.frame = thumbnailFrame
        snap2.alpha = 0
        browser.view.addSubview(snap2)
        browser.view.addSubview(snap1)
        UIView.animate(withDuration: showDuration, animations: {
            browser.maskView.alpha = 1.0
            snap1.frame = destinationFrame
            snap2.frame = destinationFrame
            snap1.alpha = 0
            snap2.alpha = 1.0
        }) { _ in
            snap1.removeFromSuperview()
            snap2.removeFromSuperview()
            completion()
        }
    }
    
    open func dismiss(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
        guard let (snap1, snap2, thumbnailFrame, destinationFrame) = snapshotsAndFrames(browser: browser) else {
            substituteAnimator.dismiss(browser: browser, completion: completion)
            return
        }
        snap1.frame = destinationFrame
        snap2.frame = destinationFrame
        snap1.alpha = 0
        browser.view.addSubview(snap2)
        browser.view.addSubview(snap1)
        browser.browserView.alpha = 0
        UIView.animate(withDuration: dismissDuration, animations: {
            browser.maskView.alpha = 0
            snap1.frame = thumbnailFrame
            snap2.frame = thumbnailFrame
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
        guard let previousView = closure(browserView.pageIndex) else {
            JXPhotoBrowserLog.high("取不到前视图！")
            return nil
        }
        JXPhotoBrowserLog.high("browserView.pageIndex:\(browserView.pageIndex)")
        JXPhotoBrowserLog.high("visibleCells:\(browserView.visibleCells)")
        guard let cell = browserView.visibleCells[browserView.pageIndex] as? JXPhotoBrowserZoomSupportedCell else {
            JXPhotoBrowserLog.high("取不到后视图！")
            return nil
        }
        let thumbnailFrame = previousView.convert(previousView.bounds, to: view)
        let showContentView = cell.showContentView
        // 两Rect求交集，得出显示中的区域
        let intersection = cell.bounds.intersection(showContentView.frame)
        let destinationFrame = cell.convert(intersection, to: view)
        guard let snap1 = previousView.resizableSnapshotView(from: previousView.bounds, afterScreenUpdates: false, withCapInsets: .zero),
            let snap2 = cell.resizableSnapshotView(from: destinationFrame, afterScreenUpdates: true, withCapInsets: .zero) else {
                JXPhotoBrowserLog.high("取不到前后截图！")
                return nil
        }
        return (snap1, snap2, thumbnailFrame, destinationFrame)
    }
}
