//
//  PhotoBrowser.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2017/3/24.
//  Copyright © 2017年 JiongXing. All rights reserved.
//

import UIKit

open class PhotoBrowser: UIViewController {

    //
    // MARK: - Public Properties
    //

    /// 实现了PhotoBrowserDelegate协议的对象
    open weak var photoBrowserDelegate: PhotoBrowserDelegate?

    /// 图片加载器
    open var photoLoader: PhotoLoader

    /// 左右两张图之间的间隙
    open var photoSpacing: CGFloat = 30

    /// 图片缩放模式
    open var imageScaleMode = UIViewContentMode.scaleAspectFill

    /// 捏合手势放大图片时的最大允许比例
    open var imageMaximumZoomScale: CGFloat = 2.0

    /// 双击放大图片时的目标比例
    open var imageZoomScaleForDoubleTap: CGFloat = 2.0

    /// 转场动画类型
    open var animationType: AnimationType = .scale

    /// 打开时的初始页码，第一页为 0.
    open var originPageIndex: Int = 0

    /// 本地图片组
    /// 优先级高于代理方法`func photoBrowser(_:, localImageForIndex:) -> UIImage?`
    open var localImages: [UIImage]?

    /// 插件组
    open var plugins: [PhotoBrowserPlugin] = []

    /// Cell 插件组
    /// 默认值[ProgressViewPlugin(), RawImageButtonPlugin()]
    open lazy var cellPlugins: [PhotoBrowserCellPlugin] = {
        return [ProgressViewPlugin(), RawImageButtonPlugin()]
    }()

    //
    // MARK: - Private Properties
    //

    /// 当前显示的图片序号，从0开始
    private var currentIndex = 0 {
        didSet {
            if animationType == .scale {
                scalePresentationController?.updateCurrentHiddenView(relatedView)
            }
            plugins.forEach {
                $0.photoBrowser(self, didChangedPageIndex: currentIndex)
            }
        }
    }

    /// 当前正在显示视图的前一个页面关联视图
    private var relatedView: UIView? {
        return photoBrowserDelegate?.photoBrowser(self, thumbnailViewForIndex: currentIndex)
    }

    /// 转场协调器
    private weak var fadePresentationController: PhotoBrowserPresentationController?

    /// 缩放型转场协调器
    private weak var scalePresentationController: ScalePresentationController?

