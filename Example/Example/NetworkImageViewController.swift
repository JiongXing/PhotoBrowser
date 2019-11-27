//
//  NetworkImageViewController.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/20.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import SDWebImage
import JXPhotoBrowser

class NetworkImageViewController: BaseCollectionViewController {
    
    override var name: String { "网络图片-两级" }
    
    override var remark: String { "打开时为本地图，然后自动加载高清图" }

    override func makeDataSource() -> [ResourceModel] {
        var result: [ResourceModel] = []
        guard let url = Bundle.main.url(forResource: "Photos", withExtension: "plist") else {
            return result
        }
        guard let data = try? Data.init(contentsOf: url) else {
            return result
        }
        
        let decoder = PropertyListDecoder()
        guard let array = try? decoder.decode([[String]].self, from: data) else {
            return result
        }
        array.forEach { item in
            let model = ResourceModel()
            model.firstLevelUrl = item[0]
            model.secondLevelUrl = item[1]
            result.append(model)
        }
        return result
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        // 加载一级资源
        if let firstLevel = self.dataSource[indexPath.item].firstLevelUrl {
            let url = URL(string: firstLevel)
            cell.imageView.sd_setImage(with: url)
        }
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        let browser = JXPhotoBrowser()
        browser.cellClassAtIndex = { _ in
            JXPhotoBrowserImageCell.self
        }
        browser.numberOfItems = { [weak self] in
            self?.dataSource.count ?? 0
        }
        browser.reloadCell = { [weak self] cell, index in
            guard let cell = cell as? JXPhotoBrowserImageCell else { return }
            guard let model = self?.dataSource[index] else { return }
            guard let urlString = model.secondLevelUrl, let url = URL(string: urlString) else {
                return
            }
            cell.index = index
            let collectionPath = IndexPath(item: index, section: indexPath.section)
            let collectionCell = collectionView.cellForItem(at: collectionPath) as? BaseCollectionViewCell
            let placeholder = collectionCell?.imageView.image
            cell.imageView.sd_setImage(with: url, placeholderImage: placeholder, options: .highPriority) { (_, _, _, _) in
                cell.setNeedsLayout()
            }
        }
        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
            let collectionPath = IndexPath(item: index, section: indexPath.section)
            let cell = collectionView.cellForItem(at: collectionPath) as? BaseCollectionViewCell
            return cell?.imageView
        })
        browser.pageIndex = indexPath.item
        browser.pageIndicator = JXPhotoBrowserNumberPageIndicator()
        browser.show(method: .present(fromVC: nil, embed: nil))
    }

}
