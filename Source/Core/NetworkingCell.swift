//
//  NetworkingCell.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit

extension JXPhotoBrowser {
    /// 可展示两级资源。比如首先展示模糊的图片，然后展示清晰的图片
    open class NetworkingCell: JXPhotoBrowser.BaseCell {
        
        public let progressView = ProgressView()
        
        /// 初始化
        open override func setupViews() {
            progressView.isHidden = true
            contentView.addSubview(progressView)
        }
        
        /// 布局
        open override func layoutSubviews() {
            super.layoutSubviews()
            progressView.center = CGPoint(x: contentView.bounds.width / 2, y: contentView.bounds.height / 2)
        }
        
        /// 刷新数据
        open func reloadData(photoLoader: JXPhotoLoader,
                             localImage: UIImage?,
                             autoloadURLString: String?) {
            // 重置环境
            progressView.isHidden = true
            // url是否有效
            guard let urlString = autoloadURLString,let url = URL(string: urlString) else {
                imageView.image = localImage
                setNeedsLayout()
                return
            }
            // 取缓存
            let image = photoLoader.imageCached(on: imageView, url: url)
            progressView.isHidden = image != nil
            let placeholder = image ?? localImage
            // 加载
            photoLoader.setImage(on: imageView, url: url, placeholder: placeholder, progressBlock: { receivedSize, totalSize in
                if totalSize > 0 {
                    self.progressView.progress = CGFloat(receivedSize) / CGFloat(totalSize)
                } else {
                    self.progressView.progress = 0
                }
            }) {
                self.progressView.isHidden = true
                self.setNeedsLayout()
            }
            setNeedsLayout()
        }
    }
    
}
