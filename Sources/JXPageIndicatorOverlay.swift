//
//  JXPageIndicatorOverlay.swift
//  JXPhotoBrowser
//

import UIKit

/// 页码指示器组件（UIPageControl 样式）
///
/// 使用方法：
/// ```swift
/// let browser = JXPhotoBrowser()
/// browser.addOverlay(JXPageIndicatorOverlay())
/// ```
///
/// 支持自定义样式：
/// ```swift
/// let indicator = JXPageIndicatorOverlay()
/// indicator.position = .bottom(padding: 20)
/// indicator.pageControl.currentPageIndicatorTintColor = .white
/// indicator.pageControl.pageIndicatorTintColor = .gray
/// browser.addOverlay(indicator)
/// ```
open class JXPageIndicatorOverlay: UIView, JXPhotoBrowserOverlay {
    
    // MARK: - 位置枚举
    
    /// 指示器在浏览器中的位置
    public enum Position {
        /// 底部居中，padding 为距底部的距离
        case bottom(padding: CGFloat)
        /// 顶部居中，padding 为距顶部的距离
        case top(padding: CGFloat)
        
        /// 默认位置：底部距离 12pt
        public static var `default`: Position { .bottom(padding: 12) }
    }
    
    // MARK: - Public Properties
    
    /// 内部 UIPageControl，可直接访问以自定义样式
    public let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.isUserInteractionEnabled = false
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()
    
    /// 指示器位置（默认底部居中，距底部 12pt）
    open var position: Position = .default {
        didSet { setNeedsUpdatePosition = true }
    }
    
    /// 仅有一页时是否自动隐藏（默认 true）
    open var hidesForSinglePage: Bool = true
    
    // MARK: - Private Properties
    
    /// 位置约束，用于更新位置时替换
    private var positionConstraint: NSLayoutConstraint?
    private var centerXConstraint: NSLayoutConstraint?
    private var setNeedsUpdatePosition = false
    
    /// 弱引用宿主浏览器
    private weak var browser: JXPhotoBrowserViewController?
    
    // MARK: - Lifecycle
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - JXPhotoBrowserOverlay
    
    open func setup(with browser: JXPhotoBrowserViewController) {
        self.browser = browser
        updatePositionConstraints()
    }
    
    open func reloadData(numberOfItems: Int, pageIndex: Int) {
        pageControl.numberOfPages = numberOfItems
        pageControl.currentPage = min(pageIndex, max(numberOfItems - 1, 0))
        
        if hidesForSinglePage {
            isHidden = numberOfItems <= 1
        }
        
        if setNeedsUpdatePosition {
            setNeedsUpdatePosition = false
            updatePositionConstraints()
        }
    }
    
    open func didChangedPageIndex(_ index: Int) {
        pageControl.currentPage = index
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.topAnchor.constraint(equalTo: topAnchor),
            pageControl.bottomAnchor.constraint(equalTo: bottomAnchor),
            pageControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            pageControl.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    /// 根据 position 更新约束
    private func updatePositionConstraints() {
        guard let container = superview else { return }
        
        // 移除旧约束
        positionConstraint?.isActive = false
        centerXConstraint?.isActive = false
        
        // 创建新约束
        let centerX = centerXAnchor.constraint(equalTo: container.centerXAnchor)
        
        let posConstraint: NSLayoutConstraint
        switch position {
        case .bottom(let padding):
            posConstraint = bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -padding)
        case .top(let padding):
            posConstraint = topAnchor.constraint(equalTo: container.topAnchor, constant: padding)
        }
        
        centerX.isActive = true
        posConstraint.isActive = true
        
        centerXConstraint = centerX
        positionConstraint = posConstraint
    }
}
