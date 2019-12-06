//
//  UICollectionView+JX.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import UIKit

extension UICollectionView: JXNamespaceWrappable {}

extension JXTypeWrapperProtocol where JXWrappedType == UICollectionView {
    
    /// 注册Cell
    public func registerCell<T: UICollectionViewCell>(_ type: T.Type) {
        let identifier = String(describing: type.self)
        jxWrappedValue.register(type, forCellWithReuseIdentifier: identifier)
    }
    
    /// 取重用Cell
    public func dequeueReusableCell<T: UICollectionViewCell>(_ type: T.Type, for indexPath: IndexPath) -> T {
        let identifier = String(describing: type.self)
        guard let cell = jxWrappedValue.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? T else {
            fatalError("\(type.self) was not registered")
        }
        return cell
    }
}
