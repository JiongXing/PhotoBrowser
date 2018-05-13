//
//  PhotoBrowserDefaultPageControl.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2017/4/25.
//  Copyright © 2017年 JiongXing. All rights reserved.
//

import UIKit

/// 给图片浏览器提供一个UIPageControl，小光点样式
open class DefaultPageControl: PageControl {
    
    /// 中心点Y坐标，距离底部值
    open var centerBottomY: CGFloat = 20
    
    /// 页码指示器
    open lazy var pageControl: UIPageControl = {
        return UIPageControl()
    }()
    
    public init() {}
    
    // MARK: - PageControl
    
    open func pageControlView(on photoBrowser: PhotoBrowser) -> UIView {
        return pageControl
    }
    
    open func pageControlDidMove(to superView: UIView) {
        // 这里可以不作任何操作
    }
    
    open func pageControlLayout(in superView: UIView) {
        pageControl.sizeToFit()
        pageControl.center = CGPoint(x: superView.bounds.midX, y: superView.bounds.maxY - centerBottomY)
    }
    
    open func pageControlPageDidChanged(current: Int, total: Int) {
        pageControl.numberOfPages = total
        pageControl.currentPage = current
    }
}
