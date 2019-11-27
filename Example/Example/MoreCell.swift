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
    
    static func generate(with browser: JXPhotoBrowser) -> Self {
        return Self.init(frame: .zero)
    }
    
    var onClick: (() -> Void)?
    
    lazy var button: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("更多+", for: .normal)
        return btn
    }()
    
    required override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(button)
        button.addTarget(self, action: #selector(click), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func click() {
        onClick?()
    }
}
