//
//  PhotoCell.swift
//  Pods
//
//  Created by jxing on 2025/10/28.
//

import UIKit
import AVFoundation
import Kingfisher

class JXPhotoCell: UICollectionViewCell {
        
        // MARK: - Static Properties
        
        /// 复用标识符
        static let reuseIdentifier = "JXPhotoCell"
        
        // MARK: - UI Components
        
        /// 主要的图片显示视图
        private let imageView: UIImageView = {
            let iv = UIImageView()
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.contentMode = .scaleAspectFit
            iv.backgroundColor = .black
            iv.clipsToBounds = true
            return iv
        }()
        
        /// 视频播放按钮覆盖层
        private let playOverlay: UIImageView = {
            let iv = UIImageView(image: UIImage(systemName: "play.circle.fill"))
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.tintColor = .white
            iv.isHidden = true
            return iv
        }()
        
        // MARK: - Initializers
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.addSubview(imageView)
            contentView.addSubview(playOverlay)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                playOverlay.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                playOverlay.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                playOverlay.widthAnchor.constraint(equalToConstant: 48),
                playOverlay.heightAnchor.constraint(equalToConstant: 48)
            ])
            backgroundColor = .black
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
        
        // MARK: - Lifecycle Methods
        
        override func prepareForReuse() {
            super.prepareForReuse()
            imageView.kf.cancelDownloadTask()
            imageView.image = nil
            playOverlay.isHidden = true
        }
        
        // MARK: - Configuration Methods
        
        func configure(source: JXMediaSource) {
            switch source {
            case .localImage(let name):
                imageView.image = UIImage(named: name)
                
            case .remoteImage(let url):
                imageView.kf.setImage(with: url)
                
            case let .localVideo(f, e):
                playOverlay.isHidden = false
                if let url = Bundle.main.url(forResource: f, withExtension: e) {
                    generateThumbnail(for: url)
                }
                
            case let .remoteVideo(url):
                playOverlay.isHidden = false
                generateThumbnail(for: url)
            }
        }
        
        // MARK: - Transition Helper
        
        /// 提供转场所需的展示 ImageView（用于几何匹配动画）
        var transitionImageView: UIImageView { imageView }
        
        // MARK: - Private Methods
        
        private func generateThumbnail(for url: URL) {
            let asset = AVURLAsset(url: url)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.1, preferredTimescale: 600)
            DispatchQueue.global(qos: .userInitiated).async {
                let cg = try? gen.copyCGImage(at: time, actualTime: nil)
                if let cg = cg {
                    DispatchQueue.main.async {
                        self.imageView.image = UIImage(cgImage: cg)
                    }
                }
            }
        }
}
