//
//  DemoMedia.swift
//  Demo
//
//  Created by jxing on 2025/10/28.
//

import Foundation

struct DemoMedia {
    let id = UUID()
    let source: SourceType

    enum SourceType {
        case remoteImage(imageURL: URL, thumbnailURL: URL?)
        case remoteVideo(url: URL, thumbnailURL: URL)
    }
}
