//
//  JXPhotoBrowser.swift
//  Demo
//
//  Created by jxing on 2025/10/24.
//

import UIKit
import Kingfisher
import AVFoundation

protocol JXPhotoBrowserDataSource: AnyObject {
    func numberOfItems(in browser: JXPhotoBrowser) -> Int
    func photoBrowser(_ browser: JXPhotoBrowser, mediaSourceAt index: Int) -> MediaSource
}

enum JXPhotoBrowserTransitionType { case fade, zoom, none }
enum JXPhotoBrowserScrollDirection {
    case horizontal, vertical
    var flowDirection: UICollectionView.ScrollDirection { self == .horizontal ? .horizontal : .vertical }
    var scrollPosition: UICollectionView.ScrollPosition { self == .horizontal ? .centeredHorizontally : .centeredVertically }
}

final class JXPhotoBrowser: UIViewController {
    weak var dataSource: JXPhotoBrowserDataSource?
    var initialIndex: Int = 0
    var scrollDirection: JXPhotoBrowserScrollDirection = .horizontal
    var transitionType: JXPhotoBrowserTransitionType = .fade

    private var collectionView: UICollectionView!
    
    // 无限循环配置
    private let loopMultiplier: Int = 1000
    var isLoopingEnabled: Bool = true
    private var realCount: Int { dataSource?.numberOfItems(in: self) ?? 0 }
    private var virtualCount: Int { isLoopingEnabled ? realCount * loopMultiplier : realCount }
    private func realIndex(fromVirtual index: Int) -> Int {
        let count = realCount
        guard count > 0 else { return 0 }
        return index % count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = scrollDirection.flowDirection
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = view.bounds.size

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.isPagingEnabled = true
        cv.backgroundColor = .black
        cv.dataSource = self
        cv.delegate = self
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.reuseIdentifier)
        view.addSubview(cv)
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: view.topAnchor),
            cv.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        collectionView = cv

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToInitialIndex()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = view.bounds.size
            layout.invalidateLayout()
        }
    }

    private func scrollToInitialIndex() {
        let count = realCount
        guard count > 0 else { return }
        let base = isLoopingEnabled ? (loopMultiplier / 2) * count : 0
        let target = base + max(0, min(initialIndex % count, count - 1))
        collectionView.scrollToItem(at: IndexPath(item: target, section: 0), at: scrollDirection.scrollPosition, animated: false)
    }

    @objc private func dismissSelf() {
        dismiss(animated: transitionType != .none, completion: nil)
    }

    func present(from vc: UIViewController) {
        modalPresentationStyle = .fullScreen
        if transitionType != .none { transitioningDelegate = self }
        vc.present(self, animated: transitionType != .none, completion: nil)
    }
}

extension JXPhotoBrowser: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return virtualCount
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.reuseIdentifier, for: indexPath) as! PhotoCell
        if realCount > 0, let src = dataSource?.photoBrowser(self, mediaSourceAt: realIndex(fromVirtual: indexPath.item)) {
            cell.configure(source: src)
        }
        return cell
    }
}

private final class PhotoCell: UICollectionViewCell {
    static let reuseIdentifier = "JXPhotoBrowserPhotoCell"
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        iv.clipsToBounds = true
        return iv
    }()
    private let playOverlay: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .white
        iv.isHidden = true
        return iv
    }()
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
    required init?(coder: NSCoder) { super.init(coder: coder) }
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask(); imageView.image = nil; playOverlay.isHidden = true
    }
    func configure(source: MediaSource) {
        switch source {
        case .localImage(let name): imageView.image = UIImage(named: name)
        case .remoteImage(let url): imageView.kf.setImage(with: url)
        case .localVideo(let f, let e):
            playOverlay.isHidden = false
            if let url = Bundle.main.url(forResource: f, withExtension: e) { generateThumbnail(for: url) }
        case .remoteVideo(let url):
            playOverlay.isHidden = false
            generateThumbnail(for: url)
        }
    }
    private func generateThumbnail(for url: URL) {
        let asset = AVURLAsset(url: url)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        DispatchQueue.global(qos: .userInitiated).async {
            let cg = try? gen.copyCGImage(at: time, actualTime: nil)
            if let cg = cg { DispatchQueue.main.async { self.imageView.image = UIImage(cgImage: cg) } }
        }
    }
}

extension JXPhotoBrowser: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? { Animator(type: transitionType, isPresenting: true) }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? { Animator(type: transitionType, isPresenting: false) }

    private final class Animator: NSObject, UIViewControllerAnimatedTransitioning {
        let type: JXPhotoBrowserTransitionType; let isPresenting: Bool
        init(type: JXPhotoBrowserTransitionType, isPresenting: Bool) { self.type = type; self.isPresenting = isPresenting }
        func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval {
            switch type { case .fade: return 0.25; case .zoom: return 0.3; case .none: return 0.0 }
        }
        func animateTransition(using ctx: UIViewControllerContextTransitioning) {
            let container = ctx.containerView
            guard let toView = ctx.view(forKey: .to) else { ctx.completeTransition(false); return }
            switch type {
            case .none:
                if isPresenting { container.addSubview(toView) }
                ctx.completeTransition(true)
            case .fade:
                if isPresenting {
                    container.addSubview(toView); toView.alpha = 0
                    UIView.animate(withDuration: transitionDuration(using: ctx), animations: { toView.alpha = 1 }) { ctx.completeTransition($0) }
                } else {
                    let fromView = ctx.view(forKey: .from)!
                    UIView.animate(withDuration: transitionDuration(using: ctx), animations: { fromView.alpha = 0 }) { _ in fromView.removeFromSuperview(); ctx.completeTransition(true) }
                }
            case .zoom:
                if isPresenting {
                    container.addSubview(toView); toView.alpha = 0; toView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                    UIView.animate(withDuration: transitionDuration(using: ctx), delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: { toView.alpha = 1; toView.transform = .identity }) { ctx.completeTransition($0) }
                } else {
                    let fromView = ctx.view(forKey: .from)!
                    UIView.animate(withDuration: transitionDuration(using: ctx), delay: 0, options: .curveEaseInOut, animations: { fromView.alpha = 0; fromView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85) }) { _ in fromView.removeFromSuperview(); ctx.completeTransition(true) }
                }
            }
        }
    }
}
