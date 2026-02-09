//
//  MediaThumbnailView.swift
//  Demo
//
//  Created by jxing on 2026/2/9.
//

import SwiftUI

/// 单个媒体缩略图（固定正方形，等比拉伸铺满）
struct MediaThumbnailView: View {
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
            .contentShape(Rectangle())
    }
}
