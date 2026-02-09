//
//  DemoViewController.swift
//  Demo
//
//  Created by jxing on 2025/10/24.
//

import UIKit
import AVKit
import AVFoundation
import Network
import Photos
import JXPhotoBrowser
import Kingfisher

// MARK: - ViewController
class DemoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    /// Banner 设置面板（控制无限循环、自动轮播）
    private var bannerSettingsPanel: BannerSettingsPanel!
    
    /// 浏览器设置面板（控制转场动画、滚动方向）
    private var browserSettingsPanel: BrowserSettingsPanel!
    
    private var collectionView: UICollectionView!
    
    /// 顶部横向 Banner 视图
    private var photoBannerView: PhotoBannerView!
    
    /// 网络状态监视器（监听网络连通性变化）
    private let networkMonitor = NWPathMonitor()
    
    /// 网络监视器队列（后台监控网络状态）
    private let networkQueue = DispatchQueue(label: "com.demo.network.monitor")
    
    // 数据源
    private var items: [DemoMedia] = []
    
    private weak var photoBrowser: JXPhotoBrowser?
    
    /// 是否允许自动旋转（固定为 false，不支持设备旋转）
    open override var shouldAutorotate: Bool {
        return false
    }
    
    /// 支持的屏幕方向（固定为竖屏）
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupNetworkMonitoring()
        setupBannerSettingsPanel()
        setupBannerBrowser()
        setupBrowserSettingsPanel()
        setupCollectionView()
    }
    
    
    // MARK: - Helper Methods
    
    /// 初始化 Banner 设置面板（位于 Banner 上方）
    private func setupBannerSettingsPanel() {
        bannerSettingsPanel = BannerSettingsPanel()
        bannerSettingsPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerSettingsPanel)
        
        NSLayoutConstraint.activate([
            bannerSettingsPanel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bannerSettingsPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bannerSettingsPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    /// 初始化浏览器设置面板（位于 Banner 下方）
    private func setupBrowserSettingsPanel() {
        browserSettingsPanel = BrowserSettingsPanel()
        browserSettingsPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(browserSettingsPanel)
        
        NSLayoutConstraint.activate([
            browserSettingsPanel.topAnchor.constraint(equalTo: photoBannerView.bottomAnchor, constant: 8),
            browserSettingsPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            browserSettingsPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupData() {
        let base = URL(string: "https://raw.githubusercontent.com/JiongXing/PhotoBrowser/master/Medias")!
        
        // 图片数据
        let photos = (0..<9).map { i -> DemoMedia in
            let original = base.appendingPathComponent("photo_\(i).png")
            let thumbnail = base.appendingPathComponent("photo_\(i)_thumbnail.png")
            return DemoMedia(source: .remoteImage(imageURL: original, thumbnailURL: thumbnail))
        }
        
        // 视频数据
        let videos = (0..<3).map { i -> DemoMedia in
            let videoURL = base.appendingPathComponent("video_\(i).mp4")
            let thumbnailURL = base.appendingPathComponent("video_thumbnail_\(i).png")
            return DemoMedia(source: .remoteVideo(url: videoURL, thumbnailURL: thumbnailURL))
        }
        
        items = photos + videos
    }
    
    /// 初始化顶部 Banner 区域
    private func setupBannerBrowser() {
        // 从 items 中提取仅包含图片的资源列表
        let bannerResources: [(imageURL: URL, thumbnailURL: URL?)] = items.compactMap { media in
            switch media.source {
            case let .remoteImage(imageURL, thumbnailURL):
                return (imageURL, thumbnailURL)
            case .remoteVideo:
                return nil
            }
        }
        
        // 创建 Banner 视图
        photoBannerView = PhotoBannerView()
        photoBannerView.translatesAutoresizingMaskIntoConstraints = false
        photoBannerView.configure(with: bannerResources)
        view.addSubview(photoBannerView)
        
        // 监听 Banner 设置面板的开关变化，实时更新 Banner 行为
        bannerSettingsPanel.onLoopingChanged = { [weak self] isLoopingEnabled in
            self?.photoBannerView.isLoopingEnabled = isLoopingEnabled
        }
        bannerSettingsPanel.onAutoPlayChanged = { [weak self] isAutoPlayEnabled in
            self?.photoBannerView.isAutoPlayEnabled = isAutoPlayEnabled
        }
        
        NSLayoutConstraint.activate([
            photoBannerView.topAnchor.constraint(equalTo: bannerSettingsPanel.bottomAnchor),
            photoBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            photoBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            photoBannerView.heightAnchor.constraint(equalToConstant: photoBannerView.bannerHeight)
        ])
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        let inset: CGFloat = 12
        layout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MediaThumbnailCell.self, forCellWithReuseIdentifier: MediaThumbnailCell.reuseIdentifier)
        
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: browserSettingsPanel.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - DataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaThumbnailCell.reuseIdentifier, for: indexPath) as! MediaThumbnailCell
        cell.configure(with: items[indexPath.item])
        if let browser = photoBrowser, browser.pageIndex == indexPath.item {
            cell.imageView.isHidden = true
        } else {
            cell.imageView.isHidden = false
        }
        return cell
    }
    
    // MARK: - DelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: 100, height: 100)
        }
        let columns: CGFloat = 3
        let totalSpacing = flowLayout.sectionInset.left + flowLayout.sectionInset.right + flowLayout.minimumInteritemSpacing * (columns - 1)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / columns)
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let browser = JXPhotoBrowser()
        browser.register(VideoPlayerCell.self, forReuseIdentifier: VideoPlayerCell.videoReuseIdentifier)
        browser.delegate = self
        browser.initialIndex = indexPath.item
        
        // 使用浏览器设置面板的配置
        browser.scrollDirection = browserSettingsPanel.scrollDirection
        browser.transitionType = browserSettingsPanel.transitionType
        browser.itemSpacing = 20
        
        self.photoBrowser = browser
        browser.present(from: self)
    }
    
    private func presentPlayer(with url: URL) {
        let playerVC = AVPlayerViewController()
        playerVC.player = AVPlayer(url: url)
        present(playerVC, animated: true) {
            playerVC.player?.play()
        }
    }
}


