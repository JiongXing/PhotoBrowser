//
//  HomeViewController.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/11.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class HomeViewController: UITableViewController {
    
    var dataSource: [MakeController] = dataType.map { cls -> MakeController in
        return ( { cls.init() }, cls.name(), cls.remark())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // JXPhotoBrowser配置日志
        JXPhotoBrowserLog.level = .low

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        tableView.jx.registerCell(HomeTableViewCell.self)

        // 触发网络数据访问授权
        guard let url = URL(string: "http://www.baidu.com") else  {
            return
        }
        JXPhotoBrowserLog.low("Request: \(url.absoluteString)")
        URLSession.shared.dataTask(with: url) { (data, resp, _) in
            if let response = resp as? HTTPURLResponse {
                JXPhotoBrowserLog.low("Response statusCode: \(response.statusCode)")
            }
        }.resume()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.jx.dequeueReusableCell(HomeTableViewCell.self)
        let data = dataSource[indexPath.row]
        cell.textLabel?.text = data.title
        cell.detailTextLabel?.text = data.subTitle
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(dataSource[indexPath.row].makeViewController(), animated: true)
    }
}

class HomeTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/*  ViewModel */
typealias MakeController = (makeViewController: () -> BaseCollectionViewController, title: String, subTitle: String)

// MARK: 数据源
private extension HomeViewController {

   static let dataType: [BaseCollectionViewController.Type] = [
      LocalImageViewController.self,
      VerticalBrowseViewController.self,
      VideoPhotoViewController.self,
      ImageZoomViewController.self,
      ImageSmoothZoomViewController.self,
      KingfisherImageViewController.self,
      SDWebImageViewController.self,
      DataSourceDeleteViewController.self,
      DataSourceAppendViewController.self,
      PushNextViewController.self,
      LoadingProgressViewController.self,
      RawImageViewController.self,
      MultipleCellViewController.self,
      MultipleSectionViewController.self,
      DefaultPageIndicatorViewController.self,
      NumberPageIndicatorViewController.self,
      GIFViewController.self
    ]
}
