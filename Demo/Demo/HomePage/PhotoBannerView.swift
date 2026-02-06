//
//  PhotoBannerView.swift
//  Demo
//
//  Created on 2025/12/17.
//

import UIKit
import JXPhotoBrowser
import Kingfisher

/// 横向滚动的图片 Banner 视图
/// 使用 JXPhotoBrowser 实现，支持分页滚动和循环滚动
class PhotoBannerView: UIView {
    
    // MARK: - Public Properties
    
    /// Banner 高度（默认 100pt）
    public var bannerHeight: CGFloat = 100 {
        didSet {
            heightConstraint?.constant = bannerHeight
        }
    }
    
    /// 左右两侧边距（默认 12pt）
    public var horizontalMargin: CGFloat = 12 {
        didSet {
            leadingConstraint?.constant = horizontalMargin
            trailingConstraint?.constant = -horizontalMargin
        }
    }
    
    /// 图片资源列表（imageURL, thumbnailURL）
    public var resources: [(imageURL: URL, thumbnailURL: URL?)] = [] {
        didSet {
            browser?.collectionView.reloadData()
        }
    }
    
    /// 是否启用无限循环滚动
    public var isLoopingEnabled: Bool = true {
        didSet {
            browser?.isLoopingEnabled = isLoopingEnabled
        }
    }
    
    /// 图片之间的间距
    public var itemSpacing: CGFloat = 8 {
        didSet {
            browser?.itemSpacing = itemSpacing
        }
    }
    
    /// 是否启用自动轮播（默认 true）
    public var isAutoPlayEnabled: Bool = true {
        didSet {
            browser?.isAutoPlayEnabled = isAutoPlayEnabled
        }
    }
    
    /// 自动轮播间隔时间（默认 3.0 秒）
    public var autoPlayInterval: TimeInterval = 3.0 {
        didSet {
            browser?.autoPlayInterval = autoPlayInterval
        }
    }
    
    // MARK: - Private Properties
    
    /// 嵌入的图片浏览器
    private var browser: JXPhotoBrowser?
    
    /// 高度约束
    private var heightConstraint: NSLayoutConstraint?
    
    /// 左侧边距约束
    private var leadingConstraint: NSLayoutConstraint?
    
    /// 右侧边距约束
    private var trailingConstraint: NSLayoutConstraint?
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBrowser()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBrowser()
    }
    
    // MARK: - Public Methods
    
    /// 配置 Banner 数据
    /// - Parameter resources: 图片资源数组（imageURL, thumbnailURL）
    public func configure(with resources: [(imageURL: URL, thumbnailURL: URL?)]) {
        self.resources = resources
    }
    
    // MARK: - Private Methods
    
    /// 初始化并设置图片浏览器
    private func setupBrowser() {
        backgroundColor = .clear
        
        let browser = JXPhotoBrowser()
        browser.delegate = self
        browser.scrollDirection = .horizontal
        browser.transitionType = .none
        browser.isLoopingEnabled = true
        browser.itemSpacing = 8  // 设置图片之间的间距
        browser.isAutoPlayEnabled = true  // 开启自动轮播
        browser.autoPlayInterval = 3.0  // 轮播间隔 3 秒
        browser.register(JXBasicImageCell.self, forReuseIdentifier: JXBasicImageCell.reuseIdentifier)
        
        // 装载页码指示器
        let pageIndicator = JXPageIndicatorOverlay()
        pageIndicator.position = .bottom(padding: 0)
        browser.addOverlay(pageIndicator)
        
        // 设置浏览器视图背景为透明，与页面背景融为一体
        browser.view.backgroundColor = .clear
        
        // 将浏览器视图添加到当前视图，并设置左右边距
        let browserView = browser.view!
        browserView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(browserView)
        
        let leading = browserView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalMargin)
        let trailing = browserView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalMargin)
        leadingConstraint = leading
        trailingConstraint = trailing
        
        NSLayoutConstraint.activate([
            browserView.topAnchor.constraint(equalTo: topAnchor),
            leading,
            trailing,
            browserView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        self.browser = browser
    }
}

// MARK: - JXPhotoBrowserDelegate

extension PhotoBannerView: JXPhotoBrowserDelegate {
    
    func numberOfItems(in browser: JXPhotoBrowser) -> Int {
        return resources.count
    }
    
    func photoBrowser(_ browser: JXPhotoBrowser, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
        let cell = browser.dequeueReusableCell(withReuseIdentifier: JXBasicImageCell.reuseIdentifier, for: indexPath) as! JXBasicImageCell
        let resource = resources[index]
        // 使用 Kingfisher 加载图片
        cell.imageView.kf.setImage(with: resource.imageURL)
        return cell
    }
}
