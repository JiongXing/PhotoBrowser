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
    
    public func hasCached(with url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        return KingfisherManager.shared.cache.imageCachedType(forKey: url.cacheKey).cached
    }
    
    public func setImage(on imageView: UIImageView, url: URL?, placeholder: UIImage?, progressBlock: @escaping (Int64, Int64) -> Void, completionHandler: @escaping () -> Void) {
        imageView.kf.setImage(with: url, placeholder: placeholder, progressBlock: { receivedSize, totalSize in
            progressBlock(receivedSize, totalSize)
        }, completionHandler: { _, _, _, _ in
            completionHandler()
        })
    }
}
