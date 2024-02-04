//
//  JXPhotoBrowser.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/11.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

/// 图片浏览器
/// - 不支持复用，每次使用请新建实例
open class JXPhotoBrowser: UIViewController, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate {
    
    /// 通过本回调，把图片浏览器嵌套在导航控制器里
    public typealias PresentEmbedClosure = (JXPhotoBrowser) -> UINavigationController
    
    /// 打开方式类型
    public enum ShowMethod {
        case push(inNC: UINavigationController?)
        case present(fromVC: UIViewController?, embed: PresentEmbedClosure?)
    }
    
    /// 滑动方向类型
    public enum ScrollDirection {
        case horizontal
        case vertical
    }
    
    /// 自实现转场动画
    open lazy var transitionAnimator: JXPhotoBrowserAnimatedTransitioning = JXPhotoBrowserFadeAnimator()
    
    /// 滑动方向
    open var scrollDirection: JXPhotoBrowser.ScrollDirection {
        set { browserView.scrollDirection = newValue }
        get { return browserView.scrollDirection }
    }
    
    /// 项间距
    open var itemSpacing: CGFloat {
        set { browserView.itemSpacing = newValue }
        get { return browserView.itemSpacing }
    }
    
    /// 当前页码
    open var pageIndex: Int {
        set { browserView.pageIndex = newValue }
        get { return browserView.pageIndex }
    }
    
    /// 浏览过程中实时获取数据总量
    open var numberOfItems: () -> Int {
        set { browserView.numberOfItems = newValue }
        get { return browserView.numberOfItems }
    }
    
    /// 返回可复用的Cell类。用户可根据index返回不同的类。本闭包将在每次复用Cell时实时调用。
    open var cellClassAtIndex: (_ index: Int) -> JXPhotoBrowserCell.Type {
        set { browserView.cellClassAtIndex = newValue }
        get { return browserView.cellClassAtIndex }
    }
    
    /// Cell刷新时用的上下文。index: 刷新的Cell对应的index；currentIndex: 当前显示的页
    public typealias ReloadCellContext = (cell: JXPhotoBrowserCell, index: Int, currentIndex: Int)
    
    /// 刷新Cell数据。本闭包将在Cell完成位置布局后调用。
    open var reloadCellAtIndex: (ReloadCellContext) -> Void {
        set { browserView.reloadCellAtIndex = newValue }
        get { return browserView.reloadCellAtIndex }
    }
    
    /// 自然滑动引起的页码改变时回调
    open lazy var didChangedPageIndex: (_ index: Int) -> Void = { _ in }
    
    /// Cell将显示
    open var cellWillAppear: (JXPhotoBrowserCell, Int) -> Void {
        set { browserView.cellWillAppear = newValue }
        get { return browserView.cellWillAppear }
    }
    
    /// Cell将不显示
    open var cellWillDisappear: (JXPhotoBrowserCell, Int) -> Void {
        set { browserView.cellWillDisappear = newValue }
        get { return browserView.cellWillDisappear }
    }
    
    /// Cell已显示
    open var cellDidAppear: (JXPhotoBrowserCell, Int) -> Void {
        set { browserView.cellDidAppear = newValue }
        get { return browserView.cellDidAppear }
    }
    
    /// 即将dismiss
    /// - Returns: 是否执行动画
    open var willDismiss: ((JXPhotoBrowser) -> Bool)?
    
    /// 已经dismiss
    open var didDismiss: ((JXPhotoBrowser) -> Void)?
    
    /// 主视图
    open lazy var browserView = JXPhotoBrowserView()
    
    /// 页码指示
    open var pageIndicator: JXPhotoBrowserPageIndicator?
    
