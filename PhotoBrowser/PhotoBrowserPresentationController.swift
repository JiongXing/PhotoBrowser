//
//  PhotoBrowserPresentationController.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/4/12.
//

import Foundation

/// 转场协调器协议
protocol PhotoBrowserPresentationController: class {

    /// 蒙板 alpha 值
    var maskAlpha: CGFloat { get set }
}
