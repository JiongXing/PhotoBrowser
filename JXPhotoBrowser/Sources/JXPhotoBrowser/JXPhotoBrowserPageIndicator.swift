//
//  JXPhotoBrowserPageIndicator.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/25.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

public protocol JXPhotoBrowserPageIndicator: UIView {
    
    func setup(with browser: JXPhotoBrowser)
    
    func reloadData(numberOfItems: Int, pageIndex: Int)
    
    func didChanged(pageIndex: Int)
}
