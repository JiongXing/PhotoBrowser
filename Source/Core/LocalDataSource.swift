//
//  LocalDataSource.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit

extension JXPhotoBrowser {
    public class LocalDataSource: NSObject, JXPhotoBrowserDataSource {
        
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
            collectionView.jx.registerCell(BaseCell.self)
        }
        
        //
        // MARK: - UICollectionViewDataSource
        //
        
        public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return numberOfItemsCallback()
        }
        
        public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.jx.dequeueReusableCell(BaseCell.self, for: indexPath)
            cell.imageView.image = localImageCallback(indexPath.item)
            cell.setNeedsLayout()
            return cell
        }
    }
}
