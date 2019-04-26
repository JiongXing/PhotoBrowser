//
//  LayoutUtil.swift
//  JXPhotoBrowser
//
//  Created by ronny on 2019/4/26.
//

import UIKit

class LayoutUtil: NSObject {
    public static var isRTLLayout: Bool {
        guard let language = Bundle.main.preferredLocalizations.first else { return false } // en
        if language.hasPrefix("ar") || language.hasPrefix("he") {
            return true
        }
        return false
    }
}
