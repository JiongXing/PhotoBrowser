//
//  KingfisherPhotoLoader.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/4/24.
//

import Foundation
import Kingfisher

@objc(KingfisherPhotoLoader)
open class KingfisherPhotoLoader: NSObject, PhotoLoader {
   
    public override init() {}

    open func isImageCached(on imageView: UIImageView, url: URL) -> Bool {
        let result = KingfisherManager.shared.cache.imageCachedType(forKey: url.cacheKey)
        switch result {
        case .none:
            return false
        case .memory:
            return true
        case .disk:
            return true
        }
    }

    open func setImage(on imageView: UIImageView, url: URL?, placeholder: UIImage?, progressBlock: @escaping (Int64, Int64) -> Void, completionHandler: @escaping () -> Void) {
        imageView.kf.setImage(with: url, placeholder: placeholder, options: nil, progressBlock: { (receivedSize, totalSize) in
            progressBlock(receivedSize, totalSize)
        }) { (_, _, _, _) in
            completionHandler()
        }
    }
}
