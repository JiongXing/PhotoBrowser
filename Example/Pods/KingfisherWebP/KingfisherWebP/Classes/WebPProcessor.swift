//
//  WebPProcessor.swift
//  Pods
//
//  Created by yeatse on 2016/10/19.
//
//

import Foundation
import Kingfisher

public struct WebPProcessor: ImageProcessor {
    public static let `default` = WebPProcessor()

    public let identifier = "com.yeatse.WebPProcessor"

    public init() {}

    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            if data.isWebPFormat {
                return Kingfisher<Image>.image(webpData: data, scale: options.scaleFactor, onlyFirstFrame: options.onlyLoadFirstFrame)
            } else {
                return DefaultImageProcessor.default.process(item: item, options: options)
            }
        }
    }
}

