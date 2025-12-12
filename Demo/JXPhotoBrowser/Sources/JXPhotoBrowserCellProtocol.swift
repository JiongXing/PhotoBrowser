//
//  JXPhotoBrowserCellProtocol.swift
//  JXPhotoBrowser
//

import UIKit

/// 图片浏览器Cell协议
/// 自定义Cell只需实现此协议即可使用，无需继承JXPhotoCell
/// 协议只包含框架必需的最小接口，其他功能由自定义Cell自由实现
public protocol JXPhotoBrowserCellProtocol: UICollectionViewCell {
    
    /// 弱引用的浏览器实例（框架会自动设置）
    /// 自定义Cell可以使用此属性调用浏览器的方法，如 dismissSelf()
    var browser: JXPhotoBrowser? { get set }
    
    /// 当前关联的真实索引（框架会自动设置）
    /// 自定义Cell可以监听此属性的变化来加载对应的内容
    var currentIndex: Int? { get set }
}

// MARK: - 可选扩展（提供默认实现）

public extension JXPhotoBrowserCellProtocol {
    
    /// 用于转场动画的视图（可选）
    /// 如果返回非nil，框架会使用此视图进行Zoom转场动画
    /// 如果返回nil，转场动画将降级为Fade动画
    var transitionImageView: UIImageView? { nil }
    
    /// 用于下拉关闭手势的滚动视图（可选）
    /// 如果返回非nil，框架会在此视图上禁用滚动以支持下拉关闭
    /// 如果返回nil，下拉关闭功能可能不可用
    var interactiveScrollView: UIScrollView? { nil }
}

