# Repository Guidelines

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

## CodeGraph

- 仓库存在 `.codegraph/` 时，理解实现、追踪调用链或评估改动影响，先调用 `codegraph_explore`；查询中明确文件、符号或起止流程。MCP 不可用时用 `codegraph explore "<query>"`。
- 返回的源码视为已读；只对未覆盖的内容、明确提示过期的文件回退到 `rg` / 文件读取。文档、配置可直接读取。
- 自动同步依赖 watcher 正常工作；索引维护、异常恢复见 [AgentWorkflow.md](Documentation/AgentWorkflow.md#codegraph-维护)。不存在索引时直接回退，只有用户要求初始化时才创建。
- 调用图用于定位和影响分析，不能证明行为正确；Demo 引用也不等于自动化测试覆盖。

## AI Agent 开发流程

完整操作说明：[Documentation/AgentWorkflow.md](Documentation/AgentWorkflow.md)。

1. **确认范围**：检查分支与工作区，保留已有修改；给出可验证的成功标准。
2. **选择路径**：文档、小修复、恢复既定行为可直接修改；新增功能、公开 API / 行为变化、跨组件重构先建 OpenSpec change。用户明确要求使用 OpenSpec 时按其要求执行。
3. **读取依据**：需求依据在 `openspec/specs/` 和对应 `openspec/changes/`；实现依据通过 CodeGraph 定位。发现冲突先说明，不能把当前实现自动视为正确需求。
4. **实施与验证**：按任务逐项实现，完成后才勾选；验证按下表和工作流文档选择，不把静态检查称为构建或交互验收。
5. **交付与归档**：报告改动、已执行验证、未覆盖项。OpenSpec change 完成且验证通过后同步主规格并归档；提交、推送、发布分别按用户授权执行。

`propose` 适合仅规划的请求，`apply` 执行已有方案。若用户已明确要求端到端完成，按该授权连续推进；不要因自动选用规划技能而丢失原始实施授权。仅在需求歧义影响行为、兼容性或验收时询问。

项目定制规则写在本文件、工作流文档和 `openspec/config.yaml`；`.agents/skills/openspec-*` 由 OpenSpec CLI 生成，不手工维护副本。

## 构建命令

按正在修改的集成方式选择:

| 命令 | 用途 |
|------|------|
| `xcodebuild -scheme JXPhotoBrowser -project JXPhotoBrowser.xcodeproj -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` | 构建主框架 |
| `(cd Demo-UIKit && LANG=en_US.UTF-8 pod install)` | 首次安装或依赖配置变更时同步 UIKit 示例依赖 |
| `xcodebuild -scheme Demo -workspace Demo-UIKit/Demo.xcworkspace -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` | 构建 UIKit / CocoaPods 示例 |
| `xcodebuild -scheme Demo -project Demo-SwiftUI/Demo.xcodeproj -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` | 构建 SwiftUI / SwiftPM 示例 |
| `cd Demo-Carthage && carthage update --use-xcframeworks --platform iOS` | 首次准备 Carthage 示例依赖 |

本库依赖 UIKit；macOS 上直接 `swift build` 不是有效的 iOS 构建验证。SwiftPM 集成使用 SwiftUI 示例的 Xcode 构建验证。发布集成检查以 [.github/workflows/ci.yml](.github/workflows/ci.yml) 为准。

## 架构

### 核心组件
- `JXPhotoBrowserViewController` — 浏览器内核:基于 `UICollectionView` 的分页与复用、循环滚动、Overlay 管理、下拉关闭
- `JXZoomImageCell` — 可缩放图片 Cell(`UIScrollView` 捏合/双击缩放、宽高比适配居中)
- `JXImageCell` — 轻量 Cell,用于内嵌 Banner 场景(无缩放)
- `JXPhotoBrowserCellProtocol` — 自定义 Cell 的最小协议：`browser`、`transitionImageView` 和下拉交互状态回调（均提供默认实现）
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

仓库无独立 `Tests/` 目标。按改动范围验证：
- 仅文档 / Agent 配置：OpenSpec 严格校验（涉及规格时）、链接和 `git diff --check`；无需构建 iOS 或运行 `pod install`。
- Swift 源码：构建主库及受影响的示例；涉及 UI / 生命周期时在模拟器验证对应交互，必要时补充真机验证。
- 发布 / 依赖配置：检查受影响的集成方式和隐私清单打包，参考 CI。
- 未执行或环境阻塞的验证必须明确列出；任务仍有必需验收未完成时，不宣称整体完成或归档。
