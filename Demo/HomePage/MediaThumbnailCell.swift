//
//  MediaThumbnailCell.swift
//  Demo
//
//  Created by jxing on 2025/10/24.
//

import UIKit
import AVKit
import AVFoundation
import Kingfisher
import JXPhotoBrowser

final class MediaThumbnailCell: UICollectionViewCell {
    
    // MARK: - Static Properties
    
    /// 复用标识符
    static let reuseIdentifier = "MediaCell"
    
    // MARK: - UI Components
    
    /// 主要的图片显示视图
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    /// 图片加载指示器
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = .gray
        return indicator
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
        contentView.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            playOverlay.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playOverlay.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playOverlay.widthAnchor.constraint(equalToConstant: 40),
            playOverlay.heightAnchor.constraint(equalToConstant: 40),
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    // MARK: - Lifecycle Methods
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        imageView.isHidden = false
        playOverlay.isHidden = true
        loadingIndicator.stopAnimating()
    }
    
    // MARK: - Configuration Methods

    /// 配置 Cell 内容
    func configure(with media: DemoMedia) {
        imageView.image = nil
        playOverlay.isHidden = true
        loadingIndicator.startAnimating()

        let completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void) = { [weak self] _ in
            self?.loadingIndicator.stopAnimating()
        }

        switch media.source {
        case let .remoteImage(imageURL, thumbnailURL):
            let url = thumbnailURL ?? imageURL
            imageView.kf.setImage(with: url, completionHandler: completionHandler)

        case let .remoteVideo(_, thumbnailURL):
            playOverlay.isHidden = false
            imageView.kf.setImage(with: thumbnailURL, completionHandler: completionHandler)
        }
    }
    
    // MARK: - Private Methods
}
