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
import Kingfisher
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

    // 数据源：改为网络图片（原图 + 缩略图）
    private let items: [DemoMedia] = {
        let base = URL(string: "https://raw.githubusercontent.com/JiongXing/PhotoBrowser/master/Medias")!
        return (0...9).map { i in
            let original = base.appendingPathComponent("photo_\(i).png")
            let thumbnail = base.appendingPathComponent("photo_\(i)_thumbnail.png")
            return DemoMedia(source: .remoteImage(imageURL: original, thumbnailURL: thumbnail))
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNetworkMonitoring()
        setupCollectionView()
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
        let media = items[indexPath.item]
        switch media.source {
        case .remoteImage:
            let browser = JXPhotoBrowser()
            browser.delegate = self
            browser.initialIndex = indexPath.item
            browser.scrollDirection = .horizontal // 可改为 .vertical 支持竖向浏览
            browser.transitionType = .zoom // 可改为 .fade 或 .none
            browser.isLoopingEnabled = true // 启用无限循环滑动
            browser.present(from: self)
        case .remoteVideo(let url):
            presentPlayer(with: url)
        }
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

    // 生命周期：即将复用（可在此取消下载、清理状态）
    func photoBrowser(_ browser: JXPhotoBrowser, willReuse cell: JXPhotoCell, at index: Int) {
        cell.imageView.kf.cancelDownloadTask()
    }

    // 生命周期：已复用（为复用的 cell 配置内容）
    func photoBrowser(_ browser: JXPhotoBrowser, didReuse cell: JXPhotoCell, at index: Int) {
        if case let .remoteImage(imageURL, thumbnailURL) = items[index].source {
            // 先显示缩略图作为占位图（若存在），再加载原图
            if let thumbURL = thumbnailURL {
                cell.imageView.kf.setImage(with: thumbURL)
                cell.imageView.kf.setImage(with: imageURL, options: [.keepCurrentImageWhileLoading]) { [weak cell] _ in
                    cell?.adjustImageViewFrame()
                    cell?.centerImageIfNeeded()
                }
            } else {
                cell.imageView.kf.setImage(with: imageURL)
            }
            cell.adjustImageViewFrame()
            cell.centerImageIfNeeded()
        } else {
            cell.imageView.image = nil
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

