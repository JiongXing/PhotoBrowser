//
//  LayoutUtil.swift
//  JXPhotoBrowser
//
//  Created by ronny on 2019/4/26.
//

import UIKit

class LayoutUtil: NSObject {
    public static var isRTLLayout: Bool {
        return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    }
}
