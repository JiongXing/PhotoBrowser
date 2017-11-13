//
//  PhotoBrowser.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2017/3/24.
//  Copyright © 2017年 JiongXing. All rights reserved.
//

import UIKit
import Kingfisher

// MARK: - PhotoBrowserDelegate
public protocol PhotoBrowserDelegate: class {
    /// 实现本方法以返回图片数量
    func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int
    
    /// 实现本方法以返回默认图片，缩略图或占位图
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage?
    
    /// 实现本方法以返回默认图所在view，在转场动画完成后将会修改这个view的hidden属性
    /// 比如你可返回ImageView，或整个Cell
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView?
    
    /// 实现本方法以返回高质量图片的url。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlForIndex index: Int) -> URL?
    
    /// 实现本方法以返回原图url。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, rawUrlForIndex index: Int) -> URL?
    
    /// 长按时回调。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, didLongPressForIndex index: Int, image: UIImage)
}

/// PhotoBrowserDelegate适配器
public extension PhotoBrowserDelegate {
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlForIndex index: Int) -> URL? {
        return nil
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, rawUrlForIndex index: Int) -> URL? {
        return nil
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, didLongPressForIndex index: Int, image: UIImage) {}
    
    func pageControlOfPhotoBrowser<T: UIView>(_ photoBrowser: PhotoBrowser) -> T? {
        return nil
    }
}

// MARK: - PhotoBrowserPageControl
public protocol PhotoBrowserPageControlDelegate: class {
    
    /// 总图片数/页数
    var numberOfPages: Int { get set }
    
    /// 取PageControl，只会取一次
    func pageControlOfPhotoBrowser(_ photoBrowser: PhotoBrowser) -> UIView
    
    /// 添加到父视图上时调用
    func photoBrowserPageControl(_ pageControl: UIView, didMoveTo superView: UIView)
    
    /// 让pageControl布局时调用
    func photoBrowserPageControl(_ pageControl: UIView, needLayoutIn superView: UIView)
    
    /// 页码变更时调用
    func photoBrowserPageControl(_ pageControl: UIView, didChangedCurrentPage currentPage: Int)
}

// MARK: - PhotoBrowser

public class PhotoBrowser: UIViewController {
    
    // MARK: -  公开属性
    /// 实现了PhotoBrowserDelegate协议的对象
    public weak var photoBrowserDelegate: PhotoBrowserDelegate?
    
    /// 实现了PhotoBrowserPageControlDelegate协议的对象
    public var pageControlDelegate: PhotoBrowserPageControlDelegate?
    
    /// 左右两张图之间的间隙
    public var photoSpacing: CGFloat = 30
    
    /// 图片缩放模式
    public var imageScaleMode = UIViewContentMode.scaleAspectFill
    
    /// 捏合手势放大图片时的最大允许比例
    public var imageMaximumZoomScale: CGFloat = 2.0
    
    /// 双击放大图片时的目标比例
    public var imageZoomScaleForDoubleTap: CGFloat = 2.0
    
    // MARK: -  内部属性
    /// 当前显示的图片序号，从0开始
    private var currentIndex = 0 {
        didSet {
            animatorCoordinator?.updateCurrentHiddenView(relatedView)
            guard let dlg = pageControlDelegate, let pageControl = self.pageControl else {
                return
            }
            dlg.photoBrowserPageControl(pageControl, didChangedCurrentPage: currentIndex)
        }
    }
    
    /// 当前正在显示视图的前一个页面关联视图
    private var relatedView: UIView? {
        return photoBrowserDelegate?.photoBrowser(self, thumbnailViewForIndex: currentIndex)
    }
    
    /// 转场协调器
    private weak var animatorCoordinator: ScaleAnimatorCoordinator?
    
    /// presentation转场动画
    private weak var presentationAnimator: ScaleAnimator?
    
    /// 本VC的presentingViewController
    private let presentingVC: UIViewController
    
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
    
    /// PageControl
    private lazy var pageControl: UIView? = { [unowned self] in
        return self.pageControlDelegate?.pageControlOfPhotoBrowser(self)
    }()
    
    /// 保存原windowLevel
    private var originWindowLevel: UIWindowLevel!
    
    // MARK: - 公开方法
    /// 初始化，传入用于present出本VC的VC，以及实现了PhotoBrowserDelegate协议的对象
    public init(showByViewController presentingVC: UIViewController, delegate: PhotoBrowserDelegate) {
        self.presentingVC = presentingVC
        self.photoBrowserDelegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        #if DEBUG
            print("deinit:\(self)")
        #endif
    }
    
