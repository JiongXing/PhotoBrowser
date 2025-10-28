//
//  MediaSource.swift
//  JXPhotoBrowser
//

import Foundation

/// 媒体源类型（图片 / 视频，本地 / 远程）
public enum JXMediaSource {
    case localImage(name: String)
    case remoteImage(url: URL)
    case localVideo(fileName: String, fileExtension: String)
    case remoteVideo(url: URL)
}
