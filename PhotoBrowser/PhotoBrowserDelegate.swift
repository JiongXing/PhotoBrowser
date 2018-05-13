//
//  PhotoBrowserDelegate.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/4/11.
//

import Foundation

public protocol PhotoBrowserDelegate: class {
    //
    // MARK: - Required
    //
    
    /// 实现本方法以返回图片数量
    func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int
    
    /// 实现本方法以返回缩放动画起始图
    func photoBrowser(_ photoBrowser: PhotoBrowser, originImageForIndex index: Int) -> UIImage?
    
    //
    // MARK: - Optional
    //
    
    /// 实现本方法以返回缩放动画起始图所在 view，在转场动画完成后将会修改这个 view 的 alpha 属性
    /// 比如你可返回 ImageView，或整个 Cell
    /// 使用 scale 动画时必须实现本方法
    func photoBrowser(_ photoBrowser: PhotoBrowser, originViewForIndex index: Int) -> UIView?
    
    /// 实现本方法以返回高质量图片的 url。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlForIndex index: Int) -> URL?
    
    /// 实现本方法以返回原图级质量的 url。当本代理方法有返回值时，自动显示查看原图按钮。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, rawUrlForIndex index: Int) -> URL?
    
    /// 实现本方法以返回本地大图。本地图片的展示将优先于网络图片
    func photoBrowser(_ photoBrowser: PhotoBrowser, localImageForIndex index: Int) -> UIImage?
    
    /// 长按时回调。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, didLongPressForIndex index: Int, image: UIImage)
    
    /// 即将关闭图片浏览器时回调
    /// - parameter index: 即将关闭时，正在显示的图片序号
    /// - parameter image: 即将关闭时，正在显示的图片
    func photoBrowser(_ photoBrowser: PhotoBrowser, willDismissWithIndex index: Int, image: UIImage?)
    
    /// 已经关闭图片浏览器时回调
    /// - parameter index: 最后显示的图片序号
    /// - parameter image: 最后显示的图片
    func photoBrowser(_ photoBrowser: PhotoBrowser, didDismissWithIndex index: Int, image: UIImage?)
}

public extension PhotoBrowserDelegate {
    func photoBrowser(_ photoBrowser: PhotoBrowser, originViewForIndex index: Int) -> UIView? { return nil }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlForIndex index: Int) -> URL? { return nil }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, rawUrlForIndex index: Int) -> URL? { return nil }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, localImageForIndex index: Int) -> UIImage? { return nil }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, didLongPressForIndex index: Int, image: UIImage) {}
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, willDismissWithIndex index: Int, image: UIImage?) {}
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, didDismissWithIndex index: Int, image: UIImage?) {}
}
