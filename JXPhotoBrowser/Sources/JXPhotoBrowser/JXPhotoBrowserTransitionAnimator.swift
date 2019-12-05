//
//  JXPhotoBrowserTransitionAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/25.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

public protocol JXPhotoBrowserTransitionAnimator: UIViewControllerAnimatedTransitioning {
    
    //
    // 以下属性由PhotoBrowser注入
    //
    /*
    /// PhotoBrowser
    var photoBrowser: JXPhotoBrowser? { get set }
    
    /// 在PhotoBrowser打开之前的ViewController
    var previousViewController: UIViewController? { get set }
    */
    
    /// 转场方向。true: 打开PhotoBrowser。false: 关闭PhotoBrowser
//    var isForShow: Bool { get set }
    
    /// 展示
    func show(browser: JXPhotoBrowser, completion: @escaping () -> Void)
    
    /// 消失
    func dismiss(browser: JXPhotoBrowser, completion: @escaping () -> Void)
}

private var isForShowKey: Int8?
private var photoBrowserKey: Int8?

extension JXPhotoBrowserTransitionAnimator {
    
    public var isForShow: Bool {
        get {
            if let value = objc_getAssociatedObject(self, &isForShowKey) as? Bool {
                return value
            }
            return true
        }
        set {
            objc_setAssociatedObject(self, &isForShowKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    public var photoBrowser: JXPhotoBrowser? {
        get {
            objc_getAssociatedObject(self, &photoBrowserKey) as? JXPhotoBrowser
        }
        set {
            objc_setAssociatedObject(self, &photoBrowserKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
