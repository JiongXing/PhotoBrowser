//
//  DataSourceAppendViewController.swift
//  Example
//
//  Created by JiongXing on 2019/11/29.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class DataSourceAppendViewController: BaseCollectionViewController {

    override class func name() -> String { "无限新增图片" }
    override class func remark() -> String { "浏览过程中不断新增图片，变更数据源，刷新UI" }
    
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
            let browserCell = context.cell as? JXPhotoBrowserImageCell
            let indexPath = IndexPath(item: context.index, section: indexPath.section)
            browserCell?.imageView.image = self.dataSource[indexPath.item].localName.flatMap { UIImage(named: $0) }
        }
        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
            let path = IndexPath(item: index, section: indexPath.section)
            let cell = collectionView.cellForItem(at: path) as? BaseCollectionViewCell
            return cell?.imageView
        })
        // 监听页码变化
        browser.didChangedPageIndex = { index in
            // 已到最后一张
            if index == self.dataSource.count - 1 {
                self.appendMoreData(browser: browser)
            }
        }
        browser.scrollDirection = .vertical
        browser.pageIndex = indexPath.item
        browser.show()
    }
    
    private func appendMoreData(browser: JXPhotoBrowser) {
        var randomIndexes = (0..<6).map { $0 }
        randomIndexes.shuffle()
        randomIndexes.forEach { index in
            let model = ResourceModel()
            model.localName = "local_\(index)"
            dataSource.append(model)
        }
        collectionView.reloadData()
        // TODO: UIScrollView的pageEnable特性原因，不能很好衔接，效果上有点问题，还未解决
        browser.reloadData()
    }
}

