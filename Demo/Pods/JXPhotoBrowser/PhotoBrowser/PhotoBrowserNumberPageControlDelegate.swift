//
//  PhotoBrowserNumberPageControlDelegate.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2017/4/25.
//  Copyright © 2017年 JiongXing. All rights reserved.
//

import UIKit

/// 给图片浏览器提供一个数字样式的PageControl
public class PhotoBrowserNumberPageControlDelegate: PhotoBrowserPageControlDelegate {
    /// 总页数
    public var numberOfPages: Int
    
    /// 字体
    public var font = UIFont.systemFont(ofSize: 17)
    
    /// 字颜色
    public var textColor = UIColor.white
    
    /// 中心点Y坐标
    public var centerY: CGFloat = 30
    
    public init(numberOfPages: Int) {
        self.numberOfPages = numberOfPages
    }
    
    // MARK: - PhotoBrowserPageControlDelegate
    
    public func pageControlOfPhotoBrowser(_ photoBrowser: PhotoBrowser) -> UIView {
        let pageControl = UILabel()
        pageControl.font = font
        pageControl.textColor = textColor
        pageControl.text = "1 / \(numberOfPages)"
        return pageControl
    }
    
    public func photoBrowserPageControl(_ pageControl: UIView, didMoveTo superView: UIView) {
        // 这里可以不作任何操作
    }
    
    public func photoBrowserPageControl(_ pageControl: UIView, needLayoutIn superView: UIView) {
        layoutPageControl(pageControl)
    }
    
    public func photoBrowserPageControl(_ pageControl: UIView, didChangedCurrentPage currentPage: Int) {
        guard let pageControl = pageControl as? UILabel else {
            return
        }
        pageControl.text = "\(currentPage + 1) / \(numberOfPages)"
        layoutPageControl(pageControl)
    }
    
    private func layoutPageControl(_ pageControl: UIView) {
        pageControl.sizeToFit()
        guard let superView = pageControl.superview else { return }
        pageControl.center = CGPoint(x: superView.bounds.midX, y: superView.bounds.minY + centerY)
    }
}
