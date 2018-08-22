//
//  LocalImageLazyLoadViewController.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2018/8/12.
//  Copyright © 2018年 JiongXing. All rights reserved.
//

import Foundation
import JXPhotoBrowser

final class LocalImageLazyLoadViewController: BaseCollectionViewController {
    
    override var switchTitle: String?  {
        return  "动画:"
    }
    
    override var name: String {
        return "本地图片-懒加载"
    }
    
    override func makeDataSource() -> [PhotoModel] {
        var result: [PhotoModel] = []
        (0..<6).forEach {
            let model = PhotoModel(thumbnailUrl: nil, highQualityUrl: nil, rawUrl: nil, localName: "local_\($0)")
            result.append(model)
        }
        return result
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reusedId, for: indexPath) as! BaseCollectionViewCell
        if let imageName = dataSource[indexPath.item].localName {
            cell.imageView.image = UIImage(named: imageName)
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        // 创建图片浏览器
        let browser = PhotoBrowser(animationType: isSWitchOn ? .scale : .fade, delegate: self, originPageIndex: indexPath.item)
        // 显示
        browser.show(from: self)
    }
}

extension LocalImageLazyLoadViewController: PhotoBrowserDelegate {
    /// 图片总数量
    func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int {
        return dataSource.count
    }
    
    /// 缩略图所在 view
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView? {
        return collectionView?.cellForItem(at: IndexPath(item: index, section: 0))
    }
    
    /// 缩略图图片，在加载完成之前用作 placeholder 显示
    /// 返回 nil 直接显示本地图片
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage? {
        return nil
    }
    
    /// 本地图片
    func photoBrowser(_ photoBrowser: PhotoBrowser, localImageForIndex index: Int) -> UIImage? {
        if let name = dataSource[index].localName {
            return UIImage(named: name)
        }
        return nil
    }
}
