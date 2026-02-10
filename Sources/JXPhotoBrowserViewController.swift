//
//  JXPhotoBrowser.swift
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
            if pageIndex != oldValue {
                // 仅在 Zoom 转场动画时，才对源视图进行显隐操作
                if transitionType == .zoom {
                    // 恢复旧的
                    delegate?.photoBrowser(self, setThumbnailHidden: false, at: oldValue)
                    // 隐藏新的
                    delegate?.photoBrowser(self, setThumbnailHidden: true, at: pageIndex)
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
    
    /// 自动轮播间隔时间（默认 3.0 秒）
    public var autoPlayInterval: TimeInterval = 3.0
        
    // MARK: - Private Properties
    
    /// 自动轮播定时器
    private var autoPlayTimer: Timer?
    
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
    
    /// 正在进行下拉交互的Cell
    private weak var interactiveDismissCell: JXPhotoBrowserCellProtocol?
    
    // MARK: - Lifecycle Methods
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCollectionView()
        applyCollectionViewConfig()
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        // 安装在 viewDidLoad 之前通过 addOverlay 注册的组件
        overlays.forEach { installOverlay($0) }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 仅在 Zoom 转场动画时，初始显示时隐藏源视图
        if transitionType == .zoom {
            delegate?.photoBrowser(self, setThumbnailHidden: true, at: pageIndex)
        }
        
        // 启动自动轮播
        startAutoPlayIfNeeded()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 停止自动轮播
        stopAutoPlay()
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
    
    /// 是否允许自动旋转（固定为 false，不支持设备旋转）
    open override var shouldAutorotate: Bool {
        return false
    }
    
    /// 支持的屏幕方向（固定为竖屏）
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // MARK: - Private Methods
    
    /// 计算指定索引的 item 尺寸
    /// - Parameter index: 实际数据源中的索引
    /// - Returns: 合法的 CGSize，优先使用代理返回值，否则使用 view.bounds（满屏）
    private func calculateItemSize(for index: Int) -> CGSize {
        if let delegateSize = delegate?.photoBrowser(self, sizeForItemAt: index),
           delegateSize.width > 0,
           delegateSize.height > 0 {
            return delegateSize
        }
        
        // itemSize 始终等于 view.bounds（满屏）
        let viewSize = view.bounds.size
        if viewSize.width > 0 && viewSize.height > 0 {
            return viewSize
        }
        
        return UIScreen.main.bounds.size
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        // 垂直滚动模式下禁用下拉关闭手势，避免与列表滚动冲突
        if scrollDirection == .vertical { return }
        
        switch gesture.state {
        case .began:
            guard let cell = visibleCell() else { return }
            interactiveDismissCell = cell
            collectionView.isScrollEnabled = false
            // 如果是 JXZoomImageCell，禁用其内部 scrollView 滚动以避免手势冲突
            if let photoCell = cell as? JXZoomImageCell {
                photoCell.scrollView.isScrollEnabled = false
            }
            
            // 记录初始状态以计算跟随
            let referenceView: UIView = (cell as? JXZoomImageCell)?.scrollView ?? collectionView
            initialTouchPoint = gesture.location(in: referenceView)
            if let imageView = cell.transitionImageView {
                initialImageCenter = imageView.center
            }
            
            // 仅在 Zoom 转场动画时，确保源视图隐藏
            if transitionType == .zoom {
                delegate?.photoBrowser(self, setThumbnailHidden: true, at: pageIndex)
            }
            
            // 通知 Cell 进入下拉交互状态
            cell.photoBrowserDismissInteractionDidChange(isInteracting: true)
            
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
                    if let photoCell = cell as? JXZoomImageCell {
                        photoCell.scrollView.isScrollEnabled = true
                    }
                    // 通知 Cell 下拉交互结束（回弹恢复）
                    cell.photoBrowserDismissInteractionDidChange(isInteracting: false)
                    self.interactiveDismissCell = nil
                }
            }
        default:
            collectionView.isScrollEnabled = true
            if let photoCell = interactiveDismissCell as? JXZoomImageCell {
                photoCell.scrollView.isScrollEnabled = true
            }
            // 通知 Cell 下拉交互结束（异常取消）
            interactiveDismissCell?.photoBrowserDismissInteractionDidChange(isInteracting: false)
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

        let safeInitialIndex: Int
        if isLoopingEnabled {
            safeInitialIndex = ((initialIndex % count) + count) % count
        } else {
            safeInitialIndex = max(0, min(initialIndex, count - 1))
        }

        let base = isLoopingEnabled ? (loopMultiplier / 2) * count : 0
        let target = base + safeInitialIndex
        
        collectionView.scrollToItem(at: IndexPath(item: target, section: 0), at: scrollDirection.scrollPosition, animated: false)
        didScrollToInitial = true
        pageIndex = safeInitialIndex
        
        // 初始定位完成后，启动自动轮播（支持嵌入式使用场景）
        startAutoPlayIfNeeded()
    }
    
    /// 循环模式变更时重新加载数据并调整位置
    private func reloadForLoopingChange() {
        let currentReal = pageIndex
        collectionView.reloadData()
        
        let count = realCount
        guard count > 0 else { return }
        
        // 计算新的目标索引
        let targetIndex: Int
        if isLoopingEnabled {
            // 切换到循环模式：定位到中间位置
            targetIndex = (loopMultiplier / 2) * count + currentReal
        } else {
            // 切换到非循环模式：定位到真实索引
            targetIndex = min(currentReal, count - 1)
        }
        
        collectionView.scrollToItem(at: IndexPath(item: targetIndex, section: 0), at: scrollDirection.scrollPosition, animated: false)
    }
    
    /// 关闭浏览器
    @objc open func dismissSelf() {
        dismiss(animated: transitionType != .none, completion: nil)
    }
    
    // MARK: - Auto Play
    
    /// 判断是否可以启动自动轮播
    private var canStartAutoPlay: Bool {
        guard isAutoPlayEnabled, !isUserInteracting else { return false }
        
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
        
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: autoPlayInterval, repeats: true) { [weak self] _ in
            self?.autoPlayToNextPage()
        }
    }
    
    /// 停止自动轮播定时器
    private func stopAutoPlay() {
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }
    
    /// 自动滚动到下一页
    private func autoPlayToNextPage() {
        let count = realCount
        guard count > 1 else {
            stopAutoPlay()
            return
        }
        
        // 未开启无限循环且已到达最后一页，停止轮播
        if !isLoopingEnabled && pageIndex >= count - 1 {
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
        
        collectionView.scrollToItem(at: IndexPath(item: targetVirtual, section: 0), at: scrollDirection.scrollPosition, animated: true)
    }
    
    // MARK: - Public Methods
    
    /// 从指定视图控制器展示浏览器
    open func present(from vc: UIViewController) {
        modalPresentationStyle = .overFullScreen
        if transitionType != .none { transitioningDelegate = self }
        vc.present(self, animated: transitionType != .none, completion: nil)
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
    /// - Note: 建议在创建JXPhotoBrowser实例后、设置delegate之前调用此方法
    @discardableResult
    public func register(_ cellClass: AnyClass, forReuseIdentifier reuseIdentifier: String) -> Bool {
        let trimmed = reuseIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            assertionFailure("JXPhotoBrowser.register(_:forReuseIdentifier:) 失败：reuseIdentifier 不能为空")
            return false
        }
        
        // 运行时校验：必须满足 JXPhotoBrowserCellProtocol（即 JXPhotoBrowserAnyCell）
        guard cellClass is JXPhotoBrowserCellProtocol.Type else {
            assertionFailure("JXPhotoBrowser.register(_:forReuseIdentifier:) 失败：\(cellClass) 未实现 JXPhotoBrowserCellProtocol")
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
        
        // 保持当前可见项居中（在已滚动到初始项后）
        if didScrollToInitial {
            let virtualItem = calculateCurrentVirtualIndex()
            collectionView.scrollToItem(at: IndexPath(item: virtualItem, section: 0), at: scrollDirection.scrollPosition, animated: false)
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
            assertionFailure("JXPhotoBrowser.collectionView(_:cellForItemAt:) 失败：delegate 不能为 nil")
            return UICollectionViewCell()
        }
        let cell = delegate.photoBrowser(self, cellForItemAt: real, at: indexPath)
        cell.browser = self
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
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 用户开始手动滚动，暂停自动轮播
        isUserInteracting = true
        stopAutoPlay()
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPageIndex()
        
        // 用户滚动结束，恢复自动轮播
        isUserInteracting = false
        startAutoPlayIfNeeded()
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateCurrentPageIndex()
            
            // 用户滚动结束，恢复自动轮播
            isUserInteracting = false
            startAutoPlayIfNeeded()
        }
    }
    
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentPageIndex()
        
        // 动画滚动结束后，检查是否需要继续自动轮播
        startAutoPlayIfNeeded()
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    /// 动态计算每个 item 的尺寸（从代理获取）
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let real = realIndex(fromVirtual: indexPath.item)
        // 从代理获取 itemSize，如果没有实现则返回 collectionView.bounds.size
        return calculateItemSize(for: real)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension JXPhotoBrowserViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture {
            if scrollDirection == .vertical { return false }
            
            let velocity = panGesture.velocity(in: view)
            // 必须是垂直向下的手势
            guard velocity.y > 0, abs(velocity.y) > abs(velocity.x) else { return false }
            
            // 如果是 JXZoomImageCell，检查缩放和滚动状态
            if let photoCell = visibleZoomImageCell() {
                let isZoomed = photoCell.scrollView.zoomScale > 1.0 + 0.01
                let isAtTop = photoCell.scrollView.contentOffset.y <= 1.0
                return !isZoomed && isAtTop
            }
            
            // 自定义 Cell（非 JXZoomImageCell）：直接允许下拉关闭
            guard visibleCell() != nil else { return false }
            return true
        }
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 允许与 ScrollView 滚动共存
        return true
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
