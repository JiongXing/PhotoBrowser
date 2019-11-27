//
//  MoreCellViewController.swift
//  Example
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class MoreCellViewController: BaseCollectionViewController {
    
    override var name: String { "最后一个视图显示更多" }
    
    override var remark: String { "示范如何在最后一个视图结束后追加一个'更多'" }
    
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
        browser.cellClassAtIndex = { _ in
            JXPhotoBrowserImageCell.self
        }
        browser.numberOfItems = { [weak self] in
            self?.dataSource.count ?? 0
        }
        browser.reloadCell = { cell, index in
            guard let cell = cell as? JXPhotoBrowserImageCell else { return }
            cell.index = index
            cell.imageView.image = UIImage(named: "local_\(index)")
        }
        browser.pageIndex = indexPath.item
        browser.show(method: .present(fromVC: nil, embed: nil))
    }
}

