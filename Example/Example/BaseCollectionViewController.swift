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
    class func name() -> String {
      return ""
    }
    
    /// 说明
    class func remark() -> String {
      return ""
    }
    
    let reusedId = "reused"
    
    private var flowLayout: UICollectionViewFlowLayout
    
    required init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        self.flowLayout = flowLayout
        super.init(collectionViewLayout: flowLayout)
    }
    /*
     // 如果您对不使用 `[weak self]` 会不会造成内存泄漏可以卡开此注释
     deinit {
     print("\(Self.self) deinit! ____#")
     }
     */
    required init?(coder aDecoder: NSCoder) {
        fatalError("使用nib文件初始化时请打开👇注释____#")
        /*
         self.dataSource = []
         self.reusedId = "reused"
         let flowLayout = UICollectionViewFlowLayout()
         flowLayout.scrollDirection = .vertical
         self.flowLayout = flowLayout
         super.init(coder: aDecoder)
         */
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = Self.name()
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
    
    func makeLocalDataSource() -> [ResourceModel] {
        var result: [ResourceModel] = []
        (0..<6).forEach { index in
            let model = ResourceModel()
            model.localName = "local_\(index)"
            result.append(model)
        }
        return result
    }
    
    func makeNetworkDataSource() -> [ResourceModel] {
        var result: [ResourceModel] = []
        guard let url = Bundle.main.url(forResource: "Photos", withExtension: "plist") else {
            return result
        }
        guard let data = try? Data.init(contentsOf: url) else {
            return result
        }
        let decoder = PropertyListDecoder()
        guard let array = try? decoder.decode([[String]].self, from: data) else {
            return result
        }
        array.forEach { item in
            let model = ResourceModel()
            model.firstLevelUrl = item[0]
            model.secondLevelUrl = item[1]
            result.append(model)
        }
        return result
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
