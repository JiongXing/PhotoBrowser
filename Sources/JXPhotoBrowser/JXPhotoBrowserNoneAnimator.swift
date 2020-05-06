//
//  JXPhotoBrowserNoneAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

open class JXPhotoBrowserNoneAnimator: JXPhotoBrowserFadeAnimator {
    
    public override init() {
        super.init()
        showDuration = 0
        dismissDuration = 0
    }
}
