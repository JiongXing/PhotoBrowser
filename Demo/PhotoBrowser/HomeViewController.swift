//
//  HomeViewController.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2018/8/12.
//  Copyright © 2018年 JiongXing. All rights reserved.
//

import UIKit

final class HomeViewController: UITableViewController {
    
    var dataSources: [[String: UIViewController]] = [
        ["本地图片-全量加载": LocalImageFullLoadViewController()],
        ["本地图片-懒加载": LocalImageLazyLoadViewController()],
    ]
    
    private let reusedId = "reused"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "JXPhotoBrowser"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reusedId)
    }
}

extension HomeViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSources.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reusedId) ?? UITableViewCell.init(style: .default, reuseIdentifier: reusedId)
        cell.textLabel?.text = dataSources[indexPath.row].first.map { $0.key }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if let vc = dataSources[indexPath.row].first.map({ $0.value }) {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
