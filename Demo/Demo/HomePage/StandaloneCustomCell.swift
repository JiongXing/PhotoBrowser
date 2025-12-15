//
//  StandaloneCustomCell.swift
//  Demo
//
//  示例：不继承JXPhotoCell的自定义Cell
//

import UIKit
import JXPhotoBrowser

/// 独立的自定义Cell示例：不继承JXPhotoCell，只实现协议
class StandaloneCustomCell: UICollectionViewCell, JXPhotoBrowserCellProtocol {
    
    /// 自定义的reuseIdentifier
    static let reuseIdentifier = "StandaloneCustomCell"
    
    // MARK: - JXPhotoBrowserCellProtocol 必需属性
    
    /// 弱引用的浏览器实例（框架会自动设置）
    weak var browser: JXPhotoBrowser?
    
    var currentIndex: Int? {
        didSet {
            loadContent()
        }
    }
    
    // MARK: - UI Components
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()
    
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
    
    private func loadContent() {
        guard let index = currentIndex else {
            imageView.image = nil
            infoLabel.isHidden = true
            return
        }
        let info = "索引: \(index)"
        infoLabel.text = info
        infoLabel.isHidden = false
    }
    
    var transitionImageView: UIImageView? {
        return imageView
    }
    
    var interactiveScrollView: UIScrollView? {
        return nil
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        browser?.dismissSelf()
    }
    
    // MARK: - Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        infoLabel.isHidden = true
        infoLabel.text = nil
        currentIndex = nil
    }
}
