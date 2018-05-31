//
//  AnimationType.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/4/12.
//

import Foundation

/// 转场动画类型
public enum AnimationType {
    /// 缩放, 是否隐藏原来的视图
    case scale(hideRelatedView: Bool)
    /// 透明渐变
    case fade
}
