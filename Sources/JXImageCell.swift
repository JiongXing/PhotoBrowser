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
    
    /// 加载指示器，默认不启用
    /// 设置 `isLoadingIndicatorEnabled = true` 后，通过 `startLoading()` / `stopLoading()` 控制显隐
    /// 可直接修改样式，例如：`cell.loadingIndicator.style = .large`、`cell.loadingIndicator.color = .red`
    public let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = .gray
        return indicator
    }()
    
    /// 是否启用加载指示器（默认 false）
    /// 启用后，调用 `startLoading()` / `stopLoading()` 控制指示器动画
    public var isLoadingIndicatorEnabled: Bool = false {
        didSet {
            if !isLoadingIndicatorEnabled {
                loadingIndicator.stopAnimating()
            }
        }
    }
    
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
        loadingIndicator.stopAnimating()
    }
    
    // MARK: - Public Methods
    
    /// 开始加载动画（需先设置 `isLoadingIndicatorEnabled = true`）
    public func startLoading() {
        guard isLoadingIndicatorEnabled else { return }
        loadingIndicator.startAnimating()
    }
    
    /// 停止加载动画
    public func stopLoading() {
        loadingIndicator.stopAnimating()
    }
    
    // MARK: - Private Methods
    
    /// 初始化 UI 布局
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        backgroundColor = .clear
    }
}
