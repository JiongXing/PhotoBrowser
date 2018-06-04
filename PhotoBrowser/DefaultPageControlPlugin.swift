//
//  DefaultPageControlPlugin.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/5/13.
//

import Foundation

/// 光点型页码指示器
open class DefaultPageControlPlugin: PhotoBrowserPlugin {

    /// 可指定中心点Y坐标，距离底部值。
    /// 若不指定，默认为20
    open var centerBottomY: CGFloat?

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
        layout()
    }

    open func photoBrowser(_ photoBrowser: PhotoBrowser, numberOfPhotos count: Int) {
        totalPages = count
        layout()
    }

    open func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidAppear view: UIView, animated: Bool) {
        // 页面出来后，再显示页码指示器
        // 多于一张图才显示
        if totalPages > 1 {
            view.addSubview(pageControl)
        }
    }

    open func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLayoutSubviews view: UIView) {
        layout()
        pageControl.isHidden = totalPages <= 1
    }

    private func layout() {
        pageControl.numberOfPages = totalPages
        pageControl.currentPage = currentPage
        pageControl.sizeToFit()
        guard let superView = pageControl.superview else { return }
        pageControl.center = CGPoint(x: superView.bounds.midX,
                                     y: superView.bounds.maxY - pageControlBottomOffsetY)
    }

    private var pageControlBottomOffsetY: CGFloat {
        if let bottomY = centerBottomY {
            return bottomY
        }
        guard let superView = pageControl.superview else {
            return 0
        }
        var offsetY: CGFloat = 0
        if #available(iOS 11.0, *) {
            offsetY = superView.safeAreaInsets.bottom
        }
        return 20 + offsetY
    }
}
