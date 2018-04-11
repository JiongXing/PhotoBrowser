//
//  PhotoBrowserDelegate.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/4/11.
//

import Foundation

public protocol PhotoBrowserDelegate: class {
    //
    // MARK: - 必选
    //
    
    /// 实现本方法以返回图片数量
    func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int
    
    /// 实现本方法以返回默认显示图片，缩略图或占位图
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage?
    
    /// 实现本方法以返回默认图所在view，在转场动画完成后将会修改这个view的alpha属性
    /// 比如你可返回ImageView，或整个Cell
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView?
    
    //
    // MARK: - 可选
    //
    
    /// 实现本方法以返回高质量图片的url。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlForIndex index: Int) -> URL?
    
    /// 实现本方法以返回原图级质量的url。当本代理方法有返回值时，自动显示查看原图按钮。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, rawUrlForIndex index: Int) -> URL?
    
    /// 长按时回调。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, didLongPressForIndex index: Int, image: UIImage)
    
    /// 即将关闭图片浏览器时回调
    /// - parameter index: 即将关闭时，正在显示的图片序号
    /// - parameter image: 即将关闭时，正在显示的图片
    func photoBrowser(_ photoBrowser: PhotoBrowser, willDismissWithIndex index: Int, image: UIImage)
    
    /// 已经关闭图片浏览器时回调
    /// - parameter index: 最后显示的图片序号
    /// - parameter image: 最后显示的图片
    func photoBrowser(_ photoBrowser: PhotoBrowser, didDismissWithIndex index: Int, image: UIImage)
}

//
// MARK: - 默认实现
//

public extension PhotoBrowserDelegate {
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlForIndex index: Int) -> URL? {
        return nil
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, rawUrlForIndex index: Int) -> URL? {
        return nil
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, didLongPressForIndex index: Int, image: UIImage) {}
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, willDismissWithIndex index: Int, image: UIImage) {}
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, didDismissWithIndex index: Int, image: UIImage) {}
    
    func pageControlOfPhotoBrowser<T: UIView>(_ photoBrowser: PhotoBrowser) -> T? {
        return nil
    }
}
