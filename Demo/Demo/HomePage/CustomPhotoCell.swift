//
//  CustomPhotoCell.swift
//  Demo
//
//  自定义Cell示例：演示如何创建和使用自定义Cell
//

import UIKit
import JXPhotoBrowser

/// 自定义图片Cell示例
/// 继承自JXPhotoCell，可以添加自定义UI和功能
class CustomPhotoCell: JXPhotoCell {
    
    /// 自定义的reuseIdentifier（可选，如果不提供会自动生成）
    static let customReuseIdentifier = "CustomPhotoCell"
    
    /// 自定义标签：显示图片信息
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCustomUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCustomUI()
    }
    
    /// 设置自定义UI
    private func setupCustomUI() {
        // 添加自定义标签
        contentView.addSubview(infoLabel)
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 重置自定义状态
        infoLabel.isHidden = true
        infoLabel.text = nil
    }
    
    /// 配置自定义信息（示例方法）
    func configureInfo(_ text: String) {
        infoLabel.text = text
        infoLabel.isHidden = text.isEmpty
    }
    
    override func reloadContent() {
        super.reloadContent()
        
        // 在内容加载后，可以添加自定义逻辑
        // 例如：显示图片信息
        if let index = currentIndex, let resource = currentResource {
            let info = "索引: \(index)\n类型: \(resource.videoURL != nil ? "视频" : "图片")"
            configureInfo(info)
        }
    }
}
