//
//  JXNetworkingDataSource.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit

public class JXNetworkingDataSource: NSObject, JXPhotoBrowserDataSource {
    
    /// 弱引用 PhotoBrowser
    public weak var browser: JXPhotoBrowser?
    
    /// 图片加载器
    public var photoLoader: JXPhotoLoader
    
    /// 共有多少项
    public var numberOfItemsCallback: () -> Int
    
    /// 一级资源，本地图片
    public var placeholderCallback: (Int) -> UIImage?
    
    /// 二级资源，自动加载的网络图片
    public var autoloadURLStringCallback: (Int) -> String?
    
    public init(photoLoader: JXPhotoLoader,
                numberOfItems: @escaping () -> Int,
                placeholder: @escaping (Int) -> UIImage?,
                autoloadURLString: @escaping (Int) -> String?) {
        self.photoLoader = photoLoader
        self.numberOfItemsCallback = numberOfItems
        self.placeholderCallback = placeholder
        self.autoloadURLStringCallback = autoloadURLString
    }
    
    //
    // MARK: - UICollectionViewDataSource
    //
    
    public func registerCell(for collectionView: UICollectionView) {
        collectionView.jx.registerCell(JXPhotoBrowserNetworkingCell.self)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItemsCallback()
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(JXPhotoBrowserNetworkingCell.self, for: indexPath)
        // 一级资源
        let localImage = placeholderCallback(indexPath.item)
        // 二级资源
        let autoloadURLString = autoloadURLStringCallback(indexPath.item)
        // 刷新数据
        cell.reloadData(photoLoader: photoLoader, localImage: localImage, autoloadURLString: autoloadURLString)
        return cell
    }
}
