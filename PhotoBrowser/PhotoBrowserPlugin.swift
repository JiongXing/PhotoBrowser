//
//  PhotoBrowserPlugin.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/5/13.
//

import Foundation

public protocol PhotoBrowserPlugin {
    /// 页码以改变
    func photoBrowser(_ photoBrowser: PhotoBrowser, didChangedPageIndex index: Int)
    
    /// 滑动时调用
    func photoBrowser(_ photoBrowser: PhotoBrowser, scrollView: UIScrollView)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, numberOfPhotos number: Int)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, reusableCell cell: PhotoBrowserCell, atIndex index: Int)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLoad view: UIView)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillAppear view: UIView, animated: Bool)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidAppear view: UIView, animated: Bool)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillLayoutSubviews view: UIView)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLayoutSubviews view: UIView)
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, didLayout cell: PhotoBrowserCell, at index: Int)
}

extension PhotoBrowserPlugin {
    public func photoBrowser(_ photoBrowser: PhotoBrowser, didChangedPageIndex index: Int) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, scrollView: UIScrollView) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, numberOfPhotos number: Int) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, reusableCell cell: PhotoBrowserCell, atIndex index: Int) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLoad view: UIView) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillAppear view: UIView, animated: Bool) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidAppear view: UIView, animated: Bool) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillLayoutSubviews view: UIView) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLayoutSubviews view: UIView) {}
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, didLayout cell: PhotoBrowserCell, at index: Int) {}
}
