//
//  JXPhotoBrowser.swift
//  JXPhotoBrowser
//

import UIKit
import AVFoundation

// MARK: - Resource Model

/// 图片资源（原图 + 可选缩略图 + 可选视频）
public struct JXPhotoResource {
    /// 原图 URL（若为视频，可作为封面图）
    public let imageURL: URL
    
    /// 缩略图 URL（可选）
    public let thumbnailURL: URL?
    
    /// 视频 URL（可选，若存在则为视频资源）
    public let videoURL: URL?
    
    public init(imageURL: URL, thumbnailURL: URL? = nil, videoURL: URL? = nil) {
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
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
    
    /// 可选：浏览器在某个索引的源缩略图需要被隐藏/恢复时调用，业务方可根据索引自行控制对应视图的显隐（用于避免 Cell 复用导致的状态错乱）
    func photoBrowser(_ browser: JXPhotoBrowser, setOriginViewHidden hidden: Bool, at index: Int)
    
    /// 可选：为 Zoom 转场提供源缩略图视图（用于起点几何计算）。
    func photoBrowser(_ browser: JXPhotoBrowser, zoomOriginViewAt index: Int) -> UIView?
    
    /// 为 Zoom 转场提供一个临时 ZoomView（仅用于动画期间展示，完成后即移除）。
    /// - 参数 isPresenting: true 表示 present 转场，false 表示 dismiss 转场。
    /// - 返回值：需要业务方提前创建并配置内容的视图实例（未添加到任意父视图）。
    /// 若返回 nil，则将自动降级为 Fade 动画。
    func photoBrowser(_ browser: JXPhotoBrowser, zoomViewForItemAt index: Int, isPresenting: Bool) -> UIView?
    
    /// 提供 Cell 加载图片所需的资源（原图 + 可选缩略图）
    func photoBrowser(_ browser: JXPhotoBrowser, resourceForItemAt index: Int) -> JXPhotoResource?
    
    /// 提供 Cell 类，若返回 nil，则使用默认的 JXPhotoCell
    func photoBrowser(_ browser: JXPhotoBrowser, cellClassForItemAt index: Int) -> AnyClass?
    
    /// 长按当前资源的回调（用于业务方弹窗、保存等操作）
    /// - Parameters:
    ///   - index: 当前资源索引
    ///   - resource: 当前资源（图片 / 视频）
    ///   - sourceView: 触发长按的视图，便于弹窗锚点
    func photoBrowser(_ browser: JXPhotoBrowser, didLongPressItemAt index: Int, resource: JXPhotoResource?, sourceView: UIView)
}

public extension JXPhotoBrowserDelegate {
    func photoBrowser(_ browser: JXPhotoBrowser, willReuse cell: JXPhotoCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, didReuse cell: JXPhotoCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, setOriginViewHidden hidden: Bool, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, zoomOriginViewAt index: Int) -> UIView? { nil }
    func photoBrowser(_ browser: JXPhotoBrowser, zoomViewForItemAt index: Int, isPresenting: Bool) -> UIView? { nil }
    func photoBrowser(_ browser: JXPhotoBrowser, resourceForItemAt index: Int) -> JXPhotoResource? { nil }
    func photoBrowser(_ browser: JXPhotoBrowser, cellClassForItemAt index: Int) -> AnyClass? { nil }
    func photoBrowser(_ browser: JXPhotoBrowser, didLongPressItemAt index: Int, resource: JXPhotoResource?, sourceView: UIView) {}
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
    
    /// 当前显示的图片索引
    public private(set) var pageIndex: Int = 0 {
        didSet {
            if pageIndex != oldValue {
                // 恢复旧的
                delegate?.photoBrowser(self, setOriginViewHidden: false, at: oldValue)
                // 隐藏新的
                delegate?.photoBrowser(self, setOriginViewHidden: true, at: pageIndex)
            }
        }
    }
    
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
    
