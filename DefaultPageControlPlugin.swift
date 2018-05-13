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
        return UIPageControl()
    }()
    
    public init() {}
    
    open func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidAppear view: UIView, animated: Bool) {
        view.addSubview(pageControl)
    }
    
    open func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLayoutSubviews view: UIView) {
        pageControl.sizeToFit()
        pageControl.center = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - centerBottomY)
    }
    
    open func photoBrowser(_ photoBrowser: PhotoBrowser, numberOfPhotos count: Int) {
        pageControl.numberOfPages = count
    }
    
    open func photoBrowser(_ photoBrowser: PhotoBrowser, didChangedPageIndex index: Int) {
        pageControl.currentPage = index
    }
}
