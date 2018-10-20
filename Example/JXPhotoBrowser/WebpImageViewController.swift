//
//  WebpImageViewController.swift
//  JXPhotoBrowser_Example
//
//  Created by JiongXing on 2018/10/16.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import JXPhotoBrowser

class WebpImageViewController: BaseCollectionViewController {
    override var name: String {
        return "WebP图片"
    }
    
    override func makeDataSource() -> [ResourceModel] {
        var result: [ResourceModel] = []
        guard let url = Bundle.main.url(forResource: "Photos", withExtension: "plist") else {
            return result
        }
        guard let data = try? Data.init(contentsOf: url) else {
            return result
        }
        let decoder = PropertyListDecoder()
        guard let array = try? decoder.decode([[String]].self, from: data) else {
            return result
        }
        let model = ResourceModel()
        model.firstLevelUrl = array[0][0]
        model.secondLevelUrl = array[0][1]
        model.thirdLevelUrl = "https://raw.githubusercontent.com/JiongXing/PhotoBrowser/master/Assets/testwebp.webp"
        result.append(model)
        return result
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        // 加载一级资源
        if let firstLevel = self.dataSource[indexPath.item].firstLevelUrl {
            let url = URL(string: firstLevel)
            cell.imageView.kf.setImage(with: url)
        } else {
            cell.imageView.kf.setImage(with: nil)
        }
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        // 网图加载器，WebP加载器
        let loader = JXKingfisherWebPLoader()
        // 数据源
        let dataSource = JXRawImageDataSource(photoLoader: loader, numberOfItems: { () -> Int in
            return self.dataSource.count
        }, localImage: { index -> UIImage? in
            let cell = collectionView.cellForItem(at: indexPath) as? BaseCollectionViewCell
            return cell?.imageView.image
        }, autoloadURLString: { index -> String? in
            return self.dataSource[index].secondLevelUrl
        }) { index -> String? in
            return self.dataSource[index].thirdLevelUrl
        }
        // 视图代理，实现了光点型页码指示器
        let delegate = JXDefaultPageControlDelegate()
        // 转场动画
        let trans = JXPhotoBrowserZoomTransitioning { (browser, index, view) -> UIView? in
            let indexPath = IndexPath(item: index, section: 0)
            return collectionView.cellForItem(at: indexPath)
        }
        // 打开浏览器
        JXPhotoBrowser(dataSource: dataSource, delegate: delegate, transDelegate: trans)
            .show(pageIndex: indexPath.item)
    }
}
