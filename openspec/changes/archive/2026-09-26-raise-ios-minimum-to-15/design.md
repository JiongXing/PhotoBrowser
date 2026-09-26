# Design

## Context

见 proposal.md。CodeGraph 定位到 UIKit 的 `DemoViewController.requestPhotoAuthorization` 和 `VideoPlayerCell.saveVideoToAlbum` 内三处 iOS 14 availability 分支；发布源码没有对应旧系统分支。SwiftUI `ContentView` 使用 iOS 16 的 NavigationStack。UIKit 锁定 Kingfisher 6.3.1，其 Pod target 仍为 iOS 10。

## Goals / Non-Goals

**Goals:** 让有效部署配置与支持范围一致，删除永不可达的授权分支，并保留可重复的默认构建路径。

**Non-Goals:** 不改动 Sources、导航结构、相册回调线程、下载/保存流程和浏览器生命周期；不因提高部署目标而升级依赖或语言版本。

## Decisions

1. 主框架、UIKit/Carthage 示例的 project/target Debug/Release 均设为 15.0；SwiftUI 均为 16.0。不添加导航降级包装来降低现有 SwiftUI 示例要求，文档明确两者区别。
2. SwiftPM 使用 `.iOS("15.0")`，保留 tools-version 5.4（`.v15` 枚举要求 PackageDescription 5.5）；podspec/Podfile 使用 `15.0`。Podfile 的 `post_install` 仅将低于 15 的生成 target 提高到 15，保留未来依赖要求的更高版本。直接修改 Pods 会在重新安装时丢失，命令行覆盖也不能解决默认构建。
3. 删除两处相册方法中 iOS 14 检查与 else 分支，保留原有 `.addOnly` 路径、授权状态判断及主线程回调。不引入只有两个调用点的通用权限服务。
4. 通过默认构建、CocoaPods lint、SwiftPM 示例与当前源码 XCFramework 检查集成和隐私清单。授权清理保持运行路径不变，模拟器验证示例启动及可覆盖的授权行为；iOS 15 真机/模拟器不可用时明确记录限制。

## Risks / Trade-offs

- [旧系统不再支持] → 属于用户明确要求的兼容性变更，同步支持文档，发布版本决策由后续发布流程处理。
- [依赖的低部署目标残留] → Podfile 下限钩子并检查生成工程和实际编译，无手工编辑生成目录。
- [仅安装 iOS 27 runtime] → 编译目标检查不等价于 iOS 15 运行验收；交付中区分两者。
- [Carthage 本机未安装] → 尝试准备构建工具；若不能运行则记录必要验收缺口并保留 change，不提前归档。
