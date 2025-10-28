//
//  JXPhotoCell.swift
//  JXPhotoBrowser
//

import UIKit

/// 仅作为容器的 Cell，不参与具体内容加载
class JXPhotoCell: UICollectionViewCell {
    // MARK: - Static
    static let reuseIdentifier = "JXPhotoCell"

    // MARK: - UI
    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .black
        return v
    }()

    private weak var transitionView: UIView?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        // 移除旧内容视图
        containerView.subviews.forEach { $0.removeFromSuperview() }
        transitionView = nil
    }

    // MARK: - Content Embedding
    func setContentView(_ view: UIView) {
        containerView.subviews.forEach { $0.removeFromSuperview() }
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        // 若未设置转场视图，默认使用当前内容视图
        if transitionView == nil { transitionView = view }
    }

    func setTransitionView(_ view: UIView?) {
        transitionView = view
    }

    // MARK: - Transition Helper
    /// 若调用方提供的是 UIImageView，则可参与几何匹配 Zoom 动画
    var transitionImageView: UIImageView? { transitionView as? UIImageView }
}
