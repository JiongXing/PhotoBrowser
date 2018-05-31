//
//  NumberPageControlPlugin.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/5/13.
//

import Foundation

/// 数字型页码指示器
open class NumberPageControlPlugin: PhotoBrowserPlugin {
    /// 字体
    open var font = UIFont.systemFont(ofSize: 17)

    /// 字颜色
    open var textColor = UIColor.white

    /// 可指定中心点Y坐标
    /// 若不指定，默认为20
    open var centerY: CGFloat?

    /// 数字指示
    open lazy var numberLabel: UILabel = {
        let view = UILabel()
        view.font = font
        view.textColor = textColor
        return view
    }()

    /// 总页码
    open var totalPages = 0

    /// 当前页码
    open var currentPage = 0

    public init() {}

    open func photoBrowser(_ photoBrowser: PhotoBrowser, numberOfPhotos count: Int) {
        totalPages = count
        layout()
    }

    open func photoBrowser(_ photoBrowser: PhotoBrowser, didChangedPageIndex index: Int) {
        currentPage = index
        layout()
    }

    open func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidAppear view: UIView, animated: Bool) {
        // 页面出来后，再显示页码指示器
        // 多于一张图才显示
        if totalPages > 1 {
            view.addSubview(numberLabel)
        }
    }

    open func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLayoutSubviews view: UIView) {
        layout()
        numberLabel.isHidden = totalPages <= 1
    }

    private func layout() {
        numberLabel.text = "\(currentPage + 1) / \(totalPages)"
        numberLabel.sizeToFit()
        guard let superView = numberLabel.superview else { return }
        numberLabel.center = CGPoint(x: superView.bounds.midX,
                                     y: superView.bounds.minY + pageControlOffsetY)
    }

    private var pageControlOffsetY: CGFloat {
        if let centerY = centerY {
            return centerY
        }
        guard let superView = numberLabel.superview else {
            return 0
        }
        var offsetY: CGFloat = 0
        if #available(iOS 11.0, *) {
            offsetY = superView.safeAreaInsets.top
        }
        return 20 + offsetY
    }
}
