//
//  JXPhotoBrowserImageView.swift
//  JXPhotoBrowser
//
//  Created by 梁大红 on 2021/2/19.
//  Copyright © 2021 JiongXing. All rights reserved.
//

import UIKit

public class JXPhotoBrowserImageView: UIImageView {

    public weak var cell: JXPhotoBrowserImageCell?
    
    public override var image: UIImage? {
        didSet {
            cell?.setNeedsLayout()
        }
    }
}
