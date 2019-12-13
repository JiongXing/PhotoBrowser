//
//  MoreDetailViewController.swift
//  Example
//
//  Created by JiongXing on 2019/11/26.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit
import AVFoundation

class MoreDetailViewController: UIViewController {
    
    lazy var label: UILabel = {
        let lab = UILabel()
        lab.textColor = .black
        lab.text = "< 更多详情 >"
        lab.textAlignment = .center
        return lab
    }()
    
    var player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
//        view.addSubview(label)
        
        let mp4Path = Bundle.main.url(forResource: "novel", withExtension: "MP4")!
        
        let item = AVPlayerItem(asset: AVAsset(url: mp4Path))
        player = AVPlayer(playerItem: item)
        let layer = AVPlayerLayer(player: player)
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player?.play()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        label.frame = view.bounds
    }
}
