//
//  LongPressedViewController.swift
//  JXPhotoBrowser_Example
//
//  Created by JiongXing on 2018/10/14.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class LongPressedViewController: LocalImageViewController {
    
    override var name: String {
        return "设置长按事件"
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        // 数据源
        let dataSource = JXPhotoBrowser.LocalDataSource(numberOfItems: {
            // 共有多少项
            return self.dataSource.count
        }, localImage: { index -> UIImage? in
            // 每一项的图片对象
            return self.dataSource[index].localName.flatMap({ name -> UIImage? in
                return UIImage(named: name)
            })
        })
        // 视图代理
        let delegate = JXPhotoBrowser.BaseDelegate()
        // 长按事件
        delegate.longPressedCallback = { index, image, gesture in
            self.longPressed(image: image, gesture: gesture)
        }
        // 打开浏览器
        JXPhotoBrowser(dataSource: dataSource, delegate: delegate).show(pageIndex: indexPath.item)
    }
    
    private func longPressed(image: UIImage?, gesture: UILongPressGestureRecognizer) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let saveImageAction = UIAlertAction(title: "图片信息", style: .default) { (_) in
            // 图片信息
            print("图片：\(String(describing: image))\n长按手势：\(gesture)")
        }
        actionSheet.addAction(saveImageAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        UIViewController.jx.topMost?.present(actionSheet, animated: true, completion: nil)
    }
}
