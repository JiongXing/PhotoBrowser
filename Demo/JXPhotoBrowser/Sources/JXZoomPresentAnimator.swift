//
//  ZoomPresentAnimator.swift
//  JXPhotoBrowser
//

import UIKit
import AVFoundation

class JXZoomPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
        func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.25 }
        
        func animateTransition(using ctx: UIViewControllerContextTransitioning) {
            let container = ctx.containerView
            let duration = transitionDuration(using: ctx)
            
            guard
                let toVC = ctx.viewController(forKey: .to) as? JXPhotoBrowser,
                let toView = ctx.view(forKey: .to)
            else {
                ctx.completeTransition(false)
                return
            }
            
            container.addSubview(toView)
            toView.alpha = 0
            toView.layoutIfNeeded()
            
            // 业务方提供的缩略图源视图（用于计算起点几何）
            let originView: UIView? = toVC.dataSource?.photoBrowser(toVC, zoomOriginViewAt: toVC.initialIndex)

            // 准备动画视图及起止几何
            var animImageView: UIImageView?
            var startFrame: CGRect = .zero
            let destIV = toVC.visiblePhotoImageView()
            var endFrame: CGRect = .zero
            var canZoom = false
            
            // 从业务方数据源获取图像与 contentMode（优先使用代理）
            let zoomImage = toVC.dataSource?.photoBrowser(toVC, zoomImageForItemAt: toVC.initialIndex)
            let zoomContentMode = toVC.dataSource?.photoBrowser(toVC, zoomContentModeForItemAt: toVC.initialIndex) ?? .scaleAspectFit
            
            if let originIV = originView as? UIImageView,
               let targetIV = destIV {
                // 起点：使用业务方缩略图视图的几何（不改变其 contentMode）
                startFrame = originIV.convert(originIV.bounds, to: container)
                // 动画用的临时 ImageView，图像优先来自数据源；无则回退到缩略图的 image
                let startImg = zoomImage ?? originIV.image
                if let startImg = startImg {
                    let iv = UIImageView(image: startImg)
                    iv.frame = startFrame
                    iv.contentMode = zoomContentMode
                    iv.clipsToBounds = true
                    animImageView = iv
                    // 计算目标显示区域：根据业务方指定的 contentMode
                    let endRect: CGRect
                    if zoomContentMode == .scaleAspectFit {
                        let basisImage = targetIV.image ?? startImg
                        endRect = AVMakeRect(aspectRatio: basisImage.size, insideRect: targetIV.bounds)
                    } else if zoomContentMode == .scaleAspectFill || zoomContentMode == .scaleToFill {
                        endRect = targetIV.bounds
                    } else {
                        // 其他模式统一退化为按拟合处理
                        let basisImage = targetIV.image ?? startImg
                        endRect = AVMakeRect(aspectRatio: basisImage.size, insideRect: targetIV.bounds)
                    }
                    endFrame = targetIV.convert(endRect, to: container)
                    // 隐藏真实视图，避免重影
                    originIV.isHidden = true
                    targetIV.isHidden = true
                    canZoom = true
                }
            }
            
            if canZoom, let animIV = animImageView {
                container.addSubview(animIV)
                UIView.animate(withDuration: duration, animations: {
                    animIV.frame = endFrame
                    toView.alpha = 1
                }) { finished in
                    destIV?.isHidden = false
                    originView?.isHidden = false
                    animIV.removeFromSuperview()
                    ctx.completeTransition(finished)
                }
            } else {
                // 降级为 fade 动画（不缩放）
                toView.alpha = 0
                UIView.animate(withDuration: duration, animations: {
                    toView.alpha = 1
                }) { finished in
                    ctx.completeTransition(finished)
                }
            }
        }
}