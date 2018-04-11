//
//  PhotoBrowserPageControlDelegate.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/4/11.
//

import Foundation

public protocol PhotoBrowserPageControlDelegate: class {
    
    /// 总图片数/页数
    var numberOfPages: Int { get set }
    
    /// 取PageControl，只会取一次
    func pageControlOfPhotoBrowser(_ photoBrowser: PhotoBrowser) -> UIView
    
    /// 添加到父视图上时调用
    func photoBrowserPageControl(_ pageControl: UIView, didMoveTo superView: UIView)
    
    /// 让pageControl布局时调用
    func photoBrowserPageControl(_ pageControl: UIView, needLayoutIn superView: UIView)
    
    /// 页码变更时调用
    func photoBrowserPageControl(_ pageControl: UIView, didChangedCurrentPage currentPage: Int)
}
