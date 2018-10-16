//
//  ZoomTransitioning.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/16.
//

import Foundation

extension JXPhotoBrowser {
    public class ZoomTransitioning: JXPhotoBrowser.Transitioning {
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
        
        public typealias FrameClosure = (_ browser: JXPhotoBrowser, _ View: UIView) -> CGRect?
        
        /// present转场时，动画起始位置
        public var presentingStartFrame: FrameClosure
        
        /// dismiss转场时，动画结束位置
        public var dismissingEndFrame: FrameClosure
        
        /// 初始化，传入动画 起始/结束 的前置页面 Frame
        public init(presentingStartFrame: @escaping FrameClosure,
                    dismissingEndFrame: @escaping FrameClosure) {
            self.presentingStartFrame = presentingStartFrame
            self.dismissingEndFrame = dismissingEndFrame
            super.init()
            setupPresenting()
            setupDismissing()
        }
        
        //
        // MARK: - 用户传入 ZoomView 的前置页面视图
        //
        
        public typealias ViewClosure = (_ browser: JXPhotoBrowser, _ View: UIView) -> UIView?
        
        /// 初始化，传入动画 起始/结束 的前置页面视图
        public convenience init(presentingStartView: @escaping ViewClosure,
                    dismissingEndView: @escaping ViewClosure) {
            let presentingStartFrame: FrameClosure = { (browser, view) -> CGRect? in
                if let startView = presentingStartView(browser, view) {
                    return startView.convert(startView.bounds, to: view)
                }
                return nil
            }
            let dismissingEndFrame: FrameClosure = { (browser, view) -> CGRect? in
                if let endView = dismissingEndView(browser, view) {
                    return endView.convert(endView.bounds, to: view)
                }
                return nil
            }
            self.init(presentingStartFrame: presentingStartFrame, dismissingEndFrame: dismissingEndFrame)
        }
        
        private func setupPresenting() {
            weak var `self` = self
            presentingAnimator = JXPhotoBrowser.ZoomPresentingAnimator(zoomView: { () -> UIView? in
                guard let `self` = self else {
                    print("JXPhotoBrowser.Transitioning.Zoom 已被释放.")
                    return nil
                }
                let view = self.browser?.transitionZoomView
                view?.contentMode = self.presentingZoomViewMode()
                view?.clipsToBounds = true
                return view
            }, startFrame: { view -> CGRect? in
                guard let browser = self?.browser else {
                    return nil
                }
                return self?.presentingStartFrame(browser, view)
            }, endFrame: { view -> CGRect? in
                if let contentView = self?.browser?.displayingContentView {
                    return contentView.convert(contentView.bounds, to: view)
                }
                return nil
            })
        }
        
        private func setupDismissing() {
            weak var `self` = self
            dismissingAnimator = JXPhotoBrowser.ZoomDismissingAnimator(zoomView: { () -> UIView? in
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
                guard let browser = self?.browser else {
                    return nil
                }
                return self?.dismissingEndFrame(browser, view)
            })
        }
    }
}
