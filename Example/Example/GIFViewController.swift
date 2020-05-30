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

class CustomGifBrowserCell: JXPhotoBrowserImageCell {
  required init(frame: CGRect) {
    super.init(frame: frame)
    self.imageView = {
      // MARK: 使用 Kingfisher.AnimatedImageView 解决内存暴涨问题(使用离屏渲染)
      let imgView = Kingfisher.AnimatedImageView(frame: .zero)
      imgView.clipsToBounds = true
      return imgView
    }()
  }
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  //Cannot override with a stored property 'imageView'
  //override var imageView: UIImageView = { UIImageView() }()
}

class GIFViewController: BaseCollectionViewController {
    
    override class func name() -> String { return "加载GIF图片" }
    override class func remark() -> String { "举例如何用加载GIF网络图片" }
     
    override func makeDataSource() -> [ResourceModel] {
        let models = makeNetworkDataSource()
        models[3].secondLevelUrl = "https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/gifImage.gif"
        models[4].secondLevelUrl = "https://gss3.bdstatic.com/7Po3dSag_xI4khGkpoWK1HF6hhy/baike/s%3D500/sign=51eb2484a1af2eddd0f149e9bd120102/48540923dd54564eb5babebbbede9c82d0584f50.jpg"
      models[5].secondLevelUrl = "https://user-gold-cdn.xitu.io/2020/5/29/1725f6a096b8d88f?w=1230&h=620&f=gif&s=1220183"
      models[6].secondLevelUrl = "https://user-gold-cdn.xitu.io/2020/5/29/1725f6cffc46f046?w=1918&h=91&f=png&s=28117"
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
        browser.numberOfItems = {
            self.dataSource.count
        }
        browser.cellClassAtIndex = { _ in CustomGifBrowserCell.self }
        browser.reloadCellAtIndex = { context in
            let url = self.dataSource[context.index].secondLevelUrl.flatMap { URL(string: $0) }
            let browserCell = context.cell as? JXPhotoBrowserImageCell
            let collectionPath = IndexPath(item: context.index, section: indexPath.section)
            let collectionCell = collectionView.cellForItem(at: collectionPath) as? BaseCollectionViewCell
            let placeholder = collectionCell?.imageView.image
            // 用SDWebImage加载 // 加载大图内存暴涨
            /*browserCell?.imageView.sd_setImage(with: url, placeholderImage: placeholder, options: [], completed: { (_, _, _, _) in
                browserCell?.setNeedsLayout()
            })*/
            // Kingfisher
            browserCell?.imageView.kf.setImage(with: url, placeholder: placeholder, options: [], completionHandler: { _ in
                browserCell?.setNeedsLayout()
            })
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
