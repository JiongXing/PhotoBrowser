//
//  ContentView.swift
//  Demo
//
//  主页面：展示 Banner、浏览器设置面板和媒体缩略图网格
//

import SwiftUI

struct ContentView: View {
    /// 媒体数据源
    @State private var items: [DemoMedia] = DemoMedia.makeSampleItems()
    
    /// Banner 设置
    @State private var isLoopingEnabled: Bool = true
    @State private var isAutoPlayEnabled: Bool = true
    
    /// 浏览器设置
    @State private var transitionType: TransitionType = .fade
    @State private var scrollDirection: ScrollDirection = .horizontal
    
    /// 持有浏览器呈现器（JXPhotoBrowser.delegate 为 weak，需要外部强引用）
    @State private var presenter: PhotoBrowserPresenter?
    
    /// 网格列配置：3 列等宽
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    /// Banner 图片资源（从 items 中过滤出图片类型）
    private var bannerResources: [(imageURL: URL, thumbnailURL: URL?)] {
        items.compactMap { media in
            switch media.source {
            case let .remoteImage(imageURL, thumbnailURL):
                return (imageURL, thumbnailURL)
            case .remoteVideo:
                return nil
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Banner 设置面板（无限循环 / 自动轮播）
                    BannerSettingsView(
                        isLoopingEnabled: $isLoopingEnabled,
                        isAutoPlayEnabled: $isAutoPlayEnabled
                    )
                    
                    // 图片轮播 Banner
                    PhotoBannerView(
                        resources: bannerResources,
                        isLoopingEnabled: isLoopingEnabled,
                        isAutoPlayEnabled: isAutoPlayEnabled
                    )
                    .frame(height: 100)
                    .padding(.horizontal, 12)
                    
                    // 浏览器设置面板（转场动画 / 滚动方向）
                    BrowserSettingsView(
                        transitionType: $transitionType,
                        scrollDirection: $scrollDirection
                    )
                    
                    // 缩略图网格
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            MediaThumbnailView(item: item)
                                .onTapGesture {
                                    openBrowser(at: index)
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    /// 打开图片浏览器
    private func openBrowser(at index: Int) {
        let newPresenter = PhotoBrowserPresenter(
            items: items,
            transitionType: transitionType.browserTransitionType,
            scrollDirection: scrollDirection.browserScrollDirection
        )
        self.presenter = newPresenter
        newPresenter.present(initialIndex: index)
    }
}

// MARK: - 缩略图视图

/// 单个媒体缩略图（固定正方形，等比拉伸铺满）
private struct MediaThumbnailView: View {
    let item: DemoMedia
    
    var body: some View {
        Color(.systemGray6)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                AsyncImage(url: item.thumbnailURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .overlay {
                if item.isVideo {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                }
            }
            .clipped()
    }
}

#Preview {
    ContentView()
}
