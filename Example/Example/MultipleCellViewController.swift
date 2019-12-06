//
//  MultipleCellViewController.swift
//  Example
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class MultipleCellViewController: BaseCollectionViewController {
    
    override var name: String { "多种类视图" }
    
    override var remark: String { "支持不同的类作为项视图" }
    
    override func makeDataSource() -> [ResourceModel] {
        makeLocalDataSource()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        cell.imageView.image = self.dataSource[indexPath.item].localName.flatMap { UIImage(named: $0) }
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        let browser = JXPhotoBrowser()
        browser.numberOfItems = {
            self.dataSource.count + 1
        }
        browser.cellClassAtIndex = { index in
            if index < self.dataSource.count {
                return JXPhotoBrowserImageCell.self
            }
            return MoreCell.self
        }
        browser.reloadCellAtIndex = { context in
            if context.index < self.dataSource.count {
                let browserCell = context.cell as? JXPhotoBrowserImageCell
                let indexPath = IndexPath(item: context.index, section: indexPath.section)
                browserCell?.imageView.image = self.dataSource[indexPath.item].localName.flatMap { UIImage(named: $0) }
            }
        }
        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
            if index < self.dataSource.count {
                let path = IndexPath(item: index, section: indexPath.section)
                let cell = collectionView.cellForItem(at: path) as? BaseCollectionViewCell
                return cell?.imageView
            }
            return nil
        })
        browser.pageIndex = indexPath.item
        browser.show()
    }
}
