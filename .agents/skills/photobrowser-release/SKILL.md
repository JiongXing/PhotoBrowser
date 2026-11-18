---
name: photobrowser-release
description: 准备和发布 JXPhotoBrowser 版本，或继续核查已推送的发布。适用于同步版本与安装文档、打标签、推送 GitHub、发布到 CocoaPods Trunk，以及验证官方 CDN 安装。
---

# 发布 JXPhotoBrowser

## 准备版本

1. 确认目标版本、发布分支和待发布提交。核对工作区、`origin`、远端分支、同版本 tag 和 Trunk 记录。接手中断的发布时，从已核实的状态继续。已登记的版本先核对公开 podspec 和 tag 指向，发现冲突时保留现有 tag 并报告差异。
2. 同步 `JXPhotoBrowser.podspec`、`JXPhotoBrowser.xcodeproj/project.pbxproj` 主框架 Debug/Release 的 `MARKETING_VERSION`、`README.md`、`README_EN.md`、`CHANGELOG.md` 及适用的中英文迁移指南。变更日志以从上个发布 tag 到本次发布源码的差异为准。SwiftPM 版本来自 Git tag，`Package.swift` 用于描述包及平台约束。
3. 在 `Demo-UIKit` 运行 `LANG=en_US.UTF-8 pod install`，让 CocoaPods 生成锁文件和已跟踪的 Pods 元数据。核对 `Podfile.lock` 和 `Pods/Manifest.lock`、Pod 的版本及 spec checksum，留意无关依赖升级或签名设置变化。按实际差异暂存发布文件，保留工作区里用户的其他修改。
4. 发布前运行 `pod lib lint JXPhotoBrowser.podspec --allow-warnings`，检查实际告警，按仓库验证矩阵核对受影响的构建和隐私清单。主库及 UIKit、SwiftUI 构建入口见 [AGENTS.md](../../../AGENTS.md#构建命令)。Carthage 检查命令及 CI 覆盖见 [CI 配置](../../../.github/workflows/ci.yml)。纯版本准备可以引用同一运行时源码已有的行为验证证据。

## 推送与发布

按用户授权执行提交、推送和 Trunk 发布。已授权整轮发布时，先提交版本改动，创建名为版本号的 annotated tag，标签格式为 `X.Y.Z`。推送前确认发布提交包含预期修复。以下命令假设已在发布分支 `master` 上、远端名为 `origin`，并已设置本次的 `release_version`。

```sh
git tag -a "${release_version:?}" -m "JXPhotoBrowser $release_version" &&
git push --atomic origin refs/heads/master:refs/heads/master "refs/tags/$release_version:refs/tags/$release_version" &&
git ls-remote origin refs/heads/master "refs/tags/$release_version" "refs/tags/$release_version^{}"
```

比较远端 `refs/tags/<版本>^{}` 和本地发布提交的 SHA。用 `gh run list --commit <SHA>` 定位分支和标签的 CI 并跟踪结果。CI 可以与 Trunk 提交和 CDN 同步并行。

确认远端标签已就绪、当前 podspec 与标签中的一致，并用 `pod trunk me` 确认会话拥有发布权限，然后运行 `pod trunk push JXPhotoBrowser.podspec --allow-warnings`。保留日志。遇到 `Net::OpenTimeout` 或 GitHub commit API 超时时，先查询 Trunk 和官方 Specs。命令即使报错，版本也可能已经登记。确认已登记且 podspec 一致后转入 CDN 验证。两处都确认尚未发布时再针对可恢复错误重试。查询本身超时时继续核实状态。

## 验证发布与安装

按顺序核对三个可独立查询的状态。下方 `<版本>` 需替换成本次版本号。

| 状态 | 查询来源 |
| --- | --- |
| Trunk 已登记 | `pod trunk info JXPhotoBrowser`，或 `https://trunk.cocoapods.org/api/v1/pods/JXPhotoBrowser` 的 `versions` |
| 官方 podspec 已发布 | `https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/3/f/6/JXPhotoBrowser/<版本>/JXPhotoBrowser.podspec.json` 与 `https://cdn.cocoapods.org/Specs/3/f/6/JXPhotoBrowser/<版本>/JXPhotoBrowser.podspec.json`。将两者与 `pod ipc spec JXPhotoBrowser.podspec` 的结构化内容比较 |
| 默认 CDN 索引可解析 | `https://cdn.cocoapods.org/all_pods_versions_3_f_6.txt` 中 `JXPhotoBrowser/` 行包含目标版本 |

版本专用 podspec 可能先于 CDN 索引可用。`pod install --repo-update` 找不到版本时，直接读默认索引并检查响应的 `Age` 和 `Cache-Control`，间隔轮询。直连版本专用 podspec 或给索引加查询参数可以诊断传播进度。普通安装的验证以默认地址为准。Trunk 已登记时继续跟踪 CDN，跳过重复发布。

默认索引出现版本后，在独立的临时 iOS 宿主中仅配置 `source 'https://cdn.cocoapods.org/'` 和 `pod 'JXPhotoBrowser', '<版本>'`，执行 `pod install --repo-update` 并构建生成的 `.xcworkspace`。核对 `Podfile.lock` 的确切版本、`trunk` 来源、spec checksum，确认没有 `EXTERNAL SOURCES`。比较下载的 `Sources/` 与 tag，并检查产物的框架版本、最低系统版本和 `PrivacyInfo.xcprivacy`。若已解析到正确版本但 Git 下载暂时失败，核实 tag 后重试安装。

交付时报告发布提交与 tag、对应 CI、Trunk 登记及默认 CDN 安装构建的结果。用实际证据注明仍在等待的环节，保留日志并在后续从该环节继续。
