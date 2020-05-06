//
//  JXPhotoBrowserNoneAnimator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

/// 使用本类以实现不出现转场动画的需求
open class JXPhotoBrowserNoneAnimator: JXPhotoBrowserFadeAnimator {
    
    public override init() {
        super.init()
        showDuration = 0
        dismissDuration = 0
    }
}
