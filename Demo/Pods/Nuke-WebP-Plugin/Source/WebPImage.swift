//
//  WebPImage.swift
//  Nuke-WebP-Plugin
//
//  Created by ryokosuge on 2018/01/17.
//  Copyright © 2018年 RyoKosuge. All rights reserved.
//

import Foundation
import Nuke

public class WebPImageDecoder: Nuke.ImageDecoding {

    private lazy var decoder: WebPDataDecoder = WebPDataDecoder()

    public init() {
    }

    public func decode(data: Data, isFinal: Bool) -> Image? {
        guard data.isWebPFormat else { return nil }
        guard !isFinal else { return _decode(data) }

        return decoder.incrementallyDecode(data, isFinal: isFinal)
    }

}

// MARK: - check webp format data.
extension WebPImageDecoder {

    public static func enable() {
        Nuke.ImageDecoderRegistry.shared.register { (context) -> ImageDecoding? in
            WebPImageDecoder.enable(context: context)
        }
    }

    public static func enable(context: Nuke.ImageDecodingContext) -> Nuke.ImageDecoding? {
        return context.data.isWebPFormat ? WebPImageDecoder() : nil
    }

}

// MARK: - private
private let _queue = DispatchQueue(label: "com.github.ryokosuge.Nuke-WebP-Plugin.DataDecoder")
extension WebPImageDecoder {

    internal func _decode(_ data: Data) -> Image? {
        return _queue.sync {
            return decoder.decode(data)
        }
    }

}
