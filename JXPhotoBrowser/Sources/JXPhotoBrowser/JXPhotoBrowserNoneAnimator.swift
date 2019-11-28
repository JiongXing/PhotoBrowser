//
//  JXPhotoBrowserNoneAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import Foundation

open class JXPhotoBrowserNoneAnimator: JXPhotoBrowserTransitionAnimator {
    
    open func show(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
        completion()
    }
    
    open func dismiss(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
        completion()
    }
}
