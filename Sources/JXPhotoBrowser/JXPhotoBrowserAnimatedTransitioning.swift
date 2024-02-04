//
//  JXPhotoBrowserAnimatedTransitioning.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/25.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

public protocol JXPhotoBrowserAnimatedTransitioning: UIViewControllerAnimatedTransitioning {
    var isForShow: Bool { get set }
    var photoBrowser: JXPhotoBrowser? { get set }
    var isNavigationAnimation: Bool { get set }
}

private var isForShowKey: Void?
private var photoBrowserKey: Void?

extension JXPhotoBrowserAnimatedTransitioning {
    
    public var isForShow: Bool {
        get {
            if let value = objc_getAssociatedObject(self, &isForShowKey) as? Bool {
                return value
            }
            return true
        }
        set {
            objc_setAssociatedObject(self, &isForShowKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    public weak var photoBrowser: JXPhotoBrowser? {
        get {
            return objc_getAssociatedObject(self, &photoBrowserKey) as? JXPhotoBrowser
        }
        set {
            objc_setAssociatedObject(self, &photoBrowserKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    public var isNavigationAnimation: Bool {
        get { return false }
        set { }
    }
    
    public func snapshot(with view: UIView) -> UIView? {
        let snapshot = view.snapshotView(afterScreenUpdates: true)
        return snapshot
    }
}
