//
//  DemoMedia.swift
//  Demo
//
//  媒体资源数据模型
//

import Foundation

struct DemoMedia: Identifiable {
    let id = UUID()
    let source: SourceType
    
    enum SourceType {
        case remoteImage(imageURL: URL, thumbnailURL: URL?)
        case remoteVideo(url: URL, thumbnailURL: URL)
    }
    
    /// 缩略图 URL（用于网格展示）
    var thumbnailURL: URL? {
        switch source {
        case let .remoteImage(_, thumbnailURL):
            return thumbnailURL
        case let .remoteVideo(_, thumbnailURL):
            return thumbnailURL
        }
    }
    
    /// 全尺寸图片 URL（用于浏览器展示）
    var fullImageURL: URL? {
        switch source {
        case let .remoteImage(imageURL, _):
            return imageURL
        case let .remoteVideo(_, thumbnailURL):
            // 视频资源在浏览器中暂时展示封面图
            return thumbnailURL
        }
    }
    
    /// 是否为视频资源
    var isVideo: Bool {
        if case .remoteVideo = source { return true }
        return false
    }
    
    /// 构建示例数据源
    static func makeSampleItems() -> [DemoMedia] {
        let base = URL(string: "https://raw.githubusercontent.com/JiongXing/PhotoBrowser/master/Medias")!
        
        // 9 张图片
        let photos = (0..<9).map { i -> DemoMedia in
            let original = base.appendingPathComponent("photo_\(i).png")
            let thumbnail = base.appendingPathComponent("photo_\(i)_thumbnail.png")
            return DemoMedia(source: .remoteImage(imageURL: original, thumbnailURL: thumbnail))
        }
        
        // 3 个视频
        let videos = (0..<3).map { i -> DemoMedia in
            let videoURL = base.appendingPathComponent("video_\(i).mp4")
            let thumbnailURL = base.appendingPathComponent("video_thumbnail_\(i).png")
            return DemoMedia(source: .remoteVideo(url: videoURL, thumbnailURL: thumbnailURL))
        }
        
        return photos + videos
    }
}
