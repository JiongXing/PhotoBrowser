//
//  KingfisherWebPLoader.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit
import Kingfisher
import KingfisherWebP

extension JXPhotoBrowser {
    public class KingfisherWebPLoader: JXPhotoLoader {
        
        public init() {}
        
        public func imageCached(on imageView: UIImageView, url: URL?) -> UIImage? {
            guard let url = url else {
                return nil
            }
            let cache = KingfisherManager.shared.cache
            let result = cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: "com.yeatse.WebPProcessor")
            switch result {
            case .none:
                return nil
            case .memory:
                return cache.retrieveImageInMemoryCache(forKey: url.cacheKey, options: options)
            case .disk:
                return cache.retrieveImageInDiskCache(forKey: url.cacheKey, options: options)
            }
        }
        
        public func setImage(on imageView: UIImageView, url: URL?, placeholder: UIImage?, progressBlock: @escaping (Int64, Int64) -> Void, completionHandler: @escaping () -> Void) {
            imageView.kf.setImage(with: url,
                                  placeholder: placeholder,
                                  options: options,
                                  progressBlock: { (receivedSize, totalSize) in
                                    progressBlock(receivedSize, totalSize)
            }) { (_, _, _, _) in
                completionHandler()
            }
        }
        
        private var options: KingfisherOptionsInfo {
            return [.cacheOriginalImage,
                    .processor(WebPProcessor.default),
                    .cacheSerializer(WebPSerializer.default)]
        }
    }
}
