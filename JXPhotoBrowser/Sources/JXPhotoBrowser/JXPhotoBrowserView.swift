//
//  JXPhotoBrowserView.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/14.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

open class JXPhotoBrowserView: UIView, UIScrollViewDelegate {
    
    /// 弱引用PhotoBrowser
    open weak var photoBrowser: JXPhotoBrowser?
    
    /// 询问当前数据总量
    open lazy var numberOfItems: () -> Int = { 0 }
    
    /// 生成单项视图，将会被调用3次以生成3块视图
    open lazy var createCell: (JXPhotoBrowser) -> UIView = { _ in UIView() }
    
    /// Cell刷新数据时调用。pageIndex从0计起
    open lazy var reloadItem: (_ cell: UIView, _ pageIndex: Int) -> Void = { _, _ in }
    
    open lazy var didChangedPageIndex: (Int) -> Void = { _ in}
    
    /// 滑动方向
    open var scrollDirection: JXPhotoBrowser.ScrollDirection = .horizontal
    
    /// 项间距
    open var itemSpacing: CGFloat = 30
    
    open var visibleCells: [Int: UIView] = [:]
    
    open var reusableCells: Set<UIView> = []
    
    /// 当前页码
    open var pageIndex = 0 {
        didSet {
            if pageIndex != oldValue {
                isPageIndexChanged = true
                didChangedPageIndex(pageIndex)
            }
        }
    }
    
    /// 页码是否已改变
    public var isPageIndexChanged = true
    
    /// 容器
    open lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .clear
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.isPagingEnabled = true
        sv.isScrollEnabled = true
        sv.delegate = self
        if #available(iOS 11.0, *) {
            sv.contentInsetAdjustmentBehavior = .never
        }
        return sv
    }()
    
    deinit {
        JXPhotoBrowserLog.low("deinit - \(self)")
    }
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    open func setup() {
        backgroundColor = .clear
        addSubview(scrollView)
    }
    
    /// 刷新数据，同时刷新Cell布局
    open func reloadData() {
        resetCells()
        layoutCells()
        reloadItems()
        refreshContentOffset()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        JXPhotoBrowserLog.low("\(self.classForCoder) layoutSubviews!")
        if scrollDirection == .horizontal {
            scrollView.frame = CGRect(x: 0, y: 0, width: bounds.width + itemSpacing, height: bounds.height)
        } else {
            scrollView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height + itemSpacing)
        }
        reloadData()
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollDirection == .horizontal && scrollView.bounds.width > 0  {
            pageIndex = Int(round(scrollView.contentOffset.x / (scrollView.bounds.width)))
        } else if scrollDirection == .vertical && scrollView.bounds.height > 0 {
            pageIndex = Int(round(scrollView.contentOffset.y / (scrollView.bounds.height)))
        }
        if isPageIndexChanged {
            JXPhotoBrowserLog.low("PageIndexChanged -> \(pageIndex)")
            isPageIndexChanged = false
            resetCells()
            layoutCells()
            reloadItems()
        }
    }
    
    /// 根据页码更新滑动位置
    open func refreshContentOffset() {
        if scrollDirection == .horizontal {
            scrollView.contentOffset = CGPoint(x: CGFloat(pageIndex) * scrollView.bounds.width, y: 0)
        } else {
            scrollView.contentOffset = CGPoint(x: 0, y: CGFloat(pageIndex) * scrollView.bounds.height)
        }
    }
    
    /// 重置所有复用Cell位置。更新 visibleCells 和 reusableCells
    open func resetCells() {
        JXPhotoBrowserLog.low("\(self.classForCoder) resetCells!")
        let itemsTotalCount = numberOfItems()
        // 移除不显示的cell
        var removingKeys: Set<Int> = []
        // 异常数值处理
        if itemsTotalCount <= 0 {
            visibleCells.forEach { key, _ in
                removingKeys.insert(key)
            }
        }
        // 移除距离当前页远的Cell
        for (index, _) in visibleCells where index < pageIndex - 1 || index > pageIndex + 1 {
            removingKeys.insert(index)
        }
        removingKeys.forEach { key in
            if let cell = visibleCells.removeValue(forKey: key) {
                cell.removeFromSuperview()
                reusableCells.insert(cell)
            }
        }
        guard let browser = photoBrowser else {
            return
        }
        // 添加要显示的cell
        for index in (pageIndex - 1)...(pageIndex + 1) {
            if index < 0 || index > itemsTotalCount - 1 {
                continue
            }
            if visibleCells[index] != nil {
                continue
            }
            var cell: UIView
            if reusableCells.count > 0 {
                cell = reusableCells.removeFirst()
            } else {
                cell = createCell(browser)
            }
            scrollView.addSubview(cell)
            visibleCells[index] = cell
        }
    }
    
    /// 刷新所有显示中的Cell位置
    open func layoutCells() {
        JXPhotoBrowserLog.low("\(self.classForCoder) layoutCells!")
        let cellWidth = bounds.width
        let cellHeight = bounds.height
        var sizeWidth: CGFloat = 0
        var sizeHeight: CGFloat = 0
        for (index, cell) in visibleCells {
            if scrollDirection == .horizontal {
                cell.frame = CGRect(x: CGFloat(index) * (cellWidth + itemSpacing), y: 0, width: cellWidth, height: cellHeight)
                sizeWidth = max(sizeWidth, cell.frame.maxX + itemSpacing)
                sizeHeight = cellHeight
            } else {
                cell.frame = CGRect(x: 0, y: CGFloat(index) * (cellHeight + itemSpacing), width: cellWidth, height: cellHeight)
                sizeHeight = max(sizeHeight, cell.frame.maxY + itemSpacing)
                sizeWidth = cellWidth
            }
        }
        scrollView.contentSize = CGSize(width: sizeWidth, height: sizeHeight)
    }
    
    /// 刷新所有Cell的数据
    open func reloadItems() {
        JXPhotoBrowserLog.low("\(self.classForCoder) reloadItems!")
        visibleCells.forEach { index, cell in
            reloadItem(cell, index)
        }
    }
}
