//
//  JXVideoCell.swift
//  JXPhotoBrowser
//

import UIKit
import AVFoundation

open class JXVideoCell: JXPhotoCell {
    
    // MARK: - Static Properties
    
    public static let videoReuseIdentifier = "JXVideoCell"
    
    // MARK: - Video Properties
    
    /// 视频播放器
    private var player: AVPlayer?
    
    /// 视频播放图层
    private var playerLayer: AVPlayerLayer?
    
    /// 当前视频 URL
    public private(set) var videoURL: URL?
    
    /// 是否正在播放
    private var isPlaying: Bool = false
    
    // MARK: - Lifecycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        stopVideo()
        videoURL = nil
    }
    
    // MARK: - Public Methods
    
    /// 配置视频资源
    /// - Parameters:
    ///   - videoURL: 视频 URL
    ///   - coverImage: 封面图（可选）
    open func configure(videoURL: URL, coverImage: UIImage? = nil) {
        stopVideo()
        self.videoURL = videoURL
        if let cover = coverImage {
            setImage(cover)
        }
        playVideo()
    }
    
    open override func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        if isPlaying {
            pauseVideo()
        } else {
            browser?.dismissSelf()
        }
    }
}

// 重新实现播放逻辑
extension JXVideoCell {
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        if let playerLayer = playerLayer {
            playerLayer.frame = imageView.bounds
        }
    }
    
    private func playVideo() {
        guard let url = videoURL else { return }
        
        if player == nil {
            let item = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: item)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = imageView.bounds
            imageView.layer.addSublayer(playerLayer!)
            
            NotificationCenter.default.addObserver(self, selector: #selector(videoDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: item)
        }
        
        player?.play()
        isPlaying = true
    }
    
    private func pauseVideo() {
        player?.pause()
        isPlaying = false
    }
    
    private func stopVideo() {
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        isPlaying = false
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc private func videoDidReachEnd() {
        player?.seek(to: .zero)
        player?.play()
    }
}
