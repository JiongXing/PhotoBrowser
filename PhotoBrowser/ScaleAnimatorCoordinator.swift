//
//  ScaleAnimatorCoordinator.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2017/3/24.
//  Copyright © 2017年 JiongXing. All rights reserved.
//

import UIKit

public class ScaleAnimatorCoordinator: UIPresentationController {
    
    /// 动画结束后需要隐藏的view
    public var currentHiddenView: UIView?
    
    /// 暂存需隐藏的view的原alpha值
    private var currentHiddenViewOriginAlpha: CGFloat?;
    
    /// 蒙板
    public var maskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        return view
    }()
    
    /// 更新动画结束后需要隐藏的view
    public func updateCurrentHiddenView(_ view: UIView?) {
        // 重新显示前一个隐藏视图。??后的1.0不会生效，仅为语法而写。
        currentHiddenView?.alpha = currentHiddenViewOriginAlpha ?? 1.0;
        // 隐藏新视图
        currentHiddenView = view
        currentHiddenViewOriginAlpha = view?.alpha
        view?.alpha = 0.01
    }
    
    override public func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView = self.containerView else { return }
        
        containerView.addSubview(maskView)
        maskView.frame = containerView.bounds
        maskView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        maskView.alpha = 0
        currentHiddenView?.alpha = 0.01
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.maskView.alpha = 1
        }, completion:nil)
    }
    
    override public func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        currentHiddenView?.alpha = 0.01
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.maskView.alpha = 0
        }, completion: { _ in
            self.currentHiddenView?.alpha = self.currentHiddenViewOriginAlpha ?? 1.0
        })
    }
}
