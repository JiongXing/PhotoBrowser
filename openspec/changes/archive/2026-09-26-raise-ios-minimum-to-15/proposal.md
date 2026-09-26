# Proposal

## Why

用户已使用 Xcode 27，并要求将库最低部署目标升级至 iOS 15。现有 SwiftPM、CocoaPods 和主框架仍声明 iOS 12，示例工程还混用 13、16 和 26.x，导致默认构建与对外兼容性声明不一致。

## What Changes

- **BREAKING**：库最低支持系统由 iOS 12 提升至 iOS 15，统一发布配置、主工程及 UIKit/Carthage 示例配置。
- SwiftUI 示例保留现有 iOS 16 最低要求（使用 NavigationStack），将工程级默认值与该要求对齐。
- 删除 UIKit 示例相册授权的 iOS 12/13 分支，直接使用 `.addOnly` API，保持现有保存与拒绝提示行为。
- 同步中英文支持说明、保存指南与项目上下文；通过 CocoaPods 再生成依赖工程，避免 Xcode 27 继续编译低于 iOS 15 的 Pod target。
- 不改动浏览器公开 API、分页、缩放、转场、视频播放和下载流程，不升级无关依赖或发布版本。

## Capabilities

### New Capabilities

- `platform-support`: 规定库的 iOS 15 最低系统要求、集成配置与示例兼容性，以及保存媒体时的只添加授权。

### Modified Capabilities

无。

## Impact

涉及 Package.swift、podspec、四个 Xcode 工程、UIKit Podfile/生成产物、UIKit 相册授权代码和支持文档。低于 iOS 15 的宿主不能集成升级后的库；库本身继续零第三方依赖。需要验证主框架、CocoaPods、SwiftPM 和当前源码生成的 Carthage XCFramework，并检查隐私清单。
