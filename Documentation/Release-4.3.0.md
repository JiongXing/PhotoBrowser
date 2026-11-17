# 4.3.0 发布记录

目标发布日期：2026-11-17（Asia/Taipei）。当前处于发布准备阶段；远端 tag、CI、CocoaPods trunk 和 CDN 消费端结果将在实际完成后记录。

## 范围与 review

以已发布 `4.2.0` tag 为比较基准，运行时代码终点为 `950c8c3`。库的实现变更集中于 `JXZoomImageCell` 与 `JXPhotoBrowserViewController`；视频子类只更新缩放几何说明。保留 PR [#243](https://github.com/JiongXing/PhotoBrowser/pull/243)、[#244](https://github.com/JiongXing/PhotoBrowser/pull/244) 的提交历史。

| 优化 | 旧行为与新行为 | review 关注点 |
| --- | --- | --- |
| 混合缩放 | 双击改变基础尺寸，改为统一原生 zoomScale | 双击后可捏合回完整显示，反向手势和重复切换正常 |
| 长图与全景图 | 以铺满为 1 倍，默认最大 2 倍 | minimum 可能小于 1；已有固定倍率存在迁移要求 |
| 换图、旋转、复用 | 更新比例和偏移；尺寸变化恢复完整显示 | 保留宿主上限，旧动画不能覆盖最终几何 |
| 顶部下拉 | 放大不再一律拒绝，触摸开始时在顶即允许 | 中部到顶不接管；单指与捏合隔离；取消准确恢复 |
| 跟手与 inset | 屏幕位移转换到缩放后的图片父坐标 | 小于 1 倍及 2 倍、自定义变换和 automatic inset 下仍跟手 |
| 容器布局 | 整页使用当前容器 bounds，移除 UIScreen 兜底 | 视图未布局时不拿全局屏幕代替，默认方向策略不变 |

本次版本准备不新增运行时行为。倍率与关闭变化已通过 OpenSpec 归档；中英文迁移指南明确上述兼容性影响。独立 review 覆盖完整运行时差异和本次文档、配置，未发现 Critical、Important 或实质 Minor 问题。未扩展无效宿主倍率配置、非默认方向策略或视频播放器能力；这些不是本次版本差异带来的功能要求。

## 版本与配置

- podspec 与主框架 Debug/Release 的版本统一为 `4.3.0`；最低 iOS 15.0、Swift tools 5.4、隐私资源打包规则不变。
- README 安装示例、CHANGELOG、中英文迁移指南同步到 4.3。
- UIKit 示例通过 `pod install` 更新本地 Pod 版本及已跟踪元数据，不手工修改 Pods；保留 Kingfisher 8.13.0。
- 主工作区既有 UIKit 工程签名配置不属于发布改动，保持未提交。

## 发布计划与验收

1. 完成 `4.2.0` 到待发布源码的独立 review，核对迁移说明和版本配置，处理阻塞问题。
2. 本地 Pod lint、主框架、UIKit/CocoaPods、SwiftUI/SwiftPM 和 Carthage XCFramework 构建通过；核对版本、最低系统和各产物隐私清单。运行时源码未变时，沿用同一源码提交的 67 项行为验证证据。
3. OpenSpec 严格校验、文档链接和 diff 检查通过，按明确路径提交发布改动；推送 master 和新的 `4.3.0` tag，核对远端 tag 与 CI。
4. 对远端 tag 执行 `pod spec lint`，随后 `pod trunk push JXPhotoBrowser.podspec --allow-warnings`；通过 trunk 公共 API 核实版本登记，不能仅凭命令退出状态判断成功或重复推送。
5. CDN 可解析后，独立宿主用 `pod 'JXPhotoBrowser', '4.3.0'` 安装构建，核对下载源码、版本和隐私清单；记录最终结果。

## 验证证据

运行时代码 `950c8c3` 的本地完整回归已通过：67/67、0 失败、0 跳过，结果 `/tmp/PhotoBrowser-FillZoom-Final/Results.xcresult`。涵盖 51 项状态/文件检查和 16 项系统 UI 测试；混合缩放、长图、取消与旋转截图已检查。详见 [缩放验证记录](../Validation/Zoom.md)。这不代替 4.3.0 发布配置、远端源码及消费端验证。

本轮发布日志统一保存在 `/tmp/JXPhotoBrowser-4.3.0-Release/`。尚未宣称真机、iPad 或旧系统交互验收。

本地发布验证使用 Xcode 27.0（27A266a），未覆盖 deployment target。

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| `pod install` | 通过，JXPhotoBrowser 为 4.3.0，Kingfisher 保持 8.13.0；CocoaPods 1.17.0 自动生成元数据 | `PodInstall.log` |
| `pod lib lint --allow-warnings` | 通过；只有签名覆盖、目标依赖顺序及无 AppIntents 依赖的提取跳过提示 | `LibLint.log` |
| 主框架、UIKit、SwiftUI iOS 构建 | 全部通过，关闭签名 | `Core.log`、`UIKit.log`、`SwiftUI.log` |
| Carthage XCFramework | 当前主工程与 Sources 的独立副本构建通过，含设备和模拟器切片 | `Carthage.log`、`CarthageSource/Carthage/Build/` |
| 版本与隐私产物 | 主框架、UIKit 内嵌框架和 Carthage 两个切片均为 4.3.0 / iOS 15.0；均包含与源码一致的隐私清单，SwiftPM 内嵌资源也一致 | `Artifacts.json` |
| 静态检查 | 六项 OpenSpec 严格校验、发布文档本地链接、版本/lockfile 和 `git diff --check` 通过 | `OpenSpec.json` |

`pod install` 提示本机存在未使用的旧 master specs repo；本次使用官方 CDN，不更改本机 repo 配置。UIKit 工程原有未提交改动已逐字核对并保留，不包含在发布提交中。
