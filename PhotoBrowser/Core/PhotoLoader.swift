//
//  PhotoLoader.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/4/24.
//

import Foundation

public protocol PhotoLoader {
    /// 是否有指定的缓存图片
    func isImageCached(on imageView: UIImageView, url: URL) -> Bool

    /// 加载图片并设置给 imageView
    /// 加载本地图片时，url 为空，placeholder 为本地图片
    func setImage(on imageView: UIImageView,
                  url: URL?,
                  placeholder: UIImage?,
                  progressBlock: @escaping (_ receivedSize: Int64, _ totalSize: Int64) -> Void,
                  completionHandler: @escaping () -> Void)
}
