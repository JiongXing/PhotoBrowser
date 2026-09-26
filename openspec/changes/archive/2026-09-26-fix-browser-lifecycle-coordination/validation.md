# Validation

验证环境：2026-09-26，Xcode 27.0，iPhone 17 / iOS 27.0 模拟器。源码基于 master 的 8e4047c，修改保留在工作区。

## 构建

以下构建均未覆盖部署版本参数，`CODE_SIGNING_ALLOWED=NO`，结果为 exit 0：

- 主框架：`/tmp/PhotoBrowser-Lifecycle-Framework-Final.log`
- UIKit / CocoaPods 示例：`/tmp/PhotoBrowser-Lifecycle-UIKit-Final2.log`
- SwiftUI / SwiftPM 示例：`/tmp/PhotoBrowser-Lifecycle-SwiftUI-Final.log`

新增视频工具显式使用 nonisolated，避免 Demo 默认 MainActor 隔离污染下载线程的文件接管；最终 UIKit 构建无此工具的隔离警告。未变更依赖，因此未运行 pod install。

## 状态、文件与相册

`SIMULATOR_UDID=F98C04D4-C1D9-4D5D-A97F-F13C5F8BF425 Validation/run-tests.sh /tmp/PhotoBrowser-Lifecycle-AllFinal` 返回 exit 0；`Results.xcresult` 为 39 项通过、0 失败、0 跳过。其中状态/文件/相册测试 30 项：

- 14 项生命周期测试：缩减、清空、替换、原始隐藏状态、自定义恢复、重新隐藏、动画/无动画关闭、暂时覆盖、下拉/回弹与轮播、刷新/导航/尺寸转场中断、旧回弹隔离、自定义 Cell 准入和配置恢复。
- 12 项原有旋转状态回归；越界回调检查现同时覆盖隐藏和恢复。
- 3 项视频文件所有权测试：下载回调结束后的持有，成功/失败清理，调用方本地源保留，文件接管失败。
- 1 项模拟器 Photos 冒烟：生成短视频并实际保存，确认源文件保留。

可控手势测试验证状态路径，不作为真实手指输入的替代。Photos 冒烟使用预先授予的模拟器添加权限；文件测试使用可控相册写入完成回调。

## 系统交互与视觉

`/tmp/PhotoBrowser-Lifecycle-AllFinal/Results.xcresult`：9 项系统交互全部通过，包括新增下拉停留/回弹/恢复轮播、双击放大后的下拉拒绝和关闭后缩略图恢复，以及 7 项原有旋转、循环、拖拽/减速、捏合、双击与轮播回归。

已查看生命周期截图（前一轮三张、最终结果包中的回弹与关闭画面）：回弹后图片恢复且轮播已继续；放大时未进入下拉；最终关闭后五张缩略图全部可见。截图导出在 `/tmp/PhotoBrowser-Lifecycle-AllFinal/Screenshots/`。

## CI 与静态检查

新增 behavior job 使用 `Validation/run-tests.sh`，与本地共用生成工程、模拟器选择、安装/权限准备和执行路径，并上传日志与结果包。脚本保留构建/测试失败退出码；Photos 权限在 XCTest 启动前设置。

脚本语法、Ruby 生成器语法、CI YAML 与共用入口检查、git diff --check、OpenSpec 严格校验均通过。远端 GitHub CI 尚未触发，不把本地通过表述为远端通过。

## 边界

未进行真机、其他 iOS 版本、iPad 分屏或网络视频端到端保存验收。新增公开协议要求均有默认实现；动态数据下的自定义 alpha/容器显隐使用恢复闭包捕获原始对象，兼容边界和示例见中英文 Guides。

## 归档后独立 Review

独立审查发现一个尚未修复的 P2 覆盖缺口：浏览器作为 UINavigationController 的子控制器呈现，宿主无动画关闭整个导航容器后，原缩略图仍隐藏。当前 viewDidDisappear 的退出判定遗漏父容器关闭；因此上述 39 项通过不代表“所有关闭路径恢复缩略图”已完整满足。

在同一 iPhone 17 / iOS 27 模拟器上追加临时 XCTest，两次复现；宿主 presentedViewController 已为空，但缩略图恢复断言失败。复核证据：`/tmp/PhotoBrowser-Subagent-LifecycleReview/container-confirmed.log`、`/tmp/PhotoBrowser-Subagent-LifecycleReview/ContainerConfirmed.xcresult`。临时用例未纳入仓库。“全屏覆盖后宿主直接关闭整条 modal 链”的独立用例通过。此问题保留为待修复项。

## 4.2.0 发布准备后续修复（2026-09-26）

上节为发现时的历史状态。后续已在 `viewDidDisappear` 中补充父容器 `isBeingDismissed` 判定，复用原缩略图恢复逻辑，并将导航容器动画/无动画关闭及临时覆盖返回场景纳入状态与 UI 回归。当前修复状态、修复前失败结果和最终验收见 [4.2.0 发布记录](../../../../Documentation/Release-4.2.0.md)。
