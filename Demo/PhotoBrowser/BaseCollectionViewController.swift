//
//  BaseViewController.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2018/8/12.
//  Copyright © 2018年 JiongXing. All rights reserved.
//

import UIKit

class BaseCollectionViewController: UICollectionViewController {
    
    /// 数据源
    var dataSource: [PhotoModel] = []
    
    /// 右上角的开关标题
    var switchTitle: String? {
        return nil
    }
    
    /// 右上角开关
    var switchView: UISwitch?
    
    /// 右上角开关是否处于打开中
    var isSWitchOn: Bool {
        if let swi = switchView {
            return swi.isOn
        }
        return false
    }
    
    /// 名称
    var name: String {
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
        dataSource = makeDataSource()
        if let swiTitle = switchTitle {
            let titleItem = UIBarButtonItem(title: swiTitle, style: .plain, target: nil, action: nil)
            let swi = UISwitch()
            swi.isOn = true
            switchView = swi
            let switchItem = UIBarButtonItem(customView: swi)
            navigationItem.rightBarButtonItems = [switchItem, titleItem]
        }
        
        collectionView?.backgroundColor = .white
        collectionView?.register(MomentsPhotoCollectionViewCell.self, forCellWithReuseIdentifier: reusedId)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let insetValue: CGFloat = 30
        let totalWidth: CGFloat = view.bounds.width - insetValue * 2
        let colCount = 3
        let spacing: CGFloat = 10.0
        let sideLength: CGFloat = (totalWidth - 2 * spacing) / CGFloat(colCount)
        
        flowLayout.minimumLineSpacing = spacing
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.itemSize = CGSize(width: sideLength, height: sideLength)
        flowLayout.sectionInset = UIEdgeInsetsMake(insetValue, insetValue, insetValue, insetValue)
    }
    
    // 子类重写
    func makeDataSource() -> [PhotoModel] {
        return []
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.asyncAfter(deadline: .now() + coordinator.transitionDuration) {
            self.collectionView?.reloadData()
        }
    }
}
