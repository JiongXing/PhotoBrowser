//
//  LocalImageSmoothZoomViewController.swift
//  Example
//
//  Created by JiongXing on 2019/11/28.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class ImageSmoothZoomViewController: BaseCollectionViewController {

    override class func name() -> String { "更丝滑的Zoom转场动画" }
    override class func remark() -> String { "需要用户自己创建并提供转场视图，以及缩略图位置" }

    override func makeDataSource() -> [ResourceModel] {
        makeLocalDataSource()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        cell.imageView.image = self.dataSource[indexPath.item].localName.flatMap { UIImage(named: $0) }
        // 等比拉伸，填满视图
        cell.imageView.contentMode = .scaleAspectFill
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        let browser = JXPhotoBrowser()
        browser.numberOfItems = {
            self.dataSource.count
        }
        browser.reloadCellAtIndex = { context in
            let browserCell = context.cell as? JXPhotoBrowserImageCell
            let indexPath = IndexPath(item: context.index, section: indexPath.section)
            browserCell?.imageView.image = self.dataSource[indexPath.item].localName.flatMap { UIImage(named: $0) }
        }
        // 更丝滑的Zoom动画
        browser.transitionAnimator = JXPhotoBrowserSmoothZoomAnimator(transitionViewAndFrame: { (index, destinationView) -> JXPhotoBrowserSmoothZoomAnimator.TransitionViewAndFrame? in
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
        browser.show(method: .push(inNC: nil))
    }
}
