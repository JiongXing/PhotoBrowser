//
//  RawImageViewController.swift
//  Example
//
//  Created by JiongXing on 2019/11/29.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser
import SDWebImage

class RawImageViewController: BaseCollectionViewController {

    override class func name() -> String { "显示查看原图" }
    override class func remark() -> String { "举例如何实现查看原图" }

    override func makeDataSource() -> [ResourceModel] {
        let models = makeNetworkDataSource()
        models[3].thirdLevelUrl = "https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/rawImage.jpg"
        return models
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        if let firstLevel = self.dataSource[indexPath.item].firstLevelUrl {
            let url = URL(string: firstLevel)
            cell.imageView.sd_setImage(with: url, completed: nil)
        }
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        let browser = JXPhotoBrowser()
        browser.numberOfItems = {
            self.dataSource.count
        }
        // 使用自定义的Cell
        browser.cellClassAtIndex = { _ in
            RawImageCell.self
        }
        browser.reloadCellAtIndex = { context in
            let browserCell = context.cell as? RawImageCell
            let collectionPath = IndexPath(item: context.index, section: indexPath.section)
            let collectionCell = collectionView.cellForItem(at: collectionPath) as? BaseCollectionViewCell
            let placeholder = collectionCell?.imageView.image
            let urlString = self.dataSource[context.index].secondLevelUrl
            let rawURLString = self.dataSource[context.index].thirdLevelUrl
            browserCell?.reloadData(placeholder: placeholder, urlString: urlString, rawURLString: rawURLString)
        }
        browser.pageIndex = indexPath.item
        browser.show()
    }
}

/// 加上进度环的Cell
class RawImageCell: JXPhotoBrowserImageCell {
    /// 进度环
    let progressView = JXPhotoBrowserProgressView()
    
    /// 查看原图按钮
    var rawButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.white, for: .highlighted)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.08)
        button.setTitle("查看原图", for: .normal)
        button.setTitle("查看原图", for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1 / UIScreen.main.scale
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        return button
    }()
    
    override func setup() {
        super.setup()
        
        addSubview(progressView)
        
        rawButton.addTarget(self, action: #selector(onRawImageButton), for: .touchUpInside)
        rawButton.isHidden = true
        addSubview(rawButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        progressView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        rawButton.sizeToFit()
        rawButton.bounds.size.width += 14
        rawButton.center = CGPoint(x: bounds.width / 2,
                                   y: bounds.height - 35 - rawButton.bounds.height)
    }
    
    func reloadData(placeholder: UIImage?, urlString: String?, rawURLString: String?) {
        self.rawURLString = rawURLString
        progressView.progress = 0
        rawButton.isHidden = true
        
        let url = urlString.flatMap { URL(string: $0) }
        imageView.sd_setImage(with: url, placeholderImage: placeholder, options: []) { [weak self] (_, error, _, _) in
            if error == nil {
                self?.setNeedsLayout()
            }
            // 原图如果有缓存就加载
            self?.loadRawImageIfCached(placeholder: self?.imageView.image, rawURLString: rawURLString)
        }
    }
    
    /// 尝试加载缓存的原图，completion回调传参：true-已加载缓存，false-没有缓存
    private func loadRawImageIfCached(placeholder: UIImage?, rawURLString: String?) {
        guard let rawString = rawURLString else {
            return
        }
        SDImageCache.shared.containsImage(forKey: rawString, cacheType: .all) { [weak self] cacheType in
            if cacheType == .none {
                self?.rawButton.isHidden = false
                return
            }
            self?.imageView.sd_setImage(with: URL(string: rawString), placeholderImage: placeholder, options: []) { (_, error, _, _) in
                if error == nil {
                    self?.setNeedsLayout()
                }
                self?.rawButton.isHidden = (error == nil)
            }
        }
    }
    
    /// 保存原图url
    private var rawURLString: String?
    
    /// 响应查看原图按钮
    @objc func onRawImageButton(_ button: UIButton) {
        self.rawButton.isHidden = true
        guard let url = rawURLString.flatMap({ URL(string: $0) }) else {
            progressView.isHidden = true
            return
        }
        imageView.sd_setImage(with: url, placeholderImage: imageView.image, options: [], progress: { [weak self] (received, total, _) in
            if total > 0 {
                self?.progressView.progress = CGFloat(received) / CGFloat(total)
            }
        }) { [weak self] (_, error, _, _) in
            if error == nil {
                self?.progressView.progress = 1.0
                self?.setNeedsLayout()
            } else {
                self?.progressView.progress = 0
                self?.rawButton.isHidden = false
            }
        }
    }
}
