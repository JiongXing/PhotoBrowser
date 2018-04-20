//
//  KingfisherPhotoLoader.swift
//  PhotoBrowser
//
//  Created by coramo on 2018/4/21.
//  Copyright © 2018年 JiongXing. All rights reserved.
//

import Foundation
import JXPhotoBrowser
import Kingfisher

class KingfisherPhotoLoader: PhotoLoader {
    func load(url: URL?, imageView: UIImageView, loaderListener: PhotoLoaderListener) {
        loaderListener.onLoadStart(hasProgress: true)
        imageView.kf.setImage(with: url, placeholder: imageView.image, options: .none, progressBlock: { (received, total) in
            loaderListener.onLoadProgress(loaded: Float(received), total: Float(total))
        }) { (image, error, cacheType, u) in
            if error != nil {
                loaderListener.onLoadError()
            }else{
                loaderListener.onLoadSuccess()
            }
        }
    }
    
    func isLoaded(url: URL, callback: (Bool) -> Void) {
        let cacheType = KingfisherManager.shared.cache.imageCachedType(forKey: url.absoluteString)
        callback(cacheType.cached)
    }
    
    
}
