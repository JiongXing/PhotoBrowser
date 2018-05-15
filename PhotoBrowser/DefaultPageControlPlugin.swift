//
//  DefaultPageControlPlugin.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/5/13.
//

import Foundation

open class DefaultPageControlPlugin: PhotoBrowserPlugin {
    
    /// 中心点Y坐标，距离底部值
    open var centerBottomY: CGFloat = 20
    
    /// 页码指示器
    open lazy var pageControl: UIPageControl = {
        let pgc = UIPageControl()
        pgc.isEnabled = false
        return pgc
    }()
    
    /// 总页码
    open var totalPages = 0
    
    /// 当前页码
    open var currentPage = 0
    
    public init() {}
    
    open func photoBrowser(_ photoBrowser: PhotoBrowser, didChangedPageIndex index: Int) {
        currentPage = index
        pageControl.currentPage = index
    }
    
    open func photoBrowser(_ photoBrowser: PhotoBrowser, numberOfPhotos count: Int) {
        totalPages = count
        pageControl.numberOfPages = count
        pageControl.currentPage = currentPage
    }
    
    open func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidAppear view: UIView, animated: Bool) {
        // 页面出来后，再显示页码指示器
        // 多于一张图才显示
        if totalPages > 1 {
            view.addSubview(pageControl)
        }
    }
    
    open func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLayoutSubviews view: UIView) {
        pageControl.sizeToFit()
        pageControl.center = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - centerBottomY)
    }
}
