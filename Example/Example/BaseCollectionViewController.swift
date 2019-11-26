//
//  BaseCollectionViewController.swift
//  JXPhotoBrwoser_Example
//
//  Created by JiongXing on 2018/10/14.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit

class BaseCollectionViewController: UICollectionViewController {

    /// 数据源
    var dataSource: [ResourceModel] = []
    
    /// 名称
    var name: String {
        return ""
    }
    
    /// 说明
    var remark: String {
        return ""
    }
    
    let reusedId = "reused"
    
    private var flowLayout: UICollectionViewFlowLayout
    
    init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        self.flowLayout = flowLayout
        super.init(collectionViewLayout: flowLayout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = name
        collectionView?.backgroundColor = .white
        collectionView?.jx.registerCell(BaseCollectionViewCell.self)
        dataSource = makeDataSource()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let insetValue: CGFloat = 30
        let totalWidth: CGFloat = view.bounds.width - insetValue * 2
        let colCount = 3
        let spacing: CGFloat = 10.0
        let sideLength: CGFloat = (totalWidth - 2 * spacing) / CGFloat(colCount)
        
        flowLayout.minimumLineSpacing = spacing
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.itemSize = CGSize(width: sideLength, height: sideLength)
        flowLayout.sectionInset = UIEdgeInsets.init(top: insetValue, left: insetValue, bottom: insetValue, right: insetValue)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    // 子类重写
    func makeDataSource() -> [ResourceModel] {
        return []
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        openPhotoBrowser(with: collectionView, indexPath: indexPath)
    }
    
    // 子类重写
    func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {}
}
