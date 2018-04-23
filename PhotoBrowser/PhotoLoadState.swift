//
//  PhotoLoadState.swift
//  JXPhotoBrowser
//
//  Created by coramo on 2018/4/18.
//

import Foundation

enum LoadState {
    case none
    case loading
    case loaded
    case failed
}

class PhotoLoadState {
    
    func setNeedsLayout() {
        if let v = self.view {
            v.updateState()
        }
    }
    
    var photoLoader: PhotoLoader?
    var thumbnailImage:UIImage?
    
    var highQualityUrl:URL? {
        willSet(newValue) {
            self.highLoadState = .none
            if let value = newValue {
                self.photoLoader?.isLoaded(url: value) { (isLoaded) in
                    if (isLoaded) {
                        self.highLoadState = .loaded
                    }
                }
            }
        }
    }
    var rawUrl:URL? {
        willSet(newValue) {
            self.rawLoadState = .none
            if let value = newValue {
                self.photoLoader?.isLoaded(url: value) { (isLoaded) in
                    if (isLoaded) {
                        self.rawLoadState = .loaded
                    }
                }
            }
        }
    }
    
    var highProgress: Float = 0
    var highLoadState: LoadState = .none
    var rawProgress: Float = 0
    var rawLoadState: LoadState = .none
    var forceRaw: Bool = false
    var view: PhotoBrowserCell?
    init(photoLoader: PhotoLoader?) {
        self.photoLoader = photoLoader
    }
    
    func load(imageView: UIImageView) {
        
        if (self.forceRaw || self.highQualityUrl == nil || self.rawLoadState == .loaded) {
            self.photoLoader?.load(url: self.rawUrl, imageView: imageView, loaderListener: RawLoadListener(state: self))
        }else{
            self.photoLoader?.load(url: self.highQualityUrl, imageView: imageView, loaderListener: HighLoadListener(state: self))
        }
    }
    
    private class HighLoadListener: PhotoLoaderListener {
        
        let state: PhotoLoadState
        
        init(state: PhotoLoadState) {
            self.state = state
        }
        
        func onLoadStart(hasProgress: Bool) {
            self.state.highLoadState = .loading
            self.state.setNeedsLayout()
        }
        
        func onLoadProgress(loaded: Float, total: Float) {
            self.state.highProgress = loaded / total
            self.state.setNeedsLayout()
        }
        
        func onLoadError() {
            self.state.highLoadState = .failed
            self.state.setNeedsLayout()
        }
        
        func onLoadSuccess() {
            self.state.highLoadState = .loaded
            self.state.setNeedsLayout()
        }
    }
    
    private class RawLoadListener: PhotoLoaderListener {
        let state: PhotoLoadState
        
        init(state: PhotoLoadState) {
            self.state = state
        }
        
        func onLoadStart(hasProgress: Bool) {
            self.state.rawLoadState = .loading
            self.state.setNeedsLayout()
        }
        
        func onLoadProgress(loaded: Float, total: Float) {
            self.state.rawProgress = loaded / total
            self.state.setNeedsLayout()
        }
        
        func onLoadError() {
            self.state.rawLoadState = .failed
            self.state.setNeedsLayout()
        }
        
        func onLoadSuccess() {
            self.state.rawLoadState = .loaded
            self.state.setNeedsLayout()
        }
    }
    
}
