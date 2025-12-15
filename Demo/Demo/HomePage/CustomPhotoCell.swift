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
    
    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        let g = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        g.minimumPressDuration = 0.5
        return g
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
        
        scrollView.addGestureRecognizer(longPressGesture)
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
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard let browser = browser, let resource = currentResource else { return }
        let downloadTitle = resource.videoURL == nil ? "下载图片到系统相册" : "下载视频到系统相册"
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: downloadTitle, style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.downloadFrom(resource: resource, presentingViewController: browser)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = contentView
            popover.sourceRect = contentView.bounds
        }
        browser.present(alert, animated: true)
    }
    
    private func downloadFrom(resource: JXPhotoResource, presentingViewController: UIViewController) {
        requestPhotoAuthorization { granted in
            guard granted else {
                DispatchQueue.main.async {
                    self.presentToast(message: "未获得相册权限，无法保存", on: presentingViewController)
                }
                return
            }
            
            if let videoURL = resource.videoURL {
                self.downloadVideoAndSave(videoURL, presentingViewController: presentingViewController)
            } else {
                self.downloadImageAndSave(resource.imageURL, presentingViewController: presentingViewController)
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
    
    private func downloadImageAndSave(_ url: URL, presentingViewController: UIViewController) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.presentToast(message: "图片下载失败", on: presentingViewController)
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
        }.resume()
    }
    
    private func downloadVideoAndSave(_ url: URL, presentingViewController: UIViewController) {
        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    self.presentToast(message: "视频下载失败", on: presentingViewController)
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
            }) { success, _ in
                DispatchQueue.main.async {
                    self.presentToast(message: success ? "已保存到系统相册" : "保存失败", on: presentingViewController)
                }
            }
        }.resume()
    }
    
    private func presentToast(message: String, on viewController: UIViewController) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        viewController.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak alert] in
            alert?.dismiss(animated: true)
        }
    }
}
