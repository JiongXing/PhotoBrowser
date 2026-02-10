//
//  PhotoBrowserPresenter.swift
//  Demo
//
//  封装 JXPhotoBrowserViewController 的创建、配置和呈现逻辑
//

import UIKit
import SwiftUI
import JXPhotoBrowser
import Kingfisher

// MARK: - 浏览器呈现器

/// 封装 JXPhotoBrowserViewController 的创建、配置和呈现
/// 实现 JXPhotoBrowserDelegate，作为 SwiftUI 与 UIKit 浏览器之间的桥梁
final class PhotoBrowserPresenter: JXPhotoBrowserDelegate {
    private let items: [DemoMedia]
    private let transitionType: JXPhotoBrowserTransitionType
    private let scrollDirection: JXPhotoBrowserScrollDirection
    
    init(
        items: [DemoMedia],
        transitionType: JXPhotoBrowserTransitionType,
        scrollDirection: JXPhotoBrowserScrollDirection
    ) {
        self.items = items
        self.transitionType = transitionType
        self.scrollDirection = scrollDirection
    }
    
    /// 从当前窗口呈现浏览器
    func present(initialIndex: Int) {
        guard let viewController = Self.topViewController() else { return }
        
        let browser = JXPhotoBrowserViewController()
        browser.delegate = self
        browser.initialIndex = initialIndex
        browser.transitionType = transitionType
        browser.scrollDirection = scrollDirection
        browser.itemSpacing = 20
        
        // 添加页码指示器
        let pageIndicator = JXPageIndicatorOverlay()
        browser.addOverlay(pageIndicator)
        
        browser.present(from: viewController)
    }
    
    // MARK: - JXPhotoBrowserDelegate
    
    func numberOfItems(in browser: JXPhotoBrowserViewController) -> Int {
        items.count
    }
    
    func photoBrowser(_ browser: JXPhotoBrowserViewController, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
        let cell = browser.dequeueReusableCell(withReuseIdentifier: JXZoomImageCell.reuseIdentifier, for: indexPath) as! JXZoomImageCell
        return cell
    }
    
    func photoBrowser(_ browser: JXPhotoBrowserViewController, willDisplay cell: JXPhotoBrowserAnyCell, at index: Int) {
        guard let photoCell = cell as? JXZoomImageCell else { return }
        guard let imageURL = items[index].fullImageURL else { return }
        
        // 先尝试从 Kingfisher 缓存中获取缩略图作为占位图
        var placeholder: UIImage?
        if let thumbnailURL = items[index].thumbnailURL {
            placeholder = ImageCache.default.retrieveImageInMemoryCache(forKey: thumbnailURL.cacheKey)
        }
        
        // 先展示缩略图占位，再加载全尺寸原图
        photoCell.imageView.kf.setImage(
            with: imageURL,
            placeholder: placeholder
        ) { [weak photoCell] _ in
            photoCell?.setNeedsLayout()
        }
    }
    
    // MARK: - 获取顶层 ViewController
    
    private static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            return nil
        }
        
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }
}
