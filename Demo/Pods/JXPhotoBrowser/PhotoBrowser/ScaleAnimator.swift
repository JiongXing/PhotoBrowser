//
//  ScaleAnimator.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2017/3/17.
//  Copyright © 2017年 JiongXing. All rights reserved.
//

import UIKit

public class ScaleAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    /// 动画开始位置的视图
    public var startView: UIView?
    
    /// 动画结束位置的视图
    public var endView: UIView?
    
    /// 用于转场时的缩放视图
    public var scaleView: UIView?
    
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
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 判断是presentataion动画还是dismissal动画
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to) else {
                return
        }
        let presentation = (toVC.presentingViewController == fromVC)
        
        // dismissal转场，需要把presentedView隐藏，只显示scaleView
        if !presentation, let presentedView = transitionContext.view(forKey: .from) {
            presentedView.isHidden = true
        }
        
        // 取转场中介容器
        let containerView = transitionContext.containerView
        
        // 求缩放视图的起始和结束frame
        guard let startView = self.startView,
            let endView = self.endView,
            let scaleView = self.scaleView else {
            return
        }
        guard let startFrame = startView.superview?.convert(startView.frame, to: containerView) else {
            print("无法获取startFrame")
            return
        }
        guard let endFrame = endView.superview?.convert(endView.frame, to: containerView) else {
            print("无法获取endFrame")
            return
        }
        scaleView.frame = startFrame
        containerView.addSubview(scaleView)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { 
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
