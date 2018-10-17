//
//  UIViewController+JX.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit

extension UIViewController: JXNamespaceWrappable {}

extension JXTypeWrapperProtocol where JXWrappedType == UIViewController {
    
    /// Returns the current application's top most view controller.
    public static var topMost: UIViewController? {
        var rootViewController: UIViewController?
        for window in UIApplication.shared.windows where !window.isHidden {
            if let windowRootViewController = window.rootViewController {
                rootViewController = windowRootViewController
                break
            }
        }
        return self.topMost(of: rootViewController)
    }
    
    /// Returns the top most view controller from given view controller's stack.
    public static func topMost(of viewController: UIViewController?) -> UIViewController? {
        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            return self.topMost(of: presentedViewController)
        }
        
        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return self.topMost(of: selectedViewController)
        }
        
        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return self.topMost(of: visibleViewController)
        }
        
        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 {
            return self.topMost(of: pageViewController.viewControllers?.first)
        }
        
        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return self.topMost(of: childViewController)
            }
        }
        
        return viewController
    }
}
