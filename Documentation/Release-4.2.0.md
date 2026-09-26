# 4.2.0 发布记录

发布日期：2026-09-26。4.2.0 已发布至 CocoaPods，完成远端 CI、tag 校验、Pod 远端校验与 CDN 消费端安装构建。本文同时保留发布前验证快照及操作步骤。

## 正式发布结果

- 发布提交：`0a09aa30ffddfbae30195e3d8c2814a5a5f321f3`，已推送到 master。
- [4.2.0 tag](https://github.com/JiongXing/PhotoBrowser/tree/4.2.0) 已推送并核对，解引用到上述提交；未移动已有 tag。
- [发布提交 CI](https://github.com/JiongXing/PhotoBrowser/actions/runs/36244232819) 四组任务全部通过。远端 iOS 18.5 模拟器 45 项测试通过，0 失败、0 跳过；本地 iOS 27 的结果见下文。
- 针对远端 tag 的 `pod spec lint JXPhotoBrowser.podspec --allow-warnings` 通过，日志 `/tmp/PhotoBrowser-4.2.0-SpecLint.log`。
- CocoaPods trunk 已于 2026-09-26 13:22:30 UTC（北京时间 21:22:30）登记 4.2.0。发布命令随后返回 `Net::OpenTimeout`，因此通过 trunk 公共版本 API、`pod trunk info` 和[正式 podspec](https://trunk.cocoapods.org/api/v1/pods/JXPhotoBrowser/specs/4.2.0) 交叉确认发布成功，没有重复提交。
- 正式 podspec 的版本、源码 tag、最低 iOS 15.0 和隐私资源配置均已核对；trunk、CDN 与本地 podspec 内容一致。
- [4.2.0 tag CI](https://github.com/JiongXing/PhotoBrowser/actions/runs/36244900721) 也已全部通过。
- CDN 版本索引最初仍命中发布前缓存，等待刷新后，独立宿主使用 `pod 'JXPhotoBrowser', '4.2.0'` 和官方 CDN 成功执行 `pod install --repo-update`；没有 `:path`、`:git` 或 `:podspec` 替代源。
- 消费端 iOS 构建通过；下载的 Sources 与 4.2.0 tag 逐文件一致，内嵌框架版本为 4.2.0、MinimumOSVersion 为 15.0，确认包含 `JXPhotoBrowser.bundle/PrivacyInfo.xcprivacy`。独立宿主位于 `/tmp/PhotoBrowser-4.2.0-CDN-Smoke/`，安装及构建日志为 `/tmp/PhotoBrowser-4.2.0-CDN-{Install,Build}.log`。

## 版本范围

按维护者选择使用次版本号 4.2.0；最低系统提高属于兼容性变化，因此在 README、迁移指南与更新记录中明确强调 iOS 15。

- 基于本地 `master` 的 `8f32310`；与已发布 `4.1.0` 比较整理更新记录。
- podspec 与主框架 Debug/Release 的版本统一为 `4.2.0`；最低 iOS 15.0。
- 中英文 README、迁移说明、使用指南及 CHANGELOG 已同步。`Demo-UIKit/Podfile.lock` 和已跟踪的 Pods 元数据由 `pod install` 自动生成。
- 发布前查询：CocoaPods trunk 最新版本为 `4.1.0`，本机账户拥有 `JXPhotoBrowser` 的发布权限，当时远端不存在 `4.2.0` tag。

## 导航容器关闭修复与发布边界

原先的导航容器关闭问题已修复：`viewDidDisappear` 在浏览器自身退出条件之外，检查直接父容器的 `isBeingDismissed`，命中后复用 `restoreThumbnail()`。不新增计时器或状态变量；临时全屏遮挡不满足父容器关闭条件。历史发现记录见[生命周期验收记录](../openspec/changes/archive/2026-09-26-fix-browser-lifecycle-coordination/validation.md#归档后独立-review)。

修复前，新增的三项真实 UIKit 状态用例均在最终缩略图恢复断言失败：动画关闭、无动画关闭、临时遮挡返回翻页后关闭导航容器。证据为 `/tmp/PhotoBrowser-Container-Baseline/Results.xcresult`。修复后这三项及对应三项 UI 用例通过，覆盖遮挡期间仍隐藏、返回继续浏览及关闭恢复。修复不宣称任意自定义嵌套容器或所有系统版本均已验收。

准备阶段曾遇到 SSH 认证失败；正式发布前已改用 HTTPS，确认 GitHub 登录正常且账户具有仓库推送权限。发布前远端 master 为 `8e4047c`；发布提交须包含 `8f32310` 的生命周期修复和 `7818c8c` 的版本准备及导航容器修复。

## 本轮验证

以下源码构建、lint、Carthage 和完整回归结果均为导航容器修复后的最终验证；`pod install` 记录沿用版本准备阶段，修复未更改依赖。

构建使用 Xcode 27.0（27A266a），不覆盖 deployment target；本机模拟器为 iPhone 17 / iOS 27，不能证明 iOS 15/16 或真机运行兼容性。

| 检查 | 结果 | 本机证据 |
| --- | --- | --- |
| `pod install` | 通过；只更新本地 Pod 版本及生成元数据，Kingfisher 保持 8.13.0 | `/tmp/PhotoBrowser-Release-PodInstall.log` |
| `pod lib lint JXPhotoBrowser.podspec --allow-warnings` | 4.2.0 通过；日志有无 AppIntents 依赖的元数据提取跳过提示 | `/tmp/PhotoBrowser-Container-Lint.log` |
| 主框架 iOS 构建 | 通过；产物版本 4.2.0，MinimumOSVersion 15.0 | `/tmp/PhotoBrowser-Container-Core.log` |
| UIKit / CocoaPods 示例 iOS 构建 | 通过；内嵌框架版本 4.2.0，MinimumOSVersion 15.0 | `/tmp/PhotoBrowser-Container-UIKit.log` |
| SwiftUI / SwiftPM 示例 iOS 构建 | 通过 | `/tmp/PhotoBrowser-Container-SwiftUI.log` |
| Carthage XCFramework | 当前主工程及 Sources 的独立副本构建通过；设备和模拟器切片均为 4.2.0 / iOS 15.0 | `/tmp/PhotoBrowser-Container-Carthage.log` |
| 隐私清单 | 主框架、CocoaPods / SwiftPM 示例产物及 Carthage 两个切片均包含库的 `PrivacyInfo.xcprivacy`，`NSPrivacyTracking` 为 false | `/tmp/PhotoBrowser-Release-{Core,UIKit,SwiftUI}/`、`/tmp/PhotoBrowser-Release-CarthageSource/Carthage/Build/` |
| 完整回归（含新增容器用例） | 45 项通过，0 失败、0 跳过；33 项状态/文件/相册测试与 12 项 UI 测试 | `/tmp/PhotoBrowser-Container-Fixed/Results.xcresult` |
| 静态检查 | OpenSpec 5 项严格校验通过；修改文档的本地文件链接、lockfile 同步及 `git diff --check` 通过 | 当前工作区 |

Carthage 使用只包含当前主 `.xcodeproj` 和 `Sources` 的临时副本，避免优先选择 UIKit workspace 中的 Pod scheme；未使用远端旧 tag。未重跑 Carthage 示例、真机或旧系统交互验收。新增导航容器场景的五张截图已检查：动画与无动画关闭后五张缩略图均恢复；覆盖期间 `hidden=1`，返回后成功翻至第 1 页，最终关闭恢复。截图位于 `/tmp/PhotoBrowser-Container-Fixed/Screenshots/`。

上表记录本地验证，不包含远端 tag 的 `pod spec lint`、GitHub CI 或 CDN 安装结果，这些在下列正式发布步骤中分别核实。构建和测试日志存于本机临时目录，不是持久发布附件。

## 正式发布步骤

以下为正式发布操作清单。发布前须审阅改动和验证结果，并确认 GitHub 写入认证可用。

1. 将 CHANGELOG 的“发布准备中”更新为实际发布日期；复核 `git diff --check`、版本一致性和完整待发布 diff，按明确文件路径暂存并提交。
2. 确认发布提交包含 `8f32310`、本次导航容器修复及版本准备改动，工作区干净且新版本 tag 不存在，然后创建 tag 并推送：

   ```sh
   git tag -a 4.2.0 -m "Release 4.2.0"
   git push origin master
   git push origin refs/tags/4.2.0
   ```

3. 确认远端 tag 对应发布提交，等待该提交 GitHub CI 通过，再验证远端 tag 源码。`pod lib lint` 使用本地源码，不能替代此步：

   ```sh
   LANG=en_US.UTF-8 pod spec lint JXPhotoBrowser.podspec --allow-warnings
   ```

4. 审阅 lint 警告后发布到 CocoaPods；沿用仓库 CI 的 `--allow-warnings`，不要使用 `--skip-import-validation` 绕过验证：

   ```sh
   LANG=en_US.UTF-8 pod trunk push JXPhotoBrowser.podspec --allow-warnings
   pod trunk info JXPhotoBrowser
   ```

5. 等待 CDN 可解析后，在独立临时宿主中使用 `pod 'JXPhotoBrowser', '4.2.0'`（不使用 `:path`），安装并构建，确认版本与 `JXPhotoBrowser.bundle/PrivacyInfo.xcprivacy`。

Git 推送、远端 tag 校验、远端 CI、trunk 发布以及 CDN 安装均是独立结果；本地验证通过不能表述为已经发布成功。
