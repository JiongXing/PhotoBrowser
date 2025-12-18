//
//  JXBasicImageCell.swift
//  JXPhotoBrowser
//

import UIKit

/// 仅用于基础图片展示的 Cell
/// 不支持缩放、手势等高级功能，主要用于嵌入式场景（如 Banner）
open class JXBasicImageCell: UICollectionViewCell, JXPhotoBrowserCellProtocol {
    
    // MARK: - Public Properties
    
    /// 浏览器实例（由框架自动注入）
    public weak var browser: JXPhotoBrowser?
    
    /// 当前真实索引（由框架自动注入）
    public var currentIndex: Int?
    
    /// 当前 Cell 对应的资源
    public var resource: JXPhotoResource? {
        didSet {
            reloadContent()
        }
    }
    
    /// 复用标识符
    public static let reuseIdentifier = "JXBasicImageCell"
    
    // MARK: - Private Properties
    
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
        JXPhotoBrowserImageLoaderConfig.shared.cancel(for: imageView)
        imageView.image = nil
        resource = nil
        currentIndex = nil
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
    
    /// 加载图片资源
    private func reloadContent() {
        guard let res = resource else {
            imageView.image = nil
            return
        }
        
        let placeholder: UIImage? = {
            guard let thumbURL = res.thumbnailURL else { return nil }
            return JXPhotoBrowserImageLoaderConfig.shared.cachedImage(for: thumbURL)
        }()
        
        JXPhotoBrowserImageLoaderConfig.shared.setImage(on: imageView, url: res.imageURL, placeholder: placeholder) { [weak self] _ in
            guard let self = self else { return }
            self.setNeedsLayout()
        }
    }
}
