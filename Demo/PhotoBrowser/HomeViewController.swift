//
//  HomeViewController.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2018/8/12.
//  Copyright © 2018年 JiongXing. All rights reserved.
//

import UIKit

final class HomeViewController: UITableViewController {
    
    var dataSources: [BaseCollectionViewController] = []
    
    private let reusedId = "reused"
    
    private func makeDataSource() -> [BaseCollectionViewController] {
        return [
            LocalImageFullLoadViewController(),
            LocalImageLazyLoadViewController(),
            NetworkImageViewController(),
            RawImageViewController(),
            LongPressViewController(),
            GIFViewController(),
            WebPViewController(),
            CellPluginViewController(),
            PopupViewController(),
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "JXPhotoBrowser"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reusedId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 这里每次回首页重建对象，生产中不推荐这样做，自行优化
        dataSources = makeDataSource()
    }
}

extension HomeViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSources.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reusedId) ?? UITableViewCell.init(style: .default, reuseIdentifier: reusedId)
        cell.textLabel?.text = dataSources[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        navigationController?.pushViewController(dataSources[indexPath.row], animated: true)
    }
}
