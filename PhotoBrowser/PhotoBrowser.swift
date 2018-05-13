//
//  PhotoBrowser.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2017/3/24.
//  Copyright © 2017年 JiongXing. All rights reserved.
//

import UIKit

public class PhotoBrowser: UIViewController {
    
    //
    // MARK: - 公开属性
    //
    
    /// 实现了PhotoBrowserDelegate协议的对象
    public weak var photoBrowserDelegate: PhotoBrowserDelegate?
    
    /// 实现了PageControlDelegate协议的对象
    public var pageControl: PageControl?
    
    /// 网络图片加载器
    public var photoLoader: PhotoLoader?
    
    /// 左右两张图之间的间隙
    public var photoSpacing: CGFloat = 30
    
    /// 图片缩放模式
    public var imageScaleMode = UIViewContentMode.scaleAspectFill
    
    /// 捏合手势放大图片时的最大允许比例
    public var imageMaximumZoomScale: CGFloat = 2.0
    
    /// 双击放大图片时的目标比例
    public var imageZoomScaleForDoubleTap: CGFloat = 2.0
    
    /// 转场动画类型
    public var animationType: AnimationType = .scale
    
    /// 打开时的初始页码，第一页为 0.
    public var initializePageIndex: Int = 0
    
    /// 插件组
    public var plugins: [PhotoBrowserPlugin] = []
    
    //
    // MARK: - 私有属性
    //
    
    /// 当前显示的图片序号，从0开始
    private var currentIndex = 0 {
        didSet {
            scalePresentationController?.updateCurrentHiddenView(relatedView)
            plugins.forEach {
                $0.photoBrowser(self, didChangedPageIndex: currentIndex)
            }
            if let pageControl = pageControl, let total = photoBrowserDelegate?.numberOfPhotos(in: self) {
                pageControl.pageControlPageDidChanged(current: currentIndex, total: total)
            }
        }
    }
    
    /// 当前正在显示视图的前一个页面关联视图
    private var relatedView: UIView? {
        return photoBrowserDelegate?.photoBrowser(self, thumbnailViewForIndex: currentIndex)
    }
    
    /// 转场协调器
    private weak var fadePresentationController: FadePresentationControllerDelegate?
    
    /// 缩放型转场协调器
    private weak var scalePresentationController: ScalePresentationController?
    
    /// 容器layout
    private lazy var flowLayout: PhotoBrowserLayout = {
        return PhotoBrowserLayout()
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
        collectionView.register(PhotoBrowserCell.self, forCellWithReuseIdentifier: NSStringFromClass(PhotoBrowserCell.self))
        return collectionView
    }()
    
    /// 保存原windowLevel
    private lazy var originWindowLevel: UIWindowLevel? = { [weak self] in
        let window = self?.view.window ?? UIApplication.shared.keyWindow
        return window?.windowLevel
    }()
    
    //
    // MARK: - 创建与销毁
    //
    
    /// 销毁
    deinit {
        #if DEBUG
        print("deinit:\(self)")
        #endif
    }
    
