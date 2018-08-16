//
//  PopupViewController.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2018/8/14.
//  Copyright © 2018 JiongXing. All rights reserved.
//

import Foundation
import JXPhotoBrowser
import Kingfisher

final class PopupViewController: BaseCollectionViewController {
    
    override var name: String {
        return "测试打开新页面"
    }
    
    override func makeDataSource() -> [PhotoModel] {
        return [PhotoModel(thumbnailUrl: "http://wx3.sinaimg.cn/thumbnail/bfc243a3gy1febm7nzbz7j20ib0iek5j.jpg",
                           highQualityUrl: "http://wx3.sinaimg.cn/large/bfc243a3gy1febm7nzbz7j20ib0iek5j.jpg",
                           rawUrl: nil, localName: nil)
        ]
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reusedId, for: indexPath) as! BaseCollectionViewCell
        if let urlString = dataSource[indexPath.item].thumbnailUrl {
            cell.imageView.kf.setImage(with: URL(string: urlString))
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        // 创建图片浏览器
        let browser = PhotoBrowser(animationType: .scale, delegate: self, originPageIndex: indexPath.item)
        // 光点型页码指示器
        browser.plugins = [DefaultPageControlPlugin()]
        // 显示
        browser.show(from: self)
    }
}

extension PopupViewController: PhotoBrowserDelegate {
    /// 图片总数量
    func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int {
        return dataSource.count
    }
    
    /// 缩略图所在 view
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView? {
        return collectionView?.cellForItem(at: IndexPath(item: index, section: 0))
    }
    
    /// 缩略图图片，在加载完成之前用作 placeholder 显示
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage? {
        let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? BaseCollectionViewCell
        return cell?.imageView.image
    }
    
    /// 高清图
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlForIndex index: Int) -> URL? {
        return dataSource[index].highQualityUrl.flatMap {
            URL(string: $0)
        }
    }
    
    /// 长按图片。你可以在此处得到当前图片，并可以做弹窗，保存图片等操作
    func photoBrowser(_ photoBrowser: PhotoBrowser, didLongPressForIndex index: Int, image: UIImage, gesture: UILongPressGestureRecognizer) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let saveImageAction = UIAlertAction(title: "图片信息", style: .default) { (_) in
            let vc = PopupNewViewController()
            let nav = UINavigationController(rootViewController: vc)
            photoBrowser.present(nav, animated: true, completion: nil)
        }
        actionSheet.addAction(saveImageAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        photoBrowser.present(actionSheet, animated: true, completion: nil)
    }
}

extension PopupViewController {
    class PopupNewViewController: UIViewController {
        override func viewDidLoad() {
            super.viewDidLoad()
            title = "新页面"
            view.backgroundColor = .white
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(onCloseButton))
        }
        
        @objc private func onCloseButton() {
            dismiss(animated: true, completion: nil)
        }
    }
}
