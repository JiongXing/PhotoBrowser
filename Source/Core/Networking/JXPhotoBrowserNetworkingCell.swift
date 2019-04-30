//
//  JXPhotoBrowserNetworkingCell.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit

/// 可展示两级资源。比如首先展示模糊的图片，然后展示清晰的图片
open class JXPhotoBrowserNetworkingCell: JXPhotoBrowserBaseCell {
    
    /// 进度环
    public let progressView = JXPhotoBrowserProgressView()
    
    /// 初始化
    public override init(frame: CGRect) {
        super.init(frame: frame)
        progressView.isHidden = true
        contentView.addSubview(progressView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 布局
    open override func layoutSubviews() {
        super.layoutSubviews()
        progressView.center = CGPoint(x: contentView.bounds.width / 2, y: contentView.bounds.height / 2)
    }
    
    /// 刷新数据
    open func reloadData(photoLoader: JXPhotoLoader,
                         placeholder: UIImage?,
                         autoloadURLString: String?) {
        // 重置环境
        progressView.isHidden = true
        progressView.progress = 0
        // url是否有效
        guard let urlString = autoloadURLString,let url = URL(string: urlString) else {
            imageView.image = placeholder
            setNeedsLayout()
            return
        }
        // 加载
        self.progressView.isHidden = false
        photoLoader.setImage(on: imageView, url: url, placeholder: placeholder, progressBlock: { receivedSize, totalSize in
            if totalSize > 0 {
                self.progressView.progress = CGFloat(receivedSize) / CGFloat(totalSize)
            }
        }) {
            self.progressView.isHidden = true
            self.setNeedsLayout()
        }
        setNeedsLayout()
    }
}
