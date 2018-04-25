//
//  PhotoLoaderDelegate.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/4/24.
//

import Foundation

public typealias DownloadProgressBlock = ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)

public protocol PhotoLoaderDelegate {
    /// 取缓存图片
    func cachedImage(with imageView: UIImageView, url: URL) -> UIImage?
    /// 加载网络图片并设置给 UIImageView
    func setImage(with imageView: UIImageView,
                  url: URL, placeholder: UIImage?,
                  progressBlock: ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)?,
                  completionHandler: (() -> Void)?)
    
}
