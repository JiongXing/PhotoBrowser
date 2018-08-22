//
//  PhotoModel.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2018/8/12.
//  Copyright © 2018年 JiongXing. All rights reserved.
//

import Foundation

struct PhotoModel {
    /// 缩略图
    var thumbnailUrl: String?
    /// 高清图
    var highQualityUrl: String?
    /// 原图
    var rawUrl: String?
    /// 本地图片
    var localName: String?
}
