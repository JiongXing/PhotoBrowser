//
//  NumberPageControlPlugin.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/5/13.
//

import Foundation

open class NumberPageControlPlugin: PhotoBrowserPlugin {
    /// 字体
    open var font = UIFont.systemFont(ofSize: 17)
    
    /// 字颜色
    open var textColor = UIColor.white
    
    /// 中心点Y坐标
    open var centerY: CGFloat = 30
    
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
    
    open func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidAppear view: UIView, animated: Bool) {
        view.addSubview(numberLabel)
    }
    
    open func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLayoutSubviews view: UIView) {
        layout()
    }
    
    open func photoBrowser(_ photoBrowser: PhotoBrowser, numberOfPhotos count: Int) {
        totalPages = count
        layout()
    }
    
    open func photoBrowser(_ photoBrowser: PhotoBrowser, didChangedPageIndex index: Int) {
        currentPage = index
        layout()
    }
    
    open func layout() {
        numberLabel.text = "\(currentPage) / \(totalPages)"
        numberLabel.sizeToFit()
        guard let superView = numberLabel.superview else { return }
        numberLabel.center = CGPoint(x: superView.bounds.midX, y: superView.bounds.minY + centerY)
    }
}