// MARK: - JXPhotoBrowser Delegate
extension DemoViewController: JXPhotoBrowserDelegate {
    func numberOfItems(in browser: JXPhotoBrowser) -> Int {
        return items.count
    }
    
    func photoBrowser(_ browser: JXPhotoBrowser, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
        let media = items[index]
        switch media.source {
        case .remoteImage:
            let cell = browser.dequeueReusableCell(withReuseIdentifier: JXPhotoBrowserCell.reuseIdentifier, for: indexPath) as! JXPhotoBrowserCell
            return cell
        case .remoteVideo:
            let cell = browser.dequeueReusableCell(withReuseIdentifier: VideoPlayerCell.videoReuseIdentifier, for: indexPath) as! VideoPlayerCell
            return cell
        }
    }
    
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoBrowserAnyCell, at index: Int) {
        let media = items[index]
        switch media.source {
        case let .remoteImage(imageURL, thumbnailURL):
            guard let photoCell = cell as? JXPhotoBrowserCell else { return }
            print("[willDisplay] index: \(index), imageURL: \(imageURL)")
            // 同步取出缓存的缩略图作为占位图，然后加载原图
            let placeholder = thumbnailURL.flatMap { ImageCache.default.retrieveImageInMemoryCache(forKey: $0.absoluteString) }
            photoCell.imageView.kf.setImage(with: imageURL, placeholder: placeholder) { [weak photoCell] _ in
                photoCell?.setNeedsLayout()
            }
        case let .remoteVideo(videoURL, thumbnailURL):
            guard let videoCell = cell as? VideoPlayerCell else { return }
            print("[willDisplay] index: \(index), videoURL: \(videoURL)")
            // 先尝试从内存缓存同步获取封面图
            let memoryImage = ImageCache.default.retrieveImageInMemoryCache(forKey: thumbnailURL.absoluteString)
            videoCell.configure(videoURL: videoURL, coverImage: memoryImage)
            
            // 内存缓存为空时（如 App 从后台恢复后缓存被清理），异步从磁盘/网络加载封面图
            if memoryImage == nil {
                videoCell.imageView.kf.setImage(with: thumbnailURL) { [weak videoCell] _ in
                    videoCell?.setNeedsLayout()
                }
            }
        }
    }
    
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoBrowserAnyCell, at index: Int) {
        // 停止视频播放
        if let videoCell = cell as? VideoPlayerCell {
            videoCell.stopVideo()
        }
    }
    
    // 为 Zoom 转场提供列表中的缩略图视图（用于起止位置计算）
    func photoBrowser(_ browser: JXPhotoBrowser, thumbnailViewAt index: Int) -> UIView? {
        let ip = IndexPath(item: index, section: 0)
        guard let cell = collectionView.cellForItem(at: ip) as? MediaThumbnailCell else { return nil }
        return cell.imageView
    }
    
    // 控制缩略图的显隐（Zoom 转场时隐藏源视图，避免视觉重叠）
    func photoBrowser(_ browser: JXPhotoBrowser, setThumbnailHidden hidden: Bool, at index: Int) {
        let ip = IndexPath(item: index, section: 0)
        if let cell = collectionView.cellForItem(at: ip) as? MediaThumbnailCell {
            cell.imageView.isHidden = hidden
        }
    }
}

