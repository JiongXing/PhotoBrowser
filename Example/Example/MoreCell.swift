//
//  MoreCell.swift
//  Example
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class MoreCell: UIView, JXPhotoBrowserCell {
    
    weak var photoBrowser: JXPhotoBrowser?
    
    static func generate(with browser: JXPhotoBrowser) -> Self {
        let instance = Self.init(frame: .zero)
        instance.photoBrowser = browser
        return instance
    }
    
    var onClick: (() -> Void)?
    
    lazy var button: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("  更多 +  ", for: .normal)
        btn.setTitleColor(UIColor.darkText, for: .normal)
        return btn
    }()
    
    required override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = .white
        addSubview(button)
        button.addTarget(self, action: #selector(click), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button.sizeToFit()
        button.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }
    
    @objc private func click() {
        photoBrowser?.dismiss()
    }
}
