//
//  LocalImageVerticalViewController.swift
//  Example
//
//  Created by JiongXing on 2019/11/28.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class LocalImageVerticalViewController: BaseCollectionViewController {
    
    override var name: String { "竖向浏览" }
    
    override var remark: String { "支持竖向的滑动" }
    
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
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        let browser = JXPhotoBrowser()
        // 指定滑动方向为垂直
        browser.scrollDirection = .vertical
        browser.numberOfItems = {
            self.dataSource.count
        }
        browser.reloadCell = { cell, index in
            if let cell = cell as? JXPhotoBrowserImageCell {
                cell.imageView.image = UIImage(named: "local_\(index)")
            }
        }
        browser.pageIndex = indexPath.item
        browser.show()
    }
}
