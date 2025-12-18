//
//  JXPhotoBrowserDelegate.swift
//  Pods
//
//  Created by jxing on 2025/12/18.
//

public typealias JXPhotoBrowserAnyCell = UICollectionViewCell & JXPhotoBrowserCellProtocol

public protocol JXPhotoBrowserDelegate: AnyObject {
    func numberOfItems(in browser: JXPhotoBrowser) -> Int
    
    func photoBrowser(_ browser: JXPhotoBrowser, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell
    
    func photoBrowser(_ browser: JXPhotoBrowser, willReuse cell: JXPhotoBrowserAnyCell, at index: Int)
    
    func photoBrowser(_ browser: JXPhotoBrowser, didReuse cell: JXPhotoBrowserAnyCell, at index: Int)
    
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoBrowserAnyCell, at index: Int)
    
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoBrowserAnyCell, at index: Int)
    
    func photoBrowser(_ browser: JXPhotoBrowser, setOriginViewHidden hidden: Bool, at index: Int)
    
    func photoBrowser(_ browser: JXPhotoBrowser, zoomOriginViewAt index: Int) -> UIView?
    
    func photoBrowser(_ browser: JXPhotoBrowser, zoomViewForItemAt index: Int, isPresenting: Bool) -> UIView?
    
    /// 返回指定索引的 item 尺寸（可选，默认返回 collectionView.bounds.size）
    func photoBrowser(_ browser: JXPhotoBrowser, sizeForItemAt index: Int) -> CGSize?
}

public extension JXPhotoBrowserDelegate {
    func photoBrowser(_ browser: JXPhotoBrowser, willReuse cell: JXPhotoBrowserAnyCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, didReuse cell: JXPhotoBrowserAnyCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoBrowserAnyCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoBrowserAnyCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, setOriginViewHidden hidden: Bool, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, zoomOriginViewAt index: Int) -> UIView? { nil }
    func photoBrowser(_ browser: JXPhotoBrowser, zoomViewForItemAt index: Int, isPresenting: Bool) -> UIView? { nil }
    func photoBrowser(_ browser: JXPhotoBrowser, sizeForItemAt index: Int) -> CGSize? { nil }
}