    /// 初始化
    /// - parameter animationType: 转场动画类型，默认为缩放动画`scale`
    /// - parameter delegate: 浏览器协议代理
    /// - parameter pageControl: 页码指示器，默认 DefaultPageControl
    /// - parameter photoLoader: 网络图片加载器，默认 KingfisherPhotoLoader
    /// - parameter initializePageIndex: 打开时的初始页码，第一页为 0.
    public init(animationType: AnimationType = .scale,
                delegate: PhotoBrowserDelegate? = nil,
                photoLoader: PhotoLoader? = KingfisherPhotoLoader(),
                pageControl: PageControl? = DefaultPageControl(),
                initializePageIndex: Int = 0) {
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
        self.modalPresentationCapturesStatusBarAppearance = true
        
        self.animationType = animationType
        self.photoBrowserDelegate = delegate
        self.photoLoader = photoLoader
        self.pageControl = pageControl
        self.initializePageIndex = initializePageIndex
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//
// MARK: - 公开方法
//

extension PhotoBrowser {
    /// 展示，传入完整参数
    /// - parameter animationType: 转场动画类型，默认为缩放动画`scale`
    /// - parameter delegate: 浏览器协议代理
    /// - parameter pageControl: 页码指示器，默认 DefaultPageControl
    /// - parameter photoLoader: 网络图片加载器，默认 KingfisherPhotoLoader
    /// - parameter initializePageIndex: 打开时的初始页码，第一页为 0.
    /// - parameter fromViewController: 基于哪个 ViewController 执行 present.
    public class func show(animationType: AnimationType = .scale,
                           delegate: PhotoBrowserDelegate,
                           pageControl: PageControl? = DefaultPageControl(),
                           photoLoader: PhotoLoader? = KingfisherPhotoLoader(),
                           initializePageIndex: Int,
                           fromViewController: UIViewController? = TopMostViewControllerGetter.topMost) {
        let vc = PhotoBrowser(animationType: animationType,
                              delegate: delegate,
                              photoLoader: photoLoader,
                              pageControl: DefaultPageControl(),
                              initializePageIndex: initializePageIndex)
        vc.show(from: fromViewController)
    }
    
    /// 展示图片浏览器
    /// - parameter presentingVC: 由谁 present 出图片浏览器
    public func show(from viewController: UIViewController? = TopMostViewControllerGetter.topMost) {
        viewController?.present(self, animated: true, completion: nil)
    }
    
    /// 关闭浏览器
    /// 不会触发`浏览器即将关闭/浏览器已经关闭`回调
    /// - parameter animated: 是否需要关闭转场动画
    public func dismiss(animated: Bool) {
        dismiss(animated: animated, completion: nil)
    }
}

//
// MARK: - 生命周期及其回调方法
//

extension PhotoBrowser {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        plugins.forEach {
            $0.photoBrowser(self, viewDidLoad: view)
        }
        currentIndex = initializePageIndex
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 遮盖状态栏
        coverStatusBar(true)
        plugins.forEach {
            $0.photoBrowser(self, viewWillAppear: view, animated: animated)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        plugins.forEach {
            $0.photoBrowser(self, viewDidAppear: view, animated: animated)
        }
        // 页面出来后，再显示页码指示器
        // 多于一张图才会显示
        if let pageControl = pageControl,
            let total = photoBrowserDelegate?.numberOfPhotos(in: self), total > 1 {
            view.addSubview(pageControl.pageControlView(on: self))
            pageControl.pageControlDidMove(to: view)
            pageControl.pageControlLayout(in: view)
        }
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        plugins.forEach {
            $0.photoBrowser(self, viewWillLayoutSubviews: view)
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutViews()
        // 屏幕旋转后的调整
        let indexPath = IndexPath.init(item: self.currentIndex, section: 0)
        self.collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        plugins.forEach {
            $0.photoBrowser(self, viewDidLayoutSubviews: view)
        }
        if let pageControl = pageControl,
            let total = photoBrowserDelegate?.numberOfPhotos(in: self), total > 1 {
            pageControl.pageControlLayout(in: view)
        }
    }
    
    /// 支持旋转
    public override var shouldAutorotate: Bool {
        return true
    }
    
    /// 支持旋转的方向
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    /// 添加视图
    private func setupViews() {
        view.addSubview(collectionView)
    }
    
    /// 视图布局
    private func layoutViews() {
        flowLayout.minimumLineSpacing = photoSpacing
        flowLayout.itemSize = view.bounds.size
        collectionView.frame = view.bounds
    }
}

extension PhotoBrowser {
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
}

//
// MARK: - UICollectionViewDataSource
//

extension PhotoBrowser: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let number = photoBrowserDelegate?.numberOfPhotos(in: self) ?? 0
        plugins.forEach {
            $0.photoBrowser(self, numberOfPhotos: number)
        }
        return number
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(PhotoBrowserCell.self), for: indexPath) as! PhotoBrowserCell
        cell.imageView.contentMode = imageScaleMode
        cell.photoBrowserCellDelegate = self
        cell.photoLoader = photoLoader
        cell.imageMaximumZoomScale = imageMaximumZoomScale
        cell.imageZoomScaleForDoubleTap = imageZoomScaleForDoubleTap
        if let local = localImage(for: indexPath.item) {
            cell.setImage(local, highQualityUrl: nil, rawUrl: nil)
        } else {
            let (image, highQualityUrl, rawUrl) = imageFor(index: indexPath.item)
            cell.setImage(image, highQualityUrl: highQualityUrl, rawUrl: rawUrl)
        }
        plugins.forEach {
            $0.photoBrowser(self, reusableCell: cell, atIndex: indexPath.item)
        }
        return cell
    }
    
