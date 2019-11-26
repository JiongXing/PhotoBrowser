//
//  JXPhotoBrowserTransitionAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/25.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

public protocol JXPhotoBrowserTransitionAnimator {
    
    /// 展示
    func show(browser: JXPhotoBrowser, completion: @escaping () -> Void)
    
    /// 消失
    func dismiss(browser: JXPhotoBrowser, completion: @escaping () -> Void)
}