// MARK: - Network Monitoring
private extension DemoViewController {
    
    /// 启动网络权限/连通性监控，连通后刷新列表以触发加载
    func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let ready = (path.status == .satisfied)
            if ready {
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
        
        networkMonitor.start(queue: networkQueue)
    }
    
    /// 下载图片 / 视频并保存到系统相册
    func downloadToAlbum(imageURL: URL?, videoURL: URL?, presentingViewController: UIViewController) {
        requestPhotoAuthorization { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                DispatchQueue.main.async {
                    self.presentToast(message: "未获得相册权限，无法保存", on: presentingViewController)
                }
                return
            }
            
            if let videoURL = videoURL {
                self.downloadVideoAndSave(videoURL, presentingViewController: presentingViewController)
            } else if let imageURL = imageURL {
                self.downloadImageAndSave(imageURL, presentingViewController: presentingViewController)
            }
        }
    }
    
    /// 请求相册权限
    func requestPhotoAuthorization(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            completion(true)
            return
        }
        
        PHPhotoLibrary.requestAuthorization { newStatus in
            completion(newStatus == .authorized)
        }
    }
    
    /// 下载图片后保存
    func downloadImageAndSave(_ url: URL, presentingViewController: UIViewController) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.presentToast(message: "图片下载失败", on: presentingViewController)
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, _ in
                DispatchQueue.main.async {
                    self.presentToast(message: success ? "已保存到系统相册" : "保存失败", on: presentingViewController)
                }
            }
        }.resume()
    }
    
    /// 下载视频后保存
    func downloadVideoAndSave(_ url: URL, presentingViewController: UIViewController) {
        URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, error in
            guard let self = self else { return }
            guard let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    self.presentToast(message: "视频下载失败", on: presentingViewController)
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
            }) { success, _ in
                DispatchQueue.main.async {
                    self.presentToast(message: success ? "已保存到系统相册" : "保存失败", on: presentingViewController)
                }
            }
        }.resume()
    }
    
    /// 简单提示
    func presentToast(message: String, on viewController: UIViewController) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        viewController.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak alert] in
            alert?.dismiss(animated: true)
        }
    }
}
