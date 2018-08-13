//
//  GIFViewController.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2018/8/13.
//  Copyright © 2018年 JiongXing. All rights reserved.
//

import Foundation
import JXPhotoBrowser
import Kingfisher

final class GIFViewController: BaseCollectionViewController {
    
    override var name: String {
        return "GIF测试"
    }
    
    override func makeDataSource() -> [PhotoModel] {
        return [PhotoModel(thumbnailUrl: "http://wx3.sinaimg.cn/thumbnail/bfc243a3gy1febm7nzbz7j20ib0iek5j.jpg",
                           highQualityUrl: "http://wx3.sinaimg.cn/large/bfc243a3gy1febm7nzbz7j20ib0iek5j.jpg",
                           rawUrl: nil, localName: nil),
                PhotoModel(thumbnailUrl: "http://wx1.sinaimg.cn/thumbnail/bfc243a3gy1febm7orgqfj20i80ht15x.jpg",
                           highQualityUrl: "http://wx1.sinaimg.cn/large/bfc243a3gy1febm7orgqfj20i80ht15x.jpg",
                           rawUrl: nil, localName: nil),
                PhotoModel(thumbnailUrl: "http://wx2.sinaimg.cn/thumbnail/bfc243a3gy1febm7sdk4lj20ib0i714u.jpg",
                           highQualityUrl: "http://img.gaoxiaogif.cn/GaoxiaoGiffiles/images/2015/07/10/maomiqiangqianbuhuan.gif",
                           rawUrl: "http://seopic.699pic.com/photo/00040/8565.jpg_wh1200.jpg",
                           localName: nil),
        ]
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reusedId, for: indexPath) as! MomentsPhotoCollectionViewCell
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
        // 显示
        browser.show(from: self)
    }
}

extension GIFViewController: PhotoBrowserDelegate {
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
        let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? MomentsPhotoCollectionViewCell
        return cell?.imageView.image
    }
    
    /// 高清图
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlForIndex index: Int) -> URL? {
        return dataSource[index].highQualityUrl.flatMap {
            URL(string: $0)
        }
    }
}
