//
//  DataSourceDeleteViewController.swift
//  Example
//
//  Created by JiongXing on 2019/11/28.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class DataSourceDeleteViewController: BaseCollectionViewController {

    override var name: String { "删除图片" }
    
    override var remark: String { "浏览过程中删除图片，变更数据源，刷新UI" }
    
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
            self.dataSource.count
        }
        browser.reloadCell = { cell, index in
            guard let browserCell = cell as? JXPhotoBrowserImageCell else {
                return
            }
            let indexPath = IndexPath(item: index, section: indexPath.section)
            browserCell.imageView.image = self.dataSource[indexPath.item].localName.flatMap { UIImage(named: $0) }
            browserCell.index = index
            // 添加长按事件
            browserCell.longPressedAction = { cell, _ in
                self.longPress(cell: cell)
            }
        }
        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
            let path = IndexPath(item: index, section: indexPath.section)
            let cell = collectionView.cellForItem(at: path) as? BaseCollectionViewCell
            return cell?.imageView
        })
        browser.pageIndex = indexPath.item
        browser.show()
    }
    
    private func longPress(cell: JXPhotoBrowserImageCell) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "删除", style: .destructive, handler: { _ in
            self.dataSource.remove(at: cell.index)
            self.collectionView.reloadData()
            cell.photoBrowser?.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        cell.photoBrowser?.present(alert, animated: true, completion: nil)
    }
}

