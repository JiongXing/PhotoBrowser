//
//  CustomPhotoCell.swift
//  Demo
//
//  自定义Cell示例：演示如何创建和使用自定义Cell
//

import UIKit
import Photos
import JXPhotoBrowser

/// 自定义图片Cell示例
/// 继承自JXPhotoCell，可以添加自定义UI和功能
class CustomPhotoCell: JXPhotoCell {
    
    // MARK: - Static Properties
    
    /// 自定义的reuseIdentifier
    static let customReuseIdentifier = "CustomPhotoCell"
    
    // MARK: - Public Properties
    
    /// 当前索引（由业务方设置，用于显示信息）
    var currentIndex: Int?
    
    // MARK: - Private Properties
    
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
    
    /// 长按手势
    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        let g = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        g.minimumPressDuration = 0.5
        return g
    }()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCustomUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCustomUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 重置自定义状态
        currentIndex = nil
        infoLabel.isHidden = true
        infoLabel.text = nil
    }
    
    // MARK: - Private Methods
    
    /// 设置自定义UI
    private func setupCustomUI() {
        // 添加自定义标签
        contentView.addSubview(infoLabel)
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        scrollView.addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - Public Methods
    
    /// 配置自定义信息
    /// - Parameter text: 要显示的文本
    func configureInfo(_ text: String) {
        infoLabel.text = text
        infoLabel.isHidden = text.isEmpty
    }
    
    /// 重写 setImage 以添加自定义逻辑
    override func setImage(_ image: UIImage?) {
        super.setImage(image)
        
        // 在图片设置后，显示索引信息
        if let index = currentIndex {
            let info = "索引: \(index)\n类型: 图片"
            configureInfo(info)
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard let browser = browser else { return }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "下载图片到系统相册", style: .default, handler: { [weak self] _ in
            guard let self = self, let image = self.imageView.image else { return }
            self.saveImageToAlbum(image, presentingViewController: browser)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = contentView
            popover.sourceRect = contentView.bounds
        }
        browser.present(alert, animated: true)
    }
    
    /// 保存图片到相册
    private func saveImageToAlbum(_ image: UIImage, presentingViewController: UIViewController) {
        requestPhotoAuthorization { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                DispatchQueue.main.async {
                    self.presentToast(message: "未获得相册权限，无法保存", on: presentingViewController)
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, _ in
                DispatchQueue.main.async {
                    self.presentToast(message: success ? "已保存到系统相册" : "保存失败", on: presentingViewController)
                }
            }
        }
    }
    
    private func requestPhotoAuthorization(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            completion(true)
            return
        }
        
        PHPhotoLibrary.requestAuthorization { newStatus in
            completion(newStatus == .authorized)
        }
    }
    
    private func presentToast(message: String, on viewController: UIViewController) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        viewController.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak alert] in
            alert?.dismiss(animated: true)
        }
    }
}
