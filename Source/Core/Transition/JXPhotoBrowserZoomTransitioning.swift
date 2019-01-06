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
    
    /// 初始化，传入动画"起始/结束"的前置视图实际需求Frame
    /// 如果打开后是超出一屏的长图，请传入与长图一致宽高比的Frame
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
    
    /// 初始化，传入动画"起始/结束"的前置视图，如缩略图所在UIImageView
    public convenience init(originViewCallback: @escaping ViewClosure) {
        let callback: FrameClosure = { (browser, index, view) -> CGRect? in
            if let oriView = originViewCallback(browser, index, view) {
                // 对`JXPhotoBrowserZoomTransitioningOriginResource`调用对应实现
                if let oriRes = oriView
                    as? JXPhotoBrowserZoomTransitioningOriginResource {
                    return JXPhotoBrowserZoomTransitioning.resRect(oriRes: oriRes,
                                                                   to: view)
                }
                return oriView.convert(oriView.bounds, to: view)
            }
            return nil
        }
        self.init(originFrameCallback: callback)
    }
    
    public typealias ResourceClosure = (
        _ browser: JXPhotoBrowser,
        _ pageIndex: Int,
        _ transContainer: UIView) -> JXPhotoBrowserZoomTransitioningOriginResource?
    
    /// 初始化，传入动画"起始/结束"的前置视图，
    /// 要求实现了`JXPhotoBrowserZoomTransitioningOriginResource`，如UIImageView.
    public convenience init(originResourceCallback: @escaping ResourceClosure) {
        let callback: FrameClosure = { (browser, index, view) -> CGRect? in
            if let oriRes = originResourceCallback(browser, index, view) {
                return JXPhotoBrowserZoomTransitioning.resRect(oriRes: oriRes, to: view)
            }
            return nil
        }
        self.init(originFrameCallback: callback)
    }
    
    /// 求OriginResource在转场容器中的Frame
    public static func resRect(oriRes: JXPhotoBrowserZoomTransitioningOriginResource,
                         to view: UIView) -> CGRect {
        let oriView = oriRes.originResourceView
        var rect = oriView.convert(oriView.bounds, to: view)
        // 维持宽高比例
        let ratio = oriRes.originResourceAspectRatio
        if ratio > 0 {
            rect.size.height = rect.width / ratio
        }
        return rect
    }
    
    private func setupPresenting() {
        weak var `self` = self
        presentingAnimator = JXPhotoBrowserZoomPresentingAnimator(zoomView: { () -> UIView? in
            guard let `self` = self else {
                print("JXPhotoBrowserZoomTransitioning 已被释放.")
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
                print("JXPhotoBrowserZoomTransitioning 已被释放.")
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

/// 转场动画原资源。如转场之前的缩略图。
public protocol JXPhotoBrowserZoomTransitioningOriginResource {
    
    /// 资源视图
    var originResourceView: UIView { get }
    
    /// 图像实际需求宽高比例，width / height
    var originResourceAspectRatio: CGFloat { get }
}

/// 让UIImageView实现
extension UIImageView: JXPhotoBrowserZoomTransitioningOriginResource {
    public var originResourceView: UIView {
        return self
    }
    
    public var originResourceAspectRatio: CGFloat {
        if let image = image, image.size.height > 0 {
            return image.size.width / image.size.height
        }
        if bounds.height > 0 {
            return bounds.width / bounds.height
        }
        return 0
    }
}
