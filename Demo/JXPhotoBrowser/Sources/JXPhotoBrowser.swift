//
//  JXPhotoBrowser.swift
//  JXPhotoBrowser
//

import UIKit
import AVFoundation

// MARK: - Data Source Protocol

public protocol JXPhotoBrowserDataSource: AnyObject {
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

    /// 可选：为指定索引提供用于 Zoom 转场的图片数据。
    /// 若返回 nil，则动画将回退使用业务方缩略图视图上的 image。
    func photoBrowser(_ browser: JXPhotoBrowser, zoomImageForItemAt index: Int) -> UIImage?
    
    /// 可选：为指定索引提供 Zoom 视图的 contentMode（由业务方设置）。
    /// 默认使用 .scaleAspectFit。
    func photoBrowser(_ browser: JXPhotoBrowser, zoomContentModeForItemAt index: Int) -> UIView.ContentMode
}

public extension JXPhotoBrowserDataSource {
    // 默认空实现，便于增量接入
    func photoBrowser(_ browser: JXPhotoBrowser, willReuse cell: JXPhotoCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, didReuse cell: JXPhotoCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoCell, at index: Int) {}

    func photoBrowser(_ browser: JXPhotoBrowser, zoomOriginViewAt index: Int) -> UIView? { nil }
    func photoBrowser(_ browser: JXPhotoBrowser, zoomImageForItemAt index: Int) -> UIImage? { nil }
    func photoBrowser(_ browser: JXPhotoBrowser, zoomContentModeForItemAt index: Int) -> UIView.ContentMode { .scaleAspectFit }
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

public final class JXPhotoBrowser: UIViewController {
    
    // MARK: - Public Properties
    
    /// 数据源代理
    public weak var dataSource: JXPhotoBrowserDataSource?
    
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
    
    /// 是否启用分页
    public var isPagingEnabled: Bool = true {
        didSet {
            if isViewLoaded {
                collectionView.isPagingEnabled = isPagingEnabled
            }
        }
    }
    
    /// 是否启用无限循环滚动
    public var isLoopingEnabled: Bool = true
    
    /// 转场动画类型
    public var transitionType: JXPhotoBrowserTransitionType = .fade
    
    // 已弃用：通过数据源方法 `zoomOriginViewAt` 提供源缩略图视图
    
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
        cv.register(JXPhotoCell.self, forCellWithReuseIdentifier: JXPhotoCell.reuseIdentifier)
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
    fileprivate var didScrollToInitial = false
    
    // MARK: - Lifecycle Methods
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCollectionView()
        applyCollectionViewConfig()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        view.addGestureRecognizer(tap)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didScrollToInitial {
            scrollToInitialIndex()
            didScrollToInitial = true
        }
    }
    
    public override func viewDidLayoutSubviews() {
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
    fileprivate func scrollToInitialIndex() {
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
    func visiblePhotoImageView() -> UIImageView? {
        let center = CGPoint(
            x: collectionView.bounds.midX + collectionView.contentOffset.x,
            y: collectionView.bounds.midY + collectionView.contentOffset.y
        )
        guard let idx = collectionView.indexPathForItem(at: center),
              let cell = collectionView.cellForItem(at: idx) as? JXPhotoCell else { return nil }
        return cell.transitionImageView
    }
    
    /// 当前真实索引（虚拟索引映射）
    func currentRealIndex() -> Int? {
        let center = CGPoint(
            x: collectionView.bounds.midX + collectionView.contentOffset.x,
            y: collectionView.bounds.midY + collectionView.contentOffset.y
        )
        guard let virtualItem = collectionView.indexPathForItem(at: center)?.item else { return nil }
        return realIndex(fromVirtual: virtualItem)
    }
    
    // MARK: - Public Methods
    
    /// 从指定视图控制器展示浏览器
    public func present(from vc: UIViewController) {
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

extension JXPhotoBrowser: UICollectionViewDataSource, UICollectionViewDelegate, JXPhotoCellLifecycleDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return virtualCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JXPhotoCell.reuseIdentifier, for: indexPath) as! JXPhotoCell
        cell.lifecycleDelegate = self
        if realCount > 0 {
            let real = realIndex(fromVirtual: indexPath.item)
            cell.currentIndex = real
            dataSource?.photoBrowser(self, didReuse: cell, at: real)
        } else {
            cell.currentIndex = nil
        }
        return cell
    }

    // 生命周期：Cell 即将显示
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? JXPhotoCell else { return }
        let real = realIndex(fromVirtual: indexPath.item)
        dataSource?.photoBrowser(self, willDisplay: cell, at: real)
    }

    // 生命周期：Cell 已消失
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? JXPhotoCell else { return }
        let real = realIndex(fromVirtual: indexPath.item)
        dataSource?.photoBrowser(self, didEndDisplaying: cell, at: real)
    }

    // 来自 Cell 的复用回调
    func photoCellWillReuse(_ cell: JXPhotoCell, lastIndex: Int?) {
        guard let last = lastIndex else { return }
        dataSource?.photoBrowser(self, willReuse: cell, at: last)
    }
}

// MARK: - Transition Animation

extension JXPhotoBrowser: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch transitionType {
        case .fade: return JXFadeAnimator(isPresenting: true)
        case .zoom: return JXZoomPresentAnimator()
        case .none: return JXNoneAnimator(isPresenting: true)
        }
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch transitionType {
        case .fade: return JXFadeAnimator(isPresenting: false)
        case .zoom: return JXZoomDismissAnimator()
        case .none: return JXNoneAnimator(isPresenting: false)
        }
    }
}
