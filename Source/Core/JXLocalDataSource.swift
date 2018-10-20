//
//  JXLocalDataSource.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit

public class JXLocalDataSource: NSObject, JXPhotoBrowserDataSource {
    
    /// 弱引用 PhotoBrowser
    public weak var browser: JXPhotoBrowser?
    
    /// 共有多少项
    public var numberOfItemsCallback: () -> Int
    
    /// 每一项的图片对象
    public var localImageCallback: (Int) -> UIImage?
    
    public init(numberOfItems: @escaping () -> Int,
                localImage: @escaping (Int) -> UIImage?) {
        self.numberOfItemsCallback = numberOfItems
        self.localImageCallback = localImage
    }
    
    public func registerCell(for collectionView: UICollectionView) {
        collectionView.jx.registerCell(JXPhotoBrowserBaseCell.self)
    }
    
    //
    // MARK: - UICollectionViewDataSource
    //
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItemsCallback()
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(JXPhotoBrowserBaseCell.self, for: indexPath)
        cell.imageView.image = localImageCallback(indexPath.item)
        cell.setNeedsLayout()
        return cell
    }
}
