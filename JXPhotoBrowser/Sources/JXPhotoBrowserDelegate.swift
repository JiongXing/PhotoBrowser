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
    
    /// 返回指定索引的 item 在列表中的缩略图视图（用于 Zoom 转场的起止位置计算）
    /// 返回 nil 时 Zoom 转场将降级为 Fade 动画
    func photoBrowser(_ browser: JXPhotoBrowser, thumbnailViewAt index: Int) -> UIView?
    
    /// 设置指定索引的 item 的缩略图视图的显隐状态（Zoom 转场时隐藏源视图，避免视觉重叠）
    func photoBrowser(_ browser: JXPhotoBrowser, setThumbnailHidden hidden: Bool, at index: Int)
    
    /// 返回指定索引的 item 尺寸，可选实现，默认返回 collectionView.bounds.size
    func photoBrowser(_ browser: JXPhotoBrowser, sizeForItemAt index: Int) -> CGSize?
}

public extension JXPhotoBrowserDelegate {
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoBrowserAnyCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoBrowserAnyCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, thumbnailViewAt index: Int) -> UIView? { nil }
    func photoBrowser(_ browser: JXPhotoBrowser, setThumbnailHidden hidden: Bool, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, sizeForItemAt index: Int) -> CGSize? { nil }
}
