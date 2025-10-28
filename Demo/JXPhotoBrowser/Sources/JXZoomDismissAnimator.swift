//
//  ZoomDismissAnimator.swift
//  JXPhotoBrowser
//

import UIKit
import AVFoundation

class JXZoomDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
        func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.25 }
        
        func animateTransition(using ctx: UIViewControllerContextTransitioning) {
            let container = ctx.containerView
            let duration = transitionDuration(using: ctx)
            
            guard
                let fromVC = ctx.viewController(forKey: .from) as? JXPhotoBrowser,
                let fromView = ctx.view(forKey: .from)
            else {
                ctx.completeTransition(false)
                return
            }
            
            if let toView = ctx.view(forKey: .to) {
                container.insertSubview(toView, belowSubview: fromView)
                toView.alpha = 1
            }
            
            let srcIV = fromVC.visiblePhotoImageView()
            var animImageView: UIImageView?
            var startFrame: CGRect = .zero
            var destView: UIView?
            var endFrame: CGRect = .zero
            var canZoom = false
            
            // 从数据源获取 zoom 图像与 contentMode（由业务方定义）
            let currentIndex = fromVC.currentRealIndex()
            let zoomImage = currentIndex.flatMap { fromVC.dataSource?.photoBrowser(fromVC, zoomImageForItemAt: $0) }
            let zoomContentMode = currentIndex.flatMap { fromVC.dataSource?.photoBrowser(fromVC, zoomContentModeForItemAt: $0) } ?? .scaleAspectFit
            
            if let iv = srcIV {
                // 起点：依据浏览器当前显示视图与 contentMode 计算
                let basisImage = (zoomImage ?? iv.image)
                if let img = basisImage, img.size.width > 0 && img.size.height > 0 {
                    let startRect: CGRect
                    if zoomContentMode == .scaleAspectFit {
                        startRect = AVMakeRect(aspectRatio: img.size, insideRect: iv.bounds)
                    } else if zoomContentMode == .scaleAspectFill || zoomContentMode == .scaleToFill {
                        startRect = iv.bounds
                    } else {
                        startRect = AVMakeRect(aspectRatio: img.size, insideRect: iv.bounds)
                    }
                    startFrame = iv.convert(startRect, to: container)
                    let aiv = UIImageView(image: img)
                    aiv.frame = startFrame
                    aiv.contentMode = zoomContentMode
                    aiv.clipsToBounds = true
                    animImageView = aiv
                    iv.isHidden = true
                    if let realIndex = currentIndex, let origin = fromVC.dataSource?.photoBrowser(fromVC, zoomOriginViewAt: realIndex) {
                        destView = origin
                        endFrame = origin.convert(origin.bounds, to: container)
                        origin.isHidden = true
                        canZoom = true
                    }
                }
            }
            
            if canZoom, let animIV = animImageView {
                container.addSubview(animIV)
                UIView.animate(withDuration: duration, animations: {
                    animIV.frame = endFrame
                    fromView.alpha = 0
                }) { _ in
                    let wasCancelled = ctx.transitionWasCancelled
                    if wasCancelled {
                        srcIV?.isHidden = false
                        destView?.isHidden = false
                        animIV.removeFromSuperview()
                        fromView.alpha = 1
                        ctx.completeTransition(false)
                    } else {
                        destView?.isHidden = false
                        animIV.removeFromSuperview()
                        fromView.removeFromSuperview()
                        ctx.completeTransition(true)
                    }
                }
            } else {
                // 降级为 fade 动画（不缩放），保持黑屏修复
                UIView.animate(withDuration: duration, animations: {
                    fromView.alpha = 0
                }) { _ in
                    let wasCancelled = ctx.transitionWasCancelled
                    if wasCancelled {
                        fromView.alpha = 1
                        ctx.completeTransition(false)
                    } else {
                        fromView.removeFromSuperview()
                        ctx.completeTransition(true)
                    }
                }
            }
        }
}