//
//  KingfisherPhotoLoader.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/7/13.
//

import Foundation
import Kingfisher
import KingfisherWebP

open class KingfisherPhotoLoader: PhotoLoader {
    
    public init() {}
    
    open func isImageCached(on imageView: UIImageView, url: URL) -> Bool {
        let result = KingfisherManager.shared.cache
            .imageCachedType(forKey: url.cacheKey, processorIdentifier: "com.yeatse.WebPProcessor")
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
        imageView.kf.setImage(with: url,
                              placeholder: placeholder,
                              options: [.cacheOriginalImage,
                                        .processor(WebPProcessor.default),
                                        .cacheSerializer(WebPSerializer.default)],
                              progressBlock: { (receivedSize, totalSize) in
                                progressBlock(receivedSize, totalSize)
        }) { (_, _, _, _) in
            completionHandler()
        }
    }
}
