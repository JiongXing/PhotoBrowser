//
//  JXPhotoBrowser.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/11.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

open class JXPhotoBrowser: UIViewController {
    
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
    open lazy var transitionAnimator: JXPhotoBrowserTransitionAnimator = JXPhotoBrowserFadeAnimator()
    
    /// 滑动方向
    open var scrollDirection: JXPhotoBrowser.ScrollDirection {
        set { browserView.scrollDirection = newValue }
        get { browserView.scrollDirection }
    }
    
    /// 项间距
    open var itemSpacing: CGFloat {
        set { browserView.itemSpacing = newValue }
        get { browserView.itemSpacing }
    }
    
    /// 当前页码
    open var pageIndex: Int {
        set { browserView.pageIndex = newValue }
        get { browserView.pageIndex }
    }
    
    /// 浏览过程中实时获取数据总量
    open var numberOfItems: () -> Int {
        set { browserView.numberOfItems = newValue }
        get { browserView.numberOfItems }
    }
    
    /// 返回可复用的Cell类。用户可根据index返回不同的类。本闭包将在每次复用Cell时实时调用。
    open var cellClassAtIndex: (_ index: Int) -> JXPhotoBrowserCell.Type {
        set { browserView.cellClassAtIndex = newValue }
        get { browserView.cellClassAtIndex }
    }
    
    /// Cell刷新时用的上下文。index: 刷新的Cell对应的index；currentIndex: 当前显示的页
    public typealias ReloadCellContext = (cell: JXPhotoBrowserCell, index: Int, currentIndex: Int)
    
    /// 刷新Cell数据。本闭包将在Cell完成位置布局后调用。
    open var reloadCellAtIndex: (ReloadCellContext) -> Void {
        set { browserView.reloadCellAtIndex = newValue }
        get { browserView.reloadCellAtIndex }
    }
    
    /// 自然滑动引起的页码改变时回调
    open var didChangedPageIndex: (_ idnex: Int) -> Void {
        set { browserView.didChangedPageIndex = newValue }
        get { browserView.didChangedPageIndex }
    }
    
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
    
    deinit {
        JXPhotoBrowserLog.low("deinit - \(self.classForCoder)")
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        browserView.photoBrowser = self
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 显示图片浏览器
    open func show(method: ShowMethod = .present(fromVC: nil, embed: nil)) {
        switch method {
        case .push(let inNC):
            let nav = inNC ?? JXPhotoBrowser.topMost?.navigationController
            nav?.pushViewController(self, animated: false)
        case .present(let fromVC, let embed):
            let toVC = embed?(self) ?? self
            toVC.modalPresentationStyle = .custom
            toVC.modalPresentationCapturesStatusBarAppearance = true
            let from = fromVC ?? JXPhotoBrowser.topMost
            from?.present(toVC, animated: false, completion: nil)
        }
    }
    
    /// 刷新
    open func reloadData() {
        browserView.reloadData()
        pageIndicator?.reloadData(numberOfItems: numberOfItems(), pageIndex: pageIndex)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        JXPhotoBrowserLog.low("Browser viewDidLoad! frame:\(view.frame) bounds:\(view.bounds)")
        
        automaticallyAdjustsScrollViewInsets = false
        hideNavigationBar(true)
        
        view.backgroundColor = .clear
        view.addSubview(maskView)
        view.addSubview(browserView)
        maskView.alpha = 0
        browserView.alpha = 0
        
        browserView.didChangedPageIndex = { [weak self] index in
            self?.pageIndicator?.didChanged(pageIndex: index)
        }
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        JXPhotoBrowserLog.low("Browser viewWillLayoutSubviews! frame:\(view.frame) bounds:\(view.bounds)")
        maskView.frame = view.bounds
        browserView.frame = view.bounds
        pageIndicator?.reloadData(numberOfItems: numberOfItems(), pageIndex: pageIndex)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        JXPhotoBrowserLog.low("Browser viewDidLayoutSubviews! frame:\(view.frame) bounds:\(view.bounds)")
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavigationBar(true)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showAnimationIfNeeded()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hideNavigationBar(false)
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
    
    private var isShowDone = false
    
    private func showAnimationIfNeeded() {
        if isShowDone {
            return
        }
        isShowDone = true
        transitionAnimator.show(browser: self) { [weak self] in
            guard let `self` = self else { return }
            self.setStatusBar(hidden: true)
            self.browserView.alpha = 1
            self.maskView.alpha = 1
            if let indicator = self.pageIndicator {
                self.view.addSubview(indicator)
                indicator.setup(with: self)
                indicator.reloadData(numberOfItems: self.numberOfItems(), pageIndex: self.pageIndex)
            }
        }
    }
    
    /// 销毁PhotoBrowser
    open func dismiss() {
        setStatusBar(hidden: false)
        transitionAnimator.dismiss(browser: self) { [weak self] in
            guard let `self` = self else { return }
            if self.presentingViewController != nil {
                self.dismiss(animated: false, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: false)
            }
        }
    }
    
    //
    // MARK: - Status Bar
    //
    
    private lazy var isPreviousStatusBarHidden: Bool = {
        var previousVC: UIViewController?
        if let vc = self.presentingViewController {
            previousVC = vc
        } else {
            if let navVCs = self.navigationController?.viewControllers, navVCs.count >= 2 {
                previousVC = navVCs[navVCs.count - 2]
            }
        }
        return previousVC?.prefersStatusBarHidden ?? false
    }()
    
    private lazy var isStatusBarHidden = self.isPreviousStatusBarHidden
    
    open override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }
    
    open func setStatusBar(hidden: Bool) {
        if hidden {
            isStatusBarHidden = true
        } else {
            isStatusBarHidden = isPreviousStatusBarHidden
        }
        setNeedsStatusBarAppearanceUpdate()
    }
    
    //
    // MARK: - 取顶层控制器
    //

    /// 取最顶层的ViewController
    open class var topMost: UIViewController? {
        return topMost(of: UIApplication.shared.keyWindow?.rootViewController)
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
