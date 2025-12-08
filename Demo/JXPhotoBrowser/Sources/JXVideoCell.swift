//
//  JXVideoCell.swift
//  JXPhotoBrowser
//

import UIKit
import AVFoundation
import Kingfisher

open class JXVideoCell: JXPhotoCell {
    public static let videoReuseIdentifier = "JXVideoCell"
    
    // MARK: - Video Properties
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var videoURL: URL?
    private var isPlaying: Bool = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        // 视频 Cell 特有的初始化逻辑（如果有）
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
        // 视频相关逻辑
        guard let browser = browser, let index = currentIndex else { return }
        
        // 重置状态
        stopVideo()
        
        if let res = browser.delegate?.photoBrowser(browser, resourceForItemAt: index) {
            self.videoURL = res.videoURL
            playButton.isHidden = (res.videoURL == nil)
            
            // 确保 playButton 响应视频播放
            setupVideoActions()
            
            // 封面图处理：
            // 如果 imageURL 与 videoURL 相同，说明没有提供独立封面，需要生成首帧
            // 否则直接加载 imageURL
            if res.imageURL == res.videoURL {
                // 尝试生成首帧（异步）
                // 占位
                imageView.image = nil
                loadVideoThumbnail(from: res.imageURL)
            } else {
                // 复用父类加载逻辑（Kingfisher）
                super.reloadContent()
            }
        }
    }
    
    private func loadVideoThumbnail(from url: URL) {
        // 简单的异步生成首帧
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            
            do {
                let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                DispatchQueue.main.async { [weak self] in
                    // 确保 URL 没变（Cell 复用）
                    guard let self = self, self.videoURL == url else { return }
                    self.imageView.image = image
                    self.adjustImageViewFrame()
                    self.centerImageIfNeeded()
                }
            } catch {
                print("Thumbnail generation failed: \(error)")
            }
        }
    }
    
    open override func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        if isPlaying {
            pauseVideo()
        } else {
            browser?.dismissSelf()
        }
    }
    
    // 覆写父类的播放按钮点击事件（需在父类中将 handlePlayButtonTap 暴露或修改访问控制）
    // 由于父类是 private，我们这里通过添加新的 target 来覆盖或者重写 UI 逻辑
    // 为了简单，我们直接重写 playVideo 等逻辑
    
    // 注意：由于父类中 playVideo 等方法是 private，我们无法直接 override。
    // 我们需要在 JXPhotoCell 中将它们改为 open 或 public，或者在这里重新实现一套。
    // 鉴于用户要求“新增一个单独的视频播放cell”，我们可以将 JXPhotoCell 中的视频逻辑剥离，
    // 或者在 JXVideoCell 中完全重写视频逻辑。
    // 这里选择重写视频逻辑，并让 JXPhotoCell 回归纯图片（或保留兼容）。
    // 但为了代码复用，最好是修改父类。
    // 考虑到工具限制，我将重新实现视频逻辑。
    
    // 实际上，父类 JXPhotoCell 已经包含了视频逻辑。
    // 用户的需求是 "新增一个单独的视频播放cell"，这意味着 JXPhotoCell 应该只负责图片，
    // 而 JXVideoCell 负责视频。
    // 所以我们需要：
    // 1. 将 JXPhotoCell 中的视频逻辑移除（或保留但默认禁用）。
    // 2. 在 JXVideoCell 中实现视频逻辑。
    
    // 为了不破坏现有逻辑，我们可以在 JXVideoCell 中覆盖 reloadContent 并实现自己的播放逻辑。
    // 并且我们需要在 JXPhotoBrowser 中支持注册不同的 Cell 类。
}

// 重新实现播放逻辑
extension JXVideoCell {
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        if let playerLayer = playerLayer {
            playerLayer.frame = imageView.bounds
        }
    }
    
    // 模拟重写 playButton 的点击
    // 我们需要在 init 中移除父类的 target 并添加自己的（如果父类加了的话）
    // 或者简单地，我们在 reloadContent 中配置 playButton
    
    // 让我们假设父类的 handlePlayButtonTap 是 private 的，我们无法 override。
    // 但 playButton 是 public 的。
    
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