    /// 背景蒙版
    open lazy var maskView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    open weak var previousNavigationControllerDelegate: UINavigationControllerDelegate?
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 显示图片浏览器
    open func show(method: ShowMethod = .present(fromVC: nil, embed: nil)) {
        switch method {
        case .push(let inNC):
            let nav = inNC ?? JXPhotoBrowser.topMost?.navigationController
            previousNavigationControllerDelegate = nav?.delegate
            nav?.delegate = self
            nav?.pushViewController(self, animated: true)
        case .present(let fromVC, let embed):
            let toVC = embed?(self) ?? self
            toVC.modalPresentationStyle = .custom
            toVC.transitioningDelegate = self
            let from = fromVC ?? JXPhotoBrowser.topMost
            from?.present(toVC, animated: true, completion: nil)
        }
    }
    
    /// 刷新
    open func reloadData() {
        browserView.reloadData()
        pageIndicator?.reloadData(numberOfItems: numberOfItems(), pageIndex: pageIndex)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        hideNavigationBar(true)
        
        browserView.photoBrowser = self
        transitionAnimator.photoBrowser = self
        
        view.backgroundColor = .clear
        view.addSubview(maskView)
        view.addSubview(browserView)
        
        browserView.didChangedPageIndex = { [weak self] index in
            guard let `self` = self else { return }
            self.pageIndicator?.didChanged(pageIndex: index)
            self.didChangedPageIndex(index)
        }
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        maskView.frame = view.bounds
        browserView.frame = view.bounds
        pageIndicator?.reloadData(numberOfItems: numberOfItems(), pageIndex: pageIndex)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavigationBar(true)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.delegate = previousNavigationControllerDelegate
        if let indicator = pageIndicator {
            view.addSubview(indicator)
            indicator.setup(with: self)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideNavigationBar(false)
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        browserView.isRotating = true
    }
    
    //
    // MARK: - Navigation Bar
    //
    
    /// 在PhotoBrowser打开之前，导航栏是否隐藏
    open var isPreviousNavigationBarHidden: Bool?
    
    private func hideNavigationBar(_ hide: Bool) {
        if hide {
            if isPreviousNavigationBarHidden == nil {
                isPreviousNavigationBarHidden = navigationController?.isNavigationBarHidden
            }
            navigationController?.setNavigationBarHidden(true, animated: false)
        } else {
            if let barHidden = isPreviousNavigationBarHidden {
                navigationController?.setNavigationBarHidden(barHidden, animated: false)
            }
        }
    }
    
    //
    // MARK: - 转场
    //
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isForShow = true
        transitionAnimator.photoBrowser = self
        return transitionAnimator
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isForShow = false
        transitionAnimator.photoBrowser = self
        return transitionAnimator
    }
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isForShow = (operation == .push)
        transitionAnimator.photoBrowser = self
        transitionAnimator.isNavigationAnimation = true
        return transitionAnimator
    }
    
    /// 关闭PhotoBrowser
    open func dismiss() {
        let animated = willDismiss?(self) ?? true
        pageIndicator?.removeFromSuperview()
        if presentingViewController != nil {
            presentingViewController?.dismiss(animated: animated) { [weak self] in
                if let `self` = self {
                    self.didDismiss?(self)
                }
            }
        } else {
            navigationController?.delegate = self
            navigationController?.popViewController(animated: animated)
            didDismiss?(self)
        }
    }
    
    deinit {
        JXPhotoBrowserLog.low("deinit - \(self.classForCoder)")
        navigationController?.delegate = previousNavigationControllerDelegate
    }
    
    //
    // MARK: - 取顶层控制器
    //

    /// 取最顶层的ViewController
    open class var topMost: UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
        return topMost(of: keyWindow?.rootViewController)
    }
    
    open class func topMost(of viewController: UIViewController?) -> UIViewController? {
        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            return self.topMost(of: presentedViewController)
        }
        
        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return self.topMost(of: selectedViewController)
        }
        
        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return self.topMost(of: visibleViewController)
        }
        
        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 {
            return self.topMost(of: pageViewController.viewControllers?.first)
        }
        
        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return self.topMost(of: childViewController)
            }
        }
        
        return viewController
    }
}
