//
//  UITableView+JX.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/20.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

extension UITableView: JXNamespaceWrappable {}

extension JXTypeWrapperProtocol where JXWrappedType == UITableView {
    
    /// 注册Cell
    public func registerCell<T: UITableViewCell>(_ type: T.Type) {
        let identifier = String(describing: type.self)
        jxWrappedValue.register(type, forCellReuseIdentifier: identifier)
    }

    /// 取重用Cell
    public func dequeueReusableCell<T: UITableViewCell>(_ type: T.Type) -> T {
        let identifier = String(describing: type.self)
        guard let cell = jxWrappedValue.dequeueReusableCell(withIdentifier: identifier) as? T else {
            fatalError("\(type.self) was not registered")
        }
        return cell
    }
}
