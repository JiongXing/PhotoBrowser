//
//  JXPhotoBrowserViewController.swift
//  JXPhotoBrowser
//

import UIKit

open class JXPhotoBrowserViewController: UIViewController {
    
    // MARK: - Public Properties
    
    /// 浏览器代理
    public weak var delegate: JXPhotoBrowserDelegate?
    
    /// 当前显示的图片索引
    public private(set) var pageIndex: Int = 0 {
        didSet {
            if pageIndex != oldValue, !isSynchronizingData {
                // 仅在 Zoom 转场动画时，才对源视图进行显隐操作
                if transitionType == .zoom {
                    hideCurrentThumbnail()
                }
                // 通知所有 Overlay 页码变化
                overlays.forEach { $0.didChangedPageIndex(pageIndex) }
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
    public var isLoopingEnabled: Bool = true {
        didSet {
            guard oldValue != isLoopingEnabled, isViewLoaded else { return }
            reloadForLoopingChange()
        }
    }
    
    /// 转场动画类型
    public var transitionType: JXPhotoBrowserTransitionType = .fade
    
    /// 图片之间的间距（默认 0）
    public var itemSpacing: CGFloat = 0 {
        didSet {
            if !itemSpacing.isFinite || itemSpacing < 0 {
                itemSpacing = 0
                return
            }
            if isViewLoaded {
                applyCollectionViewConfig()
            }
        }
    }
    
    /// 已装载的 Overlay 组件列表（默认为空，不装载任何组件）
    public private(set) var overlays: [JXPhotoBrowserOverlay] = []
    
    /// 是否启用自动轮播（默认 false）
    /// 自动轮播会在到达最后一页后自动停止
    public var isAutoPlayEnabled: Bool = false {
        didSet {
            guard isAutoPlayEnabled != oldValue else { return }
            if isAutoPlayEnabled {
                startAutoPlayIfNeeded()
            } else {
                stopAutoPlay()
            }
        }
    }

    /// 是否启用下拉关闭手势。内嵌 Banner 场景应设为 false
    public var isDismissGestureEnabled: Bool = true {
        didSet {
            if !isDismissGestureEnabled { resetDismissInteraction(animated: false) }
        }
    }
    
    /// 自动轮播间隔时间（默认 3.0 秒）
    public var autoPlayInterval: TimeInterval {
        get { configuredAutoPlayInterval }
        set {
            configuredAutoPlayInterval = newValue.isFinite ? max(0.5, newValue) : 0.5
            if isAutoPlayEnabled {
                stopAutoPlay()
                startAutoPlayIfNeeded()
            }
        }
    }
        
    // MARK: - Private Properties
    
    /// 自动轮播定时器
    private var autoPlayTimer: Timer?

    private var configuredAutoPlayInterval: TimeInterval = 3.0

    private var isProgrammaticScrollAnimating = false

    /// 正在进行的程序化滚动（自动轮播 / scrollToPage）目标虚拟索引，用于尺寸过渡时判断应保留哪一页
    private var programmaticScrollTargetVirtual: Int?

    /// 当前尺寸转场的最新目标。刷新和导航直接更新它，完成回调不持有旧页码。
    private final class SizeTransition {
        var pageIndex: Int?
        var cells: [ObjectIdentifier: JXZoomImageCell] = [:]
        let wasScrollEnabled: Bool

        init(pageIndex: Int, wasScrollEnabled: Bool) {
            self.pageIndex = pageIndex
            self.wasScrollEnabled = wasScrollEnabled
        }
    }

    private var sizeTransition: SizeTransition?

    private var isSynchronizingData = false
    private var isDisappearing = false

    private final class HiddenThumbnail {
        weak var delegate: JXPhotoBrowserDelegate?
        weak var view: UIView?
        let index: Int
        let wasHidden: Bool
        let restoration: (() -> Void)?

        init(delegate: JXPhotoBrowserDelegate, view: UIView?, index: Int, restoration: (() -> Void)?) {
            self.delegate = delegate
            self.view = view
            self.index = index
            self.wasHidden = view?.isHidden ?? false
            self.restoration = restoration
        }
    }

    private var hiddenThumbnail: HiddenThumbnail?

    private var displayedRealIndexes: [ObjectIdentifier: Int] = [:]
    
    /// 用户是否正在手动滚动（用于暂停自动轮播）
    private var isUserInteracting: Bool = false
    
    /// 图片列表集合视图（对外只读）
    public private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.isPagingEnabled = true
        
        // 注册默认Cell
        cv.register(JXZoomImageCell.self, forCellWithReuseIdentifier: JXZoomImageCell.reuseIdentifier)
        
        return cv
    }()
    
    /// 无限循环倍数
    private let loopMultiplier: Int = 10
    
    /// 真实数据源数量
    private var realCount: Int = 0
    
    /// 虚拟数据源数量（用于无限循环）
    private var virtualCount: Int {
        isLoopingEnabled ? realCount * loopMultiplier : realCount
    }
    
    /// 是否已滚动到初始位置（避免重复滚动）
    fileprivate var didScrollToInitial = false
    
    /// 交互手势
    private var panGesture: UIPanGestureRecognizer!
    
    private final class DismissInteraction {
        let cell: JXPhotoBrowserAnyCell
        let touchPoint: CGPoint
        let imageCenter: CGPoint
        let imageTransform: CGAffineTransform
        let scrollEnabled: Bool
        let viewClips: Bool
        let collectionClips: Bool
        let backgroundColor: UIColor?

        init(cell: JXPhotoBrowserAnyCell, imageView: UIImageView, touchPoint: CGPoint, browser: JXPhotoBrowserViewController) {
            self.cell = cell
            self.touchPoint = touchPoint
            imageCenter = imageView.center
            imageTransform = imageView.transform
            scrollEnabled = browser.collectionView.isScrollEnabled
            viewClips = browser.view.clipsToBounds
            collectionClips = browser.collectionView.clipsToBounds
            backgroundColor = browser.view.backgroundColor
        }
    }

    private var dismissInteraction: DismissInteraction?
    
    // MARK: - Lifecycle Methods
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCollectionView()
        applyCollectionViewConfig()
        reloadData(preservingCurrentPage: false)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        // 安装在 viewDidLoad 之前通过 addOverlay 注册的组件
        overlays.forEach { installOverlay($0) }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isDisappearing = false
        resetDismissInteraction(animated: false)
        
        // 仅在 Zoom 转场动画时，初始显示时隐藏源视图
        if transitionType == .zoom {
            hideCurrentThumbnail()
        }
        
        // 启动自动轮播
        startAutoPlayIfNeeded()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isDisappearing = true
        // 停止自动轮播
        stopAutoPlay()
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        resetDismissInteraction(animated: false)
        if isBeingDismissed || isMovingFromParent || (presentingViewController == nil && parent == nil) {
            restoreThumbnail()
        }
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // 在布局前设置 frame，确保 collectionView 有正确的尺寸
        // 有间距时，扩展 collectionView 尺寸，使 bounds = itemSize + spacing，确保分页正常
        let targetFrame = calculateCollectionViewFrame()
        if collectionView.frame != targetFrame {
            collectionView.frame = targetFrame
        }
    }
    
    /// 计算 collectionView 的 frame
    /// 扩展尺寸使 bounds = itemSize + spacing，确保 isPagingEnabled 分页单位正确
    private func calculateCollectionViewFrame() -> CGRect {
        var frame = view.bounds
        if scrollDirection == .horizontal {
            frame.size.width += itemSpacing
        } else {
            frame.size.height += itemSpacing
        }
        return frame
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 由于已实现 UICollectionViewDelegateFlowLayout，系统会自动调用代理方法获取 itemSize
        // 这里只需要在布局变化时触发重新布局
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.invalidateLayout()
        }
        
        scrollToInitialIndexIfNeeded()
        
        // 通知所有 Overlay 刷新数据（布局变化后更新位置和内容）
        let count = realCount
        overlays.forEach { $0.reloadData(numberOfItems: count, pageIndex: pageIndex) }
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        resetDismissInteraction(animated: false)

        // 尺寸变化（旋转、分屏等）会改变 itemSize，但 collectionView 不会自动保持当前页的 contentOffset，
        // 需要在过渡动画中重新滚动到目标位置
        guard didScrollToInitial, realCount > 0 else { return }

        // pageIndex 仅在拖拽/减速/程序化滚动结束时才更新，尺寸变化发生在滚动过程中时可能仍是旧值。
        // 若存在进行中的程序化滚动（如自动轮播），应保留其目标页，避免回退到旧页；
        // 否则在旧布局仍然有效时，按当前 contentOffset 换算出的几何居中页，兼容拖拽/减速中的场景
        let preservedReal: Int
        if isProgrammaticScrollAnimating, let targetVirtual = programmaticScrollTargetVirtual {
            preservedReal = realIndex(fromVirtual: targetVirtual)
        } else {
            preservedReal = realIndex(fromVirtual: calculateCurrentVirtualIndex())
        }
        // 若系统开始另一次尺寸转场，先释放上一轮的 Cell 布局状态。
        if let previous = sizeTransition {
            finishSizeTransition(previous)
        }
        let transition = SizeTransition(pageIndex: preservedReal, wasScrollEnabled: collectionView.isScrollEnabled)
        sizeTransition = transition
        stopAutoPlay()

        // 停止旧拖拽、减速和程序化滚动，不依赖被打断动画的完成回调。
        collectionView.isScrollEnabled = false
        collectionView.setContentOffset(collectionView.contentOffset, animated: false)
        isUserInteracting = false
        isProgrammaticScrollAnimating = false
        programmaticScrollTargetVirtual = nil

        collectionView.visibleCells.forEach { prepareCellForSizeTransition($0) }

        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self, self.sizeTransition === transition else { return }
            // 定位不继承系统的滚动动画，图片几何则在 coordinator 的动画中更新。
            UIView.performWithoutAnimation {
                self.view.layoutIfNeeded()
                self.alignPageForSizeTransition(transition)
            }
            transition.cells.values.forEach { $0.applySizeTransition(to: self.view.bounds.size) }
        }, completion: { [weak self] _ in
            guard let self = self, self.sizeTransition === transition else { return }
            UIView.performWithoutAnimation {
                self.alignPageForSizeTransition(transition)
                self.finishSizeTransition(transition)
            }
            self.startAutoPlayIfNeeded()
        })
    }

    private func prepareCellForSizeTransition(_ cell: UICollectionViewCell) {
        guard let transition = sizeTransition, let cell = cell as? JXZoomImageCell else { return }
        transition.cells[ObjectIdentifier(cell)] = cell
        cell.prepareForSizeTransition()
    }

    private func alignPageForSizeTransition(_ transition: SizeTransition) {
        collectionView.collectionViewLayout.invalidateLayout()
        guard let target = transition.pageIndex, (0..<realCount).contains(target) else {
            collectionView.layoutIfNeeded()
            return
        }
        collectionView.scrollToItem(at: IndexPath(item: centeredVirtualIndex(for: target), section: 0), at: scrollDirection.scrollPosition, animated: false)
        collectionView.layoutIfNeeded()
        // 宿主可在 Cell 生命周期回调中再次刷新或导航。
        if sizeTransition === transition, transition.pageIndex == target {
            pageIndex = target
        }
    }

    private func finishSizeTransition(_ transition: SizeTransition) {
        sizeTransition = nil
        transition.cells.values.forEach { $0.finishSizeTransition() }
        collectionView.isScrollEnabled = transition.wasScrollEnabled
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
    
    /// 计算整页 Cell 尺寸
    private func calculateItemSize() -> CGSize {
        let viewSize = view.bounds.size
        if viewSize.width > 0 && viewSize.height > 0 {
            return viewSize
        }
        
        return UIScreen.main.bounds.size
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard isDismissGestureEnabled else { return }
        // 垂直滚动模式下禁用下拉关闭手势，避免与列表滚动冲突
        if scrollDirection == .vertical { return }
        
        switch gesture.state {
        case .began:
            guard dismissInteraction == nil, sizeTransition == nil, !isProgrammaticScrollAnimating,
                  let cell = visibleCell(), cell.canBeginDismissInteraction,
                  let imageView = cell.transitionImageView, let container = imageView.superview else { return }
            stopAutoPlay()
            dismissInteraction = DismissInteraction(cell: cell, imageView: imageView,
                                                    touchPoint: gesture.location(in: container), browser: self)
            collectionView.isScrollEnabled = false
            view.clipsToBounds = false
            collectionView.clipsToBounds = false
            cell.photoBrowserDismissInteractionDidChange(isInteracting: true)
            
            // 仅在 Zoom 转场动画时，确保源视图隐藏
            if transitionType == .zoom {
                hideCurrentThumbnail()
            }
            
        case .changed:
            guard let interaction = dismissInteraction, let imageView = interaction.cell.transitionImageView else { return }
            let translation = gesture.translation(in: view)
            
            // 下拉时缩小；上拉时（负值）不放大，保持原大小但跟随位移
            let progress = translation.y / view.bounds.height
            let scale = translation.y > 0 ? max(0.5, 1 - abs(progress)) : 1.0
            
            // 计算让图片跟随手指的偏移量
            // 触摸点相对于图片中心的向量
            let vector = CGPoint(x: interaction.touchPoint.x - interaction.imageCenter.x,
                                 y: interaction.touchPoint.y - interaction.imageCenter.y)
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
            guard dismissInteraction?.cell.transitionImageView != nil else {
                resetDismissInteraction(animated: false)
                return
            }
            
            let velocity = gesture.velocity(in: view)
            let translation = gesture.translation(in: view)

            // 下拉超过屏幕高度 1/4，或松手时速度足够快，则关闭；手势被取消时不关闭
            let shouldDismiss = gesture.state == .ended
                && (translation.y > view.bounds.height * 0.25 || velocity.y > 500)
            
            if shouldDismiss {
                dismissSelf()
                // 不恢复 ScrollEnabled，直到页面消失
            } else {
                resetDismissInteraction(animated: true)
            }
        default:
            resetDismissInteraction(animated: false)
        }
    }
    
    /// 根据滚动偏移量更新当前页索引
    private func updateCurrentPageIndex() {
        let virtualItem = calculateCurrentVirtualIndex()
        pageIndex = realIndex(fromVirtual: virtualItem)
    }

    /// 循环模式下，若当前虚拟索引偏离中间块，无动画重定位回中间块对应位置，避免连续单向滑动耗尽虚拟数据源导致循环终止
    /// 重定位不改变真实页码 pageIndex，对用户不可见
    private func recenterForLoopingIfNeeded() {
        guard isLoopingEnabled else { return }

        let count = realCount
        guard count > 0 else { return }

        let currentVirtual = calculateCurrentVirtualIndex()
        let middleBlock = loopMultiplier / 2
        let block = currentVirtual / count

        // 偏离中间块时才重定位
        guard block != middleBlock else { return }

        let target = centeredVirtualIndex(for: pageIndex)
        collectionView.scrollToItem(at: IndexPath(item: target, section: 0), at: scrollDirection.scrollPosition, animated: false)
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

        return JXPhotoBrowserPaging.nearestVirtualIndex(
            for: realIndex,
            near: currentVirtual,
            count: count,
            virtualCount: virtualCount
        )
    }

    /// 返回真实页在循环数据源中间块的虚拟索引；非循环模式直接返回真实索引
    private func centeredVirtualIndex(for realIndex: Int) -> Int {
        guard isLoopingEnabled else { return realIndex }
        return JXPhotoBrowserPaging.centeredVirtualIndex(
            for: realIndex,
            count: realCount,
            loopMultiplier: loopMultiplier
        )
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
        
        guard view.window != nil else {
            return
        }
        
        let bounds = collectionView.bounds
        if bounds.size == .zero {
            return
        }

        let count = realCount
        guard count > 0 else {
            return
        }

        let safeInitialIndex = JXPhotoBrowserPaging.normalizedInitialIndex(initialIndex, count: count, looping: isLoopingEnabled)

        let target = centeredVirtualIndex(for: safeInitialIndex)
        
        collectionView.scrollToItem(at: IndexPath(item: target, section: 0), at: scrollDirection.scrollPosition, animated: false)
        didScrollToInitial = true
        pageIndex = safeInitialIndex
        
        // 初始定位完成后，启动自动轮播（支持嵌入式使用场景）
        startAutoPlayIfNeeded()
    }
    
    /// 循环模式变更时重新加载数据并调整位置
    private func reloadForLoopingChange() {
        resetDismissInteraction(animated: false)
        stopAutoPlay()
        let currentReal = pageIndex
        collectionView.reloadData()
        
        let count = realCount
        guard count > 0 else { return }
        
        // 计算新的目标索引
        let targetIndex = centeredVirtualIndex(for: min(currentReal, count - 1))
        
        collectionView.scrollToItem(at: IndexPath(item: targetIndex, section: 0), at: scrollDirection.scrollPosition, animated: false)
        startAutoPlayIfNeeded()
    }
    
    /// 关闭浏览器
    @objc open func dismissSelf() {
        dismiss(animated: transitionType != .none) { [weak self] in
            self?.resetDismissInteraction(animated: false)
        }
    }
    
    // MARK: - Auto Play
    
    /// 判断是否可以启动自动轮播
    private var canStartAutoPlay: Bool {
        guard isAutoPlayEnabled,
              sizeTransition == nil,
              dismissInteraction == nil,
              !isDisappearing,
              !isSynchronizingData,
              !isUserInteracting,
              !isProgrammaticScrollAnimating,
              didScrollToInitial,
              isViewLoaded,
              view.window != nil else { return false }
        
        let count = realCount
        guard count > 1 else { return false }
        
        // 开启无限循环时，始终可以自动轮播
        if isLoopingEnabled { return true }
        
        // 未开启无限循环时，仅当未到达最后一页时可以轮播
        return pageIndex < count - 1
    }
    
    /// 启动自动轮播定时器
    private func startAutoPlayIfNeeded() {
        guard canStartAutoPlay else { return }
        
        // 避免重复启动
        stopAutoPlay()
        
        // 挂载到 .common mode，避免 Banner 嵌入外层滚动列表时，滚动期间 timer 被 default mode 阻塞而卡住
        let timer = Timer(timeInterval: autoPlayInterval, repeats: true) { [weak self] _ in
            self?.autoPlayToNextPage()
        }
        RunLoop.main.add(timer, forMode: .common)
        autoPlayTimer = timer
    }
    
    /// 停止自动轮播定时器
    private func stopAutoPlay() {
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }
    
    /// 自动滚动到下一页
    private func autoPlayToNextPage() {
        guard canStartAutoPlay else {
            stopAutoPlay()
            return
        }
        
        // 自动轮播始终向前滚动：直接使用下一个虚拟索引，确保动画方向正确
        let currentVirtual = calculateCurrentVirtualIndex()
        let targetVirtual = currentVirtual + 1
        
        // 边界保护：确保目标索引在有效范围内
        guard targetVirtual < virtualCount else {
            stopAutoPlay()
            return
        }
        
        performProgrammaticScroll(to: targetVirtual, animated: true)
    }

    /// 执行翻页并在 UIKit 没有产生实际滚动动画时同步完成状态
    private func performProgrammaticScroll(to targetVirtual: Int, animated: Bool) {
        // 尺寸转场内的导航由系统转场统一定位，避免与另一段滚动动画竞争。
        let shouldAnimate = animated && sizeTransition == nil && willMoveContent(to: targetVirtual)
        isProgrammaticScrollAnimating = shouldAnimate
        programmaticScrollTargetVirtual = shouldAnimate ? targetVirtual : nil
        collectionView.scrollToItem(
            at: IndexPath(item: targetVirtual, section: 0),
            at: scrollDirection.scrollPosition,
            animated: shouldAnimate
        )

        if !shouldAnimate {
            finishProgrammaticScroll()
        }
    }

    /// 判断目标项居中后是否会改变实际 contentOffset
    private func willMoveContent(to targetVirtual: Int) -> Bool {
        collectionView.layoutIfNeeded()
        guard let attributes = collectionView.layoutAttributesForItem(at: IndexPath(item: targetVirtual, section: 0)) else {
            return false
        }

        let inset = collectionView.adjustedContentInset
        let current = collectionView.contentOffset
        if scrollDirection == .horizontal {
            let minimum = -inset.left
            let maximum = max(minimum, collectionView.contentSize.width - collectionView.bounds.width + inset.right)
            let target = min(max(attributes.center.x - collectionView.bounds.width / 2, minimum), maximum)
            return abs(target - current.x) > 0.5
        }

        let minimum = -inset.top
        let maximum = max(minimum, collectionView.contentSize.height - collectionView.bounds.height + inset.bottom)
        let target = min(max(attributes.center.y - collectionView.bounds.height / 2, minimum), maximum)
        return abs(target - current.y) > 0.5
    }

    private func finishProgrammaticScroll() {
        isProgrammaticScrollAnimating = false
        programmaticScrollTargetVirtual = nil
        updateCurrentPageIndex()
        recenterForLoopingIfNeeded()
        startAutoPlayIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// 从指定视图控制器展示浏览器
    open func present(from vc: UIViewController) {
        modalPresentationStyle = .overFullScreen
        if transitionType != .none { transitioningDelegate = self }
        vc.present(self, animated: transitionType != .none, completion: nil)
    }
    
    /// 滚动到指定索引页
    /// - Parameters:
    ///   - index: 真实数据源索引（0..<count），越界时忽略
    ///   - animated: false 时瞬间跳页，可连续快速调用；true 时使用系统滚动动画
    /// - Note: 尺寸转场期间立即选中目标页，由尺寸转场统一定位，不叠加分页动画。
    open func scrollToPage(at index: Int, animated: Bool) {
        let count = realCount
        guard count > 0, (0..<count).contains(index) else { return }
        resetDismissInteraction(animated: false)

        sizeTransition?.pageIndex = index
        stopAutoPlay()

        let targetVirtual = nearestVirtualIndex(for: index, near: calculateCurrentVirtualIndex())
        performProgrammaticScroll(to: targetVirtual, animated: animated)
    }

    /// 重新读取 delegate 数据并同步页码、循环位置、Overlay 与自动轮播
    open func reloadData(preservingCurrentPage: Bool = true) {
        let previousPage = pageIndex
        let wasSynchronizingData = isSynchronizingData
        isSynchronizingData = true
        defer { isSynchronizingData = wasSynchronizingData }
        resetDismissInteraction(animated: false)
        restoreThumbnail(dataWasReplaced: true)

        realCount = max(0, min(delegate?.numberOfItems(in: self) ?? 0, Int.max / loopMultiplier))
        stopAutoPlay()
        isProgrammaticScrollAnimating = false
        programmaticScrollTargetVirtual = nil
        collectionView.reloadData()

        guard realCount > 0 else {
            sizeTransition?.pageIndex = nil
            pageIndex = 0
            didScrollToInitial = false
            overlays.forEach { $0.reloadData(numberOfItems: 0, pageIndex: 0) }
            return
        }

        let targetReal = preservingCurrentPage
            ? max(0, min(previousPage, realCount - 1))
            : JXPhotoBrowserPaging.normalizedInitialIndex(initialIndex, count: realCount, looping: isLoopingEnabled)
        let targetVirtual = centeredVirtualIndex(for: targetReal)
        sizeTransition?.pageIndex = targetReal

        collectionView.layoutIfNeeded()
        if collectionView.bounds.size != .zero {
            collectionView.scrollToItem(at: IndexPath(item: targetVirtual, section: 0), at: scrollDirection.scrollPosition, animated: false)
            didScrollToInitial = true
        } else {
            didScrollToInitial = false
        }
        pageIndex = targetReal
        overlays.forEach { $0.reloadData(numberOfItems: realCount, pageIndex: targetReal) }

        if transitionType == .zoom, view.window != nil {
            hideCurrentThumbnail()
        }
        isSynchronizingData = wasSynchronizingData
        startAutoPlayIfNeeded()
    }

    /// 当前展示中的 Cell（协议类型，支持自定义Cell）
    /// 通过几何中心距离计算，确保在滚动中也能准确获取视觉中心的 Cell
    open func visibleCell() -> JXPhotoBrowserCellProtocol? {
        let cells = collectionView.visibleCells.compactMap { $0 as? JXPhotoBrowserCellProtocol }
        guard !cells.isEmpty else { return nil }
        
        let viewCenter = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        
        return cells.min { lhs, rhs in
            let lhsCenter = lhs.convert(CGPoint(x: lhs.bounds.midX, y: lhs.bounds.midY), to: view)
            let rhsCenter = rhs.convert(CGPoint(x: rhs.bounds.midX, y: rhs.bounds.midY), to: view)
            
            let dl = hypot(lhsCenter.x - viewCenter.x, lhsCenter.y - viewCenter.y)
            let dr = hypot(rhsCenter.x - viewCenter.x, rhsCenter.y - viewCenter.y)
            return dl < dr
        }
    }
    
    /// 当前展示中的 ZoomImageCell（便捷方法，仅返回 JXZoomImageCell 类型）
    open func visibleZoomImageCell() -> JXZoomImageCell? {
        return visibleCell() as? JXZoomImageCell
    }
    
    // MARK: - Thumbnail Visibility

    /// 所有缩略图查询都以宿主的当前数据为准，包括刷新前已经更换数据的窗口期。
    func thumbnailViewForCurrentPage() -> UIView? {
        guard let delegate = delegate, (0..<max(0, delegate.numberOfItems(in: self))).contains(pageIndex) else { return nil }
        return delegate.photoBrowser(self, thumbnailViewAt: pageIndex)
    }

    func hideCurrentThumbnail() {
        guard transitionType == .zoom, viewIfLoaded?.window != nil,
              let delegate = delegate, (0..<max(0, delegate.numberOfItems(in: self))).contains(pageIndex) else { return }
        let thumbnail = delegate.photoBrowser(self, thumbnailViewAt: pageIndex)
        if let hidden = hiddenThumbnail, hidden.delegate === delegate,
           hidden.index == pageIndex, hidden.view === thumbnail {
            // 列表复用可能重置显隐；重新隐藏但保留最初的恢复状态。
            delegate.photoBrowser(self, setThumbnailHidden: true, at: pageIndex)
            return
        }

        restoreThumbnail()
        hiddenThumbnail = HiddenThumbnail(delegate: delegate, view: thumbnail, index: pageIndex,
                                          restoration: delegate.photoBrowser(self, thumbnailRestorationAt: pageIndex))
        delegate.photoBrowser(self, setThumbnailHidden: true, at: pageIndex)
    }

    func restoreThumbnail(dataWasReplaced: Bool = false) {
        guard let hidden = hiddenThumbnail else { return }
        hiddenThumbnail = nil
        if let restoration = hidden.restoration {
            restoration()
            return
        }

        // 保留旧显隐接口，但不以失效索引访问新数据，也不把恢复操作施加到替换后的视图。
        if let delegate = hidden.delegate, (0..<max(0, delegate.numberOfItems(in: self))).contains(hidden.index) {
            let currentView = delegate.photoBrowser(self, thumbnailViewAt: hidden.index)
            if currentView === hidden.view, currentView != nil || !dataWasReplaced {
                delegate.photoBrowser(self, setThumbnailHidden: false, at: hidden.index)
            }
        }
        hidden.view?.isHidden = hidden.wasHidden
    }

    // MARK: - Overlay Management
    
    /// 装载一个 Overlay 组件到浏览器
    /// Overlay 会被添加到浏览器 view 的最上层，并在适当时机收到页码变化等通知
    ///
    /// 使用示例：
    /// ```swift
    /// let browser = JXPhotoBrowserViewController()
    /// browser.addOverlay(JXPageIndicatorOverlay())
    /// ```
    ///
    /// - Parameter overlay: 遵循 `JXPhotoBrowserOverlay` 协议的视图组件
    /// - Note: 可在 viewDidLoad 之前或之后调用。如果 view 已加载，会立即添加到视图并触发 setup
    open func addOverlay(_ overlay: JXPhotoBrowserOverlay) {
        if overlays.contains(where: { $0 === overlay }) { return }
        if let oldBrowser = overlay.superview?.next as? JXPhotoBrowserViewController, oldBrowser !== self {
            oldBrowser.removeOverlay(overlay)
        } else if overlay.superview != nil {
            overlay.removeFromSuperview()
        }
        overlays.append(overlay)
        
        // 如果 view 已加载，立即装载到视图
        if isViewLoaded {
            installOverlay(overlay)
        }
    }
    
    /// 移除指定的 Overlay 组件
    /// - Parameter overlay: 要移除的 Overlay 实例
    open func removeOverlay(_ overlay: JXPhotoBrowserOverlay) {
        overlay.removeFromSuperview()
        overlays.removeAll { $0 === overlay }
    }
    
    /// 将 Overlay 安装到视图层级并触发 setup
    private func installOverlay(_ overlay: JXPhotoBrowserOverlay) {
        view.addSubview(overlay)
        overlay.setup(with: self)
        overlay.reloadData(numberOfItems: realCount, pageIndex: pageIndex)
    }
    
    // MARK: - Setup & Configuration
    
    /// 注册自定义Cell类
    /// - Parameters:
    ///   - cellClass: 要注册的Cell类（必须实现JXPhotoBrowserCellProtocol协议）
    ///   - reuseIdentifier: 必须提供的复用标识符（与调用方复用时保持一致）
    /// - Returns: 注册是否成功（false 表示参数不合法或未实现协议）
    /// - Note: 建议在创建JXPhotoBrowserViewController实例后、设置delegate之前调用此方法
    @discardableResult
    public func register(_ cellClass: AnyClass, forReuseIdentifier reuseIdentifier: String) -> Bool {
        let trimmed = reuseIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            assertionFailure("JXPhotoBrowserViewController.register(_:forReuseIdentifier:) 失败：reuseIdentifier 不能为空")
            return false
        }
        
        // 运行时校验：必须满足 JXPhotoBrowserCellProtocol（即 JXPhotoBrowserAnyCell）
        guard cellClass is JXPhotoBrowserCellProtocol.Type else {
            assertionFailure("JXPhotoBrowserViewController.register(_:forReuseIdentifier:) 失败：\(cellClass) 未实现 JXPhotoBrowserCellProtocol")
            return false
        }
        
        collectionView.register(cellClass, forCellWithReuseIdentifier: trimmed)
        return true
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
    
    /// 添加并设置集合视图的 frame（使用 frame 布局，避免初始化时 bounds 为 .zero 的问题）
    open func setupCollectionView() {
        view.addSubview(collectionView)
        view.clipsToBounds = true  // 裁剪超出部分，隐藏扩展的间距区域
        // 使用 frame 布局，立即设置 frame，确保 bounds 不为 .zero
        collectionView.frame = calculateCollectionViewFrame()
    }
    
    /// 根据当前属性应用集合视图配置（支持运行时切换）
    open func applyCollectionViewConfig() {
        resetDismissInteraction(animated: false)
        // 始终开启系统分页（itemSize 已适配间距）
        collectionView.isPagingEnabled = true
        
        // 更新滚动方向和间距
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let newDirection = scrollDirection.flowDirection
            if layout.scrollDirection != newDirection {
                layout.scrollDirection = newDirection
                layout.invalidateLayout()
            }
            
            // 应用图片间距
            // minimumLineSpacing 始终表示滚动方向上的间距（水平→列间距，垂直→行间距）
            layout.minimumLineSpacing = itemSpacing
            layout.minimumInteritemSpacing = 0
        }
        
        // 为最后一个 item 右侧（或底部）添加 inset，补偿缺失的间距
        if scrollDirection == .horizontal {
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: itemSpacing)
        } else {
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: itemSpacing, right: 0)
        }

        view.setNeedsLayout()
        if view.window != nil {
            view.layoutIfNeeded()
        }
        
        // 保持当前可见项居中（在已滚动到初始项后）
        // 注意：不能用 calculateCurrentVirtualIndex() 反推——它按【新的】scrollDirection 读取 contentOffset，
        // 方向切换后 offset 已不对应新方向，会导致定位错误、丢失当前页。改为基于已记录的真实页码 pageIndex 计算目标虚拟索引。
        if didScrollToInitial {
            let count = realCount
            if count > 0 {
                let virtualItem = centeredVirtualIndex(for: pageIndex)
                collectionView.scrollToItem(at: IndexPath(item: virtualItem, section: 0), at: scrollDirection.scrollPosition, animated: false)
            }
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension JXPhotoBrowserViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return virtualCount
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let real = realCount > 0 ? realIndex(fromVirtual: indexPath.item) : 0
        guard let delegate = delegate else {
            assertionFailure("JXPhotoBrowserViewController.collectionView(_:cellForItemAt:) 失败：delegate 不能为 nil")
            return UICollectionViewCell()
        }
        let cell = delegate.photoBrowser(self, cellForItemAt: real, at: indexPath)
        cell.browser = self
        // 新出现或复用的 Cell 必须在集合视图首次布局前加入当前转场。
        prepareCellForSizeTransition(cell)
        if sizeTransition != nil, let photoCell = cell as? JXZoomImageCell {
            photoCell.applySizeTransition(to: view.bounds.size)
        }
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let protocolCell = cell as? JXPhotoBrowserAnyCell else { return }
        let real = realIndex(fromVirtual: indexPath.item)
        displayedRealIndexes[ObjectIdentifier(cell)] = real
        delegate?.photoBrowser(self, willDisplay: protocolCell, at: real)
    }
    
    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let protocolCell = cell as? JXPhotoBrowserAnyCell else { return }
        let real = displayedRealIndexes.removeValue(forKey: ObjectIdentifier(cell))
            ?? realIndex(fromVirtual: indexPath.item)
        delegate?.photoBrowser(self, didEndDisplaying: protocolCell, at: real)
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 用户开始手动滚动，暂停自动轮播
        isProgrammaticScrollAnimating = false
        programmaticScrollTargetVirtual = nil
        isUserInteracting = true
        stopAutoPlay()
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard sizeTransition == nil else { return }
        updateCurrentPageIndex()
        recenterForLoopingIfNeeded()

        // 用户滚动结束，恢复自动轮播
        isUserInteracting = false
        startAutoPlayIfNeeded()
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard sizeTransition == nil else { return }
        if !decelerate {
            updateCurrentPageIndex()
            recenterForLoopingIfNeeded()

            // 用户滚动结束，恢复自动轮播
            isUserInteracting = false
            startAutoPlayIfNeeded()
        }
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard sizeTransition == nil else { return }
        finishProgrammaticScroll()
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    /// 每个 item 固定使用浏览器整页尺寸
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return calculateItemSize()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension JXPhotoBrowserViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture {
            if !isDismissGestureEnabled || scrollDirection == .vertical { return false }
            guard dismissInteraction == nil, sizeTransition == nil, !isProgrammaticScrollAnimating else { return false }
            
            let velocity = panGesture.velocity(in: view)
            // 必须是垂直向下的手势
            guard velocity.y > 0, abs(velocity.y) > abs(velocity.x) else { return false }

            guard let cell = visibleCell(),
                  let imageView = cell.transitionImageView,
                  imageView.superview != nil,
                  imageView.bounds.size != .zero else { return false }
            
            return cell.canBeginDismissInteraction
        }
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 允许与 ScrollView 滚动共存
        return true
    }
}

private extension JXPhotoBrowserViewController {
    func resetDismissInteraction(animated: Bool) {
        guard let interaction = dismissInteraction else { return }
        let imageView = interaction.cell.transitionImageView
        if !animated { imageView?.layer.removeAllAnimations() }
        let updates = {
            imageView?.transform = interaction.imageTransform
            self.view.backgroundColor = interaction.backgroundColor
        }
        let completion: (Bool) -> Void = { _ in
            guard self.dismissInteraction === interaction else { return }
            self.dismissInteraction = nil
            self.collectionView.isScrollEnabled = interaction.scrollEnabled
            self.view.clipsToBounds = interaction.viewClips
            self.collectionView.clipsToBounds = interaction.collectionClips
            interaction.cell.photoBrowserDismissInteractionDidChange(isInteracting: false)
            self.startAutoPlayIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: updates, completion: completion)
        } else {
            updates()
            completion(true)
        }
    }
}

// MARK: - Transition Animation

extension JXPhotoBrowserViewController: UIViewControllerTransitioningDelegate {
    
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
