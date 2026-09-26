# Validation

## Environment

- 2026-09-26，Xcode 27.0（27A266a），iPhone 17 / iOS 27.0（24A434）模拟器。
- 本机仅安装 iOS 27 runtime；未执行 iOS 15/16 运行或真机验收。
- CocoaPods 1.16.2；本次安装 Carthage 0.40.0 以完成构建验证。

## Configuration and review

- 主框架、UIKit/Carthage 示例以及生成 Pods 的 project/target Debug/Release 均为 15.0；SwiftUI 示例均为 16.0（用户确认保留 NavigationStack）。
- `swift package dump-package` 成功，平台为 15.0；使用字符串部署版本以兼容现有 tools-version 5.4。
- `LANG=en_US.UTF-8 pod install --project-directory=Demo-UIKit` 成功；Kingfisher 保持 6.3.1，lockfile 仅本地 podspec 和 Podfile 校验和变化。
- 生成 Pods 工程的 ID/排序变化已按 target/configuration 解析比较，构建设置语义仅部署目标改变。
- UIKit 相册代码仅删除旧系统分支，保留现有 `.addOnly` 状态判断、回调线程、提示及视频保存状态恢复。发布源码 `Sources/` 没有修改。
- 历史 `Validation/Rotation/README.md` 与已归档 change 中的旧部署目标是当时的证据，不改写历史。

## Builds

以下构建均未通过命令行覆盖 `IPHONEOS_DEPLOYMENT_TARGET`：

| 项目 | 验证 | 结果 |
| --- | --- | --- |
| 主框架 | `xcodebuild -scheme JXPhotoBrowser -project JXPhotoBrowser.xcodeproj -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` | 通过，MinimumOSVersion / Mach-O minos 为 15.0 |
| UIKit / CocoaPods | `xcodebuild -scheme Demo -workspace Demo-UIKit/Demo.xcworkspace -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` | 通过，App MinimumOSVersion 为 15.0 |
| SwiftUI / SwiftPM | `xcodebuild -scheme Demo -project Demo-SwiftUI/Demo.xcodeproj -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` | 通过，App MinimumOSVersion 为 16.0 |
| CocoaPods lint | `LANG=en_US.UTF-8 pod lib lint JXPhotoBrowser.podspec --allow-warnings` | 通过 |
| Carthage XCFramework | `carthage build --no-skip-current --use-xcframeworks --platform iOS` | 通过；另在隔离目录仅放主工程和当前 Sources，确认构建主框架 scheme |
| Carthage 示例 | 将上述生成产物放入示例的忽略目录后，`xcodebuild -scheme Demo -project Demo-Carthage/Demo.xcodeproj -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` | 通过，App MinimumOSVersion 为 15.0 |
| UIKit 模拟器 | 同一 workspace，SDK 为 iphonesimulator、目标为 iPhone 17 | 通过并成功安装启动 |

所有上述发布方式和示例产物均确认存在 JXPhotoBrowser 的 `PrivacyInfo.xcprivacy`。Carthage 的 ios-arm64 与 ios-arm64_x86_64-simulator 所有架构 Mach-O minos 均为 15.0。

根目录 Carthage 会优先发现 UIKit workspace 中的本地 Pod scheme，因此另外复制主 `.xcodeproj` 到 `/tmp/PhotoBrowser-ios15-CarthageSource` 并链接当前 `Sources`，再次构建主工程；Carthage 示例使用第二份产物，不使用远端 4.1 tag。

UIKit 构建保留第三方 Kingfisher 6.3.1 的已有废弃 API / Swift 6 语法提示；本次没有手工修改 Pods 源码或升级依赖。主工程自身没有新增 API 废弃警告。

构建日志：`/tmp/PhotoBrowser-ios15-{core,uikit,swiftui,lint,carthage-core,carthage-demo,uikitsim}.log`。独立 DerivedData 路径使用 `/tmp/PhotoBrowser-ios15-*`。

## Simulator

