//
//  BannerSettingsView.swift
//  Demo
//
//  Banner 设置面板：控制无限循环和自动轮播行为
//

import SwiftUI

/// Banner 设置面板
/// 控制 Banner 的无限循环和自动轮播行为，选项变更实时生效
struct BannerSettingsView: View {
    @Binding var isLoopingEnabled: Bool
    @Binding var isAutoPlayEnabled: Bool
    
    var body: some View {
        HStack(spacing: 24) {
            // 无限循环开关
            Toggle("无限循环", isOn: $isLoopingEnabled)
                .font(.subheadline)
            
            // 自动轮播开关
            Toggle("自动轮播", isOn: $isAutoPlayEnabled)
                .font(.subheadline)
        }
        .toggleStyle(.switch)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .padding(.horizontal, 12)
    }
}

#Preview {
    BannerSettingsView(
        isLoopingEnabled: .constant(true),
        isAutoPlayEnabled: .constant(true)
    )
}
