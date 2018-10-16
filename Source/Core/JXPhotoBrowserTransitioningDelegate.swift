//
//  JXPhotoBrowserTransitioningDelegate.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit

/// 转场动画代理
public protocol JXPhotoBrowserTransitioningDelegate: UIViewControllerTransitioningDelegate {
    
    /// 实现者应弱引用 PhotoBrowser，由 PhotoBrowser 初始化完毕后注入
    var browser: JXPhotoBrowser? { set get }
    
    /// 蒙板 alpha 值
    var maskAlpha: CGFloat { set get }
}
