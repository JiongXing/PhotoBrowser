//
//  DefaultPageIndicatorViewController.swift
//  Example
//
//  Created by JiongXing on 2019/12/16.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser
import SDWebImage

class DefaultPageIndicatorViewController: BaseCollectionViewController {

    override class func name() -> String { "UIPageControl样式的页码指示器" }
    override class func remark() -> String { "举例如何使用UIPageControl样式的页码指示器" }

    override func makeDataSource() -> [ResourceModel] {
        makeNetworkDataSource()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        if let firstLevel = self.dataSource[indexPath.item].firstLevelUrl {
            let url = URL(string: firstLevel)
            cell.imageView.sd_setImage(with: url, completed: nil)
        }
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        let browser = JXPhotoBrowser()
        browser.numberOfItems = {
            self.dataSource.count
        }
        browser.reloadCellAtIndex = { context in
            let url = self.dataSource[context.index].secondLevelUrl.flatMap { URL(string: $0) }
            let browserCell = context.cell as? JXPhotoBrowserImageCell
            browserCell?.index = context.index
            let collectionPath = IndexPath(item: context.index, section: indexPath.section)
            let collectionCell = collectionView.cellForItem(at: collectionPath) as? BaseCollectionViewCell
            let placeholder = collectionCell?.imageView.image
            browserCell?.imageView.sd_setImage(with: url, placeholderImage: placeholder, options: [], completed: { (_, _, _, _) in
                browserCell?.setNeedsLayout()
            })
        }
        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
            let path = IndexPath(item: index, section: indexPath.section)
            let cell = collectionView.cellForItem(at: path) as? BaseCollectionViewCell
            return cell?.imageView
        })
        // UIPageIndicator样式的页码指示器
        browser.pageIndicator = JXPhotoBrowserDefaultPageIndicator()
        browser.pageIndex = indexPath.item
        browser.show()
    }
}
