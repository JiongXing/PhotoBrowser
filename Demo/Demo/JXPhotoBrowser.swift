//
//  JXPhotoBrowser.swift
//  Demo
//
//  Created by jxing on 2025/10/24.
//

import UIKit
import Kingfisher
import AVFoundation

// MARK: - Data Source Protocol

protocol JXPhotoBrowserDataSource: AnyObject {
    func numberOfItems(in browser: JXPhotoBrowser) -> Int
    func photoBrowser(_ browser: JXPhotoBrowser, mediaSourceAt index: Int) -> MediaSource
}

// MARK: - Enums

enum JXPhotoBrowserTransitionType { 
    case fade, zoom, none 
}

enum JXPhotoBrowserScrollDirection {
    case horizontal, vertical
    
    var flowDirection: UICollectionView.ScrollDirection { 
        self == .horizontal ? .horizontal : .vertical 
    }
    
    var scrollPosition: UICollectionView.ScrollPosition { 
        self == .horizontal ? .centeredHorizontally : .centeredVertically 
    }
}

// MARK: - Main Browser Class

final class JXPhotoBrowser: UIViewController {
    
    // MARK: - Public Properties
    
    /// 数据源代理
    weak var dataSource: JXPhotoBrowserDataSource?
    
    /// 初始显示的图片索引
    var initialIndex: Int = 0
    
    /// 滚动方向（水平或垂直）
    var scrollDirection: JXPhotoBrowserScrollDirection = .horizontal {
        didSet {
            if isViewLoaded {
                applyCollectionViewConfig()
            }
        }
    }
    
    /// 是否启用分页
    var isPagingEnabled: Bool = true {
        didSet {
            if isViewLoaded {
                collectionView.isPagingEnabled = isPagingEnabled
            }
        }
    }
    
    /// 是否启用无限循环滚动
    var isLoopingEnabled: Bool = true
    
    /// 转场动画类型
    var transitionType: JXPhotoBrowserTransitionType = .fade
    
    /// 提供源缩略图视图的闭包（用于 Zoom 几何匹配）
    var originViewProvider: ((Int) -> UIView?)?
    
    // MARK: - Private Properties
    
