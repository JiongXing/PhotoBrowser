//
//  PhotoLoaderDelegate.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/4/24.
//

import Foundation

public protocol PhotoLoaderDelegate {
    /// 取缓存图片
    func cachedImage(with imageView: UIImageView, url: URL) -> UIImage?
    
    /// 加载网络图片并设置给 UIImageView
    func setImage(on imageView: UIImageView,
                  url: URL, placeholder: UIImage?,
                  progressBlock: ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)?,
                  completionHandler: (() -> Void)?)
    
    /// 加载本地图片
    func setLocalImage(on imageView: UIImageView,
                       image: UIImage,
                       completionHandler: (() -> Void)?)
}
