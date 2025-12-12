//
//  JXPhotoBrowserCellRegistry.swift
//  JXPhotoBrowser
//

import UIKit

/// Cell注册管理器：用于管理自定义Cell类的注册和复用标识符
public class JXPhotoBrowserCellRegistry {
    
    /// 单例实例
    public static let shared = JXPhotoBrowserCellRegistry()
    
    /// 存储Cell类与reuseIdentifier的映射关系
    private var cellClassToIdentifier: [String: String] = [:]
    
    /// 存储reuseIdentifier与Cell类的映射关系（用于反查）
    private var identifierToCellClass: [String: AnyClass] = [:]
    
    /// 私有初始化，强制使用单例
    private init() {
        // 注册默认的Cell类
        registerDefaultCells()
    }
    
    /// 注册默认的Cell类（JXPhotoCell 和 JXVideoCell）
    private func registerDefaultCells() {
        register(JXPhotoCell.self, forReuseIdentifier: JXPhotoCell.reuseIdentifier)
        register(JXVideoCell.self, forReuseIdentifier: JXVideoCell.videoReuseIdentifier)
    }
    
    /// 注册自定义Cell类
    /// - Parameters:
    ///   - cellClass: 要注册的Cell类（必须实现JXPhotoBrowserCellProtocol协议）
    ///   - reuseIdentifier: 可选的复用标识符，如果为nil则自动生成
    /// - Returns: 实际使用的reuseIdentifier
    @discardableResult
    public func register(_ cellClass: AnyClass, forReuseIdentifier reuseIdentifier: String? = nil) -> String {
        let className = NSStringFromClass(cellClass)
        
        // 如果提供了reuseIdentifier，使用提供的；否则自动生成
        let identifier = reuseIdentifier ?? generateReuseIdentifier(for: cellClass)
        
        // 存储映射关系
        cellClassToIdentifier[className] = identifier
        identifierToCellClass[identifier] = cellClass
        
        return identifier
    }
    
    /// 根据Cell类获取对应的reuseIdentifier
    /// - Parameter cellClass: Cell类
    /// - Returns: 对应的reuseIdentifier，如果未注册则返回nil
    public func reuseIdentifier(for cellClass: AnyClass?) -> String? {
        guard let cellClass = cellClass else { return nil }
        let className = NSStringFromClass(cellClass)
        return cellClassToIdentifier[className]
    }
    
    /// 根据reuseIdentifier获取对应的Cell类
    /// - Parameter reuseIdentifier: 复用标识符
    /// - Returns: 对应的Cell类，如果未注册则返回nil
    public func cellClass(for reuseIdentifier: String) -> AnyClass? {
        return identifierToCellClass[reuseIdentifier]
    }
    
    /// 检查Cell类是否已注册
    /// - Parameter cellClass: Cell类
    /// - Returns: 是否已注册
    public func isRegistered(_ cellClass: AnyClass) -> Bool {
        let className = NSStringFromClass(cellClass)
        return cellClassToIdentifier[className] != nil
    }
    
    /// 为Cell类自动生成reuseIdentifier
    /// - Parameter cellClass: Cell类
    /// - Returns: 生成的reuseIdentifier
    private func generateReuseIdentifier(for cellClass: AnyClass) -> String {
        let className = NSStringFromClass(cellClass)
        // 使用类名作为reuseIdentifier，确保唯一性
        return "\(className)_Custom"
    }
    
    /// 清除所有注册（保留默认Cell）
    public func clear() {
        cellClassToIdentifier.removeAll()
        identifierToCellClass.removeAll()
        registerDefaultCells()
    }
}