    /// 是否允许屏幕旋转（默认允许）
    public var allowsRotation: Bool = true
    
    
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
        cv.register(JXVideoCell.self, forCellWithReuseIdentifier: JXVideoCell.videoReuseIdentifier)
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
    
    /// 正在进行下拉交互的 Cell（避免滚动导致目标错误）
    private weak var interactiveDismissCell: JXPhotoCell?
    
    /// 下拉交互开始时的触摸点（用于计算跟随偏移）
    private var initialTouchPoint: CGPoint = .zero
    
    /// 下拉交互开始时的图片中心点
    private var initialImageCenter: CGPoint = .zero
    
    // MARK: - Lifecycle Methods
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        pageIndex = initialIndex
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
        delegate?.photoBrowser(self, setOriginViewHidden: true, at: pageIndex)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 页面消失时（如非交互关闭），尝试恢复
        // 注意：交互关闭时会由 Animator 处理恢复，这里只是兜底
        if let coordinator = transitionCoordinator {
            // 在转场结束后统一恢复，避免提前显示导致重影
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.photoBrowser(self, setOriginViewHidden: false, at: self.pageIndex)
            }
        } else {
            delegate?.photoBrowser(self, setOriginViewHidden: false, at: pageIndex)
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
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard realCount > 0 else { return }
        
        let currentVirtual = calculateCurrentVirtualIndex()
        let currentReal = realIndex(fromVirtual: currentVirtual)
        let targetVirtual = nearestVirtualIndex(for: currentReal, near: currentVirtual)
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.scrollToVirtualIndex(targetVirtual, size: size)
        }, completion: { [weak self] _ in
            self?.scrollToVirtualIndex(targetVirtual, size: size)
            self?.updateCurrentPageIndex()
        })
    }
    
    /// 是否允许自动旋转
    open override var shouldAutorotate: Bool {
        return allowsRotation
    }
    
    /// 支持的屏幕方向
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return allowsRotation ? .all : .portrait
    }
    
    // MARK: - Private Methods
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard let cell = visiblePhotoCell() else { return }
            interactiveDismissCell = cell
            collectionView.isScrollEnabled = false
            cell.scrollView.isScrollEnabled = false
            
            // 记录初始状态以计算跟随
            initialTouchPoint = gesture.location(in: cell.scrollView)
            if let imageView = cell.transitionImageView {
                initialImageCenter = imageView.center
            }
            
            // 确保源视图隐藏
            delegate?.photoBrowser(self, setOriginViewHidden: true, at: pageIndex)
            
        case .changed:
            guard let cell = interactiveDismissCell, let imageView = cell.transitionImageView else { return }
            let translation = gesture.translation(in: view)
            
            // 下拉时缩小；上拉时（负值）不放大，保持原大小但跟随位移
            let progress = translation.y / view.bounds.height
            let scale = translation.y > 0 ? max(0.5, 1 - abs(progress)) : 1.0
            
            // 计算让图片跟随手指的偏移量
            // 触摸点相对于图片中心的向量
            let vector = CGPoint(x: initialTouchPoint.x - initialImageCenter.x,
                                 y: initialTouchPoint.y - initialImageCenter.y)
            // 当图片缩小时，为了保持触摸点位置不变，需要补偿的位移
            // 公式：Offset = Vector * (1 - Scale)
            let adjustX = vector.x * (1 - scale)
            let adjustY = vector.y * (1 - scale)
            
            // 变换图片：Translation + Adjustment
            let transform = CGAffineTransform(translationX: translation.x + adjustX, y: translation.y + adjustY)
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
            
            // 只要有向下的速度则关闭
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
                    cell.scrollView.isScrollEnabled = true
                    self.interactiveDismissCell = nil
                }
            }
        default:
            collectionView.isScrollEnabled = true
            if let cell = interactiveDismissCell {
                cell.scrollView.isScrollEnabled = true
            }
            interactiveDismissCell = nil
        }
    }
    
    /// 根据滚动偏移量更新当前页索引
    private func updateCurrentPageIndex() {
        let virtualItem = calculateCurrentVirtualIndex()
        pageIndex = realIndex(fromVirtual: virtualItem)
    }
    
    /// 计算当前基于偏移量的虚拟索引
    private func calculateCurrentVirtualIndex() -> Int {
        let size = collectionView.bounds.size
        let offset = collectionView.contentOffset
        guard size.width > 0, size.height > 0 else { return 0 }
        
        var virtualItem: Int
        if scrollDirection == .horizontal {
            virtualItem = Int(round(offset.x / size.width))
        } else {
            virtualItem = Int(round(offset.y / size.height))
        }
        
        return max(0, min(virtualItem, virtualCount - 1))
    }

    /// 找到与当前虚拟索引最接近的同实索引虚拟项
    private func nearestVirtualIndex(for realIndex: Int, near currentVirtual: Int) -> Int {
        let count = realCount
        guard count > 0 else { return 0 }
        
        if !isLoopingEnabled { return realIndex }
        
        let block = currentVirtual / count
        var candidate = block * count + realIndex
        
        if candidate >= virtualCount, block > 0 {
            candidate = (block - 1) * count + realIndex
        }
        
        return max(0, min(candidate, virtualCount - 1))
    }
    
    /// 根据虚拟索引滚动到目标位置，保持当前项
    private func scrollToVirtualIndex(_ index: Int, size: CGSize) {
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout, layout.itemSize != size {
            layout.itemSize = size
            layout.invalidateLayout()
        }
        
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: scrollDirection.scrollPosition, animated: false)
        collectionView.layoutIfNeeded()
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
    
    /// Cell 触发的长按事件回调给业务方
    /// - Parameter cell: 触发长按的 Cell
    func handleLongPress(from cell: JXPhotoCell) {
        guard let index = cell.currentIndex else { return }
        let resource = cell.currentResource ?? delegate?.photoBrowser(self, resourceForItemAt: index)
        let sourceView = cell.transitionImageView ?? cell
        delegate?.photoBrowser(self, didLongPressItemAt: index, resource: resource, sourceView: sourceView)
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
        
        // 使用几何中心距离计算，确保在滚动中也能准确获取视觉中心的 Cell
        let viewCenter = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        
        return cells.min { lhs, rhs in
            let lhsCenter = lhs.convert(CGPoint(x: lhs.bounds.midX, y: lhs.bounds.midY), to: view)
            let rhsCenter = rhs.convert(CGPoint(x: rhs.bounds.midX, y: rhs.bounds.midY), to: view)
            
            let dl = hypot(lhsCenter.x - viewCenter.x, lhsCenter.y - viewCenter.y)
            let dr = hypot(rhsCenter.x - viewCenter.x, rhsCenter.y - viewCenter.y)
            return dl < dr
        }
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
            let virtualItem = calculateCurrentVirtualIndex()
            collectionView.scrollToItem(at: IndexPath(item: virtualItem, section: 0), at: scrollDirection.scrollPosition, animated: false)
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension JXPhotoBrowser: UICollectionViewDataSource, UICollectionViewDelegate {
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return virtualCount
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let real = realCount > 0 ? realIndex(fromVirtual: indexPath.item) : 0
        let cellClass: AnyClass? = delegate?.photoBrowser(self, cellClassForItemAt: real)
        
        // 默认为 JXPhotoCell
        let reuseIdentifier: String
        if cellClass == JXVideoCell.self {
            reuseIdentifier = JXVideoCell.videoReuseIdentifier
        } else {
            reuseIdentifier = JXPhotoCell.reuseIdentifier
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! JXPhotoCell
        cell.browser = self
        if realCount > 0 {
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
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPageIndex()
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateCurrentPageIndex()
        }
    }
    
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentPageIndex()
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
            // 只响应垂直向下的手势，且处于顶部
            return isAtTop && velocity.y > 0 && abs(velocity.y) > abs(velocity.x)
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
