# Tasks

## 1. 部署配置与依赖

- [x] 1.1 统一库及 UIKit/Carthage 示例为 iOS 15、SwiftUI 示例为 iOS 16；同步中英文支持文档及上下文，以配置扫描确认 Debug/Release 与发布声明一致。
- [x] 1.2 配置 Podfile 的 iOS 15 下限钩子并运行 pod install；确认依赖版本不变、生成工程无低于 15 的 iOS target。

## 2. 相册兼容代码

- [x] 2.1 删除三处 iOS 14 判断及旧授权分支，同步中英文保存指南；审查 diff 确认 `.addOnly` 的既有授权判断、拒绝提示与回调线程保持不变。
- [x] 2.2 构建并在 iOS 27 模拟器启动 UIKit 示例，验证可覆盖的相册授权/保存路径，记录结果及无法覆盖的系统版本。证据：Smoke、Revoked、Authorized 三份 xcresult 各 1 项通过，细节与限制见 validation.md。

## 3. 集成验证

- [x] 3.1 使用不覆盖部署目标的命令构建主框架、UIKit/CocoaPods 和 SwiftUI/SwiftPM 示例，运行 Pod lint；检查产物最低版本及隐私清单。
- [x] 3.2 通过 Carthage 从当前源码生成 XCFramework，构建 Carthage 示例并核对最低版本及隐私清单。
- [x] 3.3 审查完整 diff，执行 OpenSpec 严格校验和 git diff --check；记录证据，必要验收全部完成后同步规格并归档。

配置证据：四个主工程及 Pods 的 project/target Debug/Release 扫描通过；Pods 语义差异仅部署目标变化，Kingfisher 仍为 6.3.1。授权 diff 保留原 iOS 14+ 路径，未新增抽象或改动 Sources。
