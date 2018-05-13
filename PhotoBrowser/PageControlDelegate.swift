//
//  PageControlDelegate.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/4/11.
//

import Foundation

public protocol PageControlDelegate: class {

    /// 取PageControl，只会取一次
    func pageControlView(on photoBrowser: PhotoBrowser) -> UIView
    
    /// 添加到父视图上时调用
    func pageControlDidMove(to superView: UIView)
    
    /// 让pageControl布局时调用
    func pageControlLayout(in superView: UIView)
    
    /// 页码变更时调用
    /// - parameter current: 当前页码，从0开始
    /// - parameter total: 总页数
    func pageControlPageDidChanged(current: Int, total: Int)
}
