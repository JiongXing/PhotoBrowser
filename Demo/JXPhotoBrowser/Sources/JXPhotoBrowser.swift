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

public typealias JXPhotoBrowserAnyCell = UICollectionViewCell & JXPhotoBrowserCellProtocol

public protocol JXPhotoBrowserDelegate: AnyObject {
    func numberOfItems(in browser: JXPhotoBrowser) -> Int
    
    func photoBrowser(_ browser: JXPhotoBrowser, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell
    
    func photoBrowser(_ browser: JXPhotoBrowser, willReuse cell: JXPhotoBrowserAnyCell, at index: Int)
    
    func photoBrowser(_ browser: JXPhotoBrowser, didReuse cell: JXPhotoBrowserAnyCell, at index: Int)
    
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoBrowserAnyCell, at index: Int)
    
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoBrowserAnyCell, at index: Int)
    
    func photoBrowser(_ browser: JXPhotoBrowser, setOriginViewHidden hidden: Bool, at index: Int)
    
    func photoBrowser(_ browser: JXPhotoBrowser, zoomOriginViewAt index: Int) -> UIView?
    
    func photoBrowser(_ browser: JXPhotoBrowser, zoomViewForItemAt index: Int, isPresenting: Bool) -> UIView?
}

public extension JXPhotoBrowserDelegate {
    func photoBrowser(_ browser: JXPhotoBrowser, willReuse cell: JXPhotoBrowserAnyCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, didReuse cell: JXPhotoBrowserAnyCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, willDisplay cell: JXPhotoBrowserAnyCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, didEndDisplaying cell: JXPhotoBrowserAnyCell, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, setOriginViewHidden hidden: Bool, at index: Int) {}
    func photoBrowser(_ browser: JXPhotoBrowser, zoomOriginViewAt index: Int) -> UIView? { nil }
    func photoBrowser(_ browser: JXPhotoBrowser, zoomViewForItemAt index: Int, isPresenting: Bool) -> UIView? { nil }
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
                // 仅在 Zoom 转场动画时，才对源视图进行显隐操作
                if transitionType == .zoom {
                    // 恢复旧的
                    delegate?.photoBrowser(self, setOriginViewHidden: false, at: oldValue)
                    // 隐藏新的
                    delegate?.photoBrowser(self, setOriginViewHidden: true, at: pageIndex)
                }
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
    
    /// Cell注册管理器（用于注册自定义Cell类）
    public let cellRegistry = JXPhotoBrowserCellRegistry.shared
    
    
    // MARK: - Private Properties
    
    /// 图片列表集合视图（对外只读）
    public private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = view.bounds.size
        print("layout.itemSize: \(layout.itemSize)")
        let cv = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.isPagingEnabled = true
        
        // 注册默认Cell
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
    
    
    /// 下拉交互开始时的触摸点（用于计算跟随偏移）
    private var initialTouchPoint: CGPoint = .zero
    
    /// 下拉交互开始时的图片中心点
    private var initialImageCenter: CGPoint = .zero
    
    /// 正在进行下拉交互的Cell（使用协议类型以支持自定义Cell）
    private weak var interactiveDismissCellProtocol: JXPhotoBrowserCellProtocol?
    
    // MARK: - Lifecycle Methods
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        pageIndex = initialIndex
        setupCollectionView()
        applyCollectionViewConfig()
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 仅在 Zoom 转场动画时，初始显示时隐藏源视图
        if transitionType == .zoom {
            delegate?.photoBrowser(self, setOriginViewHidden: true, at: pageIndex)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("viewDidAppear (async) collectionView frame: \(self.collectionView.frame)")
            print("viewDidAppear (async) collectionView bounds: \(self.collectionView.bounds)")
            print("viewDidAppear (async) collectionView contentOffset: \(self.collectionView.contentOffset)")
            print("viewDidAppear (async) collectionView contentSize: \(self.collectionView.contentSize)")
            let virtualIndex = self.calculateCurrentVirtualIndex()
            let realIndex = self.realIndex(fromVirtual: virtualIndex)
            print("viewDidAppear (async) current virtualIndex: \(virtualIndex), realIndex: \(realIndex)")
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 仅在 Zoom 转场动画时，页面消失时（如非交互关闭），尝试恢复
        // 注意：交互关闭时会由 Animator 处理恢复，这里只是兜底
        if transitionType == .zoom {
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
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        collectionView.frame = view.bounds
        
        print("viewDidLayoutSubviews view bounds: \(view.bounds)")
        print("viewDidLayoutSubviews collectionView frame: \(collectionView.frame)")
        print("viewDidLayoutSubviews collectionView bounds: \(collectionView.bounds)")
        print("viewDidLayoutSubviews collectionView contentOffset: \(collectionView.contentOffset)")
        print("viewDidLayoutSubviews collectionView contentSize: \(collectionView.contentSize)")
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let size = collectionView.bounds.size
            if size != .zero, layout.itemSize != size {
                layout.itemSize = size
                layout.invalidateLayout()
                print("viewDidLayoutSubviews update layout.itemSize: \(size)")
            }
        }
        
        scrollToInitialIndexIfNeeded()
    }
    
    /// 是否允许自动旋转（固定为 false，不支持设备旋转）
    open override var shouldAutorotate: Bool {
        return false
    }
    
    /// 支持的屏幕方向（固定为竖屏）
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // MARK: - Private Methods
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        // 垂直滚动模式下禁用下拉关闭手势，避免与列表滚动冲突
        if scrollDirection == .vertical { return }
        
