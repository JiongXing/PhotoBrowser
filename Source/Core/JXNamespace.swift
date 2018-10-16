//
//  JXNamespace.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation

/// 类型协议
public protocol JXTypeWrapperProtocol {
    associatedtype WrappedType
    var wrappedValue: WrappedType { get }
    init(value: WrappedType)
}

public struct JXNamespaceWrapper<T>: JXTypeWrapperProtocol {
    public let wrappedValue: T
    public init(value: T) {
        self.wrappedValue = value
    }
}

/// 命名空间协议
public protocol JXNamespaceWrappable {
    associatedtype WrapperType
    var jx: WrapperType { get }
    static var jx: WrapperType.Type { get }
}

extension JXNamespaceWrappable {
    public var jx: JXNamespaceWrapper<Self> {
        return JXNamespaceWrapper(value: self)
    }
    
    public static var jx: JXNamespaceWrapper<Self>.Type {
        return JXNamespaceWrapper.self
    }
}
