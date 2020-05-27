//
//  VerticalBrowseViewController.swift
//  Example
//
//  Created by JiongXing on 2019/12/13.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser
import AVKit

class VerticalBrowseViewController: BaseCollectionViewController {
    
    override class func name() -> String { "竖向浏览视频" }
    override class func remark() -> String {  "抖音的浏览方式" }

    override func makeDataSource() -> [ResourceModel] {
        var result: [ResourceModel] = []
        (0..<6).forEach { index in
            let model = ResourceModel()
            model.localName = "video_\(index % 3)"
            result.append(model)
        }
        return result
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        cell.backgroundColor = .red
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        let browser = JXPhotoBrowser()
        // 指定滑动方向为垂直
        browser.scrollDirection = .vertical
        browser.numberOfItems = {
            self.dataSource.count
        }
        browser.cellClassAtIndex = { index in
            VideoCell.self
        }
        browser.reloadCellAtIndex = { context in
            JXPhotoBrowserLog.high("reload cell!")
            let resourceName = self.dataSource[context.index].localName!
            let browserCell = context.cell as? VideoCell
            if let url = Bundle.main.url(forResource: resourceName, withExtension: "MP4") {
                browserCell?.player.replaceCurrentItem(with: AVPlayerItem(url: url))
            }
        }
        browser.cellWillAppear = { cell, index in
            JXPhotoBrowserLog.high("开始播放")
            (cell as? VideoCell)?.player.play()
        }
        browser.cellWillDisappear = { cell, index in
            JXPhotoBrowserLog.high("暂停播放")
            (cell as? VideoCell)?.player.pause()
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