- `/tmp/PhotoBrowser-ios15-Smoke.xcresult`：UIKit 首页启动，导航栏存在，1 项 UI smoke test 通过。
- 测试工程位于 `/tmp/PhotoBrowser-ios15-Validation`，基于现有 Rotation 生成器，临时 UI 测试对已安装 UIKit Demo 执行真实操作；不进入发布工程。
- 初次长按未弹出菜单；脚本改为等待浏览器 ScrollView 并更换触点后能够打开菜单。第二次实际出现只添加权限弹窗，脚本误用英文拒绝按钮而失败；之后按实际中文按钮修正。再运行时实际 TCC 状态已经是允许，不符合该次测试的拒绝前提，因此改用 simctl 明确预置授权状态。这些失败结果未计为通过，未因此修改产品行为。
- `/tmp/PhotoBrowser-ios15-Revoked.xcresult`：预置 photos-add 为拒绝，进入真实视频页并长按保存，两次保存尝试均显示“请在系统设置中允许访问相册”，1 项 UI test 通过，确认拒绝状态不会永久锁住再次保存。
- `/tmp/PhotoBrowser-ios15-Authorized.xcresult`：预置 photos-add 为允许，进入真实视频页并长按保存，实际完成下载和相册写入，出现“已保存到相册”，1 项 UI test 通过。
- 图片保存辅助方法目前没有界面调用入口，本次仅做原分支等价审查和编译验证，未新增入口或声称完成图片保存运行验收。首次权限弹窗已确认请求只添加权限，但首次点击拒绝后的瞬时提示没有可靠自动化验收。

## Final checks

- 已审查完整 diff 与生成配置语义，无浏览内核或无关依赖变更。
- `openspec validate --all --strict --no-interactive --json`、`git diff --check` 均通过。
- Git 提交、推送和发布未执行。

## Follow-up dependency upgrade (2026-09-26)

用户随后要求将升级过程中冲突的框架一并升级或移除版本限制。本节更新前文“保留 Kingfisher 6.3.1 和 Podfile 下限钩子”的最终状态，平台支持契约不变。

- CocoaPods 查询和上游 tags 均确认 Kingfisher 最新稳定版为 8.13.0。UIKit 从 6.3.1 升至 8.13.0；Podfile 原本就没有 Kingfisher 版本限制，通过 `pod update Kingfisher` 更新实际锁定版本。
- SwiftUI 从 8.6.2 升至 8.13.0，最低依赖约束和 Package.resolved 同步。保留同主版本升级范围；没有改为跟随开发分支。
- Kingfisher 8.13.0 原生支持下限为 iOS 15，移除上一轮 `post_install` 部署目标改写。正常 `pod install` 后，所有生成 iOS 配置仍为 15.0，Podfile.lock 与 Manifest.lock 一致。
- 缩略图加载回调显式标注 `@MainActor @Sendable`，匹配 Kingfisher 新签名；新版构建不再出现旧 Kingfisher 的废弃 API / Swift 6 语法警告，也没有该回调的 Sendable 转换警告。
- Carthage 移除 `~> 4.1` 限制，中英文示例同步。隔离目录执行 `carthage update --no-build --no-use-binaries` 成功解析到当前远端最新发布 4.1.0；此操作仅验证解析，不等于远端 4.1.0 已包含尚未发布的 iOS 15 修改。上一节当前源码 XCFramework 和 Carthage 示例的构建证据仍适用。
- Kingfisher SwiftPM manifest 要求 Swift tools 6.2，示例说明补充 Xcode 26+。GitHub macOS 15 runner 文档当前默认 Xcode 16.4，但同时安装了 Xcode 26.x，因此两个 iOS CI job 显式使用 `setup-xcode` 的 `latest-stable`；YAML 解析通过，未触发远端 CI。
- UIKit/CocoaPods、SwiftUI/SwiftPM 的真机 SDK 和 iOS 27 模拟器构建全部通过。产物最低版本仍为 15.0 / 16.0，两者均包含库和 Kingfisher 的隐私清单。
- 本次 Pods 由 CocoaPods 正常生成。99 个与 SwiftPM 上游 checkout 对应的依赖源码文件逐字节一致，未手改依赖代码。
- 项目自有改动的 `git diff --check` 通过；完整检查报告 Kingfisher 上游源码的 441 处空白格式提示。依照仓库规则保留原始依赖源码，不为消除这些提示修改生成目录。OpenSpec 严格校验通过。
- `/tmp/PhotoBrowser-dependencies-SmokeFinal.xcresult`：iOS 27 模拟器两项 UI 测试通过，覆盖 UIKit 图片打开、双击操作、翻页和关闭，以及 SwiftUI 图片打开；两份截图均人工检查确认真实图片已显示。初次使用 collection view 序号选取缩略图未打开 UIKit 浏览器，改用已观察的缩略图位置后通过，没有调整产品代码来迁就测试。

本次构建与解析日志保存在 `/tmp/PhotoBrowser-dependencies-*.log`。
