//
//  JXKingfisherWebPLoader.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit
import Kingfisher
import KingfisherWebP

public class JXKingfisherWebPLoader: JXPhotoLoader {
    
    public init() {}
    
    public func hasCached(with url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        let identifier = "com.yeatse.WebPProcessor"
        return KingfisherManager.shared.cache
            .imageCachedType(forKey: url.cacheKey, processorIdentifier: identifier).cached
    }
    
    public func setImage(on imageView: UIImageView, url: URL?, placeholder: UIImage?, progressBlock: @escaping (Int64, Int64) -> Void, completionHandler: @escaping () -> Void) {
        let options: KingfisherOptionsInfo = [.cacheOriginalImage,
                                              .processor(WebPProcessor.default),
                                              .cacheSerializer(WebPSerializer.default)]
        
        imageView.kf.setImage(with: url, placeholder: placeholder, options: options, progressBlock: { receivedSize, totalSize in
            progressBlock(receivedSize, totalSize)
        }, completionHandler: { _, _, _, _ in
            completionHandler()
        })
    }
}
