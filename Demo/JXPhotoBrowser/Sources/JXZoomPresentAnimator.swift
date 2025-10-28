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
            
            var originView: UIView?
            if let provider = toVC.originViewProvider {
                originView = provider(toVC.initialIndex)
            }

            var animImageView: UIImageView?
            var startFrame: CGRect = .zero
            let destIV = toVC.visiblePhotoImageView()
            var endFrame: CGRect = .zero
            var canZoom = false
            if let originIV = originView as? UIImageView, let startImg = originIV.image,
               let targetIV = destIV {
                // 构造动画起点视图
                startFrame = originIV.convert(originIV.bounds, to: container)
                let iv = UIImageView(image: startImg)
                iv.frame = startFrame
                iv.contentMode = originIV.contentMode
                iv.clipsToBounds = true
                animImageView = iv
                // 计算目标显示区域（按 scaleAspectFit）；若目标图片未就绪，使用起始图片的尺寸进行拟合
                let fitRect: CGRect
                if let targetImg = targetIV.image, targetImg.size.width > 0 && targetImg.size.height > 0 {
                    fitRect = AVMakeRect(aspectRatio: targetImg.size, insideRect: targetIV.bounds)
                } else {
                    fitRect = AVMakeRect(aspectRatio: startImg.size, insideRect: targetIV.bounds)
                }
                endFrame = targetIV.convert(fitRect, to: container)
                // 隐藏真实视图，避免重影
                originIV.isHidden = true
                targetIV.isHidden = true
                canZoom = true
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