//
//  DemoVideoCell.swift
//  Demo
//
//  示例视频播放 Cell，展示如何在 Demo 中实现自定义的视频 Cell

import UIKit
import AVFoundation
import JXPhotoBrowser

/// Demo 中的视频展示 Cell
/// 继承自 JXPhotoCell，添加视频播放功能
open class DemoVideoCell: JXPhotoCell {
    
    // MARK: - Static Properties
    
    public static let videoReuseIdentifier = "DemoVideoCell"
    
    // MARK: - Video Properties
    
    /// 视频播放器
    private var player: AVPlayer?
    
    /// 视频播放图层
    private var playerLayer: AVPlayerLayer?
    
    /// 当前视频 URL
    public private(set) var videoURL: URL?
    
    /// 是否正在播放
    private var isPlaying: Bool = false
    
    /// 播放器状态 KVO 观察者
    private var timeControlStatusObservation: NSKeyValueObservation?
    
    /// 播放资源状态 KVO 观察者
    private var itemStatusObservation: NSKeyValueObservation?
    
    /// 是否正在下拉交互中（用于下拉时隐藏 loading）
    private var isDismissInteracting: Bool = false
    
    // MARK: - Loading UI
    
    /// 视频加载指示器
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLoadingIndicator()
        setupAppLifecycleObservers()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLoadingIndicator()
        setupAppLifecycleObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        stopVideo()
        videoURL = nil
        isDismissInteracting = false
    }
    
    // MARK: - Setup
    
    private func setupLoadingIndicator() {
        contentView.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// 配置视频资源
    /// - Parameters:
    ///   - videoURL: 视频 URL
    ///   - coverImage: 封面图（可选）
    open func configure(videoURL: URL, coverImage: UIImage? = nil) {
        stopVideo()
        self.videoURL = videoURL
        imageView.image = coverImage
        setNeedsLayout()
        playVideo()
    }
    
    open override func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        if isPlaying {
            pauseVideo()
        } else {
            browser?.dismissSelf()
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        if let playerLayer = playerLayer {
            playerLayer.frame = imageView.bounds
        }
    }
    
    private func playVideo() {
        guard let url = videoURL else { return }
        
        // 显示加载指示器
        showLoading()
        
        if player == nil {
            let item = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: item)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = imageView.bounds
            imageView.layer.addSublayer(playerLayer!)
            
            NotificationCenter.default.addObserver(self, selector: #selector(videoDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: item)
            
            // 观察播放器的 timeControlStatus，精确判断视频是否正在播放
            // 在主线程读取 player.timeControlStatus 当前最新状态，比 change.newValue 更可靠
            timeControlStatusObservation = player?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    switch player.timeControlStatus {
                    case .playing:
                        self.hideLoading()
                    case .waitingToPlayAtSpecifiedRate:
                        if !self.isDismissInteracting {
                            self.showLoading()
                        }
                    case .paused:
                        break
                    @unknown default:
                        break
                    }
                }
            }
            
            // 观察资源加载状态
            itemStatusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    switch item.status {
                    case .readyToPlay:
                        // 资源就绪后检查播放状态，兜底处理 timeControlStatus KVO 可能未触发的情况
                        if self.player?.timeControlStatus == .playing {
                            self.hideLoading()
                        }
                    case .failed:
                        self.hideLoading()
                    default:
                        break
                    }
                }
            }
        }
        
        player?.play()
        isPlaying = true
    }
    
    private func pauseVideo() {
        player?.pause()
        isPlaying = false
    }
    
    /// 停止视频播放并清理资源
    public func stopVideo() {
        timeControlStatusObservation?.invalidate()
        timeControlStatusObservation = nil
        itemStatusObservation?.invalidate()
        itemStatusObservation = nil
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        isPlaying = false
        hideLoading()
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    // MARK: - Dismiss Interaction
    
    open override func photoBrowserDismissInteractionDidChange(isInteracting: Bool) {
        isDismissInteracting = isInteracting
        if isInteracting {
            // 下拉交互开始，隐藏 loading 避免遮挡缩小中的画面
            hideLoading()
        } else {
            // 下拉交互结束（回弹恢复），如果视频仍在缓冲中则恢复显示 loading
            if player?.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                showLoading()
            }
        }
    }
    
    // MARK: - Loading Helpers
    
    private func showLoading() {
        guard !isDismissInteracting else { return }
        loadingIndicator.startAnimating()
        contentView.bringSubviewToFront(loadingIndicator)
    }
    
    private func hideLoading() {
        loadingIndicator.stopAnimating()
    }
    
    @objc private func videoDidReachEnd() {
        player?.seek(to: .zero)
        player?.play()
    }
    
    // MARK: - App Lifecycle
    
    /// App 进入后台时，主动断开 playerLayer 与 player 的关联
    /// 防止 iOS 回收 GPU 资源后 playerLayer 进入不可恢复的异常状态
    @objc private func handleDidEnterBackground() {
        guard let playerLayer = playerLayer else { return }
        playerLayer.player = nil
    }
    
    /// App 从后台返回前台时，重新关联 player 并恢复播放
    @objc private func handleWillEnterForeground() {
        guard let player = player, let playerLayer = playerLayer else { return }
        playerLayer.player = player
        
        if isPlaying {
            player.play()
        }
    }
}
