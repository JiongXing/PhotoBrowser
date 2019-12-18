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
}
