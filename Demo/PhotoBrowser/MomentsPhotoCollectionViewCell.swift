//
//  MomentsPhotoCollectionViewCell.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2017/3/10.
//  Copyright © 2017年 JiongXing. All rights reserved.
//

import UIKit
import Kingfisher

class MomentsPhotoCollectionViewCell: UICollectionViewCell {
    
    static var defalutId: String {
        return NSStringFromClass(self)
    }
    
    lazy var imageView: AnimatedImageView = {
        
        let iv = AnimatedImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.masksToBounds = true
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        imageView.frame = contentView.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
