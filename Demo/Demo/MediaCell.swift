//
//  MediaCell.swift
//  Demo
//
//  Created by jxing on 2025/10/24.
//

import UIKit
import AVKit
import AVFoundation
import Kingfisher

final class MediaCell: UICollectionViewCell {
    static let reuseIdentifier = "MediaCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        return iv
    }()

    private let playOverlay: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

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

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        playOverlay.isHidden = true
    }

    func configure(with media: Media) {
        imageView.image = nil
        playOverlay.isHidden = true

        switch media.source {
        case .localImage(let name):
            imageView.image = UIImage(named: name)

        case .remoteImage(let url):
            imageView.kf.setImage(with: url)

        case .localVideo(let fileName, let ext):
            playOverlay.isHidden = false
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                generateThumbnail(for: url)
            }

        case .remoteVideo(let url):
            playOverlay.isHidden = false
            generateThumbnail(for: url)
        }
    }

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
