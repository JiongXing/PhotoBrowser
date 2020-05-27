//
//  VideoPhotoViewController.swift
//  Example
//
//  Created by JiongXing on 2019/11/29.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser
import AVKit

class VideoPhotoViewController: BaseCollectionViewController {

    override class func name() -> String { "视频与图片混合浏览" }
    override class func remark() -> String { "微信我的相册浏览方式" }

    override func makeDataSource() -> [ResourceModel] {
        var result: [ResourceModel] = []
        (0..<6).forEach { index in
            let model = ResourceModel()
            model.localName = index % 2 == 0 ? "video_\(index / 2)" : "local_\(index)"
            result.append(model)
        }
        return result
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        if indexPath.item % 2 == 0 {
            cell.imageView.image = nil
            cell.backgroundColor = .red
        } else {
            cell.imageView.image = self.dataSource[indexPath.item].localName.flatMap { UIImage(named: $0) }
            cell.backgroundColor = .clear
        }
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        let browser = JXPhotoBrowser()
        browser.numberOfItems = {
            self.dataSource.count
        }
        browser.cellClassAtIndex = { index in
            index % 2 == 0 ? VideoCell.self : JXPhotoBrowserImageCell.self
        }
        browser.reloadCellAtIndex = { context in
            JXPhotoBrowserLog.high("reload cell!")
            let resourceName = self.dataSource[context.index].localName!
            if context.index % 2 == 0 {
                let browserCell = context.cell as? VideoCell
                if let url = Bundle.main.url(forResource: resourceName, withExtension: "MP4") {
                    browserCell?.player.replaceCurrentItem(with: AVPlayerItem(url: url))
                }
            } else {
                let browserCell = context.cell as? JXPhotoBrowserImageCell
                browserCell?.imageView.image = UIImage(named: resourceName)
            }
        }
        browser.cellWillAppear = { cell, index in
            if index % 2 == 0 {
                JXPhotoBrowserLog.high("开始播放")
                (cell as? VideoCell)?.player.play()
            }
        }
        browser.cellWillDisappear = { cell, index in
            if index % 2 == 0 {
                JXPhotoBrowserLog.high("暂停播放")
                (cell as? VideoCell)?.player.pause()
            }
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
