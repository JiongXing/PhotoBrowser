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
    let imageView: UIImageView = {
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
        imageView.isHidden = false
        playOverlay.isHidden = true
    }
    
    // MARK: - Configuration Methods

    /// 配置 Cell 内容
    func configure(with media: DemoMedia) {
        imageView.image = nil
        playOverlay.isHidden = true

        switch media.source {
        case let .remoteImage(imageURL, thumbnailURL):
            if let thumb = thumbnailURL {
                imageView.kf.setImage(with: thumb)
            } else {
                imageView.kf.setImage(with: imageURL)
            }

        case let .remoteVideo(_, thumbnailURL):
            playOverlay.isHidden = false
            imageView.kf.setImage(with: thumbnailURL)
        }
    }
    
    // MARK: - Private Methods
}
