//
//  PhotoLoader.swift
//  JXPhotoBrowser
//
//  Created by coramo on 2018/4/18.
//

import Foundation

public protocol PhotoLoader: class {
    
    func load(url: URL?, imageView: UIImageView, loaderListener: PhotoLoaderListener)
    
    func isLoaded(url:URL, callback:(_ isLoaded: Bool) -> Void)
}

public protocol PhotoLoaderListener: class {
    
    func onLoadStart(hasProgress: Bool)
    
    func onLoadProgress(loaded: Float, total: Float)
    
    func onLoadError()
    
    func onLoadSuccess()
    
}
