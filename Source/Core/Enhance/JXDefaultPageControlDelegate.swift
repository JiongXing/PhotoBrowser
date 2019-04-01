//
//  JXDefaultPageControlDelegate.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/15.
//

import Foundation

/// 实现了以 UIPageControl 为页码指示器的 Delegate.
open class JXDefaultPageControlDelegate: JXPhotoBrowserBaseDelegate {
    
    /// 指定Y轴从底部往上偏移值
    open lazy var offsetY: CGFloat = {
        if #available(iOS 11.0, *), let window = UIApplication.shared.keyWindow,
            window.safeAreaInsets.bottom > 0 {
            return 20
        }
        return 15
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
    
    open override func photoBrowserViewWillLayoutSubviews(_ browser: JXPhotoBrowser) {
        super.photoBrowserViewWillLayoutSubviews(browser)
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
        pageControl.center.x = superView.bounds.width / 2
        let originY: CGFloat = superView.bounds.maxY
        pageControl.frame.origin.y = originY - offsetY - pageControl.bounds.height
        pageControl.isHidden = totalPages <= 1
    }
}
