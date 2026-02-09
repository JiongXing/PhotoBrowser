//
//  JXPhotoBrowserOverlay.swift
//  JXPhotoBrowser
//

import UIKit

/// 浏览器附加视图组件协议
/// 用于页码指示器、关闭按钮、标题栏等附加 UI 组件的统一接入
///
/// 遵循此协议的 UIView 可通过 `browser.addOverlay(_:)` 装载到浏览器上。
/// 框架会在适当时机调用协议方法通知组件更新状态。
///
/// - Note: 默认不装载任何 Overlay，业务方按需装载
public protocol JXPhotoBrowserOverlay: UIView {
    
    /// 组件被添加到浏览器视图时调用
    /// 在此方法中完成初始布局（如添加约束、设置 frame 等）
    /// - Parameter browser: 宿主浏览器实例
    func setup(with browser: JXPhotoBrowser)
    
    /// 数据重载或布局变化时调用
    /// 组件应根据最新的总数和页码更新显示内容
    /// - Parameters:
    ///   - numberOfItems: 当前数据总数
    ///   - pageIndex: 当前页码
    func reloadData(numberOfItems: Int, pageIndex: Int)
    
    /// 页码变化时调用
    /// - Parameter index: 新的页码
    func didChangedPageIndex(_ index: Int)
}
