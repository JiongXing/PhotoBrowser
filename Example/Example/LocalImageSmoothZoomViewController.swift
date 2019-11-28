//
//  LocalImageSmoothZoomViewController.swift
//  Example
//
//  Created by JiongXing on 2019/11/28.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class LocalImageSmoothZoomViewController: BaseCollectionViewController {
    
    override var name: String { "更丝滑的Zoom转场动画" }
    
    override var remark: String { "需要用户自己创建并提供转场视图，以及缩略图位置" }
    
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
            UIImage(named: name)
        })
        // 等比拉伸，填满视图
        cell.imageView.contentMode = .scaleAspectFill
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        let browser = JXPhotoBrowser()
        browser.numberOfItems = {
            self.dataSource.count
        }
        browser.reloadCell = { cell, index in
            if let cell = cell as? JXPhotoBrowserImageCell {
                cell.imageView.image = UIImage(named: "local_\(index)")
            }
        }
        // 更丝滑的Zoom动画
        browser.transitionAnimator = JXPhotoBrowserSmoothZoomAnimator(transitionContext: { (index, destinationView) -> JXPhotoBrowserSmoothZoomAnimator.TransitionContext? in
            let path = IndexPath(item: index, section: indexPath.section)
            guard let cell = collectionView.cellForItem(at: path) as? BaseCollectionViewCell else {
                return nil
            }
            let image = cell.imageView.image
            let transitionView = UIImageView(image: image)
            transitionView.contentMode = cell.imageView.contentMode
            transitionView.clipsToBounds = true
            let thumbnailFrame = cell.imageView.convert(cell.imageView.bounds, to: destinationView)
            return (transitionView, thumbnailFrame)
        })
        browser.pageIndex = indexPath.item
        browser.show()
    }
}
