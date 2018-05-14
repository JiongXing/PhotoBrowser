//
//  DescriptionPlugin.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2018/5/13.
//  Copyright © 2018年 JiongXing. All rights reserved.
//

import Foundation
import JXPhotoBrowser

/// 图片描述插件
class DescriptionPlugin: PhotoBrowserPlugin {
    
    /// 自定义添加的视图组
    var labels: [UILabel] = []
    
    /// 视图数据源
    var dataSource = ["   进化的喵喵~",
                      "   抱抱大腿~"]
    
    /// 每次取复用 cell 时会调用
    func photoBrowser(_ photoBrowser: PhotoBrowser, reusableCell cell: PhotoBrowserCell, atIndex index: Int) {
        guard index == 5 || index == 7 else {
            return
        }
        let label = (cell.associatedObject as? UILabel) ?? {
            let lab = makeLabel()
            cell.contentView.addSubview(lab)
            cell.associatedObject = lab
            return lab
        }()
        switch index {
        case 5:
            label.text = dataSource[0]
        case 7:
            label.text = dataSource[1]
        default:
            break
        }
    }

    /// PhotoBrowserCell 执行布局方法时调用
    func photoBrowser(_ photoBrowser: PhotoBrowser, didLayout cell: PhotoBrowserCell, at index: Int) {
        guard index == 5 || index == 7 else {
            return
        }
        if let label = cell.associatedObject as? UILabel {
            let height: CGFloat = 100
            label.frame = CGRect(x: 0,
                                 y: cell.contentView.bounds.height - height,
                                 width: cell.contentView.bounds.width,
                                 height: height)
        }
    }
    
    private func makeLabel() -> UILabel {
        let lab = UILabel()
        lab.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        lab.textColor = .white
        lab.font = UIFont.systemFont(ofSize: 15)
        lab.numberOfLines = 0
        return lab
    }
}