    /// 尝试取本地图片
    private func localImage(for index: Int) -> UIImage? {
        return photoBrowserDelegate?.photoBrowser(self, localImageForIndex: index)
    }
    
    private func imageFor(index: Int) -> (UIImage?, highQualityUrl: URL?, rawUrl: URL?) {
        guard let delegate = photoBrowserDelegate else {
            return (nil, nil, nil)
        }
        // 缩略图
        let thumbnailImage = delegate.photoBrowser(self, thumbnailImageForIndex: index)
        // 高清图url
        let highQualityUrl = delegate.photoBrowser(self, highQualityUrlForIndex: index)
        // 原图url
        let rawUrl = delegate.photoBrowser(self, rawUrlForIndex: index)
        return (thumbnailImage, highQualityUrl, rawUrl)
    }
}

//
// MARK: - UICollectionViewDelegate
//

extension PhotoBrowser: UICollectionViewDelegate {
    /// 减速完成后，计算当前页
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let width = scrollView.frame.width + photoSpacing
        currentIndex = Int(offsetX / width)
    }
}

//
// MARK: - 转场动画
//

extension PhotoBrowser: UIViewControllerTransitioningDelegate {
    /// 提供进场动画
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // 枚举动画类型
        switch animationType {
        case .scale:
            return makeScalePresentationAnimator()
        case .fade:
            return FadeAnimator()
        }
    }
    
    /// 提供退场动画
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch animationType {
        case .scale:
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
        case .fade:
            let controller = FadePresentationController(presentedViewController: presented, presenting: presented)
            fadePresentationController = controller
            return controller
        }
    }
    
    /// 创建缩放型进场动画
    private func makeScalePresentationAnimator() -> UIViewControllerAnimatedTransitioning {
        // 立即布局
        setupViews()
        layoutViews()
        // 立即加载collectionView
        let indexPath = IndexPath(item: currentIndex, section: 0)
        collectionView.reloadData()
        collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        collectionView.layoutIfNeeded()
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
// MARK: - PhotoBrowserCellDelegate
//

extension PhotoBrowser: PhotoBrowserCellDelegate {
    func photoBrowserCell(_ cell: PhotoBrowserCell, didSingleTap image: UIImage?) {
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
    
    func photoBrowserCell(_ view: PhotoBrowserCell, didPanScale scale: CGFloat) {
        // 实测用scale的平方，效果比线性好些
        let alpha = scale * scale
        fadePresentationController?.maskAlpha = alpha
        // 半透明时重现状态栏，否则遮盖状态栏
        coverStatusBar(alpha >= 1.0)
    }
    
    func photoBrowserCell(_ cell: PhotoBrowserCell, didLongPressWith image: UIImage) {
        if let indexPath = collectionView.indexPath(for: cell) {
            photoBrowserDelegate?.photoBrowser(self, didLongPressForIndex: indexPath.item, image: image)
        }
    }
}

