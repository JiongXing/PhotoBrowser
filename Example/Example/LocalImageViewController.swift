//
//  LocalImageViewController.swift
//  JXPhotoBrwoser_Example
//
//  Created by JiongXing on 2018/10/14.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class LocalImageViewController: BaseCollectionViewController {
    
    override var name: String { "本地图片" }
    
    override var remark: String { "最简单的场景" }
    
    override func makeDataSource() -> [ResourceModel] {
        var result: [ResourceModel] = []
        (0..<7).forEach { index in
            let model = ResourceModel()
            model.localName = "local_\(index)"
            result.append(model)
        }
        return result
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        cell.imageView.image = self.dataSource[indexPath.item].localName.flatMap({ name -> UIImage? in
            return UIImage(named: name)
        })
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        let browser = JXPhotoBrowser()
        browser.createCell = { photoBrowser in
            let cell = JXPhotoBrowserImageCell()
            cell.photoBrowser = photoBrowser
            return cell
        }
        browser.numberOfItems = { [weak self] in
            self?.dataSource.count ?? 0
        }
        browser.reloadItem = { cell, index in
            guard let cell = cell as? JXPhotoBrowserImageCell else { return }
            cell.index = index
            cell.imageView.image = UIImage(named: "local_\(index)")
        }
        browser.pageIndex = indexPath.item
        browser.show(method: .present(fromVC: nil, embed: nil))
    }
}
