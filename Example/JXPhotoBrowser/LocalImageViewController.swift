//
//  LocalImageViewController.swift
//  JXPhotoBrwoser_Example
//
//  Created by JiongXing on 2018/10/14.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class LocalImageViewController: BaseCollectionViewController {
    
    override var name: String {
        return "本地图片"
    }
    
    override func makeDataSource() -> [ResourceModel] {
        var result: [ResourceModel] = []
        (0..<6).forEach { index in
            let model = ResourceModel()
            model.localName = "local_\(index)"
            result.append(model)
        }
        return result
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        cell.imageView.image = self.modelArray[indexPath.item].localName.flatMap({ name -> UIImage? in
            return UIImage(named: name)
        })
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        // 数据源
        let dataSource = JXLocalDataSource(numberOfItems: {
            // 共有多少项
            return self.modelArray.count
        }, localImage: { index -> UIImage? in
            // 每一项的图片对象
            return self.modelArray[index].localName.flatMap({ name -> UIImage? in
                return UIImage(named: name)
            })
        })
        // 打开浏览器
//        JXPhotoBrowser(dataSource: dataSource).show(pageIndex: indexPath.item)
        
        // MARK: -  缩放长图
        // 视图代理，实现了光点型页码指示器
        let delegate = JXDefaultPageControlDelegate()
        ///frame  缩放
        let trans = JXPhotoBrowserZoomTransitioning { (browser, index, view) -> CGRect? in
            let indexPath = IndexPath(item: index, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) {
                let height = (cell as! BaseCollectionViewCell).imageView.image?.size.height ?? 0.0
                let width = (cell as! BaseCollectionViewCell).imageView.image?.size.width ?? 0.0
                let proportion = width / height
                let rect = cell.convert(cell.bounds, to: view)
                return CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.width / proportion )
            }
            return nil
        }
        
        // 打开浏览器
        JXPhotoBrowser(dataSource: dataSource, delegate: delegate, transDelegate: trans)
            .show(pageIndex: indexPath.item)
    }
}