    /// 容器layout
    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        return layout
    }()

    /// 容器
    private lazy var collectionView: UICollectionView = { [unowned self] in
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerCell(PhotoBrowserCell.self)
        collectionView.isPagingEnabled = true
        collectionView.alwaysBounceVertical = false
        return collectionView
    }()

    /// 保存原windowLevel
    private lazy var originWindowLevel: UIWindowLevel? = { [weak self] in
        let window = self?.view.window ?? UIApplication.shared.keyWindow
        return window?.windowLevel
    }()

    //
    // MARK: - Initialize
    //

    #if DEBUG
    /// 销毁
    deinit {
        print("deinit:\(self)")
    }
    #endif

    /// 初始化
    /// - parameter animationType: 转场动画类型，默认为缩放动画`scale`
    /// - parameter delegate: 浏览器协议代理
    /// - parameter photoLoader: 网络图片加载器，传 nil 则使用 KingfisherPhotoLoader
    /// - parameter originPageIndex: 打开时的初始页码，第一页为 0.
    public init(animationType: AnimationType = .scale,
                delegate: PhotoBrowserDelegate? = nil,
                photoLoader: PhotoLoader? = nil,
                originPageIndex: Int = 0) {
        self.photoLoader = photoLoader ?? {
            let cls = NSClassFromString("KingfisherPhotoLoader")
            assert(cls != nil, "请传入你实现的 photoLoader 或在 Podfile 选用 Kingfisher subspec!")
            return (cls as! NSObject.Type).init() as! PhotoLoader
            }()
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom

        self.animationType = animationType
        self.photoBrowserDelegate = delegate
        self.originPageIndex = originPageIndex
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Life Cycle
    //
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        plugins.forEach {
            $0.photoBrowser(self, viewDidLoad: view)
        }
        currentIndex = originPageIndex
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 遮盖状态栏
        coverStatusBar(true)
        plugins.forEach {
            $0.photoBrowser(self, viewWillAppear: view, animated: animated)
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        plugins.forEach {
            $0.photoBrowser(self, viewDidAppear: view, animated: animated)
        }
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        plugins.forEach {
            $0.photoBrowser(self, viewWillLayoutSubviews: view)
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutViews()
        plugins.forEach {
            $0.photoBrowser(self, viewDidLayoutSubviews: view)
        }
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // 屏幕旋转处理
        DispatchQueue.main.asyncAfter(deadline: .now() + coordinator.transitionDuration, execute: {
            let indexPath = IndexPath(item: self.currentIndex, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        })
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        plugins.forEach {
            $0.photoBrowser(self, viewWillDisappear: view)
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        plugins.forEach {
            $0.photoBrowser(self, viewDidDisappear: view)
        }
    }
    
    /// 支持旋转
    open override var shouldAutorotate: Bool {
        return true
    }
    
    /// 支持旋转的方向
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    //
    // MARK: - Public Methods
    //

    /// 展示图片浏览器
    /// - parameter presentingVC: 由谁 present 出图片浏览器
    /// - parameter presentingVC: 由谁 present 出图片浏览器
    open func show(from viewController: UIViewController? = TopMostViewControllerGetter.topMost,
                   wrapped: UINavigationController? = nil) {
        if let nav = wrapped {
            self.transitioningDelegate = nil
            nav.transitioningDelegate = self
            nav.modalPresentationStyle = .custom
            viewController?.present(nav, animated: true, completion: nil)
        } else {
            viewController?.present(self, animated: true, completion: nil)
        }
    }

    /// 关闭浏览器
    /// 不会触发`浏览器即将关闭/浏览器已经关闭`回调
    /// - parameter animated: 是否需要关闭转场动画
    open func dismiss(animated: Bool) {
        coverStatusBar(false)
        dismiss(animated: animated, completion: nil)
    }

    /// 展示，传入完整参数
    /// - parameter animationType: 转场动画类型，默认为缩放动画`scale`
    /// - parameter delegate: 浏览器协议代理
    /// - parameter photoLoader: 网络图片加载器，传 nil 则使用 KingfisherPhotoLoader
    /// - parameter plugins: 插件组，默认加载一个光点型页码指示器
    /// - parameter originPageIndex: 打开时的初始页码，第一页为 0.
    /// - parameter fromViewController: 基于哪个 ViewController 执行 present。默认视图顶层VC。
    /// - returns:  所创建的图片浏览器
    @discardableResult
    open class func show(animationType: AnimationType = .scale,
                         delegate: PhotoBrowserDelegate,
                         photoLoader: PhotoLoader? = nil,
                         plugins: [PhotoBrowserPlugin] = [DefaultPageControlPlugin()],
                         originPageIndex: Int,
                         fromViewController: UIViewController? = TopMostViewControllerGetter.topMost
        ) -> PhotoBrowser {
        let vc = PhotoBrowser(animationType: animationType,
                              delegate: delegate,
                              photoLoader: photoLoader,
                              originPageIndex: originPageIndex)
        vc.plugins = plugins
        vc.show(from: fromViewController)
        return vc
    }

    /// 展示本地图片
    /// - parameter localImages: 本地图片组
    /// - parameter animationType: 转场动画类型，默认为缩放动画`fade`
    /// - parameter delegate: 浏览器协议代理
    /// - parameter photoLoader: 图片加载器，传 nil 则使用 KingfisherPhotoLoader
    /// - parameter plugins: 插件组，默认加载一个光点型页码指示器
    /// - parameter originPageIndex: 打开时的初始页码，第一页为 0.
    /// - parameter fromViewController: 基于哪个 ViewController 执行 present。默认视图顶层VC。
    /// - returns:  所创建的图片浏览器
    @discardableResult
    open class func show(localImages: [UIImage],
                         animationType: AnimationType = .fade,
                         delegate: PhotoBrowserDelegate? = nil,
                         photoLoader: PhotoLoader? = nil,
                         plugins: [PhotoBrowserPlugin] = [DefaultPageControlPlugin()],
                         originPageIndex: Int,
                         fromViewController: UIViewController? = TopMostViewControllerGetter.topMost
        ) -> PhotoBrowser {
        let vc = PhotoBrowser(animationType: animationType,
                              delegate: delegate,
                              photoLoader: photoLoader,
                              originPageIndex: originPageIndex)
        vc.localImages = localImages
        vc.plugins = plugins
        vc.show(from: fromViewController)
        return vc
    }

    /// 重新加载数据源
    open func reloadData() {
        collectionView.reloadData()
        checkAndRefreshCurrentIndex()
    }

    /// 删除某项
    open func deleteItem(at index: Int) {
        collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
        checkAndRefreshCurrentIndex()
    }
    
    /// 加载某项的原图。要求处于当前显示中项才可以查看。
    open func loadRawImage(at index: Int) {
        if let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0))
            as? PhotoBrowserCell {
            cell.loadRawImage()
        }
    }
    
    /// 滑到哪张图片
    /// - parameter index: 图片序号，从0开始
    open func scrollToItem(_ index: Int, at position: UICollectionViewScrollPosition, animated: Bool) {
        currentIndex = index
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: position, animated: animated)
    }

    //
    // MARK: - Private Methods
    //

    /// 添加视图
    private func setupViews() {
        view.addSubview(collectionView)
    }

    /// 视图布局
    private func layoutViews() {
        flowLayout.minimumLineSpacing = photoSpacing
        flowLayout.itemSize = view.bounds.size
        collectionView.frame = view.bounds
        collectionView.frame.size.width = view.bounds.width + photoSpacing
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: photoSpacing)
    }

    /// 遮盖状态栏。以改变windowLevel的方式遮盖
    private func coverStatusBar(_ cover: Bool) {
        guard let window = view.window ?? UIApplication.shared.keyWindow else {
            return
        }
        if originWindowLevel == nil {
            originWindowLevel = window.windowLevel
        }
        guard let originLevel = originWindowLevel else {
            return
        }
        window.windowLevel = cover ? UIWindowLevelStatusBar + 1 : originLevel
    }
    
    /// 检查 numberOfItems，更新 currentIndex
    private func checkAndRefreshCurrentIndex() {
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        if currentIndex > (numberOfItems - 1) {
            currentIndex = numberOfItems - 1
        }
        if numberOfItems == 0 {
            dismiss(animated: true)
        }
    }
}

