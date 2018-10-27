//
//  JXLocalDataSource.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit

open class JXLocalDataSource<T: JXPhotoBrowserBaseCell>: NSObject, JXPhotoBrowserDataSource {
    
    /// 弱引用 PhotoBrowser
    open weak var browser: JXPhotoBrowser?
    
    /// 共有多少项
    open var numberOfItemsCallback: () -> Int
    
    /// Cell重用时回调
    public var reuseCallback: ((T, Int) -> Void)?
    
    /// 每一项的图片对象
    open var localImageCallback: (Int) -> UIImage?
    
    /// 初始化
    public init(numberOfItems: @escaping () -> Int,
                localImage: @escaping (Int) -> UIImage?) {
        self.numberOfItemsCallback = numberOfItems
        self.localImageCallback = localImage
    }
    
    /// 配置重用Cell，回调(Cell, Index)
    public func configReusableCell(reuse: ((_ cell: T, _ index: Int) -> Void)?) {
        reuseCallback = reuse
    }
    
    /// 注册Cell
    public func registerCell(for collectionView: UICollectionView) {
        collectionView.jx.registerCell(T.self)
    }
    
    //
    // MARK: - UICollectionViewDataSource
    //
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItemsCallback()
    }
    
    /// Cell复用
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(T.self, for: indexPath)
        cell.imageView.image = localImageCallback(indexPath.item)
        cell.setNeedsLayout()
        reuseCallback?(cell, indexPath.item)
        return cell
    }
}
