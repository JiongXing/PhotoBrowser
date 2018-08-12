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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "本地图片-懒加载"
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
        
        let browser = PhotoBrowser(animationType: isSWitchOn ? .scale : .fade, delegate: self, originPageIndex: indexPath.item)
        browser.show(from: self)
    }
}

extension LocalImageLazyLoadViewController: PhotoBrowserDelegate {
    func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int {
        return dataSource.count
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView? {
        return collectionView?.cellForItem(at: IndexPath(item: index, section: 0))
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage? {
        return nil
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, localImageForIndex index: Int) -> UIImage? {
        if let name = dataSource[index].localName {
            return UIImage(named: name)
        }
        return nil
    }
}
