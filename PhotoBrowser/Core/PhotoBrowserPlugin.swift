//
//  PhotoBrowserPlugin.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/5/13.
//

import Foundation

public protocol PhotoBrowserPlugin {
    /// 页码已改变
    func photoBrowser(_ photoBrowser: PhotoBrowser, didChangedPageIndex index: Int)

    /// 滑动时调用
    func photoBrowser(_ photoBrowser: PhotoBrowser, scrollViewDidScroll: UIScrollView)

    /// 每次取图片总数量时会调用
    func photoBrowser(_ photoBrowser: PhotoBrowser, numberOfPhotos number: Int)

    /// 执行 viewDidLoad 时调用
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLoad view: UIView)

    /// 执行 viewWillAppear 时调用
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillAppear view: UIView, animated: Bool)

    /// 执行 viewDidAppear 时调用
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidAppear view: UIView, animated: Bool)

    /// 执行 viewWillLayoutSubviews 时调用
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillLayoutSubviews view: UIView)

    /// 执行 viewDidLayoutSubviews 时调用
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLayoutSubviews view: UIView)

    /// 执行 viewWillDisappear 时调用
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillDisappear view: UIView)

    /// 执行 viewDidDisappear 时调用
    func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidDisappear view: UIView)
}

extension PhotoBrowserPlugin {
    /// 页码已改变
    public func photoBrowser(_ photoBrowser: PhotoBrowser, didChangedPageIndex index: Int) {}

    /// 滑动时调用
    public func photoBrowser(_ photoBrowser: PhotoBrowser, scrollViewDidScroll: UIScrollView) {}

    /// 每次取图片总数量时会调用
    public func photoBrowser(_ photoBrowser: PhotoBrowser, numberOfPhotos number: Int) {}

    /// 每次取复用 cell 时会调用
    public func photoBrowser(_ photoBrowser: PhotoBrowser, reusableCell cell: PhotoBrowserCell, atIndex index: Int) {}

    /// PhotoBrowserCell 执行布局方法时调用
    public func photoBrowser(_ photoBrowser: PhotoBrowser, didLayout cell: PhotoBrowserCell) {}

    /// 执行 viewDidLoad 时调用
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLoad view: UIView) {}

    /// 执行 viewWillAppear 时调用
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillAppear view: UIView, animated: Bool) {}

    /// 执行 viewDidAppear 时调用
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidAppear view: UIView, animated: Bool) {}

    /// 执行 viewWillLayoutSubviews 时调用
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillLayoutSubviews view: UIView) {}

    /// 执行 viewDidLayoutSubviews 时调用
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidLayoutSubviews view: UIView) {}

    /// 执行 viewWillDisappear 时调用
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewWillDisappear view: UIView) {}

    /// 执行 viewDidDisappear 时调用
    public func photoBrowser(_ photoBrowser: PhotoBrowser, viewDidDisappear view: UIView) {}
}
