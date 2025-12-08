//
//  JXPhotoBrowser.swift
//  JXPhotoBrowser
//

import UIKit
import AVFoundation

// MARK: - Resource Model

/// 图片资源（原图 + 可选缩略图）
public struct JXPhotoResource {
    /// 原图 URL
    public let imageURL: URL
    
    /// 缩略图 URL（可选）
    public let thumbnailURL: URL?
    
    public init(imageURL: URL, thumbnailURL: URL? = nil) {
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
    }
}

// MARK: - Delegate Protocol

public protocol JXPhotoBrowserDelegate: AnyObject {
    /// 返回项目总数
    func numberOfItems(in browser: JXPhotoBrowser) -> Int
    
    /// 生命周期：Cell 即将复用（传入上一次对应的 index）
    func photoBrowser(_ browser: JXPhotoBrowser, willReuse cell: JXPhotoCell, at index: Int)
    /// 生命周期：Cell 复用完成（已关联到新的 index）
    func photoBrowser(_ browser: JXPhotoBrowser, didReuse cell: JXPhotoCell, at index: Int)
    /// 生命周期：Cell 即将显示
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoCell, at index: Int)
    /// 生命周期：Cell 已消失
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoCell, at index: Int)
    
    /// 可选：为 Zoom 转场提供源缩略图视图（用于起点几何计算）。
    func photoBrowser(_ browser: JXPhotoBrowser, zoomOriginViewAt index: Int) -> UIView?
    
    /// 为 Zoom 转场提供一个临时 ZoomView（仅用于动画期间展示，完成后即移除）。
    /// - 参数 isPresenting: true 表示 present 转场，false 表示 dismiss 转场。
    /// - 返回值：需要业务方提前创建并配置内容的视图实例（未添加到任意父视图）。
    /// 若返回 nil，则将自动降级为 Fade 动画。
    func photoBrowser(_ browser: JXPhotoBrowser, zoomViewForItemAt index: Int, isPresenting: Bool) -> UIView?
    
    /// 提供 Cell 加载图片所需的资源（原图 + 可选缩略图）
    func photoBrowser(_ browser: JXPhotoBrowser, resourceForItemAt index: Int) -> JXPhotoResource?
}

public extension JXPhotoBrowserDelegate {
    // 默认空实现，便于增量接入
    func photoBrowser(_ browser: JXPhotoBrowser, willReuse cell: JXPhotoCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, didReuse cell: JXPhotoCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoCell, at index: Int) {}
    
    func photoBrowser(_ browser: JXPhotoBrowser, zoomOriginViewAt index: Int) -> UIView? { nil }
    func photoBrowser(_ browser: JXPhotoBrowser, zoomViewForItemAt index: Int, isPresenting: Bool) -> UIView? { nil }
    
    func photoBrowser(_ browser: JXPhotoBrowser, resourceForItemAt index: Int) -> JXPhotoResource? { nil }
}

// MARK: - Enums

public enum JXPhotoBrowserTransitionType {
    case fade, zoom, none
}

public enum JXPhotoBrowserScrollDirection {
    case horizontal, vertical
    
    var flowDirection: UICollectionView.ScrollDirection {
        self == .horizontal ? .horizontal : .vertical
    }
    
    var scrollPosition: UICollectionView.ScrollPosition {
        self == .horizontal ? .centeredHorizontally : .centeredVertically
    }
}

// MARK: - Main Browser Class

open class JXPhotoBrowser: UIViewController {
    
    // MARK: - Public Properties
    
    /// 浏览器代理
    public weak var delegate: JXPhotoBrowserDelegate?
    
    /// 初始显示的图片索引
    public var initialIndex: Int = 0
    
    /// 滚动方向（水平或垂直）
    public var scrollDirection: JXPhotoBrowserScrollDirection = .horizontal {
        didSet {
            if isViewLoaded {
                applyCollectionViewConfig()
            }
        }
    }
    
    /// 是否启用无限循环滚动
    public var isLoopingEnabled: Bool = true
    
    /// 转场动画类型
    public var transitionType: JXPhotoBrowserTransitionType = .fade
    
    
    // MARK: - Private Properties
    
