//
//  JXPhotoBrowserFadeAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/25.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

open class JXPhotoBrowserFadeAnimator: JXPhotoBrowserTransitionAnimator {
    
    open func show(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25, animations: {
            browser.maskView.alpha = 1.0
            browser.browserView.alpha = 1.0
        }) { _ in
            completion()
        }
    }
    
    open func dismiss(browser: JXPhotoBrowser, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25, animations: {
            browser.maskView.alpha = 0
            browser.browserView.alpha = 0
        }) { _ in
            completion()
        }
    }
}
