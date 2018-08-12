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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "本地图片-全量加载"
    }
    
    override func makeDataSource() -> [PhotoModel] {
        var result: [PhotoModel] = []
        (0..<6).forEach {
            let model = PhotoModel(thumbnailUrl: nil, highQualityUrl: nil, rawUrl: nil, localName: "local_\($0)")
            result.append(model)
        }
        return result
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
            PhotoBrowser.show(localImages: images, animationType: .scale, delegate: self, originPageIndex: indexPath.item, fromViewController: self)
        } else {
            PhotoBrowser.show(localImages: images, originPageIndex: indexPath.item)
        }
    }
}

extension LocalImageFullLoadViewController: PhotoBrowserDelegate {
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView? {
        return collectionView?.cellForItem(at: IndexPath(item: index, section: 0))
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage? {
        return nil
    }
}