    /// 图片列表集合视图（对外只读）
    public private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = view.bounds.size
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.isPagingEnabled = true
        cv.register(JXPhotoCell.self, forCellWithReuseIdentifier: JXPhotoCell.reuseIdentifier)
        return cv
    }()
    
    /// 无限循环倍数
    private let loopMultiplier: Int = 1000
    
    /// 真实数据源数量
    private var realCount: Int {
        delegate?.numberOfItems(in: self) ?? 0
    }
    
    /// 虚拟数据源数量（用于无限循环）
    private var virtualCount: Int {
        isLoopingEnabled ? realCount * loopMultiplier : realCount
    }
    
    /// 是否已滚动到初始位置（避免重复滚动）
    fileprivate var didScrollToInitial = false
    
    /// 交互手势
    private var panGesture: UIPanGestureRecognizer!
    
    /// 当前被隐藏的源视图（用于保持“抽离”效果）
    private weak var currentHiddenView: UIView?
    
    /// 正在进行下拉交互的 Cell（避免滚动导致目标错误）
    private weak var interactiveDismissCell: JXPhotoCell?
    
    // MARK: - Lifecycle Methods
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCollectionView()
        applyCollectionViewConfig()
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didScrollToInitial {
            scrollToInitialIndex()
            didScrollToInitial = true
        }
        // 初始显示时隐藏源视图
        if let cell = visiblePhotoCell(), let index = cell.currentIndex {
            updateHiddenOriginView(at: index)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 页面消失时（如非交互关闭），尝试恢复
        // 注意：交互关闭时会由 Animator 处理恢复，这里只是兜底
        if transitionCoordinator == nil {
             currentHiddenView?.isHidden = false
        }
    }
    
    open override func viewDidLayoutSubviews() {
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
    
    /// 更新隐藏的源视图
    private func updateHiddenOriginView(at index: Int) {
        let newView = delegate?.photoBrowser(self, zoomOriginViewAt: index)
        
        // 如果相同则不处理
        if newView === currentHiddenView { return }
        
        // 恢复之前的
        if let old = currentHiddenView {
            old.isHidden = false
        }
        
        // 隐藏当前的
        if let view = newView {
            view.isHidden = true
            currentHiddenView = view
        } else {
            currentHiddenView = nil
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard let cell = visiblePhotoCell() else { return }
            interactiveDismissCell = cell
            collectionView.isScrollEnabled = false
            
            // 确保源视图隐藏
            if let index = cell.currentIndex {
                updateHiddenOriginView(at: index)
            }
            
        case .changed:
            guard let cell = interactiveDismissCell, let imageView = cell.transitionImageView else { return }
            let translation = gesture.translation(in: view)
            
            // 下拉时缩小；上拉时（负值）不放大，保持原大小但跟随位移
            let progress = translation.y / view.bounds.height
            let scale = translation.y > 0 ? max(0.5, 1 - abs(progress)) : 1.0
            
            // 变换图片
            let transform = CGAffineTransform(translationX: translation.x, y: translation.y)
                .scaledBy(x: scale, y: scale)
            imageView.transform = transform
            
            // 背景透明度：只有下拉时才变透明
            let alpha = translation.y > 0 ? max(0, 1 - abs(progress) * 1.5) : 1.0
            view.backgroundColor = UIColor.black.withAlphaComponent(alpha)
            
        case .ended, .cancelled:
            guard let cell = interactiveDismissCell, let imageView = cell.transitionImageView else {
                collectionView.isScrollEnabled = true
                return
            }
            
            let velocity = gesture.velocity(in: view)
            let translation = gesture.translation(in: view)
            
            // 松手时有向下的速度则关闭
            let shouldDismiss = velocity.y > 10
            if shouldDismiss {
                dismissSelf()
                // 不恢复 ScrollEnabled，直到页面消失
            } else {
                // 恢复
                UIView.animate(withDuration: 0.25, animations: {
                    imageView.transform = .identity
                    self.view.backgroundColor = .black
                }) { _ in
                    self.collectionView.isScrollEnabled = true
                    self.interactiveDismissCell = nil
                }
            }
        default:
            collectionView.isScrollEnabled = true
            interactiveDismissCell = nil
        }
    }

    /// 将虚拟索引转换为真实索引
    open func realIndex(fromVirtual index: Int) -> Int {
        let count = realCount
        guard count > 0 else { return 0 }
        return index % count
    }
    
    /// 滚动到初始索引位置
    open func scrollToInitialIndex() {
        let count = realCount
        guard count > 0 else { return }
        let base = isLoopingEnabled ? (loopMultiplier / 2) * count : 0
        let target = base + max(0, min(initialIndex % count, count - 1))
        collectionView.scrollToItem(at: IndexPath(item: target, section: 0), at: scrollDirection.scrollPosition, animated: false)
    }
    
    /// 关闭浏览器
    @objc open func dismissSelf() {
        dismiss(animated: transitionType != .none, completion: nil)
    }
    
    // MARK: - Public Methods
    
    /// 从指定视图控制器展示浏览器
    open func present(from vc: UIViewController) {
        modalPresentationStyle = .overFullScreen
        if transitionType != .none { transitioningDelegate = self }
        vc.present(self, animated: transitionType != .none, completion: nil)
    }
    
    /// 供转场动画调用：在展示动画开始前，尽量让初始 Cell 就绪
    /// - 做法：强制布局、刷新数据并滚动到初始索引，然后再次布局
    /// - 目的：避免在 Present 阶段无法拿到目标 Cell 导致的 `destIV == nil`
    open func prepareForPresentTransitionIfNeeded() {
        view.layoutIfNeeded()
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        if !didScrollToInitial {
            scrollToInitialIndex()
            didScrollToInitial = true
            collectionView.layoutIfNeeded()
        }
    }
    
    /// 当前展示中的 PhotoCell（用于转场目标等）
    open func visiblePhotoCell() -> JXPhotoCell? {
        let cells = collectionView.visibleCells.compactMap { $0 as? JXPhotoCell }
        guard !cells.isEmpty else { return nil }

        let center = CGPoint(
            x: collectionView.bounds.midX + collectionView.contentOffset.x,
            y: collectionView.bounds.midY + collectionView.contentOffset.y
        )

        let nearestCell = cells.min { lhs, rhs in
            let dl = hypot(lhs.center.x - center.x, lhs.center.y - center.y)
            let dr = hypot(rhs.center.x - center.x, rhs.center.y - center.y)
            return dl < dr
        }

        return nearestCell
    }
    
    // MARK: - Setup & Configuration
    
    /// 添加并约束集合视图
    open func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    /// 根据当前属性应用集合视图配置（支持运行时切换）
    open func applyCollectionViewConfig() {
        // 分页固定开启
        collectionView.isPagingEnabled = true
        
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
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return virtualCount
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JXPhotoCell.reuseIdentifier, for: indexPath) as! JXPhotoCell
        cell.browser = self
        if realCount > 0 {
            let real = realIndex(fromVirtual: indexPath.item)
            cell.currentIndex = real
            delegate?.photoBrowser(self, didReuse: cell, at: real)
        } else {
            cell.currentIndex = nil
        }
        return cell
    }
    
    // 生命周期：Cell 即将显示
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? JXPhotoCell else { return }
        let real = realIndex(fromVirtual: indexPath.item)
        delegate?.photoBrowser(self, willDisplay: cell, at: real)
    }
    
    // 生命周期：Cell 已消失
    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? JXPhotoCell else { return }
        let real = realIndex(fromVirtual: indexPath.item)
        delegate?.photoBrowser(self, didEndDisplaying: cell, at: real)
    }
    
    // （生命周期代理已移除，复用与点击关闭由 Cell 内部处理）
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let center = CGPoint(
            x: collectionView.bounds.midX + collectionView.contentOffset.x,
            y: collectionView.bounds.midY + collectionView.contentOffset.y
        )
        if let indexPath = collectionView.indexPathForItem(at: center) {
            let real = realIndex(fromVirtual: indexPath.item)
            updateHiddenOriginView(at: real)
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension JXPhotoBrowser: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture {
            guard let cell = visiblePhotoCell() else { return false }
            // 只有在未缩放且处于顶部时才响应下拉
            let isZoomed = cell.scrollView.zoomScale > 1.0 + 0.01
            // 允许一定误差
            let isAtTop = cell.scrollView.contentOffset.y <= 1.0
            
            if isZoomed { return false }
            
            let velocity = panGesture.velocity(in: view)
            // 只响应垂直向下的手势
            return velocity.y > 0 && abs(velocity.y) > abs(velocity.x)
        }
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 允许与 ScrollView 滚动共存
        return true
    }
}

// MARK: - Transition Animation

extension JXPhotoBrowser: UIViewControllerTransitioningDelegate {
    
    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch transitionType {
        case .fade: return JXFadeAnimator(isPresenting: true)
        case .zoom: return JXZoomPresentAnimator()
        case .none: return JXNoneAnimator(isPresenting: true)
        }
    }
    
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch transitionType {
        case .fade: return JXFadeAnimator(isPresenting: false)
        case .zoom: return JXZoomDismissAnimator()
        case .none: return JXNoneAnimator(isPresenting: false)
        }
    }
}
