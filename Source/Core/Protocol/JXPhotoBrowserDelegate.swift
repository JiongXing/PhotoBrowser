//
//  JXPhotoBrowserDelegate.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit

/// 视图代理
public protocol JXPhotoBrowserDelegate: UICollectionViewDelegate {
    
    /// 实现者应弱引用 PhotoBrowser，由 PhotoBrowser 初始化完毕后注入
    var browser: JXPhotoBrowser? { set get }
    
    /// pageIndex 值改变时回调
    func photoBrowser(_ browser: JXPhotoBrowser, pageIndexDidChanged pageIndex: Int)
    
    /// 取当前显示页的内容视图。比如是 ImageView.
    func displayingContentView(_ browser: JXPhotoBrowser, pageIndex: Int) -> UIView?
    
    /// 取转场动画视图
    func transitionZoomView(_ browser: JXPhotoBrowser, pageIndex: Int) -> UIView?
    
    /// viewDidLoad 即将结束时调用
    func photoBrowserViewDidLoad(_ browser: JXPhotoBrowser)
    
    /// viewWillAppear 即将结束时调用
    func photoBrowser(_ browser: JXPhotoBrowser, viewWillAppear animated: Bool)
    
    /// viewWillLayoutSubviews 即将结束时调用
    func photoBrowserViewWillLayoutSubviews(_ browser: JXPhotoBrowser)
    
    /// viewDidLayoutSubviews 即将结束时调用
    func photoBrowserViewDidLayoutSubviews(_ browser: JXPhotoBrowser)
    
    /// viewDidAppear 即将结束时调用
    func photoBrowser(_ browser: JXPhotoBrowser, viewDidAppear animated: Bool)
    
    /// viewWillDisappear 即将结束时调用
    func photoBrowser(_ browser: JXPhotoBrowser, viewWillDisappear animated: Bool)
    
    /// viewDidDisappear 即将结束时调用
    func photoBrowser(_ browser: JXPhotoBrowser, viewDidDisappear animated: Bool)
    
    /// 关闭
    func dismissPhotoBrowser(_ browser: JXPhotoBrowser)
    
    /// 数据源已刷新
    func photoBrowserDidReloadData(_ browser: JXPhotoBrowser)
}
