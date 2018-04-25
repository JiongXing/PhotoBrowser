//
//  KingfisherPhotoLoader.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/4/24.
//

import Foundation
import Kingfisher

public class KingfisherPhotoLoader: PhotoLoaderDelegate {
    
    public func cachedImage(with imageView: UIImageView, url: URL) -> UIImage? {
        let result = KingfisherManager.shared.cache.imageCachedType(forKey: url.cacheKey)
        switch result {
        case .none:
            return nil
        case .memory:
            return KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: url.cacheKey)
        case .disk:
            return KingfisherManager.shared.cache.retrieveImageInDiskCache(forKey: url.cacheKey)
        }
    }
    
    public func setImage(with imageView: UIImageView, url: URL, placeholder: UIImage?, progressBlock: ((Int64, Int64) -> Void)?, completionHandler: (() -> Void)?) {
        imageView.kf.setImage(with: url, placeholder: placeholder, options: nil, progressBlock: { (receivedSize, totalSize) in
            progressBlock?(receivedSize, totalSize)
        }) { (_, _, _, _) in
            completionHandler?()
        }
    }
    
}
