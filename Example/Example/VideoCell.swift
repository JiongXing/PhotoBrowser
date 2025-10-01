//
//  VideoCell.swift
//  Example
//
//  Created by JiongXing on 2019/12/13.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import JXPhotoBrowser

class VideoCell: UIView, JXPhotoBrowserCell {
    
    weak var photoBrowser: JXPhotoBrowser?
    
    lazy var player = AVPlayer()
    lazy var playerLayer = AVPlayerLayer(player: player)
    
    static func generate(with browser: JXPhotoBrowser) -> Self {
        let instance = Self.init(frame: .zero)
        instance.photoBrowser = browser
        return instance
    }
    
    required override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = .black
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(click))
        addGestureRecognizer(tap)
        
        layer.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    @objc private func click() {
        photoBrowser?.dismiss()
    }
    
    func prepareForReuse() {
        // 停止播放并清理播放器状态
        player.pause()
        player.replaceCurrentItem(with: nil)
    }
}
