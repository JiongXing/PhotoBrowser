//
//  NetworkImageViewController.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2018/8/13.
//  Copyright © 2018年 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser
import Kingfisher

final class NetworkImageViewController: BaseCollectionViewController {
    
    override var name: String {
        return "缩略图-高清图"
    }
    
    override func makeDataSource() -> [PhotoModel] {
        return [PhotoModel(thumbnailUrl: "http://wx3.sinaimg.cn/thumbnail/bfc243a3gy1febm7nzbz7j20ib0iek5j.jpg",
                           highQualityUrl: "http://wx3.sinaimg.cn/large/bfc243a3gy1febm7nzbz7j20ib0iek5j.jpg",
                           rawUrl: nil, localName: nil),
                PhotoModel(thumbnailUrl: "http://wx1.sinaimg.cn/thumbnail/bfc243a3gy1febm7orgqfj20i80ht15x.jpg",
                           highQualityUrl: "http://wx1.sinaimg.cn/large/bfc243a3gy1febm7orgqfj20i80ht15x.jpg",
                           rawUrl: nil, localName: nil),
                PhotoModel(thumbnailUrl: "http://wx1.sinaimg.cn/thumbnail/bfc243a3gy1febm7n9eorj20i60hsann.jpg",
                           highQualityUrl: "http://wx1.sinaimg.cn/large/bfc243a3gy1febm7n9eorj20i60hsann.jpg",
                           rawUrl: nil, localName: nil),
                PhotoModel(thumbnailUrl: "http://wx2.sinaimg.cn/thumbnail/bfc243a3gy1febm7pmnk7j20i70jidwo.jpg",
                           highQualityUrl: "http://wx2.sinaimg.cn/large/bfc243a3gy1febm7pmnk7j20i70jidwo.jpg",
                           rawUrl: nil, localName: nil),
                PhotoModel(thumbnailUrl: "http://wx3.sinaimg.cn/thumbnail/bfc243a3gy1febm7qjop4j20i00hw4c6.jpg",
                           highQualityUrl: "http://wx3.sinaimg.cn/large/bfc243a3gy1febm7qjop4j20i00hw4c6.jpg",
                           rawUrl: nil, localName: nil),
                PhotoModel(thumbnailUrl: "http://wx4.sinaimg.cn/thumbnail/bfc243a3gy1febm7rncxaj20ek0i74dv.jpg",
                           highQualityUrl: "http://wx4.sinaimg.cn/large/bfc243a3gy1febm7rncxaj20ek0i74dv.jpg",
                           rawUrl: nil, localName: nil),
                PhotoModel(thumbnailUrl: "http://wx2.sinaimg.cn/thumbnail/bfc243a3gy1febm7sdk4lj20ib0i714u.jpg",
                           highQualityUrl: "http://wx2.sinaimg.cn/large/bfc243a3gy1febm7sdk4lj20ib0i714u.jpg",
                           rawUrl: nil, localName: nil),
                PhotoModel(thumbnailUrl: "http://wx4.sinaimg.cn/thumbnail/bfc243a3gy1febm7tekewj20i20i4aoy.jpg",
                           highQualityUrl: "http://wx4.sinaimg.cn/large/bfc243a3gy1febm7tekewj20i20i4aoy.jpg",
                           rawUrl: nil, localName: nil),
                PhotoModel(thumbnailUrl: "http://wx3.sinaimg.cn/thumbnail/bfc243a3gy1febm7usmc8j20i543zngx.jpg",
                           highQualityUrl: "http://wx3.sinaimg.cn/large/bfc243a3gy1febm7usmc8j20i543zngx.jpg",
                           rawUrl: nil, localName: nil)
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
        // 光点型页码指示器
        browser.plugins = [DefaultPageControlPlugin()]
        // 显示
        browser.show(from: self)
    }
}

extension NetworkImageViewController: PhotoBrowserDelegate {
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
