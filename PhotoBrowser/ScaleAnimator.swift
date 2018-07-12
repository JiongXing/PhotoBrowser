//
//  ScaleAnimator.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2017/3/17.
//  Copyright © 2017年 JiongXing. All rights reserved.
//

import UIKit

/// 缩放动画
class ScaleAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    /// 动画开始位置的视图
    var startView: UIView?

    /// 动画结束位置的视图
    var endView: UIView?

    /// 用于转场时的缩放视图
    var scaleView: UIView?

    /// 初始化
    init(startView: UIView?, endView: UIView?, scaleView: UIView?) {
        self.startView = startView
        self.endView = endView
        self.scaleView = scaleView
    }

    /// 初始化，无参
    override convenience init() {
        self.init(startView: nil, endView: nil, scaleView: nil)
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 判断是presentataion动画还是dismissal动画
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to) else {
                print("获取 viewController 失败")
                transitionContext.completeTransition(false)
                return
        }
        let presentation = (toVC.presentingViewController == fromVC)

        // dismissal转场，需要把presentedView隐藏，只显示scaleView
        if !presentation, let presentedView = transitionContext.view(forKey: .from) {
            presentedView.alpha = 0.01
        }

        // 转场容器
        let containerView = transitionContext.containerView

        guard let startView = self.startView, let scaleView = self.scaleView else {
            print("获取 startView/scaleView 失败")
            transitionContext.completeTransition(false)
            return
        }
        let startFrame = startView.convert(startView.bounds, to: containerView)
        var endFrame = startFrame
        var endAlpha: CGFloat = 0.0

        if let endView = self.endView {
            // 当前正在显示视图的前一个页面关联视图已经存在，此时分两种情况
            // 视图显示在屏幕内，作scale动画；否则作fade动画
            let relativeFrame = endView.convert(endView.bounds, to: nil)
            let keyWindowBounds =  UIScreen.main.bounds
            if keyWindowBounds.intersects(relativeFrame) {
                // 在屏幕内，求endFrame，让其缩放
                endAlpha = 1.0
                endFrame = endView.convert(endView.bounds, to: containerView)
            }
        }

        scaleView.frame = startFrame
        containerView.addSubview(scaleView)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            scaleView.alpha = endAlpha
            scaleView.frame = endFrame
        }) { _ in
            // presentation转场，需要把目标视图添加到视图栈
            if presentation, let presentedView = transitionContext.view(forKey: .to) {
                containerView.addSubview(presentedView)
            }
            scaleView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
