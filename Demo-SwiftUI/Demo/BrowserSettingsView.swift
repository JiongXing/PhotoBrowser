//
//  BrowserSettingsView.swift
//  Demo
//
//  浏览器设置面板：控制转场动画类型和滚动方向
//

import SwiftUI
import JXPhotoBrowser

// MARK: - SwiftUI 侧的枚举类型

/// 转场动画类型（映射 JXPhotoBrowserTransitionType）
/// 注意：Zoom 转场需要通过 delegate 获取列表中缩略图的 UIView 引用，
/// SwiftUI 的 AsyncImage 无法提供底层 UIView，因此 SwiftUI 仅支持 Fade 和 None。
enum TransitionType: String, CaseIterable, Identifiable {
    case fade = "淡入淡出"
    case none = "无"
    
    var id: String { rawValue }
    
    /// 转换为框架的转场类型
    var browserTransitionType: JXPhotoBrowserTransitionType {
        switch self {
        case .fade: return .fade
        case .none: return .none
        }
    }
}

/// 滚动方向（映射 JXPhotoBrowserScrollDirection）
enum ScrollDirection: String, CaseIterable, Identifiable {
    case horizontal = "水平"
    case vertical = "垂直"
    
    var id: String { rawValue }
    
    /// 转换为框架的滚动方向
    var browserScrollDirection: JXPhotoBrowserScrollDirection {
        switch self {
        case .horizontal: return .horizontal
        case .vertical: return .vertical
        }
    }
}

// MARK: - 设置面板视图

/// 浏览器设置面板
/// 控制图片大图浏览器的转场动画和滚动方向
struct BrowserSettingsView: View {
    @Binding var transitionType: TransitionType
    @Binding var scrollDirection: ScrollDirection
    
    var body: some View {
        VStack(spacing: 16) {
            // 转场动画选择
            HStack {
                Text("转场动画")
                    .font(.subheadline)
                    .frame(width: 70, alignment: .leading)
                Picker("转场动画", selection: $transitionType) {
                    ForEach(TransitionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // 滚动方向选择
            HStack {
                Text("滚动方向")
                    .font(.subheadline)
                    .frame(width: 70, alignment: .leading)
                Picker("滚动方向", selection: $scrollDirection) {
                    ForEach(ScrollDirection.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .padding(.horizontal, 12)
    }
}

#Preview {
    BrowserSettingsView(
        transitionType: .constant(.fade),
        scrollDirection: .constant(.horizontal)
    )
}
