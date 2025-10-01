//
//  JXPhotoBrowserCell.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

public protocol JXPhotoBrowserCell: UIView {
    
    static func generate(with browser: JXPhotoBrowser) -> Self
    
    /// 准备复用，清除内容防止闪烁
    func prepareForReuse()
}

public extension JXPhotoBrowserCell {
    /// 默认实现为空，子类可重写以清除特定内容
    func prepareForReuse() {
        // 默认实现为空
    }
}