//
// MARK: - UICollectionView DataSource
//

extension PhotoBrowser: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var number = 0
        if let localCount = localImages?.count {
            number = localCount
        } else if let dlgNumber = photoBrowserDelegate?.numberOfPhotos(in: self) {
            number = dlgNumber
        }
        plugins.forEach {
            $0.photoBrowser(self, numberOfPhotos: number)
        }
        return number
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(PhotoBrowserCell.self, for: indexPath)
        cell.imageView.contentMode = imageScaleMode
        cell.cellDelegate = self
        cell.photoLoader = photoLoader
        cell.imageMaximumZoomScale = imageMaximumZoomScale
        cell.imageZoomScaleForDoubleTap = imageZoomScaleForDoubleTap
        cellPlugins.forEach {
            $0.photoBrowserCellDidReused(cell, at: indexPath.item)
        }
        if let local = localImage(for: indexPath.item) {
            cell.setImage(local, highQualityUrl: nil, rawUrl: nil)
        } else {
            let (image, highQualityUrl, rawUrl) = imageFor(index: indexPath.item)
            cell.setImage(image, highQualityUrl: highQualityUrl, rawUrl: rawUrl)
        }
        return cell
    }

    /// 尝试取本地图片
    private func localImage(for index: Int) -> UIImage? {
        guard let images = localImages, index < images.count else {
            return localImageFromDelegate(for: index)
        }
        return images[index]
    }
    
    /// 通过代理取本地图片
    private func localImageFromDelegate(for index: Int) -> UIImage? {
        return photoBrowserDelegate?.photoBrowser(self, localImageForIndex: index)
    }

    private func imageFor(index: Int) -> (UIImage?, highQualityUrl: URL?, rawUrl: URL?) {
        guard let delegate = photoBrowserDelegate else {
            return (nil, nil, nil)
        }
        // 缩略图
        let originImage = delegate.photoBrowser(self, thumbnailImageForIndex: index)
        // 高清图url
        let highQualityUrl = delegate.photoBrowser(self, highQualityUrlForIndex: index)
        // 原图url
        let rawUrl = delegate.photoBrowser(self, rawUrlForIndex: index)
        return (originImage, highQualityUrl, rawUrl)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let pbCell = cell as? PhotoBrowserCell {
            cellPlugins.forEach {
                $0.photoBrowserCellWillDisplay(pbCell, at: indexPath.item)
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let pbCell = cell as? PhotoBrowserCell {
            cellPlugins.forEach {
                $0.photoBrowserCellDidEndDisplaying(pbCell, at: indexPath.item)
            }
        }
    }
}

//
// MARK: - UICollectionView Delegate
//

extension PhotoBrowser: UICollectionViewDelegate {
    /// 减速完成后，计算当前页
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
    }

    /// 滑动中
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        plugins.forEach {
            $0.photoBrowser(self, scrollViewDidScroll: scrollView)
        }
    }
}

//
// MARK: - Animated Transitioning
//

