//
//  ZoomPresentAnimator.swift
//  JXPhotoBrowser
//

import UIKit
import AVFoundation

open class JXZoomPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    open func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    open func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let container = ctx.containerView
        let duration = transitionDuration(using: ctx)

        guard let toVC = ctx.viewController(forKey: .to) as? JXPhotoBrowser,
              let toView = ctx.view(forKey: .to) else {
            print("[JXZoomPresentAnimator] ❌ 降级原因: toVC 或 toView 为 nil")
            ctx.completeTransition(false)
            return
        }
        
        print("[JXZoomPresentAnimator] 🚀 开始 Zoom 转场动画, initialIndex: \(toVC.initialIndex)")

        // 添加目标视图并强制布局，确保 collectionView 有可见 Cell
        container.addSubview(toView)
        toView.frame = ctx.finalFrame(for: toVC)
        toView.layoutIfNeeded()
        
        // 滚动到初始位置，确保目标 Cell 可见
        toVC.scrollToInitialIndexIfNeeded()
        toVC.collectionView.layoutIfNeeded()
        
        print("[JXZoomPresentAnimator] 📐 toView.frame: \(toView.frame)")
        print("[JXZoomPresentAnimator] 📐 collectionView.frame: \(toVC.collectionView.frame)")
        print("[JXZoomPresentAnimator] 📐 visibleCells.count: \(toVC.collectionView.visibleCells.count)")

        // 检查前置条件
        guard let originView = toVC.delegate?.photoBrowser(toVC, zoomOriginViewAt: toVC.initialIndex) else {
            print("[JXZoomPresentAnimator] ❌ 降级原因: originView 为 nil (delegate 未实现 zoomOriginViewAt)")
            fallbackToFade(toView: toView, duration: duration, ctx: ctx)
            return
        }
        print("[JXZoomPresentAnimator] ✅ originView: \(originView), bounds: \(originView.bounds)")
        
        guard let zoomView = toVC.delegate?.photoBrowser(toVC, zoomViewForItemAt: toVC.initialIndex, isPresenting: true) else {
            print("[JXZoomPresentAnimator] ❌ 降级原因: zoomView 为 nil (delegate 未实现 zoomViewForItemAt)")
            fallbackToFade(toView: toView, duration: duration, ctx: ctx)
            return
        }
        print("[JXZoomPresentAnimator] ✅ zoomView: \(zoomView)")
        
        let visibleCell = toVC.visiblePhotoCell()
        print("[JXZoomPresentAnimator] 📍 visiblePhotoCell: \(String(describing: visibleCell))")
        
        let targetIV = visibleCell?.transitionImageView
        print("[JXZoomPresentAnimator] ✅ targetIV: \(String(describing: targetIV)), bounds: \(targetIV?.bounds ?? .zero)")

        // 起止几何
        let startFrame = originView.convert(originView.bounds, to: container)
        
        // 计算目标 frame：优先使用 targetIV，否则基于 originView 比例计算居中位置
        let endFrame: CGRect
        if let targetIV = targetIV, targetIV.bounds.size != .zero {
            endFrame = targetIV.convert(targetIV.bounds, to: container)
            print("[JXZoomPresentAnimator] 🎯 使用 targetIV 计算 endFrame")
        } else {
            // targetIV 不可用（图片未加载），基于 originView 的比例计算目标位置
            let containerSize = container.bounds.size
            let originSize = originView.bounds.size
            guard originSize.width > 0 && originSize.height > 0 else {
                print("[JXZoomPresentAnimator] ❌ 降级原因: originView.bounds.size 为 zero")
                fallbackToFade(toView: toView, duration: duration, ctx: ctx)
                return
            }
            // 按 AspectFit 计算目标尺寸
            let scale = min(containerSize.width / originSize.width, containerSize.height / originSize.height)
            let targetWidth = originSize.width * scale
            let targetHeight = originSize.height * scale
            let targetX = (containerSize.width - targetWidth) / 2
            let targetY = (containerSize.height - targetHeight) / 2
            endFrame = CGRect(x: targetX, y: targetY, width: targetWidth, height: targetHeight)
            print("[JXZoomPresentAnimator] 🎯 基于 originView 比例计算 endFrame")
        }
        print("[JXZoomPresentAnimator] 🎯 startFrame: \(startFrame)")
        print("[JXZoomPresentAnimator] 🎯 endFrame: \(endFrame)")

        // 隐藏真实视图，避免重影
        originView.isHidden = true
        targetIV?.isHidden = true
        toView.backgroundColor = .clear

        // 使用业务方提供的 ZoomView 作为临时视图
        zoomView.frame = startFrame
        container.addSubview(zoomView)

        UIView.animate(withDuration: duration, animations: {
            zoomView.frame = endFrame
            toView.backgroundColor = .black
        }) { finished in
            print("[JXZoomPresentAnimator] ✅ Zoom 动画完成")
            // 还原
            targetIV?.isHidden = false
            originView.isHidden = false
            zoomView.removeFromSuperview()
            ctx.completeTransition(finished)
        }
    }
    
    /// 降级为淡入动画
    private func fallbackToFade(toView: UIView, duration: TimeInterval, ctx: UIViewControllerContextTransitioning) {
        print("[JXZoomPresentAnimator] ⚠️ 降级为 Fade 动画")
        toView.alpha = 0
        UIView.animate(withDuration: duration, animations: {
            toView.alpha = 1
        }) { finished in
            ctx.completeTransition(finished)
        }
    }
}
