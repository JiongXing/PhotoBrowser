//
//  FadePresentationController.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/4/12.
//

import UIKit

/// 透明渐变转场协调器
class FadePresentationController: UIPresentationController {

    /// 蒙板
    var maskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        return view
    }()

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView = self.containerView else { return }

        containerView.addSubview(maskView)
        maskView.frame = containerView.bounds
        maskView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        maskView.alpha = 0
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.maskView.alpha = 1
        }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.maskView.alpha = 0
        })
    }
}

// MARK: - 转场协调器协议

extension FadePresentationController: PhotoBrowserPresentationController {
    var maskAlpha: CGFloat {
        set {
            maskView.alpha = newValue
        }
        get {
            return maskView.alpha
        }
    }
}