extension PhotoBrowser: UIViewControllerTransitioningDelegate {
    /// 提供进场动画
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // 立即布局
        setupViews()
        layoutViews()
        // 立即加载collectionView
        let indexPath = IndexPath(item: currentIndex, section: 0)
        collectionView.reloadData()
        collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        collectionView.layoutIfNeeded()
        // 枚举动画类型
        switch animationType {
        case .scale, .scaleNoHiding:
            return makeScalePresentationAnimator(indexPath: indexPath)
        case .fade:
            return FadeAnimator()
        }
    }

    /// 提供退场动画
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch animationType {
        case .scale, .scaleNoHiding:
            return makeDismissedAnimator()
        case .fade:
            return FadeAnimator()
        }
    }

    /// 提供转场协调器
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        switch animationType {
        case .scale:
            let controller = ScalePresentationController(presentedViewController: presented, presenting: presenting)
            controller.currentHiddenView = relatedView
            fadePresentationController = controller
            scalePresentationController = controller
            return controller
        case .scaleNoHiding:
            let controller = ScalePresentationController(presentedViewController: presented, presenting: presenting)
            fadePresentationController = controller
            scalePresentationController = controller
            return controller
        case .fade:
            let controller = FadePresentationController(presentedViewController: presented, presenting: presented)
            fadePresentationController = controller
            return controller
        }
    }

    /// 创建缩放型进场动画
    private func makeScalePresentationAnimator(indexPath: IndexPath) -> UIViewControllerAnimatedTransitioning {
        let cell = collectionView.cellForItem(at: indexPath) as? PhotoBrowserCell
        let imageView = UIImageView(image: cell?.imageView.image)
        imageView.contentMode = imageScaleMode
        imageView.clipsToBounds = true
        // 创建animator
        return ScaleAnimator(startView: relatedView, endView: cell?.imageView, scaleView: imageView)
    }

    /// 创建缩放型退场动画
    private func makeDismissedAnimator() -> UIViewControllerAnimatedTransitioning? {
        guard let cell = collectionView.visibleCells.first as? PhotoBrowserCell else {
            return nil
        }
        let imageView = UIImageView(image: cell.imageView.image)
        imageView.contentMode = imageScaleMode
        imageView.clipsToBounds = true
        return ScaleAnimator(startView: cell.imageView, endView: relatedView, scaleView: imageView)
    }
}

//
// MARK: - PhotoBrowserCell Delegate
//

extension PhotoBrowser: PhotoBrowserCellDelegate {

    public func photoBrowserCell(_ cell: PhotoBrowserCell, didSingleTap image: UIImage?) {
        if let dlg = photoBrowserDelegate {
            dlg.photoBrowser(self, willDismissWithIndex: currentIndex, image: image)
        }
        coverStatusBar(false)
        dismiss(animated: true, completion: { [weak self] in
            if let `self` = self, let dlg = self.photoBrowserDelegate {
                dlg.photoBrowser(self, didDismissWithIndex: self.currentIndex, image: image)
            }
        })
    }

    public func photoBrowserCell(_ view: PhotoBrowserCell, didPanScale scale: CGFloat) {
        // 实测用scale的平方，效果比线性好些
        let alpha = scale * scale
        fadePresentationController?.maskAlpha = alpha
        // 半透明时重现状态栏，否则遮盖状态栏
        coverStatusBar(alpha >= 1.0)
    }

    public func photoBrowserCell(_ cell: PhotoBrowserCell, didLongPressWith image: UIImage) {
        if let indexPath = collectionView.indexPath(for: cell) {
            photoBrowserDelegate?.photoBrowser(self, didLongPressForIndex: indexPath.item, image: image)
        }
    }

    public func photoBrowserCellDidLayout(_ cell: PhotoBrowserCell) {
        cellPlugins.forEach {
            $0.photoBrowserCellDidLayout(cell)
        }
    }

    public func photoBrowserCellSetImage(_ cell: PhotoBrowserCell, placeholder: UIImage?, highQualityUrl: URL?, rawUrl: URL?) {
        cellPlugins.forEach {
            $0.photoBrowserCellSetImage(cell, placeholder: placeholder, highQualityUrl: highQualityUrl, rawUrl: rawUrl)
        }
    }

    public func photoBrowserCellWillLoadImage(_ cell: PhotoBrowserCell, placeholder: UIImage?, url: URL?) {
        cellPlugins.forEach {
            $0.photoBrowserCellWillLoadImage(cell, placeholder: placeholder, url: url)
        }
    }

    public func photoBrowserCellLoadingImage(_ cell: PhotoBrowserCell, receivedSize: Int64, totalSize: Int64) {
        cellPlugins.forEach {
            $0.photoBrowserCellLoadingImage(cell, receivedSize: receivedSize, totalSize: totalSize)
        }
    }

    public func photoBrowserCellDidLoadImage(_ cell: PhotoBrowserCell, placeholder: UIImage?, url: URL?) {
        cellPlugins.forEach {
            $0.photoBrowserCellDidLoadImage(cell, placeholder: placeholder, url: url)
        }
    }
}

private extension UICollectionView {
    func registerCell<T: UICollectionViewCell>(_ type: T.Type) {
        let identifier = String(describing: type.self)
        register(type, forCellWithReuseIdentifier: identifier)
    }

    func dequeueReusableCell<T: UICollectionViewCell>(_ type: T.Type, for indexPath: IndexPath) -> T {
        let identifier = String(describing: type.self)
        guard let cell = dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? T else {
            fatalError("\(type.self) was not registered")
        }
        return cell
    }
}
