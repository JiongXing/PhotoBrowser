# CLAUDE.md

JXPhotoBrowser — 轻量级 iOS 图片/视频浏览器。单一内核 + 协议扩展点,零数据模型依赖。

## 行为准则

**先想清楚,再动手。** 有多种理解时列出来,不要默默选一个;有更简单的方案就直说;不确定就问。

**最小改动。** 只写解决问题所需的代码:不加没被要求的功能、抽象或"灵活性"。不顺手"改进"无关代码、注释或格式;风格以周边代码为准,即使你有不同偏好。自己的改动产生的孤儿(未使用的 import/变量/方法)要清理,但不动既有的死代码——发现了可以提一句。每一行改动都应能追溯到用户的原始请求。

**目标可验证。** 动手前把任务转成可验证的成功标准(如"修 bug"→"先复现,改完确认不再复现"),多步任务先列简短计划,完成后逐项核对。

## 项目结构

- `Sources/` — 正式发布的库源码(浏览器内核、转场动画、Cell、Overlay、`PrivacyInfo.xcprivacy`)
- `Demo-UIKit/` — UIKit 示例(CocoaPods,`pod install` 后开 `Demo.xcworkspace` 而非 `.xcodeproj`)
- `Demo-SwiftUI/` — SwiftUI 桥接示例
- `Demo-Carthage/` — Carthage 集成示例
- 根目录 `Package.swift`、`JXPhotoBrowser.podspec` — SwiftPM / CocoaPods 发布配置

**不要手动修改生成目录**:`Demo-UIKit/Pods/`、`.build/` 等。

## 构建命令

按正在修改的集成方式选择:

| 命令 | 用途 |
|------|------|
| `swift build` | 构建 SwiftPM 库目标 |
| `xcodebuild -scheme JXPhotoBrowser -project JXPhotoBrowser.xcodeproj build` | 构建主框架 |
| `cd Demo-UIKit && pod install` | 安装 UIKit 示例依赖 |
| `xcodebuild -scheme Demo -project Demo-UIKit/Demo.xcodeproj build` | 构建 UIKit 示例 |
| `xcodebuild -scheme Demo -project Demo-SwiftUI/Demo.xcodeproj build` | 构建 SwiftUI 示例 |
| `cd Demo-Carthage && carthage update --use-xcframeworks --platform iOS` | 首次准备 Carthage 示例依赖 |

## 架构

### 核心组件
- `JXPhotoBrowserViewController` — 浏览器内核:基于 `UICollectionView` 的分页与复用、循环滚动、Overlay 管理、下拉关闭
- `JXZoomImageCell` — 可缩放图片 Cell(`UIScrollView` 捏合/双击缩放、宽高比适配居中)
- `JXImageCell` — 轻量 Cell,用于内嵌 Banner 场景(无缩放)
- `JXPhotoBrowserCellProtocol` — 自定义 Cell 的最小协议,仅 2 个属性(`browser`、`transitionImageView`)
- `JXPhotoBrowserDelegate` — 宿主提供数量、Cell 实例、生命周期回调、Zoom 转场缩略图
- `JXPhotoBrowserOverlay` / `JXPageIndicatorOverlay` — 附加 UI 插件协议及内置页码指示器

### 转场动画
`JXZoomPresentAnimator` / `JXZoomDismissAnimator`(微信式 Zoom,缩略图不可用时回退 Fade)、`JXFadeAnimator`、`JXNoneAnimator`。

### 关键设计
- **零数据模型依赖**:数据加载通过 `JXPhotoBrowserDelegate` 委托给宿主
- **虚拟数据源实现循环**:`realCount * loopMultiplier` 映射保持滚动方向连续
- **Overlay 机制**:通过 `addOverlay()` 按需加载附加 UI
- **全屏与 Banner 共用同一内核**:`PhotoBannerView` 以 `transitionType = .none` 复用浏览器控制器

### 自定义参考
- `Demo-UIKit/Demo/HomePage/VideoPlayerCell.swift` — 继承 `JXZoomImageCell` 实现视频播放
- `Demo-UIKit/Demo/HomePage/PhotoBannerView.swift` — 用 `JXImageCell` 复用内核做 Banner

## 代码风格

4 空格缩进;`// MARK:` 分段;公开类型 `JX` 前缀、大驼峰(`JXPhotoBrowserViewController`),属性方法小驼峰(`isLoopingEnabled`);扩展按职责拆分。未配置 SwiftLint/SwiftFormat——以周边文件风格为准。

## 测试与验证

仓库无独立 `Tests/` 目标。提交前:
1. 构建主库及受影响的示例工程
2. 在模拟器中手动验证关键交互:缩放、下拉关闭、循环滚动、SwiftUI 桥接