    /// 展示，传入图片序号，从0开始
    public func show(index: Int) {
        currentIndex = index
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
        self.modalPresentationCapturesStatusBarAppearance = true
        presentingVC.present(self, animated: true, completion: nil)
    }
    
    /// 便利的展示方法，合并init和show两个步骤
    public class func show(byViewController presentingVC: UIViewController, delegate: PhotoBrowserDelegate, index: Int) {
        let vc = PhotoBrowser(showByViewController: presentingVC, delegate: delegate)
        vc.show(index: index)
    }
    
    // MARK: - 内部方法
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 遮盖状态栏
        coverStatusBar(true)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 页面出来后，再显示页码指示器
        // 多于一张图才会显示
        if let pcdlg = pageControlDelegate, pcdlg.numberOfPages > 1, let pc = pageControl {
            view.addSubview(pc)
            pcdlg.photoBrowserPageControl(pc, needLayoutIn: view)
        }
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layoutViews()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 屏幕旋转后的调整
        let indexPath = IndexPath.init(item: self.currentIndex, section: 0)
        self.collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
    }
    
    /// 支持旋转
    public override var shouldAutorotate: Bool {
        return true
    }
    
    /// 支持旋转的方向
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    /// 添加视图
    private func setupViews() {
        view.addSubview(collectionView)
    }
    
    /// 视图布局
    private func layoutViews() {
        // flowLayout
        flowLayout.minimumLineSpacing = photoSpacing
        flowLayout.itemSize = view.bounds.size
        // collectionView
        collectionView.frame = view.bounds
    }
    
    /// 遮盖状态栏。以改变windowLevel的方式遮盖
    private func coverStatusBar(_ cover: Bool) {
        let win = view.window ?? UIApplication.shared.keyWindow
        guard let window = win else {
            return
        }
        
        if originWindowLevel == nil {
            originWindowLevel = window.windowLevel
        }
        if cover {
            window.windowLevel = UIWindowLevelStatusBar + 1
        } else {
            window.windowLevel = originWindowLevel
        }
    }
}

extension PhotoBrowser: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let delegate = photoBrowserDelegate else {
            return 0
        }
        return delegate.numberOfPhotos(in: self)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(PhotoBrowserCell.self), for: indexPath) as! PhotoBrowserCell
        cell.imageView.contentMode = imageScaleMode
        cell.photoBrowserCellDelegate = self
        let (image, highQualityUrl, rawUrl) = imageFor(index: indexPath.item)
        cell.setImage(image, highQualityUrl: highQualityUrl, rawUrl: rawUrl)
        cell.imageMaximumZoomScale = imageMaximumZoomScale
        cell.imageZoomScaleForDoubleTap = imageZoomScaleForDoubleTap
        return cell
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

// MARK: - UICollectionViewDelegate

extension PhotoBrowser: UICollectionViewDelegate {
    /// 减速完成后，计算当前页
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let width = scrollView.frame.width + photoSpacing
        currentIndex = Int(offsetX / width)
    }
}

// MARK: - 转场动画

extension PhotoBrowser: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
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
        let animator = ScaleAnimator(startView: relatedView, endView: cell?.imageView, scaleView: imageView)
        presentationAnimator = animator
        return animator
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let cell = collectionView.visibleCells.first as? PhotoBrowserCell else {
            return nil
        }
        let imageView = UIImageView(image: cell.imageView.image)
        imageView.contentMode = imageScaleMode
        imageView.clipsToBounds = true
        return ScaleAnimator(startView: cell.imageView, endView: relatedView, scaleView: imageView)
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let coordinator = ScaleAnimatorCoordinator(presentedViewController: presented, presenting: presenting)
        coordinator.currentHiddenView = relatedView
        animatorCoordinator = coordinator
        return coordinator
    }
}

// MARK: - PhotoBrowserCellDelegate

extension PhotoBrowser: PhotoBrowserCellDelegate {
    public func photoBrowserCellDidSingleTap(_ view: PhotoBrowserCell) {
        coverStatusBar(false)
        dismiss(animated: true, completion: nil)
    }
    
    public func photoBrowserCell(_ view: PhotoBrowserCell, didPanScale scale: CGFloat) {
        // 实测用scale的平方，效果比线性好些
        let alpha = scale * scale
        animatorCoordinator?.maskView.alpha = alpha
        // 半透明时重现状态栏，否则遮盖状态栏
        coverStatusBar(alpha >= 1.0)
    }
    
    public func photoBrowserCell(_ cell: PhotoBrowserCell, didLongPressWith image: UIImage) {
        if let indexPath = collectionView.indexPath(for: cell) {
            photoBrowserDelegate?.photoBrowser(self, didLongPressForIndex: indexPath.item, image: image)
        }
    }
}

