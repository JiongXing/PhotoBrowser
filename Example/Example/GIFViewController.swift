//
//  GIFViewController.swift
//  Example
//
//  Created by JiongXing on 2019/11/29.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser
import SDWebImage
import Kingfisher

class GIFViewController: BaseCollectionViewController {
    
    override class func name() -> String { return "加载GIF图片" }
    override class func remark() -> String { "举例如何用SDWebImage加载GIF网络图片(第5张)" }
     
    override func makeDataSource() -> [ResourceModel] {
        let models = makeNetworkDataSource()
        models[3].secondLevelUrl = "https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/gifImage.gif"
        models[4].secondLevelUrl = "https://gss3.bdstatic.com/7Po3dSag_xI4khGkpoWK1HF6hhy/baike/s%3D500/sign=51eb2484a1af2eddd0f149e9bd120102/48540923dd54564eb5babebbbede9c82d0584f50.jpg"
        return models
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        if let firstLevel = self.dataSource[indexPath.item].firstLevelUrl {
            let url = URL(string: firstLevel)
            cell.imageView.sd_setImage(with: url, completed: nil)
            //cell.imageView.kf.setImage(with: url)
        }
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        let browser = JXPhotoBrowser()
        /* 系统UIImageView直接加载GIF内存开销大，最好自定义
        browser.cellClassAtIndex = { index in
            return 你自定义的Cell，其中最好使用对GIF优化的ImageView
        }*/
        browser.numberOfItems = {
            self.dataSource.count
        }
        browser.reloadCellAtIndex = { context in
            let url = self.dataSource[context.index].secondLevelUrl.flatMap { URL(string: $0) }
            let browserCell = context.cell as? JXPhotoBrowserImageCell
            let collectionPath = IndexPath(item: context.index, section: indexPath.section)
            let collectionCell = collectionView.cellForItem(at: collectionPath) as? BaseCollectionViewCell
            let placeholder = collectionCell?.imageView.image
            // 用SDWebImage加载
            browserCell?.imageView.sd_setImage(with: url, placeholderImage: placeholder, options: [], completed: { (_, _, _, _) in
                browserCell?.setNeedsLayout()
            })
            // Kingfisher
            /*browserCell?.imageView.kf.setImage(with: url, placeholder: placeholder, options: [], completionHandler: { _ in
                browserCell?.setNeedsLayout()
            })*/
        }
        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
            let path = IndexPath(item: index, section: indexPath.section)
            let cell = collectionView.cellForItem(at: path) as? BaseCollectionViewCell
            return cell?.imageView
        })
        browser.pageIndex = indexPath.item
        browser.show()
    }
}
