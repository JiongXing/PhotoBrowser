//
//  JXPhotoBrowserCellProtocol.swift
//  JXPhotoBrowser
//

import UIKit

/// 图片浏览器Cell协议
/// 自定义Cell只需实现此协议即可使用，无需继承JXPhotoCell
/// 协议只包含框架必需的最小接口，其他功能由自定义Cell自由实现
public protocol JXPhotoBrowserCellProtocol: UICollectionViewCell {
    
    /// 浏览器实例（可选，框架会自动设置）
    /// - Important: 实现时必须声明为 `weak var` 以避免循环引用
    /// - Note: 需要调用浏览器方法（如关闭）的 Cell 才需要实现此属性
    var browser: JXPhotoBrowser? { get set }
    
    /// 用于转场动画的视图（可选）
    /// 如果返回非nil，框架会使用此视图进行Zoom转场动画
    /// 如果返回nil，转场动画将降级为Fade动画
    var transitionImageView: UIImageView? { get }
}

// MARK: - 默认实现

public extension JXPhotoBrowserCellProtocol {
    
    var browser: JXPhotoBrowser? {
        get { nil }
        set { }
    }
    
    var transitionImageView: UIImageView? { nil }
}

