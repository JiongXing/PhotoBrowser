//
//  MediaSource.swift
//  Demo
//
//  Created by jxing on 2025/10/24.
//

import Foundation

enum MediaSource {
    case localImage(name: String)
    case remoteImage(url: URL)
    case localVideo(fileName: String, fileExtension: String)
    case remoteVideo(url: URL)
}

struct Media {
    let id = UUID()
    let source: MediaSource
}
