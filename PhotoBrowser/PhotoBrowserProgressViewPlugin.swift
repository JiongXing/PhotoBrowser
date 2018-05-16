//
//  PhotoBrowserProgressViewPlugin.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/5/16.
//

import Foundation

open class PhotoBrowserProgressViewPlugin: PhotoBrowserCellPlugin {
    
    /// 每次取复用 cell 时会调用
    public func photoBrowserCellDidReused(_ cell: PhotoBrowserCell, at index: Int) {
        _ = (cell.associatedObjects["ProgressView"] as? PhotoBrowserProgressView) ?? {
            let view = PhotoBrowserProgressView()
            view.isHidden = true
            cell.contentView.addSubview(view)
            cell.associatedObjects["ProgressView"] = view
            return view
        }()
    }
    
    /// PhotoBrowserCell 执行布局方法时调用
    public func photoBrowserCellDidLayout(_ cell: PhotoBrowserCell) {
        if let progressView = cell.associatedObjects["ProgressView"] as? PhotoBrowserProgressView {
            progressView.center = CGPoint(x: cell.contentView.bounds.midX, y: cell.contentView.bounds.midY)
        }
    }
    
    /// 即将加载图片
    public func photoBrowserCellWillLoadImage(_ cell: PhotoBrowserCell, placeholder: UIImage?, url: URL?) {
        if let progressView = cell.associatedObjects["ProgressView"] as? PhotoBrowserProgressView {
            progressView.isHidden = false
        }
    }
    
    /// 正在加载图片
    public func photoBrowserCellLoadingImage(_ cell: PhotoBrowserCell, receivedSize: Int64, totalSize: Int64) {
        if let progressView = cell.associatedObjects["ProgressView"] as? PhotoBrowserProgressView {
            if totalSize > 0 {
                progressView.progress = CGFloat(receivedSize) / CGFloat(totalSize)
            }
        }
    }
    
    /// 加载图片完成
    public func photoBrowserCellDidLoadImage(_ cell: PhotoBrowserCell, placeholder: UIImage?, url: URL?) {
        if let progressView = cell.associatedObjects["ProgressView"] as? PhotoBrowserProgressView {
            progressView.isHidden = true
        }
    }
}
