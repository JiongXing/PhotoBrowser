//
//  CustomCell.swift
//  JXPhotoBrowser_Example
//
//  Created by JiongXing on 2018/10/27.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import JXPhotoBrowser

/// 自定义Cell
class CustomCell: JXPhotoBrowserNetworkingCell {
    
    /// 是否需要添加长按手势。返回`false`即可避免添加长按手势
    override var isNeededLongPressGesture: Bool {
        return false
    }
    
    /// 下方背景
    let remarkBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    
    /// 备注文字
    let remarkLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(remarkBackgroundView)
        remarkBackgroundView.addSubview(remarkLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        do {
            let height: CGFloat = 140
            let y: CGFloat = contentView.bounds.height - height
            remarkBackgroundView.frame = CGRect(x: 0, y: y, width: contentView.bounds.width, height: height)
        }
        do {
            let margin: CGFloat = 20
            let width: CGFloat = remarkBackgroundView.frame.width - margin * 2
            let height: CGFloat = remarkBackgroundView.frame.height - 40 - margin * 2
            remarkLabel.frame = CGRect(x: margin, y: margin, width: width, height: height)
        }
    }
}