        switch gesture.state {
        case .began:
            // 优先使用协议类型（支持自定义Cell），如果失败则使用JXPhotoCell（向后兼容）
            guard let cell = (visibleCell() ?? visiblePhotoCell()) else { return }
            interactiveDismissCellProtocol = cell
            collectionView.isScrollEnabled = false
            cell.interactiveScrollView?.isScrollEnabled = false
            
            // 记录初始状态以计算跟随
            let scrollView = cell.interactiveScrollView ?? collectionView
            initialTouchPoint = gesture.location(in: scrollView)
            if let imageView = cell.transitionImageView {
                initialImageCenter = imageView.center
            }
            
            // 仅在 Zoom 转场动画时，确保源视图隐藏
            if transitionType == .zoom {
                delegate?.photoBrowser(self, setOriginViewHidden: true, at: pageIndex)
            }
            
        case .changed:
            guard let cell = interactiveDismissCellProtocol, let imageView = cell.transitionImageView else { return }
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
            guard let cell = interactiveDismissCellProtocol, let imageView = cell.transitionImageView else {
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
                    cell.interactiveScrollView?.isScrollEnabled = true
                    self.interactiveDismissCellProtocol = nil
                }
            }
        default:
            collectionView.isScrollEnabled = true
            if let cell = interactiveDismissCellProtocol {
                cell.interactiveScrollView?.isScrollEnabled = true
            }
            interactiveDismissCellProtocol = nil
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
    open func scrollToInitialIndexIfNeeded() {
        guard didScrollToInitial == false else {
            return
        }
        
        let bounds = collectionView.bounds
        if bounds.size == .zero {
            print("scrollToInitialIndexIfNeeded skipped, collectionView bounds is zero")
            return
        }
        
        didScrollToInitial = true
        
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        
        let count = realCount
        guard count > 0 else {
            print("scrollToInitialIndexIfNeeded realCount is zero")
            return
        }
        
        let base = isLoopingEnabled ? (loopMultiplier / 2) * count : 0
        let target = base + max(0, min(initialIndex % count, count - 1))
        
        print("scrollToInitialIndexIfNeeded perform scroll, initialIndex = \(initialIndex), target = \(target)")
        let offset: CGPoint
        if scrollDirection == .horizontal {
            offset = CGPoint(x: CGFloat(target) * bounds.width, y: 0)
        } else {
            offset = CGPoint(x: 0, y: CGFloat(target) * bounds.height)
        }
        collectionView.setContentOffset(offset, animated: false)
        collectionView.layoutIfNeeded()
        
        pageIndex = initialIndex
        
        print("scrollToInitialIndexIfNeeded done, collectionView frame: \(collectionView.frame)")
        print("scrollToInitialIndexIfNeeded contentOffset: \(collectionView.contentOffset)")
        print("scrollToInitialIndexIfNeeded contentSize: \(collectionView.contentSize)")
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
    
    /// 当前展示中的 Cell（协议类型，支持自定义Cell）
    open func visibleCell() -> JXPhotoBrowserCellProtocol? {
        return visiblePhotoCell()
    }
    
    // MARK: - Setup & Configuration
    
    /// 注册自定义Cell类
    /// - Parameters:
    ///   - cellClass: 要注册的Cell类（必须实现JXPhotoBrowserCellProtocol协议）
    ///   - reuseIdentifier: 可选的复用标识符，如果为nil则自动生成
    /// - Returns: 实际使用的reuseIdentifier
    /// - Note: 建议在创建JXPhotoBrowser实例后、设置delegate之前调用此方法
    @discardableResult
    public func register(_ cellClass: AnyClass, forReuseIdentifier reuseIdentifier: String? = nil) -> String {
        // 注册到管理器
        let identifier = cellRegistry.register(cellClass, forReuseIdentifier: reuseIdentifier)
        collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
        return identifier
    }
    
    /// 获取复用的Cell
    /// - Parameters:
    ///   - reuseIdentifier: 复用标识符
    ///   - indexPath: 索引路径
    /// - Returns: 符合JXPhotoBrowserCellProtocol协议的Cell
    /// - Note: 如果dequeue的Cell不符合协议要求，会触发断言失败
    public func dequeueReusableCell(withReuseIdentifier reuseIdentifier: String, for indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let protocolCell = cell as? JXPhotoBrowserAnyCell else {
            fatalError("Cell with identifier '\(reuseIdentifier)' must conform to JXPhotoBrowserCellProtocol")
        }
        return protocolCell
    }
    
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
        print("collectionView cellForItemAt indexPath: \(indexPath)")
        guard let delegate = delegate else {
            print("collectionView cellForItemAt indexPath: delegate is nil")
            return collectionView.dequeueReusableCell(withReuseIdentifier: JXPhotoCell.reuseIdentifier, for: indexPath)
        }
        let cell = delegate.photoBrowser(self, cellForItemAt: real, at: indexPath)
        cell.browser = self
        if realCount > 0 {
            cell.currentIndex = real
            delegate.photoBrowser(self, didReuse: cell, at: real)
        } else {
            cell.currentIndex = nil
        }
        print("collectionView cellForItemAt indexPath: cell is not nil")
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let protocolCell = cell as? JXPhotoBrowserAnyCell else { return }
        let real = realIndex(fromVirtual: indexPath.item)
        delegate?.photoBrowser(self, willDisplay: protocolCell, at: real)
    }
    
    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let protocolCell = cell as? JXPhotoBrowserAnyCell else { return }
        let real = realIndex(fromVirtual: indexPath.item)
        delegate?.photoBrowser(self, didEndDisplaying: protocolCell, at: real)
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
            if scrollDirection == .vertical { return false }
            
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
