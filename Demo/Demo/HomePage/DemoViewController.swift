//
//  DemoViewController.swift
//  Demo
//
//  Created by jxing on 2025/10/24.
//

import UIKit
import AVKit
import AVFoundation
import JXPhotoBrowser
import Network

// MARK: - ViewController
class DemoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    private var collectionView: UICollectionView!
    
    /// 网络监控：是否已允许/可达网络（用于延迟图片加载）
    private var isNetworkReady: Bool = false
    
    /// 网络状态监视器（监听网络连通性变化）
    private let networkMonitor = NWPathMonitor()
    
    /// 网络监视器队列（后台监控网络状态）
    private let networkQueue = DispatchQueue(label: "com.demo.network.monitor")
    
    // 数据源
    private var items: [DemoMedia] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupNetworkMonitoring()
        setupCollectionView()
    }
    
    // MARK: - Helper Methods
    private func generateThumbnail(for videoURL: URL) -> URL? {
        // 在实际项目中，应由服务器返回视频封面图 URL。
        // 这里仅为演示，使用视频首帧。
        // 但 AVAssetImageGenerator 是异步耗时操作，不适合在 cellForRow 中直接生成并返回 image。
        // 且 Kingfisher 或 SDWebImage 通常支持视频 URL 作为 Key 来缓存首帧（需插件）。
        // 简单起见，我们这里不做本地生成，而是假设我们有一个能获取首帧的服务端接口，或者让 Cell 内部处理。
        // 既然用户要求“示例工程截取视频首帧作为封面，不要拿photo的数据混用”，
        // 我们可以在 JXVideoCell 中使用 AVAssetImageGenerator 获取首帧，或者在 DemoViewController 预处理。
        
        // 为了响应用户请求，我们修改 setupData，尝试为视频生成本地临时封面，
        // 或者更简单的，直接在 resourceForItemAt 中返回 videoURL 作为 imageURL，
        // 然后让 Kingfisher 的 VideoProvider (如果集成了) 或者我们自定义的 Loader 去加载。
        
        // 但目前 Kingfisher 默认不支持视频首帧。
        // 我们可以简单地在 DemoMedia 中增加一个 thumbnailImage 属性（UIImage），
        // 并在 setupData 中异步生成。
        return nil
    }
    
    private func setupData() {
        let base = URL(string: "https://raw.githubusercontent.com/JiongXing/PhotoBrowser/master/Medias")!
        
        // 图片数据
        let photos = (0...9).map { i -> DemoMedia in
            let original = base.appendingPathComponent("photo_\(i).png")
            let thumbnail = base.appendingPathComponent("photo_\(i)_thumbnail.png")
            return DemoMedia(source: .remoteImage(imageURL: original, thumbnailURL: thumbnail))
        }
        
        // 视频数据
        let videos = (0...2).map { i -> DemoMedia in
            let videoURL = base.appendingPathComponent("video_\(i).mp4")
            // 视频封面处理：
            // 实际上远程视频无法同步获取首帧。
            // 1. 服务端应该提供封面 URL。
            // 2. 客户端下载视频头文件生成。
            // 3. Kingfisher 扩展。
            // 鉴于这是一个 Demo，且用户要求“截取视频首帧”，我们可以在 JXVideoCell 中处理：
            // 当 imageURL == videoURL 时，尝试提取首帧。
            // 为了传递这个意图，我们在 delegate 中将 imageURL 设为 videoURL。
            return DemoMedia(source: .remoteVideo(url: videoURL))
        }
        
        items = photos + videos
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
        collectionView.register(DemoMediaCell.self, forCellWithReuseIdentifier: DemoMediaCell.reuseIdentifier)
        
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DemoMediaCell.reuseIdentifier, for: indexPath) as! DemoMediaCell
        cell.configure(with: items[indexPath.item], shouldLoad: isNetworkReady)
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
    
    // MARK: - 交互：点击视频进行播放
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 无论是图片还是视频，都使用 JXPhotoBrowser 进行浏览
        // 如果是视频，JXPhotoBrowser 内部会处理播放逻辑
        let browser = JXPhotoBrowser()
        browser.delegate = self
        browser.initialIndex = indexPath.item
        browser.scrollDirection = .horizontal
        browser.transitionType = .zoom
        browser.isLoopingEnabled = true
        
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
    
    /// 提供 Cell 类，用于区分视频和图片
    func photoBrowser(_ browser: JXPhotoBrowser, cellClassForItemAt index: Int) -> AnyClass? {
        let media = items[index]
        switch media.source {
        case .remoteImage:
            return JXPhotoCell.self
        case .remoteVideo:
            return JXVideoCell.self
        }
    }
    
    /// 提供资源（原图 + 缩略图 + 视频），加载逻辑由 Cell 内部处理
    func photoBrowser(_ browser: JXPhotoBrowser, resourceForItemAt index: Int) -> JXPhotoResource? {
        let media = items[index]
        switch media.source {
        case let .remoteImage(imageURL, thumbnailURL):
            return JXPhotoResource(imageURL: imageURL, thumbnailURL: thumbnailURL)
        case let .remoteVideo(url):
            // 视频模式下，imageURL 设为 nil 或视频 URL，由 Cell 内部判断是否需要生成首帧
            // 这里我们将 imageURL 设为 videoURL，告知 Cell 这是一个视频，且没有独立封面
            return JXPhotoResource(imageURL: url, thumbnailURL: nil, videoURL: url)
        }
    }
    
    // 生命周期：将要显示（可做轻量 UI 调整）
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoCell, at index: Int) { }
    
    // 生命周期：已消失（可回收资源）
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoCell, at index: Int) { }
    
    // 为 Zoom 转场提供源缩略图视图（用于起点几何计算）
    func photoBrowser(_ browser: JXPhotoBrowser, zoomOriginViewAt index: Int) -> UIView? {
        let ip = IndexPath(item: index, section: 0)
        guard let cell = collectionView.cellForItem(at: ip) as? DemoMediaCell else { return nil }
        return cell.imageView
    }
    
    // 提供 Zoom 转场使用的临时 ZoomView（转场结束即移除）
    func photoBrowser(_ browser: JXPhotoBrowser, zoomViewForItemAt index: Int, isPresenting: Bool) -> UIView? {
        let ip = IndexPath(item: index, section: 0)
        guard let cell = collectionView.cellForItem(at: ip) as? DemoMediaCell else { return nil }
        guard let image = cell.imageView.image else { return nil }
        let iv = UIImageView(image: image)
        iv.contentMode = cell.imageView.contentMode
        iv.clipsToBounds = true
        return iv
    }
}

// MARK: - Network Monitoring
private extension DemoViewController {
    
    /// 启动网络权限/连通性监控，连通后刷新列表以触发加载
    func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let ready = (path.status == .satisfied)
            if ready != self.isNetworkReady {
                self.isNetworkReady = ready
                if ready {
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
        
        networkMonitor.start(queue: networkQueue)
    }
}

