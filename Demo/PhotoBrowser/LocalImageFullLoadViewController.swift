//
//  LocalImageFullLoadViewController.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2018/8/12.
//  Copyright © 2018年 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser

final class LocalImageFullLoadViewController: BaseCollectionViewController {
    
    override var switchTitle: String?  {
        return  "动画:"
    }
    
    override var name: String {
        return "本地图片-全量加载"
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reusedId, for: indexPath) as! MomentsPhotoCollectionViewCell
        if let imageName = dataSource[indexPath.item].localName {
            cell.imageView.image = UIImage(named: imageName)
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        // 获取全量图片
        let images = dataSource.map { (model) -> UIImage in
            var image: UIImage?
            if let name = model.localName {
                image = UIImage(named: name)
            }
            return image ?? UIImage()
        }
        // 是否用动画
        if isSWitchOn {
            // .scale 动画，需要设置 delegate 以获取缩略图
            PhotoBrowser.show(localImages: images, animationType: .scale, delegate: self, originPageIndex: indexPath.item, fromViewController: self)
        } else {
            // 不需要设置 delegate
            PhotoBrowser.show(localImages: images, originPageIndex: indexPath.item)
        }
    }
}

extension LocalImageFullLoadViewController: PhotoBrowserDelegate {
    /// 缩略图所在 view
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView? {
        return collectionView?.cellForItem(at: IndexPath(item: index, section: 0))
    }
    
    /// 缩略图图片，在加载完成之前用作 placeholder 显示
    /// 返回 nil 直接显示本地图片
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage? {
        return nil
    }
}
