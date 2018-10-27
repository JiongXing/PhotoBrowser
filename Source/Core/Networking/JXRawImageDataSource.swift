//
//  JXRawImageDataSource.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit

public class JXRawImageDataSource<T: JXPhotoBrowserRawButtonCell>: NSObject, JXPhotoBrowserDataSource {

    /// 弱引用 PhotoBrowser
    public weak var browser: JXPhotoBrowser?
    
    /// 共有多少项
    public var numberOfItemsCallback: () -> Int
    
    /// Cell重用时回调
    public var reuseCallback: ((T, Int) -> Void)?
    
    /// 每一项的图片对象
    public var localImageCallback: (Int) -> UIImage?
    
    /// 图片加载器
    public var photoLoader: JXPhotoLoader
    
    /// 获取自动加载用的网络图片地址
    public var autoloadURLStringCallback: (Int) -> String?
    
    /// 获取原图的地址
    public var rawURLStringCallback: (Int) -> String?
    
    /// 初始化
    public init(photoLoader: JXPhotoLoader,
                numberOfItems: @escaping () -> Int,
                placeholder: @escaping (Int) -> UIImage?,
                autoloadURLString: @escaping (Int) -> String?,
                rawURLString: @escaping (Int) -> String?) {
        self.photoLoader = photoLoader
        self.numberOfItemsCallback = numberOfItems
        self.localImageCallback = placeholder
        self.autoloadURLStringCallback = autoloadURLString
        self.rawURLStringCallback = rawURLString
    }
    
    /// 配置重用Cell，回调(Cell, Index)
    public func configReusableCell(reuse: ((_ cell: T, _ index: Int) -> Void)?) {
        reuseCallback = reuse
    }
    
    /// 注册Cell
    public func registerCell(for collectionView: UICollectionView) {
        collectionView.jx.registerCell(T.self)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItemsCallback()
    }
    
    /// Cell复用
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(T.self, for: indexPath)
        // 一级资源
        let placeholder = localImageCallback(indexPath.item)
        // 二级资源
        let autoloadURLString = autoloadURLStringCallback(indexPath.item)
        // 三级资源
        let rawURLString = rawURLStringCallback(indexPath.item)
        // 刷新数据
        cell.reloadData(photoLoader: photoLoader, placeholder: placeholder, autoloadURLString: autoloadURLString, rawURLString: rawURLString)
        reuseCallback?(cell, indexPath.item)
        return cell
    }
}
