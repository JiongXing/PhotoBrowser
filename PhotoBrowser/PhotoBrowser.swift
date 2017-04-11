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
public protocol PhotoBrowserDelegate {
    /// 实现本方法以返回图片数量
    func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int
    
    /// 实现本方法以返回默认图片，缩略图或占位图
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage
    
    /// 实现本方法以返回默认图所在view，在转场动画完成后将会修改这个view的hidden属性
    /// 比如你可返回ImageView，或整个Cell
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView
    
    /// 实现本方法以返回高质量图片。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityImageForIndex index: Int) -> UIImage?
    
    /// 实现本方法以返回高质量图片的url。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlStringForIndex index: Int) -> URL?
    
    /// 长按时回调
    func photoBrowser(_ photoBrowser: PhotoBrowser, didLongPressForIndex index: Int, image: UIImage)
}

/// 适配器
public extension PhotoBrowserDelegate {
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityImageForIndex: Int) -> UIImage? {
        return nil
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlStringForIndex: Int) -> URL? {
        return nil
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, didLongPressForIndex index: Int, image: UIImage) {}
}

// MARK: - PhotoBrowser

public class PhotoBrowser: UIViewController {
    // MARK: - 属性
    
    /// 实现了PhotoBrowserDelegate协议的对象
    public var photoBrowserDelegate: PhotoBrowserDelegate
    
    /// 左右两张图之间的间隙
    public var photoSpacing: CGFloat = 30
    
    /// 图片缩放模式
    public var imageScaleMode = UIViewContentMode.scaleAspectFill
    
    /// 是否显示pageControl。默认true
    public var isShowPageControl = true {
        didSet {
            pageControl.isHidden = !isShowPageControl
        }
    }
    
    /// 当前显示的图片序号，从0开始
    fileprivate var currentIndex = 0 {
        didSet {
            animatorCoordinator?.updateCurrentHiddenView(relatedView)
            if isShowPageControl {
                pageControl.currentPage = currentIndex
            }
        }
    }
    
    /// 当前正在显示视图的前一个页面关联视图
    fileprivate var relatedView: UIView {
        return photoBrowserDelegate.photoBrowser(self, thumbnailViewForIndex: currentIndex)
    }
    
    /// 转场协调器
    fileprivate weak var animatorCoordinator: ScaleAnimatorCoordinator?
    
    /// presentation转场动画
    fileprivate weak var presentationAnimator: ScaleAnimator?
    
    /// 本VC的presentingViewController
    fileprivate let presentingVC: UIViewController
    
    /// 容器
    fileprivate let collectionView: UICollectionView
    
    /// 容器layout
    private let flowLayout: PhotoBrowserLayout
    
    /// PageControl
    fileprivate let pageControl = UIPageControl()
    
    // MARK: - 方法
    
    /// 初始化，传入用于present本VC的VC，以及实现了PhotoBrowserDelegate协议的对象
    public init(showByViewController presentingVC: UIViewController, delegate: PhotoBrowserDelegate) {
        self.presentingVC = presentingVC
        self.photoBrowserDelegate = delegate
        flowLayout = PhotoBrowserLayout()
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 展示
    public func show(index: Int) {
        if isShowPageControl {
            pageControl.numberOfPages = self.photoBrowserDelegate.numberOfPhotos(in: self)
        }
        currentIndex = index
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
        self.modalPresentationCapturesStatusBarAppearance = true
        presentingVC.present(self, animated: true, completion: nil)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // flowLayout
        flowLayout.minimumLineSpacing = photoSpacing
        flowLayout.itemSize = view.bounds.size
        
        // collectionView
        collectionView.frame = view.bounds
        collectionView.backgroundColor = UIColor.clear
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoBrowserCell.self, forCellWithReuseIdentifier: NSStringFromClass(PhotoBrowserCell.self))
        view.addSubview(collectionView)
        
        // pageControl
        if isShowPageControl {
            pageControl.sizeToFit()
            view.addSubview(pageControl)
        }
        
        // 立即加载collectionView
        let indexPath = IndexPath(item: currentIndex, section: 0)
        collectionView.reloadData()
        collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        collectionView.layoutIfNeeded()
        // 取当前应显示的cell，完善转场动画器的设置
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoBrowserCell {
            presentationAnimator?.endView = cell.imageView
            let imageView = UIImageView(image: cell.imageView.image)
            imageView.contentMode = imageScaleMode
            imageView.clipsToBounds = true
            presentationAnimator?.scaleView = imageView
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        if isShowPageControl {
            pageControl.center = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - 20)
        }
    }
    
    override public var shouldAutorotate: Bool {
        return false
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension PhotoBrowser: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoBrowserDelegate.numberOfPhotos(in: self)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(PhotoBrowserCell.self), for: indexPath) as! PhotoBrowserCell
        cell.imageView.contentMode = imageScaleMode
        cell.photoBrowserCellDelegate = self
        let (image, url) = imageFor(index: indexPath.item)
        cell.setImage(image, url: url)
        return cell
    }
    
    /// 取已有图像，若有高清图，只返回高清图，否则返回缩略图和url
    private func imageFor(index: Int) -> (UIImage, URL?) {
        if let highQualityImage = photoBrowserDelegate.photoBrowser(self, highQualityImageForIndex: index) {
            return (highQualityImage, nil)
        }
        var highQualityUrl: URL?
        if let url = photoBrowserDelegate.photoBrowser(self, highQualityUrlStringForIndex: index) {
            var cacheImage: UIImage?
            let result = KingfisherManager.shared.cache.isImageCached(forKey: url.cacheKey)
            if result.cached, let cacheType = result.cacheType {
                switch cacheType {
                case .memory:
                    cacheImage = KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: url.cacheKey)
                case .disk:
                    cacheImage = KingfisherManager.shared.cache.retrieveImageInDiskCache(forKey: url.cacheKey)
                default:
                    cacheImage = nil
                }
            }
            if cacheImage != nil {
                return (cacheImage!, nil)
            }
            highQualityUrl = url
        }
        let thumbnailImage = photoBrowserDelegate.photoBrowser(self, thumbnailImageForIndex: index)
        return (thumbnailImage, highQualityUrl)
    }
}

// MARK: - UICollectionViewDelegate

extension PhotoBrowser: UICollectionViewDelegate {
    /// 减速完成后，计算当前页
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let width = scrollView.bounds.width + photoSpacing
        currentIndex = Int(offsetX / width)
    }
}

// MARK: - 转场动画

extension PhotoBrowser: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // 在本方法被调用时，endView和scaleView还未确定。需于viewDidLoad方法中给animator赋值endView
        let animator = ScaleAnimator(startView: relatedView, endView: nil, scaleView: nil)
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
        dismiss(animated: true, completion: nil)
    }
    
    public func photoBrowserCell(_ view: PhotoBrowserCell, didPanScale scale: CGFloat) {
        // 实测用scale的平方，效果比线性好些
        animatorCoordinator?.maskView.alpha = scale * scale
    }
    
    public func photoBrowserCell(_ cell: PhotoBrowserCell, didLongPressWith image: UIImage) {
        if let indexPath = collectionView.indexPath(for: cell) {
            photoBrowserDelegate.photoBrowser(self, didLongPressForIndex: indexPath.item, image: image)
        }
    }
}

