//
//  ViewController.swift
//  Demo
//
//  Created by jxing on 2026/2/10.
//

import UIKit
import JXPhotoBrowser

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Demo"

        // 验证 JXPhotoBrowser 框架已通过 Carthage 正确集成
        let browser = JXPhotoBrowserViewController()
        print("JXPhotoBrowser 通过 Carthage 集成成功: \(browser)")
    }
}
