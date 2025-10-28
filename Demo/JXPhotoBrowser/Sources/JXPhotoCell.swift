//
//  JXPhotoCell.swift
//  JXPhotoBrowser
//

import UIKit

protocol JXPhotoCellLifecycleDelegate: AnyObject {
    func photoCellWillReuse(_ cell: JXPhotoCell, lastIndex: Int?)
}

/// 固定图片视图的 Cell，不再动态添加视图
public final class JXPhotoCell: UICollectionViewCell {
    // MARK: - Static
    public static let reuseIdentifier = "JXPhotoCell"
    
    // MARK: - UI
    public let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    // MARK: - Lifecycle Delegate & State
    weak var lifecycleDelegate: JXPhotoCellLifecycleDelegate?
    var currentIndex: Int?
    
    // MARK: - Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        backgroundColor = .black
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    public override func prepareForReuse() {
        super.prepareForReuse()
        // 通知即将复用（携带上一次的 index）
        lifecycleDelegate?.photoCellWillReuse(self, lastIndex: currentIndex)
        // 清空旧图像与状态
        imageView.image = nil
        currentIndex = nil
    }
    
    // MARK: - Transition Helper
    /// 若调用方提供的是 UIImageView，则可参与几何匹配 Zoom 动画
    var transitionImageView: UIImageView? { imageView }

    public override func layoutSubviews() {
        super.layoutSubviews()
        print("imageView.frame: \(imageView.frame)")
    }
}
