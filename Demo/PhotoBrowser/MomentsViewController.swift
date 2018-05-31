//
//  MomentsViewController.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2017/3/9.
//  Copyright © 2017年 JiongXing. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class MomentsViewController: UITableViewController {

    private var thumbnailImageSections: [[String]] = []
    private var highQualityImageSections: [[String]] = []
    private var overlayModelSections: [[OverlayModel]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        (0..<6).forEach { _ in
            thumbnailImageSections.append([
                "http://wx3.sinaimg.cn/thumbnail/bfc243a3gy1febm7nzbz7j20ib0iek5j.jpg",
                "http://wx1.sinaimg.cn/thumbnail/bfc243a3gy1febm7n9eorj20i60hsann.jpg",
                "http://wx1.sinaimg.cn/thumbnail/bfc243a3gy1febm7orgqfj20i80ht15x.jpg",
                "http://wx2.sinaimg.cn/thumbnail/bfc243a3gy1febm7pmnk7j20i70jidwo.jpg",
                "http://wx3.sinaimg.cn/thumbnail/bfc243a3gy1febm7qjop4j20i00hw4c6.jpg",
                "http://wx4.sinaimg.cn/thumbnail/bfc243a3gy1febm7rncxaj20ek0i74dv.jpg",
                "http://wx2.sinaimg.cn/thumbnail/bfc243a3gy1febm7sdk4lj20ib0i714u.jpg",
                "http://wx4.sinaimg.cn/thumbnail/bfc243a3gy1febm7tekewj20i20i4aoy.jpg",
                "http://wx3.sinaimg.cn/thumbnail/bfc243a3gy1febm7usmc8j20i543zngx.jpg"
                ])
            highQualityImageSections.append([
                "http://wx3.sinaimg.cn/large/bfc243a3gy1febm7nzbz7j20ib0iek5j.jpg",
                "http://wx1.sinaimg.cn/large/bfc243a3gy1febm7n9eorj20i60hsann.jpg",
                "http://wx1.sinaimg.cn/large/bfc243a3gy1febm7orgqfj20i80ht15x.jpg",
                "http://wx2.sinaimg.cn/large/bfc243a3gy1febm7pmnk7j20i70jidwo.jpg",
                "http://wx3.sinaimg.cn/large/bfc243a3gy1febm7qjop4j20i00hw4c6.jpg",
                "http://wx4.sinaimg.cn/large/bfc243a3gy1febm7rncxaj20ek0i74dv.jpg",
                "http://wx2.sinaimg.cn/large/bfc243a3gy1febm7sdk4lj20ib0i714u.jpg",
                "http://wx4.sinaimg.cn/large/bfc243a3gy1febm7tekewj20i20i4aoy.jpg",
                "http://wx3.sinaimg.cn/large/bfc243a3gy1febm7usmc8j20i543zngx.jpg"
                ])
            overlayModelSections.append([])
        }
        overlayModelSections[1] = [
            OverlayModel(showButton: true, text: nil),
            OverlayModel(showButton: true, text: "   啊啊啊~"),
            OverlayModel(showButton: true, text: nil),
            OverlayModel(showButton: true, text: nil),
            OverlayModel(showButton: true, text: nil),
            OverlayModel(showButton: true, text: "   喵喵进化~"),
            OverlayModel(showButton: true, text: nil),
            OverlayModel(showButton: true, text: "   抱抱大腿~"),
            OverlayModel(showButton: true, text: nil)
        ]
        tableView.register(MomentsTableViewCell.self, forCellReuseIdentifier: String(describing: MomentsTableViewCell.self))
        tableView.tableFooterView = UIView()
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
            self.tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return thumbnailImageSections.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier:
            String(describing: MomentsTableViewCell.self)) as? MomentsTableViewCell)
            ?? MomentsTableViewCell()
        cell.didTouchDeleteButton = { [weak self] index in
            self?.thumbnailImageSections[indexPath.row].remove(at: index)
            self?.highQualityImageSections[indexPath.row].remove(at: index)
            self?.overlayModelSections[indexPath.row].remove(at: index)
            self?.configureCellData(cell: cell, indexPath: indexPath)
            cell.deleteItem(at: index)
        }
        configureCellData(cell: cell, indexPath: indexPath)
        cell.reloadData()
        return cell
    }

    private func configureCellData(cell: MomentsTableViewCell, indexPath: IndexPath) {
        cell.thumbnailImageUrls = thumbnailImageSections[indexPath.row]
        cell.highQualityImageUrls = highQualityImageSections[indexPath.row]
        cell.overlayModels = overlayModelSections[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = (tableView.dequeueReusableCell(withIdentifier:
            String(describing: MomentsTableViewCell.self)) as? MomentsTableViewCell)
            ?? MomentsTableViewCell()
        return cell.height(for: tableView.bounds.width)
    }
}
