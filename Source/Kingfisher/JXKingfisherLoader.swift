//
//  JXKingfisherLoader.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit
import Kingfisher

public class JXKingfisherLoader: JXPhotoLoader {
    
    public init() {}
    
    public func imageCached(on imageView: UIImageView, url: URL?) -> UIImage? {
        guard let url = url else {
            return nil
        }
        let cache = KingfisherManager.shared.cache
        let result = cache.imageCachedType(forKey: url.cacheKey)
        switch result {
        case .none:
            return nil
        case .memory:
            return cache.retrieveImageInMemoryCache(forKey: url.cacheKey)
        case .disk:
            return cache.retrieveImageInDiskCache(forKey: url.cacheKey)
        }
    }
    
    public func setImage(on imageView: UIImageView, url: URL?, placeholder: UIImage?, progressBlock: @escaping (Int64, Int64) -> Void, completionHandler: @escaping () -> Void) {
        imageView.kf.setImage(with: url,
                              placeholder: placeholder,
                              options: [],
                              progressBlock: { (receivedSize, totalSize) in
                                progressBlock(receivedSize, totalSize)
        }) { (_, _, _, _) in
            completionHandler()
        }
    }
}
