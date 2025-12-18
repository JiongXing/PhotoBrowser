//
//  JXPhotoBrowserDelegate.swift
//  Pods
//
//  Created by jxing on 2025/12/18.
//

public typealias JXPhotoBrowserAnyCell = UICollectionViewCell & JXPhotoBrowserCellProtocol

public protocol JXPhotoBrowserDelegate: AnyObject {
    /// 返回图片总数，必须实现
    func numberOfItems(in browser: JXPhotoBrowser) -> Int
    
    /// 返回指定索引的 item 对应的 Cell，必须实现
    func photoBrowser(_ browser: JXPhotoBrowser, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell
    
    /// 当 Cell 将要显示时调用，可选实现
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoBrowserAnyCell, at index: Int)
    
    /// 当 Cell 已经显示时调用，可选实现
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoBrowserAnyCell, at index: Int)
    
    /// 设置指定索引的 item 的源视图的隐藏状态，可选实现
    func photoBrowser(_ browser: JXPhotoBrowser, setOriginViewHidden hidden: Bool, at index: Int)
    
    /// 返回指定索引的 item 的源视图，可选实现
    func photoBrowser(_ browser: JXPhotoBrowser, zoomOriginViewAt index: Int) -> UIView?
    
    /// 返回指定索引的 item 的缩放视图，可选实现
    func photoBrowser(_ browser: JXPhotoBrowser, zoomViewForItemAt index: Int, isPresenting: Bool) -> UIView?
    
    /// 返回指定索引的 item 尺寸，可选实现，默认返回 collectionView.bounds.size
    func photoBrowser(_ browser: JXPhotoBrowser, sizeForItemAt index: Int) -> CGSize?
}

public extension JXPhotoBrowserDelegate {
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoBrowserAnyCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoBrowserAnyCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, setOriginViewHidden hidden: Bool, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, zoomOriginViewAt index: Int) -> UIView? { nil }
    func photoBrowser(_ browser: JXPhotoBrowser, zoomViewForItemAt index: Int, isPresenting: Bool) -> UIView? { nil }
    func photoBrowser(_ browser: JXPhotoBrowser, sizeForItemAt index: Int) -> CGSize? { nil }
}
