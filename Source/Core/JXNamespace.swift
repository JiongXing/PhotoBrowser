//
//  JXNamespace.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation

/// 类型协议
public protocol JXTypeWrapperProtocol {
    associatedtype JXWrappedType
    var jxWrappedValue: JXWrappedType { get }
    init(value: JXWrappedType)
}

public struct JXNamespaceWrapper<T>: JXTypeWrapperProtocol {
    public let jxWrappedValue: T
    public init(value: T) {
        self.jxWrappedValue = value
    }
}

/// 命名空间协议
public protocol JXNamespaceWrappable {
    associatedtype JXWrappedType
    var jx: JXWrappedType { get }
    static var jx: JXWrappedType.Type { get }
}

extension JXNamespaceWrappable {
    public var jx: JXNamespaceWrapper<Self> {
        return JXNamespaceWrapper(value: self)
    }
    
    public static var jx: JXNamespaceWrapper<Self>.Type {
        return JXNamespaceWrapper.self
    }
}
