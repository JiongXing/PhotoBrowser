//
//  JXVideoCell.swift
//  JXPhotoBrowser
//

import UIKit
import AVFoundation

open class JXVideoCell: JXPhotoCell {
    public static let videoReuseIdentifier = "JXVideoCell"
    
    // MARK: - Video Properties
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var videoURL: URL?
    private var isPlaying: Bool = false
    
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
    
    open override func reloadContent() {
        stopVideo()
        videoURL = currentResource?.videoURL
        playButton.isHidden = (videoURL == nil)
        if videoURL != nil {
            setupVideoActions()
        }
        super.reloadContent()
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
    
    private func setupVideoActions() {
        // 移除可能的旧 targets
        playButton.gestureRecognizers?.forEach { playButton.removeGestureRecognizer($0) }
        
        let playTap = UITapGestureRecognizer(target: self, action: #selector(handleVideoPlayTap))
        playButton.addGestureRecognizer(playTap)
        playButton.isUserInteractionEnabled = true
    }
    
    @objc private func handleVideoPlayTap() {
        playVideo()
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
        playButton.isHidden = true
        isPlaying = true
    }
    
    private func pauseVideo() {
        player?.pause()
        playButton.isHidden = false
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
