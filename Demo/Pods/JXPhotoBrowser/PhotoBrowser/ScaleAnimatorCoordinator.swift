//
//  ScaleAnimatorCoordinator.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2017/3/24.
//  Copyright © 2017年 JiongXing. All rights reserved.
//

import UIKit

protocol ScaleAnimatorCoordinatorDelegate: NSObjectProtocol {
    /// 转场动画即将开始时回调
    func scaleTransitionWillBegin(isBeingPresented: Bool)
}

extension ScaleAnimatorCoordinatorDelegate {
    func scaleTransitionWillBegin(isBeingPresented: Bool) {}
}

public class ScaleAnimatorCoordinator: UIPresentationController {
    
    weak var animatorDelegate: ScaleAnimatorCoordinatorDelegate?

    /// 动画结束后需要隐藏的view
    public var currentHiddenView: UIView?
    
    /// 蒙板
    public var maskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        return view
    }()
    
    /// 更新动画结束后需要隐藏的view
    public func updateCurrentHiddenView(_ view: UIView) {
        currentHiddenView?.isHidden = false
        currentHiddenView = view
        view.isHidden = true
    }
    
    override public func presentationTransitionWillBegin() {
        if let dlg = animatorDelegate {
            dlg.scaleTransitionWillBegin(isBeingPresented: true)
        }
        super.presentationTransitionWillBegin()
        guard let containerView = self.containerView else { return }
        
        containerView.addSubview(maskView)
        maskView.frame = containerView.bounds
        maskView.alpha = 0
        currentHiddenView?.isHidden = true
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.maskView.alpha = 1
        }, completion:nil)
    }
    
    override public func dismissalTransitionWillBegin() {
        if let dlg = animatorDelegate {
            dlg.scaleTransitionWillBegin(isBeingPresented: false)
        }
        super.dismissalTransitionWillBegin()
        currentHiddenView?.isHidden = true
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.maskView.alpha = 0
        }, completion: { _ in
            self.currentHiddenView?.isHidden = false
        })
    }
}
