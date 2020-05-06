//
//  JXPhotoBrowserLog.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/12.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import Foundation

public struct JXPhotoBrowserLog {
    
    /// 日志重要程度等级
    public enum Level: Int {
        case low = 0
        case middle
        case high
        case forbidden
    }
    
    /// 允许输出日志的最低等级。`forbidden`为禁止所有日志
    public static var level: Level = .forbidden
    
    public static func low(_ item: @autoclosure () -> Any) {
        if level.rawValue <= Level.low.rawValue {
            print("[JXPhotoBrowser] [low]", item())
        }
    }
    
    public static func middle(_ item: @autoclosure () -> Any) {
        if level.rawValue <= Level.middle.rawValue {
            print("[JXPhotoBrowser] [middle]", item())
        }
    }
    
    public static func high(_ item: @autoclosure () -> Any) {
        if level.rawValue <= Level.high.rawValue {
            print("[JXPhotoBrowser] [high]", item())
        }
    }
}
