//
//  JXPhotoBrowserDataSource.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit

/// 数据源
public protocol JXPhotoBrowserDataSource: UICollectionViewDataSource {
    
    /// 实现者应弱引用 PhotoBrowser，由 PhotoBrowser 初始化完毕后注入
    var browser: JXPhotoBrowser? { set get }
    
    /// 注册Cell
    func registerCell(for collectionView: UICollectionView)
}
