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
    
    /// 返回可复用的Cell类。用户可根据index返回不同的类。本闭包将在每次复用Cell时实时调用。
    open lazy var cellClassAtIndex: (_ index: Int) -> JXPhotoBrowserCell.Type = { _ in
        JXPhotoBrowserImageCell.self
    }
    
    /// 刷新Cell数据。本闭包将在Cell完成位置布局后调用。
    open lazy var reloadCell: (_ cell: JXPhotoBrowserCell, _ pageIndex: Int) -> Void = { _, _ in }
    
    /// 页码已改变
    open lazy var didChangedPageIndex: (Int) -> Void = { _ in }
    
    /// 滑动方向
    open var scrollDirection: JXPhotoBrowser.ScrollDirection = .horizontal
    
    /// 项间距
    open var itemSpacing: CGFloat = 30
    
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
        JXPhotoBrowserLog.low("deinit - \(self.classForCoder)")
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
    
    //
    // MARK: - 复用Cell
    //
    
    /// 显示中的Cell
    open var visibleCells = [Int: JXPhotoBrowserCell]()
    
    /// 缓存中的Cell
    open var reusableCells = [String: [JXPhotoBrowserCell]]()
    
    /// 入队
    private func enqueue(cell: JXPhotoBrowserCell) {
        let name = String(describing: cell.classForCoder)
        if var array = reusableCells[name] {
            array.append(cell)
            reusableCells[name] = array
        } else {
            reusableCells[name] = [cell]
        }
    }
    
    /// 出队，没缓存则新建
    private func dequeue(cellType: JXPhotoBrowserCell.Type, browser: JXPhotoBrowser) -> JXPhotoBrowserCell {
        var cell: JXPhotoBrowserCell
        let name = String(describing: cellType.classForCoder())
        if var array = reusableCells[name], array.count > 0 {
            JXPhotoBrowserLog.middle("命中缓存！\(name)")
            cell = array.removeFirst()
            reusableCells[name] = array
        } else {
            JXPhotoBrowserLog.middle("新建Cell! \(name)")
            cell = cellType.generate(with: browser)
        }
        return cell
    }
    
    /// 重置所有Cell的位置。更新 visibleCells 和 reusableCells
    open func resetCells() {
        JXPhotoBrowserLog.middle("\(self.classForCoder) resetCells!")
        guard let browser = photoBrowser else {
            return
        }
        // 移除不在显示范围内的cell
        var removingKeys: Set<Int> = []
        let itemsTotalCount = numberOfItems()
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
                JXPhotoBrowserLog.middle("移除 index:\(key)，并入列")
                enqueue(cell: cell)
            }
        }
        // 添加要显示的cell
        for index in (pageIndex - 1)...(pageIndex + 1) {
            if index < 0 || index > itemsTotalCount - 1 {
                continue
            }
            let clazz = cellClassAtIndex(index)
            JXPhotoBrowserLog.middle("Required class name: \(String(describing: clazz))")
            if let cell = visibleCells[index],
                String(describing: cell.classForCoder) == String(describing: clazz) {
                JXPhotoBrowserLog.middle("index:\(index)显示中")
                continue
            }
            JXPhotoBrowserLog.middle("index:\(index) 出列!")
            let cell = dequeue(cellType: clazz, browser: browser)
            visibleCells[index] = cell
            scrollView.addSubview(cell)
        }
    }
    
    /// 刷新所有显示中的Cell位置
    open func layoutCells() {
        JXPhotoBrowserLog.middle("\(self.classForCoder) layoutCells!")
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
            reloadCell(cell, index)
        }
    }
}
