//
//  JXImageCell.swift
//  JXPhotoBrowser
//

import UIKit

/// 轻量级图片展示 Cell
/// 不支持缩放、手势等高级功能，适用于 Banner 等嵌入式场景
open class JXImageCell: UICollectionViewCell, JXPhotoBrowserCellProtocol {
    
    // MARK: - Public Properties
    
    /// 复用标识符
    public static let reuseIdentifier = "JXImageCell"
    
    /// 内部图片视图，仅做展示
    public let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    // MARK: - Lifecycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    // MARK: - Private Methods
    
    /// 初始化 UI 布局
    private func setupUI() {
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        backgroundColor = .clear
    }
}