    /// 主要的集合视图
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = view.bounds.size
    
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .black
        cv.dataSource = self
        cv.delegate = self
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.reuseIdentifier)
        return cv
    }()
    
    /// 无限循环倍数
    private let loopMultiplier: Int = 1000
    
    /// 真实数据源数量
    private var realCount: Int { 
        dataSource?.numberOfItems(in: self) ?? 0 
    }
    
    /// 虚拟数据源数量（用于无限循环）
    private var virtualCount: Int { 
        isLoopingEnabled ? realCount * loopMultiplier : realCount 
    }
    
    /// 是否已滚动到初始位置（避免重复滚动）
    private var didScrollToInitial = false
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCollectionView()
        applyCollectionViewConfig()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didScrollToInitial {
            scrollToInitialIndex()
            didScrollToInitial = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            if layout.itemSize != view.bounds.size {
                layout.itemSize = view.bounds.size
                layout.invalidateLayout()
            }
        }
        if !didScrollToInitial {
            scrollToInitialIndex()
            didScrollToInitial = true
        }
    }
    
    // MARK: - Private Methods
    
    /// 将虚拟索引转换为真实索引
    private func realIndex(fromVirtual index: Int) -> Int {
        let count = realCount
        guard count > 0 else { return 0 }
        return index % count
    }
    
    /// 滚动到初始索引位置
    private func scrollToInitialIndex() {
        let count = realCount
        guard count > 0 else { return }
        let base = isLoopingEnabled ? (loopMultiplier / 2) * count : 0
        let target = base + max(0, min(initialIndex % count, count - 1))
        collectionView.scrollToItem(at: IndexPath(item: target, section: 0), at: scrollDirection.scrollPosition, animated: false)
    }
    
    /// 关闭浏览器
    @objc private func dismissSelf() {
        dismiss(animated: transitionType != .none, completion: nil)
    }
    
    /// 当前可见的图片视图（用于转场目标）
    fileprivate func visiblePhotoImageView() -> UIImageView? {
        let center = CGPoint(
            x: collectionView.bounds.midX + collectionView.contentOffset.x,
            y: collectionView.bounds.midY + collectionView.contentOffset.y
        )
        guard let idx = collectionView.indexPathForItem(at: center),
              let cell = collectionView.cellForItem(at: idx) as? PhotoCell else { return nil }
        return cell.transitionImageView
    }
    
    /// 当前真实索引（虚拟索引映射）
    fileprivate func currentRealIndex() -> Int? {
        let center = CGPoint(
            x: collectionView.bounds.midX + collectionView.contentOffset.x,
            y: collectionView.bounds.midY + collectionView.contentOffset.y
        )
        guard let virtualItem = collectionView.indexPathForItem(at: center)?.item else { return nil }
        return realIndex(fromVirtual: virtualItem)
    }
    
    // MARK: - Public Methods
    
    /// 从指定视图控制器展示浏览器
    func present(from vc: UIViewController) {
        modalPresentationStyle = .fullScreen
        if transitionType != .none { transitioningDelegate = self }
        vc.present(self, animated: transitionType != .none, completion: nil)
    }

    // MARK: - Setup & Configuration
    
    /// 添加并约束集合视图
    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    /// 根据当前属性应用集合视图配置（支持运行时切换）
    private func applyCollectionViewConfig() {
        // 分页开关
        collectionView.isPagingEnabled = isPagingEnabled
        
        // 更新滚动方向
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let newDirection = scrollDirection.flowDirection
            if layout.scrollDirection != newDirection {
                layout.scrollDirection = newDirection
                layout.invalidateLayout()
            }
        }
        
        // 保持当前可见项居中（在已滚动到初始项后）
        if didScrollToInitial {
            let center = CGPoint(
                x: collectionView.bounds.midX + collectionView.contentOffset.x,
                y: collectionView.bounds.midY + collectionView.contentOffset.y
            )
            if let indexPath = collectionView.indexPathForItem(at: center) {
                collectionView.scrollToItem(at: indexPath, at: scrollDirection.scrollPosition, animated: false)
            }
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate

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

// MARK: - Photo Cell

private final class PhotoCell: UICollectionViewCell {
    
    // MARK: - Static Properties
    
    /// 复用标识符
    static let reuseIdentifier = "JXPhotoBrowserPhotoCell"
    
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
    
    func configure(source: MediaSource) {
        switch source {
        case .localImage(let name): 
            imageView.image = UIImage(named: name)
            
        case .remoteImage(let url): 
            imageView.kf.setImage(with: url)
            
        case .localVideo(let f, let e):
            playOverlay.isHidden = false
            if let url = Bundle.main.url(forResource: f, withExtension: e) { 
                generateThumbnail(for: url) 
            }
            
        case .remoteVideo(let url):
            playOverlay.isHidden = false
            generateThumbnail(for: url)
        }
    }
    
    // MARK: - Transition Helper
    
    /// 提供转场所需的展示 ImageView（用于几何匹配动画）
    fileprivate var transitionImageView: UIImageView { imageView }
    
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

// MARK: - Transition Animation

extension JXPhotoBrowser: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? { 
        switch transitionType {
        case .fade: return FadeAnimator(isPresenting: true)
        case .zoom: return ZoomPresentAnimator()
        case .none: return NoneAnimator(isPresenting: true)
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? { 
        switch transitionType {
        case .fade: return FadeAnimator(isPresenting: false)
        case .zoom: return ZoomDismissAnimator()
        case .none: return NoneAnimator(isPresenting: false)
        }
    }
    
    // MARK: - Animator Classes
    
    private final class FadeAnimator: NSObject, UIViewControllerAnimatedTransitioning {
        let isPresenting: Bool
        
        init(isPresenting: Bool) { 
            self.isPresenting = isPresenting 
        }
        
        func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.25 }
        
        func animateTransition(using ctx: UIViewControllerContextTransitioning) {
            let container = ctx.containerView
            if isPresenting {
                guard let toView = ctx.view(forKey: .to) else {
                    ctx.completeTransition(false)
                    return
                }
                container.addSubview(toView)
                toView.alpha = 0
                UIView.animate(withDuration: transitionDuration(using: ctx), animations: {
                    toView.alpha = 1
                }) { finished in
                    ctx.completeTransition(finished)
                }
            } else {
                guard let fromView = ctx.view(forKey: .from) else {
                    ctx.completeTransition(false)
                    return
                }
                if let toView = ctx.view(forKey: .to) {
                    container.insertSubview(toView, belowSubview: fromView)
                    toView.alpha = 1
                }
                UIView.animate(withDuration: transitionDuration(using: ctx), animations: {
                    fromView.alpha = 0
                }) { _ in
                    let wasCancelled = ctx.transitionWasCancelled
                    if wasCancelled {
                        fromView.alpha = 1
                        ctx.completeTransition(false)
                    } else {
                        fromView.removeFromSuperview()
                        ctx.completeTransition(true)
                    }
                }
            }
        }
    }
    
    private final class ZoomPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
        func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.25 }
        
        func animateTransition(using ctx: UIViewControllerContextTransitioning) {
            let container = ctx.containerView
            let duration = transitionDuration(using: ctx)
            
            guard
                let toVC = ctx.viewController(forKey: .to) as? JXPhotoBrowser,
                let toView = ctx.view(forKey: .to)
            else {
                ctx.completeTransition(false)
                return
            }
            
            container.addSubview(toView)
            toView.alpha = 0
            toView.layoutIfNeeded()
            
            var originView: UIView?
            if let provider = toVC.originViewProvider {
                originView = provider(toVC.initialIndex)
            }
            
            var animImageView: UIImageView?
            var startFrame: CGRect = .zero
            var destIV = toVC.visiblePhotoImageView()
            var endFrame: CGRect = .zero
            var canZoom = false
            if let originIV = originView as? UIImageView, let startImg = originIV.image,
               let targetIV = destIV, let targetImg = targetIV.image, targetImg.size.width > 0 && targetImg.size.height > 0 {
                // 构造动画起点视图
                startFrame = originIV.convert(originIV.bounds, to: container)
                let iv = UIImageView(image: startImg)
                iv.frame = startFrame
                iv.contentMode = originIV.contentMode
                iv.clipsToBounds = true
                animImageView = iv
                // 计算目标显示区域（按 scaleAspectFit）
                let fit = AVMakeRect(aspectRatio: targetImg.size, insideRect: targetIV.bounds)
                endFrame = targetIV.convert(fit, to: container)
                // 隐藏真实视图，避免重影
                originIV.isHidden = true
                targetIV.isHidden = true
                canZoom = true
            }
            
            if canZoom, let animIV = animImageView {
                container.addSubview(animIV)
                UIView.animate(withDuration: duration, animations: {
                    animIV.frame = endFrame
                    toView.alpha = 1
                }) { finished in
                    destIV?.isHidden = false
                    originView?.isHidden = false
                    animIV.removeFromSuperview()
                    ctx.completeTransition(finished)
                }
            } else {
                // 降级为 fade 动画（不缩放）
                toView.alpha = 0
                UIView.animate(withDuration: duration, animations: {
                    toView.alpha = 1
                }) { finished in
                    ctx.completeTransition(finished)
                }
            }
        }
    }
    
    private final class ZoomDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
        func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.25 }
        
        func animateTransition(using ctx: UIViewControllerContextTransitioning) {
            let container = ctx.containerView
            let duration = transitionDuration(using: ctx)
            
            guard
                let fromVC = ctx.viewController(forKey: .from) as? JXPhotoBrowser,
                let fromView = ctx.view(forKey: .from)
            else {
                ctx.completeTransition(false)
                return
            }
            
            if let toView = ctx.view(forKey: .to) {
                container.insertSubview(toView, belowSubview: fromView)
                toView.alpha = 1
            }
            
            let srcIV = fromVC.visiblePhotoImageView()
            var animImageView: UIImageView?
            var startFrame: CGRect = .zero
            var destView: UIView?
            var endFrame: CGRect = .zero
            var canZoom = false
            if let iv = srcIV, let img = iv.image, img.size.width > 0 && img.size.height > 0 {
                let fit = AVMakeRect(aspectRatio: img.size, insideRect: iv.bounds)
                startFrame = iv.convert(fit, to: container)
                let aiv = UIImageView(image: img)
                aiv.frame = startFrame
                aiv.contentMode = iv.contentMode
                aiv.clipsToBounds = true
                animImageView = aiv
                iv.isHidden = true
                if let currentIndex = fromVC.currentRealIndex(), let origin = fromVC.originViewProvider?(currentIndex) {
                    destView = origin
                    endFrame = origin.convert(origin.bounds, to: container)
                    origin.isHidden = true
                    canZoom = true
                }
            }
            
            if canZoom, let animIV = animImageView {
                container.addSubview(animIV)
                UIView.animate(withDuration: duration, animations: {
                    animIV.frame = endFrame
                    fromView.alpha = 0
                }) { _ in
                    let wasCancelled = ctx.transitionWasCancelled
                    if wasCancelled {
                        srcIV?.isHidden = false
                        destView?.isHidden = false
                        animIV.removeFromSuperview()
                        fromView.alpha = 1
                        ctx.completeTransition(false)
                    } else {
                        destView?.isHidden = false
                        animIV.removeFromSuperview()
                        fromView.removeFromSuperview()
                        ctx.completeTransition(true)
                    }
                }
            } else {
                // 降级为 fade 动画（不缩放），保持黑屏修复
                UIView.animate(withDuration: duration, animations: {
                    fromView.alpha = 0
                }) { _ in
                    let wasCancelled = ctx.transitionWasCancelled
                    if wasCancelled {
                        fromView.alpha = 1
                        ctx.completeTransition(false)
                    } else {
                        fromView.removeFromSuperview()
                        ctx.completeTransition(true)
                    }
                }
            }
        }
    }
    
    private final class NoneAnimator: NSObject, UIViewControllerAnimatedTransitioning {
        let isPresenting: Bool
        
        init(isPresenting: Bool) { 
            self.isPresenting = isPresenting 
        }
        
        func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.0 }
        
        func animateTransition(using ctx: UIViewControllerContextTransitioning) {
            let container = ctx.containerView
            if isPresenting {
                if let toView = ctx.view(forKey: .to) { container.addSubview(toView) }
                ctx.completeTransition(true)
            } else {
                if let fromView = ctx.view(forKey: .from) { fromView.removeFromSuperview() }
                ctx.completeTransition(true)
            }
        }
    }
}
