//
//  JXDefaultPageControlDelegate.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/15.
//

import Foundation

/// 实现了以 UIPageControl 为页码指示器的 Delegate.
open class JXDefaultPageControlDelegate: JXPhotoBrowserBaseDelegate {
    
    /// 可指定中心点Y坐标，距离底部值。默认值：iPhoneX为30，非iPhoneX为20
    open lazy var centerBottomY: CGFloat = {
        if #available(iOS 11.0, *) {
            return 30
        }
        return 20
    }()
    
    /// 页码指示器
    open lazy var pageControl: UIPageControl = {
        let pgc = UIPageControl()
        pgc.isEnabled = false
        return pgc
    }()
    
    open override func photoBrowser(_ browser: JXPhotoBrowser, pageIndexDidChanged pageIndex: Int) {
        super.photoBrowser(browser, pageIndexDidChanged: pageIndex)
        pageControl.currentPage = pageIndex
    }
    
    open override func photoBrowserViewDidLayoutSubviews(_ browser: JXPhotoBrowser) {
        super.photoBrowserViewDidLayoutSubviews(browser)
        layout()
    }
    
    open override func photoBrowser(_ browser: JXPhotoBrowser, viewDidAppear animated: Bool) {
        super.photoBrowser(browser, viewDidAppear: animated)
        // 页面出来后，再显示页码指示器
        // 多于一张图才添加到视图
        let totalPages = browser.itemsCount
        if totalPages > 1 {
            browser.view.addSubview(pageControl)
        }
    }
    
    open override func photoBrowserDidReloadData(_ browser: JXPhotoBrowser) {
        layout()
    }
    
    //
    // MARK: - Private
    //
    
    private func layout() {
        guard let browser = self.browser else {
            return
        }
        guard let superView = pageControl.superview else { return }
        let totalPages = browser.itemsCount
        pageControl.numberOfPages = totalPages
        pageControl.currentPage = browser.pageIndex
        pageControl.sizeToFit()
        pageControl.center = CGPoint(x: superView.bounds.width / 2,
                                     y: superView.bounds.maxY - centerBottomY)
        pageControl.isHidden = totalPages <= 1
    }
}
