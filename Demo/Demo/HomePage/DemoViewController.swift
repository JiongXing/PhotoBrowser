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

// MARK: - ViewController
class DemoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {

    private var collectionView: UICollectionView!

    // 数据源：改为网络图片（原图 + 缩略图）
    private let items: [DemoMedia] = {
        let base = URL(string: "https://raw.githubusercontent.com/JiongXing/PhotoBrowser/master/Medias")!
        return (0...8).map { i in
            let original = base.appendingPathComponent("photo_\(i).png")
            let thumbnail = base.appendingPathComponent("photo_\(i)_thumbnail.png")
            return DemoMedia(source: .remoteImage(imageURL: original, thumbnailURL: thumbnail))
        }
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
        case .remoteImage:
            let browser = JXPhotoBrowser()
            browser.dataSource = self
            browser.initialIndex = indexPath.item
            browser.scrollDirection = .horizontal // 可改为 .vertical 支持竖向浏览
            browser.transitionType = .zoom // 可改为 .fade 或 .none
            browser.isLoopingEnabled = true // 启用无限循环滑动
            // 为无缝 Zoom 动画提供源缩略图视图
            browser.originViewProvider = { [weak self] i in
                let ip = IndexPath(item: i, section: 0)
                guard let cell = self?.collectionView.cellForItem(at: ip) as? DemoMediaCell else { return nil }
                return cell.transitionImageView
            }
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


// MARK: - JXPhotoBrowser DataSource
extension DemoViewController: JXPhotoBrowserDataSource {
    func numberOfItems(in browser: JXPhotoBrowser) -> Int {
        return items.count
    }

    // 由调用方提供一个用于展示的视图（此处用 UIImageView 加载原图）
    func photoBrowser(_ browser: JXPhotoBrowser, viewForItemAt index: Int) -> UIView {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        iv.clipsToBounds = true
        if case let .remoteImage(imageURL, _) = items[index].source {
            iv.kf.setImage(with: imageURL)
        }
        return iv
    }

    // 可选：提供转场视图（返回 nil 时，默认使用展示视图）
    func photoBrowser(_ browser: JXPhotoBrowser, transitionViewAt index: Int) -> UIView? {
        return nil
    }
}

