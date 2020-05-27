//
//  MultipleCellViewController.swift
//  Example
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class MultipleCellViewController: BaseCollectionViewController {
    
    override class func name() -> String { "多种类视图" }
    override class func remark() -> String { "支持不同的类作为项视图，如在最后一页显示更多推荐" }
    
    override func makeDataSource() -> [ResourceModel] {
        makeLocalDataSource()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        cell.imageView.image = self.dataSource[indexPath.item].localName.flatMap { UIImage(named: $0) }
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        let browser = JXPhotoBrowser()
        browser.numberOfItems = {
            self.dataSource.count + 1
        }
        browser.cellClassAtIndex = { index in
            if index < self.dataSource.count {
                return JXPhotoBrowserImageCell.self
            }
            return MoreCell.self
        }
        browser.reloadCellAtIndex = { context in
            if context.index < self.dataSource.count {
                let browserCell = context.cell as? JXPhotoBrowserImageCell
                let indexPath = IndexPath(item: context.index, section: indexPath.section)
                browserCell?.imageView.image = self.dataSource[indexPath.item].localName.flatMap { UIImage(named: $0) }
            }
        }
        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
            if index < self.dataSource.count {
                let path = IndexPath(item: index, section: indexPath.section)
                let cell = collectionView.cellForItem(at: path) as? BaseCollectionViewCell
                return cell?.imageView
            }
            return nil
        })
        browser.pageIndex = indexPath.item
        browser.show()
    }
}

class MoreCell: UIView, JXPhotoBrowserCell {
    
    weak var photoBrowser: JXPhotoBrowser?
    
    static func generate(with browser: JXPhotoBrowser) -> Self {
        let instance = Self.init(frame: .zero)
        instance.photoBrowser = browser
        return instance
    }
    
    var onClick: (() -> Void)?
    
    lazy var button: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("  更多 +  ", for: .normal)
        btn.setTitleColor(UIColor.darkText, for: .normal)
        return btn
    }()
    
    required override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = .white
        addSubview(button)
        button.addTarget(self, action: #selector(click), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button.sizeToFit()
        button.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }
    
    @objc private func click() {
        photoBrowser?.dismiss()
    }
}
