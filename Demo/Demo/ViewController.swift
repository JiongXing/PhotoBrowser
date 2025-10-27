//
//  ViewController.swift
//  Demo
//
//  Created by jxing on 2025/10/24.
//

import UIKit
import AVKit
import AVFoundation

// MARK: - ViewController
class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {

    private var collectionView: UICollectionView!

    // 数据源：默认本地图片 local_0 至 local_8，可混入视频项
    private let items: [Media] = {
        var arr: [Media] = []
        for i in 0...8 {
            arr.append(Media(source: .localImage(name: "local_\(i)")))
        }
        // 示例：如需添加本地视频（将 sample.mp4 加入工程资源后取消注释）
        // arr.append(Media(source: .localVideo(fileName: "sample", fileExtension: "mp4")))
        return arr
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
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
        collectionView.register(MediaCell.self, forCellWithReuseIdentifier: MediaCell.reuseIdentifier)

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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCell.reuseIdentifier, for: indexPath) as! MediaCell
        cell.configure(with: items[indexPath.item])
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
        case .localImage, .remoteImage:
            let browser = JXPhotoBrowser()
            browser.dataSource = self
            browser.initialIndex = indexPath.item
            browser.scrollDirection = .horizontal // 可改为 .vertical 支持竖向浏览
            browser.transitionType = .zoom // 可改为 .fade 或 .none
            browser.isLoopingEnabled = true // 启用无限循环滑动
            // 为无缝 Zoom 动画提供源缩略图视图
            browser.originViewProvider = { [weak self] i in
                let ip = IndexPath(item: i, section: 0)
                guard let cell = self?.collectionView.cellForItem(at: ip) as? MediaCell else { return nil }
                return cell.transitionImageView
            }
            browser.present(from: self)
        case .localVideo(let fileName, let ext):
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                presentPlayer(with: url)
            }
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


// MARK: - JXPhotoBrowser DataSource
extension ViewController: JXPhotoBrowserDataSource {
    func numberOfItems(in browser: JXPhotoBrowser) -> Int {
        return items.count
    }
    func photoBrowser(_ browser: JXPhotoBrowser, mediaSourceAt index: Int) -> MediaSource {
        return items[index].source
    }
}

