//
//  WebPSerializer.swift
//  Pods
//
//  Created by yeatse on 2016/10/20.
//
//

import Kingfisher

public struct WebPSerializer: CacheSerializer {

    public static let `default` = WebPSerializer()
    private init() {}

    public func data(with image: Image, original: Data?) -> Data? {
        if let original = original, !original.isWebPFormat {
            return DefaultCacheSerializer.default.data(with: image, original: original)
        } else {
            return image.kf.normalized.kf.webpRepresentation()
        }
    }

    public func image(with data: Data, options: KingfisherOptionsInfo?) -> Image? {
        return WebPProcessor.default.process(item: .data(data), options: options ?? [])
    }
}
