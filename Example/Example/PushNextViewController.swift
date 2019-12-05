//
//  PushNextViewController.swift
//  Example
//
//  Created by JiongXing on 2019/11/29.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class PushNextViewController: BaseCollectionViewController {

    override var name: String { "带导航栏Push" }
    
    override var remark: String { "让PhotoBrowser嵌入导航控制器里，Push到下一页" }
    
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
        browser.reloadCellAtIndex = { context in
            guard let browserCell = context.cell as? JXPhotoBrowserImageCell else {
                return
            }
            let indexPath = IndexPath(item: context.index, section: indexPath.section)
            browserCell.imageView.image = self.dataSource[indexPath.item].localName.flatMap { UIImage(named: $0) }
            // 添加长按事件
            browserCell.longPressedAction = { cell, _ in
                self.longPress(cell: cell)
            }
        }
        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
            JXPhotoBrowserLog.high("获取前视图, index:\(index)")
            let path = IndexPath(item: index, section: indexPath.section)
            let cell = collectionView.cellForItem(at: path) as? BaseCollectionViewCell
            return cell?.imageView
        })
        browser.pageIndex = indexPath.item
        // 让PhotoBrowser嵌入当前的导航控制器里
        browser.show(method: .push(inNC: nil))
    }
    
    private func longPress(cell: JXPhotoBrowserImageCell) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "查看详情", style: .destructive, handler: { _ in
            let detail = MoreDetailViewController()
            cell.photoBrowser?.navigationController?.pushViewController(detail, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        cell.photoBrowser?.present(alert, animated: true, completion: nil)
    }
}
