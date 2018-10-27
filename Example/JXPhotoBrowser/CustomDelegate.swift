//
//  CustomDelegate.swift
//  JXPhotoBrowser_Example
//
//  Created by JiongXing on 2018/10/27.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import JXPhotoBrowser

class CustomDelegate: JXDefaultPageControlDelegate {

    /// 点下一张
    var clickBackCallback: ((CustomDelegate) -> Void)?
    
    /// 点下一张
    var clickForwardCallback: ((CustomDelegate) -> Void)?
    
    // 后退按钮
    lazy var backButton: UIButton = { [unowned self] in
        return self.makeButton(title: "<<")
    }()
    
    // 前进按钮
    lazy var forwardButton: UIButton = { [unowned self] in
        return self.makeButton(title: ">>")
    }()
    
    private func makeButton(title: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.layer.cornerRadius = 3
        button.layer.borderWidth = 1 / UIScreen.main.scale
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }
    
    /// 初始化
    override func photoBrowserViewDidLoad(_ browser: JXPhotoBrowser) {
        browser.view.addSubview(backButton)
        browser.view.addSubview(forwardButton)
        backButton.addTarget(self, action: #selector(onBackButton), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(onForwardButton), for: .touchUpInside)
    }
    
    override func photoBrowserViewDidLayoutSubviews(_ browser: JXPhotoBrowser) {
        super.photoBrowserViewDidLayoutSubviews(browser)
        do {
            let width: CGFloat = 50
            let height: CGFloat = 30
            let x: CGFloat = 20
            let y: CGFloat = 40
            backButton.frame = CGRect(x: x, y: y, width: width, height: height)
        }
        do {
            let width: CGFloat = 50
            let height: CGFloat = 30
            let x = browser.view.bounds.width - 20 - width
            let y: CGFloat = 40
            forwardButton.frame = CGRect(x: x, y: y, width: width, height: height)
        }
    }
    
    @objc private func onBackButton() {
        clickBackCallback?(self)
    }
    
    @objc private func onForwardButton() {
        clickForwardCallback?(self)
    }
}
