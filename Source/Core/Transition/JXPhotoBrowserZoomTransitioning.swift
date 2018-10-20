//
//  JXPhotoBrowserZoomTransitioning.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/16.
//

import Foundation

public class JXPhotoBrowserZoomTransitioning: JXPhotoBrowserTransitioning {
    /// present转场时，内容缩张模式
    public var presentingZoomViewMode: () -> UIView.ContentMode = {
        return UIView.ContentMode.scaleAspectFill
    }
    
    /// dismiss转场时，内容缩张模式
    public var dismissingZoomViewMode: () -> UIView.ContentMode = {
        return UIView.ContentMode.scaleAspectFill
    }
    
    //
    // MARK: - 用户传入 ZoomView 的前置页面 Frame
    //
    
    public typealias FrameClosure = (
        _ browser: JXPhotoBrowser,
        _ pageIndex: Int,
        _ transContainer: UIView) -> CGRect?
    
    /// 取前置视图的Frame
    public var originFrameCallback: FrameClosure
    
    /// 初始化，传入动画 起始/结束 的前置视图 Frame
    public init(originFrameCallback: @escaping FrameClosure) {
        self.originFrameCallback = originFrameCallback
        super.init()
        setupPresenting()
        setupDismissing()
    }
    
    //
    // MARK: - 用户传入 ZoomView 的前置页面视图
    //
    
    public typealias ViewClosure = (
        _ browser: JXPhotoBrowser,
        _ pageIndex: Int,
        _ transContainer: UIView) -> UIView?
    
    /// 初始化，传入动画 起始/结束 的前置视图
    public convenience init(originViewCallback: @escaping ViewClosure) {
        let callback: FrameClosure = { (browser, index, view) -> CGRect? in
            if let oriView = originViewCallback(browser, index, view) {
                return oriView.convert(oriView.bounds, to: view)
            }
            return nil
        }
        self.init(originFrameCallback: callback)
    }
    
    private func setupPresenting() {
        weak var `self` = self
        presentingAnimator = JXPhotoBrowserZoomPresentingAnimator(zoomView: { () -> UIView? in
            guard let `self` = self else {
                print("JXPhotoBrowser.Transitioning.Zoom 已被释放.")
                return nil
            }
            let view = self.browser?.transitionZoomView
            view?.contentMode = self.presentingZoomViewMode()
            view?.clipsToBounds = true
            return view
        }, startFrame: { view -> CGRect? in
            if let browser = self?.browser {
                return self?.originFrameCallback(browser, browser.pageIndex, view)
            }
            return nil
        }, endFrame: { view -> CGRect? in
            if let contentView = self?.browser?.displayingContentView {
                return contentView.convert(contentView.bounds, to: view)
            }
            return nil
        })
    }
    
    private func setupDismissing() {
        weak var `self` = self
        dismissingAnimator = JXPhotoBrowserZoomDismissingAnimator(zoomView: { () -> UIView? in
            guard let `self` = self else {
                print("JXPhotoBrowser.Transitioning.Zoom 已被释放.")
                return nil
            }
            let view = self.browser?.transitionZoomView
            view?.contentMode = self.dismissingZoomViewMode()
            view?.clipsToBounds = true
            return view
        }, startFrame: { view -> CGRect? in
            if let contentView = self?.browser?.displayingContentView {
                return contentView.convert(contentView.bounds, to: view)
            }
            return nil
        }, endFrame: { view -> CGRect? in
            if let browser = self?.browser {
                return self?.originFrameCallback(browser, browser.pageIndex, view)
            }
            return nil
        })
    }
}
