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
import Photos

// MARK: - ViewController
class DemoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    private var collectionView: UICollectionView!
    
    /// 网络状态监视器（监听网络连通性变化）
    private let networkMonitor = NWPathMonitor()
    
    /// 网络监视器队列（后台监控网络状态）
    private let networkQueue = DispatchQueue(label: "com.demo.network.monitor")
    
    // 数据源
    private var items: [DemoMedia] = []
    
    private weak var photoBrowser: JXPhotoBrowser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupNetworkMonitoring()
        setupCollectionView()
    }
    
    // MARK: - Helper Methods
    
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
            let thumbnailURL = base.appendingPathComponent("video_thumbnail_\(i).png")
            return DemoMedia(source: .remoteVideo(url: videoURL, thumbnailURL: thumbnailURL))
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
        case let .remoteVideo(url, thumbnailURL):
            // 视频模式下，直接使用提供的封面图 URL
            return JXPhotoResource(imageURL: thumbnailURL, thumbnailURL: thumbnailURL, videoURL: url)
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
    
    // 控制源缩略图的显隐（浏览器切换图片时调用）
    func photoBrowser(_ browser: JXPhotoBrowser, setOriginViewHidden hidden: Bool, at index: Int) {
        // 由于我们现在依赖 browser.pageIndex 来控制显隐（在 cellForItemAt 中），
        // 且 browser.pageIndex 在调用此代理方法前已经更新。
        // 所以我们只需要触发受影响 Cell 的更新即可。
        
        // 1. 找到当前 index 对应的 Cell 并更新
        let ip = IndexPath(item: index, section: 0)
        if let cell = collectionView.cellForItem(at: ip) as? DemoMediaCell {
            // 直接触发 configure 或者手动设置 isHidden
            // 推荐手动设置，比 reloadItems 更轻量
            cell.imageView.isHidden = hidden
        }
        
        // 2. 如果是显示（hidden=false），说明可能是上一个页面，需要恢复
        // 但其实上一个页面的恢复在 updateHiddenOriginView 中已经通过 restoreHiddenOriginViewIfNeeded 处理了
        // restore 会调用 setOriginViewHidden(false, at: oldIndex)
        // 所以这里只要处理好当前传进来的 index 即可
    }
    
    func photoBrowser(_ browser: JXPhotoBrowser, didLongPressItemAt index: Int, resource: JXPhotoResource?, sourceView: UIView) {
        guard let resource = resource else { return }
        let downloadTitle = resource.videoURL == nil ? "下载图片到系统相册" : "下载视频到系统相册"
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: downloadTitle, style: .default, handler: { [weak self] _ in
            self?.downloadToAlbum(resource: resource, presentingViewController: browser)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        browser.present(alert, animated: true)
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
    func downloadToAlbum(resource: JXPhotoResource, presentingViewController: UIViewController) {
        requestPhotoAuthorization { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                DispatchQueue.main.async {
                    self.presentToast(message: "未获得相册权限，无法保存", on: presentingViewController)
                }
                return
            }
            
            if let videoURL = resource.videoURL {
                self.downloadVideoAndSave(videoURL, presentingViewController: presentingViewController)
            } else {
                self.downloadImageAndSave(resource.imageURL, presentingViewController: presentingViewController)
            }
        }
    }
    
    /// 请求相册权限
    func requestPhotoAuthorization(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
//        if status == .authorized || status == .limited {
        if status == .authorized {
            completion(true)
            return
        }
        
        PHPhotoLibrary.requestAuthorization { newStatus in
//            completion(newStatus == .authorized || newStatus == .limited)
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

