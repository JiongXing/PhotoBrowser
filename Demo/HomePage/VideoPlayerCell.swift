//
//  VideoPlayerCell.swift
//  Demo
//
//  视频播放 Cell，在浏览器中承担视频播放职责

import UIKit
import AVFoundation
import Photos
import JXPhotoBrowser

/// 视频播放 Cell
/// 继承自 JXZoomImageCell，添加视频播放功能
open class VideoPlayerCell: JXZoomImageCell {
    
    // MARK: - Static Properties
    
    public static let videoReuseIdentifier = "VideoPlayerCell"
    
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
    
    /// 是否正在保存视频
    private var isSavingVideo: Bool = false
    
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
        setupLongPressGesture()
        setupAppLifecycleObservers()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLoadingIndicator()
        setupLongPressGesture()
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
    
    private func setupLongPressGesture() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        scrollView.addGestureRecognizer(longPress)
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
    
    // MARK: - Long Press & Save Video
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, videoURL != nil else { return }
        presentSaveActionSheet()
    }
    
    private func presentSaveActionSheet() {
        guard let viewController = browser else { return }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "保存视频", style: .default) { [weak self] _ in
            self?.saveVideoToAlbum()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // iPad 适配 popover
        if let popover = alert.popoverPresentationController {
            popover.sourceView = contentView
            popover.sourceRect = CGRect(x: contentView.bounds.midX, y: contentView.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(alert, animated: true)
    }
    
    private func saveVideoToAlbum() {
        guard let url = videoURL, !isSavingVideo else { return }
        isSavingVideo = true
        
        // 先请求相册权限
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }
        
        switch status {
        case .authorized, .limited:
            downloadAndSaveVideo(from: url)
        case .notDetermined:
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] newStatus in
                    DispatchQueue.main.async {
                        if newStatus == .authorized || newStatus == .limited {
                            self?.downloadAndSaveVideo(from: url)
                        } else {
                            self?.isSavingVideo = false
                            self?.showToast("需要相册权限才能保存视频")
                        }
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                    DispatchQueue.main.async {
                        if newStatus == .authorized {
                            self?.downloadAndSaveVideo(from: url)
                        } else {
                            self?.isSavingVideo = false
                            self?.showToast("需要相册权限才能保存视频")
                        }
                    }
                }
            }
        default:
            isSavingVideo = false
            showToast("请在系统设置中允许访问相册")
        }
    }
    
    private func downloadAndSaveVideo(from url: URL) {
        // 本地文件直接保存
        if url.isFileURL {
            performSaveToAlbum(fileURL: url)
            return
        }
        
        showToast("正在保存...")
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                
                if let error {
                    self.isSavingVideo = false
                    self.showToast("下载失败：\(error.localizedDescription)")
                    return
                }
                
                guard let tempURL else {
                    self.isSavingVideo = false
                    self.showToast("下载失败")
                    return
                }
                
                // 将临时文件移动到 tmp 目录（带 .mp4 后缀），避免系统自动清理
                let destinationURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("mp4")
                do {
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    self.performSaveToAlbum(fileURL: destinationURL)
                } catch {
                    self.isSavingVideo = false
                    self.showToast("保存失败")
                }
            }
        }
        task.resume()
    }
    
    private func performSaveToAlbum(fileURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isSavingVideo = false
                
                // 清理非本地源的临时文件
                if !fileURL.isFileURL || fileURL.path.contains(NSTemporaryDirectory()) {
                    try? FileManager.default.removeItem(at: fileURL)
                }
                
                if success {
                    self.showToast("已保存到相册")
                } else {
                    self.showToast("保存失败：\(error?.localizedDescription ?? "未知错误")")
                }
            }
        }
    }
    
    // MARK: - Toast
    
    private func showToast(_ message: String) {
        guard let superView = browser?.view ?? window else { return }
        
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.font = .systemFont(ofSize: 14, weight: .medium)
        toastLabel.textAlignment = .center
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds = true
        toastLabel.numberOfLines = 0
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 内边距
        let padding: CGFloat = 16
        toastLabel.frame.size = toastLabel.sizeThatFits(CGSize(width: superView.bounds.width - 80, height: .greatestFiniteMagnitude))
        
        superView.addSubview(toastLabel)
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: superView.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: superView.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            toastLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: toastLabel.frame.width + padding * 2),
            toastLabel.heightAnchor.constraint(equalToConstant: toastLabel.frame.height + padding)
        ])
        
        toastLabel.alpha = 0
        UIView.animate(withDuration: 0.25) {
            toastLabel.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UIView.animate(withDuration: 0.25, animations: {
                toastLabel.alpha = 0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
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
