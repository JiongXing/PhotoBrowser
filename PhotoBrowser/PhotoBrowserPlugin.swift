//
//  PhotoBrowserPlugin.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/5/13.
//

import Foundation

public protocol PhotoBrowserPlugin {
    func photoBrowser(_ photoBrowser: PhotoBrowser, didChangedPageIndex index: Int)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, numberOfPhotos number: Int)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, reusableCell cell: PhotoBrowserCell, atIndex index: Int)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLoad view: UIView)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillAppear view: UIView, animated: Bool)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidAppear view: UIView, animated: Bool)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillLayoutSubviews view: UIView)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLayoutSubviews view: UIView)
}

extension PhotoBrowserPlugin {
    public func photoBrowser(_ photoBrowser: PhotoBrowser, didChangedPageIndex index: Int) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, numberOfPhotos number: Int) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, reusableCell cell: PhotoBrowserCell, atIndex index: Int) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLoad view: UIView) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillAppear view: UIView, animated: Bool) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidAppear view: UIView, animated: Bool) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillLayoutSubviews view: UIView) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLayoutSubviews view: UIView) {}
}
