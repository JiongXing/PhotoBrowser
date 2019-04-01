//
//  JXPhotoLoader.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation

/// PhotoLoader 实现者必须是 NSObject 子类
public protocol JXPhotoLoader {
    /// 取缓存的图片对象
    func hasCached(with url: URL?) -> Bool
    
    /// 加载图片并设置给 imageView
    /// 加载本地图片时，url 为空，placeholder 为本地图片
    func setImage(on imageView: UIImageView,
                  url: URL?,
                  placeholder: UIImage?,
                  progressBlock: @escaping (_ receivedSize: Int64, _ totalSize: Int64) -> Void,
                  completionHandler: @escaping () -> Void)
}
