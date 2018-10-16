//
//  HomeViewController.swift
//  JXPhotoBrwoser_Example
//
//  Created by JiongXing on 2018/10/14.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit

final class HomeViewController: UITableViewController {

    var dataSources: [BaseCollectionViewController] = []
    
    private let reusedId = "reused"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "JXPhotoBrowser"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reusedId)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataSources = makeDataSource()
    }
    
    private func makeDataSource() -> [BaseCollectionViewController] {
        return [
            LocalImageViewController(),
            LongPressedViewController(),
            LocalDefaultPageControlViewController(),
            LocalNumberControlViewController(),
            ZoomViewController(),
            ZoomFrameViewController(),
            NetworkingImageViewController(),
            RawImageViewController(),
            GIFImageViewController(),
            WebpImageViewController()
        ]
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
