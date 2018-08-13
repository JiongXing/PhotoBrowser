//
//  CellPluginViewController.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2018/8/14.
//  Copyright © 2018年 JiongXing. All rights reserved.
//

import Foundation
import JXPhotoBrowser
import Kingfisher

final class CellPluginViewController: BaseCollectionViewController {
    
    override var name: String {
        return "Cell插件测试"
    }
    
    override func makeDataSource() -> [PhotoModel] {
        return [PhotoModel(thumbnailUrl: "http://wx3.sinaimg.cn/thumbnail/bfc243a3gy1febm7nzbz7j20ib0iek5j.jpg",
                           highQualityUrl: "http://wx3.sinaimg.cn/large/bfc243a3gy1febm7nzbz7j20ib0iek5j.jpg",
                           rawUrl: nil, localName: nil),
                PhotoModel(thumbnailUrl: "http://wx1.sinaimg.cn/thumbnail/bfc243a3gy1febm7orgqfj20i80ht15x.jpg",
                           highQualityUrl: "http://wx1.sinaimg.cn/large/bfc243a3gy1febm7orgqfj20i80ht15x.jpg",
                           rawUrl: nil, localName: nil),
                PhotoModel(thumbnailUrl: "http://wx2.sinaimg.cn/thumbnail/bfc243a3gy1febm7sdk4lj20ib0i714u.jpg",
                           highQualityUrl: "http://wx2.sinaimg.cn/large/bfc243a3gy1febm7sdk4lj20ib0i714u.jpg",
                           rawUrl: nil, localName: nil),
        ]
    }
    
    var overlayModels = [
        OverlayModel(showButton: true, text: "   咦发生什么事~"),
        OverlayModel(showButton: true, text: "   求抱抱~"),
        OverlayModel(showButton: true, text: "   我也要~")
    ]
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reusedId, for: indexPath) as! BaseCollectionViewCell
        if let urlString = dataSource[indexPath.item].thumbnailUrl {
            cell.imageView.kf.setImage(with: URL(string: urlString))
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        // 创建图片浏览器
        let browser = PhotoBrowser(animationType: .scale, delegate: self, originPageIndex: indexPath.item)
        // 数字型页码指示器
        browser.plugins = [NumberPageControlPlugin()]
        // Cell插件，覆盖在Cell之上
        let overlayPlugin = OverlayPlugin()
        overlayPlugin.dataSourceProvider = { [unowned self] index in
            return self.overlayModels[index]
        }
        weak var weakBrowser = browser
        overlayPlugin.didTouchDeleteButton = { [unowned self] index in
            
            self.dataSource.remove(at: index)
            self.overlayModels.remove(at: index)
            self.collectionView?.reloadData()
            weakBrowser?.deleteItem(at: index)
        }
        browser.cellPlugins.append(overlayPlugin)
        // 显示
        browser.show(from: self)
    }
}

extension CellPluginViewController: PhotoBrowserDelegate {
    /// 图片总数量
    func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int {
        return dataSource.count
    }
    
    /// 缩略图所在 view
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView? {
        return collectionView?.cellForItem(at: IndexPath(item: index, section: 0))
    }
    
    /// 缩略图图片，在加载完成之前用作 placeholder 显示
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage? {
        let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? BaseCollectionViewCell
        return cell?.imageView.image
    }
    
    /// 高清图
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlForIndex index: Int) -> URL? {
        return dataSource[index].highQualityUrl.flatMap {
            URL(string: $0)
        }
    }
    
}

