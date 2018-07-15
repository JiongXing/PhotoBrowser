//
//  PhotoBrowserDelegate.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/4/11.
//

import Foundation

public protocol PhotoBrowserDelegate: class {

    /// 浏览非本地图片时必须实现本方法
    /// 实现本方法以返回图片数量
    func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int

    /// 使用 scale 动画时必须实现本方法
    /// 实现本方法以返回各缩略图所在 view，在转场动画完成后将会修改这个 view 的 alpha 属性
    /// 比如你可返回 ImageView，或整个 Cell
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView?

    /// 实现本方法以返回各缩略图图片
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage?

    /// 实现本方法以返回高质量图片的 url。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlForIndex index: Int) -> URL?

    /// 实现本方法以返回原图级质量的 url。当本代理方法有返回值时，自动显示查看原图按钮。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, rawUrlForIndex index: Int) -> URL?
    
    /// 实现本方法以返回本地大图。
    /// 本地图片的展示将优先于网络图片。
    /// 如果给 PhotoBrowser 设置了本地图片组 localImages，则本方法不生效。
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
    func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int { return 0 }

    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView? { return nil }

    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlForIndex index: Int) -> URL? { return nil }

    func photoBrowser(_ photoBrowser: PhotoBrowser, rawUrlForIndex index: Int) -> URL? { return nil }

    func photoBrowser(_ photoBrowser: PhotoBrowser, localImageForIndex index: Int) -> UIImage? { return nil }

    func photoBrowser(_ photoBrowser: PhotoBrowser, didLongPressForIndex index: Int, image: UIImage) {}

    func photoBrowser(_ photoBrowser: PhotoBrowser, willDismissWithIndex index: Int, image: UIImage?) {}

    func photoBrowser(_ photoBrowser: PhotoBrowser, didDismissWithIndex index: Int, image: UIImage?) {}
}
