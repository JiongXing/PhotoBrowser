//
//  CustomCellViewController.swift
//  JXPhotoBrowser_Example
//
//  Created by JiongXing on 2018/10/27.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import JXPhotoBrowser

class CustomCellViewController: BaseCollectionViewController {
    override var name: String {
        return "自定义Cell"
    }
    
    weak var browser: JXPhotoBrowser?
    
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
            model.remark = item[2]
            result.append(model)
        }
        result[0].thirdLevelUrl = "http://seopic.699pic.com/photo/00040/8565.jpg_wh1200.jpg"
        return result
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        // 加载一级资源
        if let firstLevel = self.modelArray[indexPath.item].firstLevelUrl {
            let url = URL(string: firstLevel)
            cell.imageView.kf.setImage(with: url)
        } else {
            cell.imageView.kf.setImage(with: nil)
        }
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        // 网图加载器
        let loader = JXKingfisherLoader()
        // 数据源，通过泛型指定使用的<Cell>
        let dataSource = JXNetworkingDataSource<CustomCell>(photoLoader: loader, numberOfItems: { () -> Int in
            return self.modelArray.count
        }, placeholder: { index -> UIImage? in
            let cell = collectionView.cellForItem(at: indexPath) as? BaseCollectionViewCell
            return cell?.imageView.image
        }) { index -> String? in
            return self.modelArray[index].secondLevelUrl
        }
        // Cell复用回调
        dataSource.configReusableCell { [weak self] (cell, index) in
            cell.remarkLabel.text = self?.modelArray[index].remark
            // 删除
            cell.clickDeleteCallback = { _ in
                print("移除第\(index)项")
                self?.modelArray.remove(at: index)
                self?.browser?.reloadData()
            }
        }
        // 自定义视图代理
        let delegate = CustomDelegate()
        // 上一张
        delegate.clickBackCallback = { [weak self] _ in
            if let browser = self?.browser {
                browser.scrollToItem(browser.pageIndex - 1, at: .centeredHorizontally, animated: true)
            }
        }
        // 下一张
        delegate.clickForwardCallback = { [weak self] _ in
            if let browser = self?.browser {
                browser.scrollToItem(browser.pageIndex + 1, at: .centeredHorizontally, animated: true)
            }
        }
        // 转场动画
        let trans = JXPhotoBrowserZoomTransitioning { (browser, index, view) -> UIView? in
            let indexPath = IndexPath(item: index, section: 0)
            return collectionView.cellForItem(at: indexPath)
        }
        // 浏览器
        let browser = JXPhotoBrowser(dataSource: dataSource, delegate: delegate, transDelegate: trans)
        self.browser = browser
        // 打开
        browser.show(pageIndex: indexPath.item)
    }
}
