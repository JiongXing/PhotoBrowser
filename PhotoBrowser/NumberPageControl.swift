//
//  NumberPageControl.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2017/4/25.
//  Copyright © 2017年 JiongXing. All rights reserved.
//

import UIKit

/// 给图片浏览器提供一个数字样式的PageControl
open class NumberPageControl: PageControl {
    
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
        view.text = "0 / 0"
        return view
    }()
    
    public init() {}
    
    // MARK: - PageControl
    
    open func pageControlView(on photoBrowser: PhotoBrowser) -> UIView {
        return numberLabel
    }
    
    open func pageControlDidMove(to superView: UIView) {
        // 这里可以不作任何操作
    }
    
    open func pageControlLayout(in superView: UIView) {
        layout()
    }
    
    open func pageControlPageDidChanged(current: Int, total: Int) {
        numberLabel.text = "\(current + 1) / \(total)"
        layout()
    }
    
    open func layout() {
        numberLabel.sizeToFit()
        guard let superView = numberLabel.superview else { return }
        numberLabel.center = CGPoint(x: superView.bounds.midX, y: superView.bounds.minY + centerY)
    }
}
