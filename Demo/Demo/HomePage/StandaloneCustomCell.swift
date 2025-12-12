//
//  StandaloneCustomCell.swift
//  Demo
//
//  示例：不继承JXPhotoCell的自定义Cell
//

import UIKit
import JXPhotoBrowser
import Kingfisher

/// 独立的自定义Cell示例：不继承JXPhotoCell，只实现协议
class StandaloneCustomCell: UICollectionViewCell, JXPhotoBrowserCellProtocol {
    
    /// 自定义的reuseIdentifier
    static let reuseIdentifier = "StandaloneCustomCell"
    
    // MARK: - JXPhotoBrowserCellProtocol 必需属性
    
    /// 弱引用的浏览器实例（框架会自动设置）
    weak var browser: JXPhotoBrowser?
    
    /// 当前关联的真实索引（框架会自动设置）
    /// 监听此属性的变化来加载对应的内容
    var currentIndex: Int? {
        didSet {
            loadContent()
        }
    }
    
    // MARK: - UI Components
    
    /// 图片视图
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()
    
    /// 自定义标签
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .black
        
        contentView.addSubview(imageView)
        contentView.addSubview(infoLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            infoLabel.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        // 添加单击手势关闭浏览器
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Content Loading
    
    /// 加载内容（自定义实现，不依赖框架的reloadContent）
    private func loadContent() {
        guard let browser = browser, let index = currentIndex else {
            imageView.image = nil
            infoLabel.isHidden = true
            return
        }
        
        // 从delegate获取资源（使用自定义的数据模型或框架的JXPhotoResource）
        if let resource = browser.delegate?.photoBrowser(browser, resourceForItemAt: index) {
            // 加载图片
            imageView.kf.setImage(with: resource.imageURL) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    // 显示信息
                    let info = "索引: \(index)\n类型: \(resource.videoURL != nil ? "视频" : "图片")"
                    self.infoLabel.text = info
                    self.infoLabel.isHidden = false
                case .failure:
                    self.infoLabel.text = "加载失败"
                    self.infoLabel.isHidden = false
                }
            }
        } else {
            imageView.image = nil
            infoLabel.isHidden = true
        }
    }
    
    /// 用于转场动画的视图（可选）
    var transitionImageView: UIImageView? {
        return imageView
    }
    
    /// 用于下拉关闭手势的滚动视图（可选，此示例不支持下拉关闭）
    var interactiveScrollView: UIScrollView? {
        return nil  // 返回nil表示不支持下拉关闭功能
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        browser?.dismissSelf()
    }
    
    // MARK: - Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        infoLabel.isHidden = true
        infoLabel.text = nil
        currentIndex = nil
    }
}

