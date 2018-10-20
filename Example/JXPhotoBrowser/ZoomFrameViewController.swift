//
//  ZoomFrameViewController.swift
//  JXPhotoBrowser_Example
//
//  Created by JiongXing on 2018/10/16.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import JXPhotoBrowser

class ZoomFrameViewController: BaseCollectionViewController {
    
    override var name: String {
        return "Zoom动画-使用动画起始/结束Frame"
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
        cell.imageView.image = self.dataSource[indexPath.item].localName.flatMap({ name -> UIImage? in
            return UIImage(named: name)
        })
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        // 数据源
        let dataSource = JXLocalDataSource(numberOfItems: {
            // 共有多少项
            return self.dataSource.count
        }, localImage: { index -> UIImage? in
            // 每一项的图片对象
            return self.dataSource[index].localName.flatMap({ name -> UIImage? in
                return UIImage(named: name)
            })
        })
        // 视图代理，实现了光点型页码指示器
        let delegate = JXDefaultPageControlDelegate()
        // 转场动画
        let trans = JXPhotoBrowserZoomTransitioning { (browser, index, view) -> CGRect? in
            let indexPath = IndexPath(item: index, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) {
                return cell.convert(cell.bounds, to: view)
            }
            return nil
        }
        // 打开浏览器
        JXPhotoBrowser(dataSource: dataSource, delegate: delegate, transDelegate: trans)
            .show(pageIndex: indexPath.item)
    }
}
