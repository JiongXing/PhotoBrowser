//
//  DemoMediaCell.swift
//  Demo
//
//  Created by jxing on 2025/10/24.
//

import UIKit
import AVKit
import AVFoundation
import Kingfisher
import JXPhotoBrowser

final class DemoMediaCell: UICollectionViewCell {
    
    // MARK: - Static Properties
    
    /// 复用标识符
    static let reuseIdentifier = "MediaCell"
    
    // MARK: - UI Components
    
    /// 主要的图片显示视图
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    /// 视频播放按钮覆盖层
    private let playOverlay: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Setup Methods
    
    private func setup() {
        contentView.addSubview(imageView)
        contentView.addSubview(playOverlay)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            playOverlay.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playOverlay.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playOverlay.widthAnchor.constraint(equalToConstant: 40),
            playOverlay.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Lifecycle Methods
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        playOverlay.isHidden = true
    }
    
    // MARK: - Configuration Methods

    /// 配置 Cell 内容
    /// - 参数 shouldLoad: 是否允许进行网络加载（未连通时仅展示占位）
    func configure(with media: DemoMedia, shouldLoad: Bool) {
        imageView.image = nil
        playOverlay.isHidden = true

        switch media.source {
        case let .remoteImage(imageURL, thumbnailURL):
            guard shouldLoad else { break }
            if let thumb = thumbnailURL {
                imageView.kf.setImage(with: thumb)
            } else {
                imageView.kf.setImage(with: imageURL)
            }

        case let .remoteVideo(url):
            playOverlay.isHidden = false
            if shouldLoad {
                generateThumbnail(for: url)
            }
        }
    }
    
    // MARK: - Transition Helper
    
    /// 提供转场所需的缩略图 ImageView（用于几何匹配动画）
    var transitionImageView: UIImageView { imageView }
    
    // MARK: - Private Methods
    
    private func generateThumbnail(for url: URL) {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    self?.imageView.image = image
                }
            } catch {
                // 保持占位背景
            }
        }
    }
}
