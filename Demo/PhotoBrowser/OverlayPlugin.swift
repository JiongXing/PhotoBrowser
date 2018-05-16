//
//  OverlayPlugin.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2018/5/13.
//  Copyright © 2018年 JiongXing. All rights reserved.
//

import Foundation
import JXPhotoBrowser

/// 附加视图插件
class OverlayPlugin: PhotoBrowserCellPlugin {
    
    /// 点删除按钮回调
    var didTouchDeleteButton: ((_ index: Int) -> Void)?
    
    /// 视图数据源
    static var dataSource = [AdditionalModel(showButton: false, text: nil),
                             AdditionalModel(showButton: true, text: "   啊啊啊~"),
                             AdditionalModel(showButton: false, text: nil),
                             AdditionalModel(showButton: false, text: nil),
                             AdditionalModel(showButton: false, text: nil),
                             AdditionalModel(showButton: true, text: "   喵喵进化~"),
                             AdditionalModel(showButton: false, text: nil),
                             AdditionalModel(showButton: false, text: "   抱抱大腿~"),
                             AdditionalModel(showButton: false, text: nil)]
    
    /// 每次取复用 cell 时会调用
    func photoBrowserCellDidReused(_ cell: PhotoBrowserCell, at index: Int) {
        let additionalView = (cell.associatedObjects["OverlayPlugin"] as? AdditionalView) ?? {
            let view = AdditionalView()
            view.didTouchDeleteButton = { [weak self] index in
                OverlayPlugin.dataSource.remove(at: index)
                self?.didTouchDeleteButton?(index)
            }
            cell.contentView.addSubview(view)
            cell.associatedObjects["OverlayPlugin"] = view
            return view
            }()
        additionalView.configure(OverlayPlugin.dataSource[index])
        additionalView.index = index
    }
    
    /// PhotoBrowserCell 执行布局方法时调用
    func photoBrowserCellDidLayout(_ cell: PhotoBrowserCell) {
        if let view = cell.associatedObjects["OverlayPlugin"] as? AdditionalView {
            let height: CGFloat = 100
            view.frame = CGRect(x: 0,
                                y: cell.contentView.bounds.height - height,
                                width: cell.contentView.bounds.width,
                                height: height)
            view.setNeedsLayout()
        }
    }
    
    class AdditionalView: UIView {
        /// 所在 cell 索引
        var index = 0
        
        /// 点删除按钮回调
        var didTouchDeleteButton: ((_ index: Int) -> Void)?
        
        /// 文本视图
        lazy var label: UILabel = {
            let lab = UILabel()
            lab.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            lab.textColor = .white
            lab.font = UIFont.systemFont(ofSize: 15)
            lab.numberOfLines = 0
            return lab
        }()
        
        /// 按钮
        lazy var button: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            btn.setTitleColor(.white, for: .normal)
            btn.setTitle("删除", for: .normal)
            return btn
        }()
        
        init() {
            super.init(frame: .zero)
            addSubview(label)
            addSubview(button)
            button.addTarget(self, action: #selector(onButton), for: .touchUpInside)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            label.frame = self.bounds
            button.sizeToFit()
            let x = self.bounds.width - 20 - button.bounds.width
            let y = self.bounds.height - 20 - button.bounds.height
            button.frame = CGRect(x: x, y: y, width: button.bounds.width, height: button.bounds.height)
        }
        
        @objc private func onButton() {
            didTouchDeleteButton?(index)
        }
        
        func configure(_ model: AdditionalModel) {
            button.isHidden = !model.showButton
            label.text = model.text
            label.isHidden = model.text == nil
        }
    }
    
    struct AdditionalModel {
        let showButton: Bool
        let text: String?
    }
}
