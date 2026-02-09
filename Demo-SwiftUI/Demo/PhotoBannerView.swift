//
//  PhotoBannerView.swift
//  Demo
//
//  横向滚动的图片 Banner 视图（SwiftUI 桥接）
//  使用 UIViewControllerRepresentable 嵌入 JXPhotoBrowser，支持分页滚动、循环滚动和自动轮播
//

import SwiftUI
import JXPhotoBrowser
import Kingfisher

/// 横向滚动的图片 Banner 视图
/// 通过 UIViewControllerRepresentable 桥接 JXPhotoBrowser，适用于嵌入式 Banner 场景
struct PhotoBannerView: UIViewControllerRepresentable {
    
    /// 图片资源列表（imageURL, thumbnailURL）
    let resources: [(imageURL: URL, thumbnailURL: URL?)]
    
    /// 是否启用无限循环滚动
    var isLoopingEnabled: Bool = true
    
    /// 是否启用自动轮播
    var isAutoPlayEnabled: Bool = true
    
    // MARK: - UIViewControllerRepresentable
    
    func makeCoordinator() -> Coordinator {
        Coordinator(resources: resources)
    }
    
    func makeUIViewController(context: Context) -> JXPhotoBrowser {
        let browser = JXPhotoBrowser()
        browser.delegate = context.coordinator
        browser.scrollDirection = .horizontal
        browser.transitionType = .none
        browser.isLoopingEnabled = isLoopingEnabled
        browser.itemSpacing = 8
        browser.isAutoPlayEnabled = isAutoPlayEnabled
        browser.autoPlayInterval = 3.0
        browser.register(JXImageCell.self, forReuseIdentifier: JXImageCell.reuseIdentifier)
        
        // 装载页码指示器
        let pageIndicator = JXPageIndicatorOverlay()
        pageIndicator.position = .bottom(padding: 0)
        browser.addOverlay(pageIndicator)
        
        // 设置浏览器视图背景为透明，与页面背景融为一体
        browser.view.backgroundColor = .clear
        browser.view.layer.cornerRadius = 12
        browser.view.clipsToBounds = true
        
        return browser
    }
    
    func updateUIViewController(_ browser: JXPhotoBrowser, context: Context) {
        // 同步 SwiftUI 状态到 JXPhotoBrowser
        context.coordinator.resources = resources
        browser.isLoopingEnabled = isLoopingEnabled
        browser.isAutoPlayEnabled = isAutoPlayEnabled
    }
    
    // MARK: - Coordinator
    
    /// 作为 JXPhotoBrowserDelegate，桥接 SwiftUI 数据到 JXPhotoBrowser
    final class Coordinator: NSObject, JXPhotoBrowserDelegate {
        
        /// 图片资源列表
        var resources: [(imageURL: URL, thumbnailURL: URL?)]
        
        init(resources: [(imageURL: URL, thumbnailURL: URL?)]) {
            self.resources = resources
        }
        
        // MARK: - JXPhotoBrowserDelegate
        
        func numberOfItems(in browser: JXPhotoBrowser) -> Int {
            resources.count
        }
        
        func photoBrowser(_ browser: JXPhotoBrowser, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
            let cell = browser.dequeueReusableCell(withReuseIdentifier: JXImageCell.reuseIdentifier, for: indexPath) as! JXImageCell
            let resource = resources[index]
            // 启用加载指示器
            cell.isLoadingIndicatorEnabled = true
            cell.startLoading()
            cell.imageView.kf.setImage(with: resource.imageURL) { [weak cell] _ in
                cell?.stopLoading()
            }
            return cell
        }
    }
}
