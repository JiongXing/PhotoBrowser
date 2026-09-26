# PR #241 尺寸转场回归

此目录只用于验证，不进入发布库或 Demo。脚本把独立测试工程生成到指定临时目录，直接编译当前 `Sources/*.swift`，不修改主工程或 Pods。

## 运行

需要 Xcode、iOS Simulator，以及 CocoaPods 使用的 Ruby `xcodeproj` gem。

```sh
ruby Validation/Rotation/generate_project.rb /tmp/PhotoBrowser-Rotation
xcrun simctl list devices available
xcodebuild -project /tmp/PhotoBrowser-Rotation/Rotation.xcodeproj \
  -scheme Rotation -destination 'platform=iOS Simulator,id=<设备 UUID>' \
  -derivedDataPath /tmp/PhotoBrowser-Rotation/DerivedData \
  -resultBundlePath /tmp/PhotoBrowser-Rotation/results.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never test
```

每次运行使用新的结果包路径。仅运行状态回归可加 `-only-testing:RotationTests`；仅运行系统交互可加 `-only-testing:RotationUITests`。

## 覆盖与限制

- `RotationTests`：使用真实 UIKit 集合视图和可控转场协调器，验证缩减/清空数据、动画开始前后跳页、无效导航、轮播暂停恢复、循环与间距、Cell 首次布局前准备、复用、缩放回调、旧转场完成回调以及默认方向策略。可控协调器用于检查时序，不代表真实系统旋转。
- `RotationUITests`：全屏 Scene 宿主和允许旋转的浏览器子类，调用系统旋转、拖拽/减速、捏合及双击。每个页面检查同时验证页码、实际集合视图位置和对齐；保存屏幕截图。宿主的 `phase` 记录转场开始时真实的拖拽/减速状态。
- 测试宿主使用本地生成的图片、20 点间距，不依赖网络。iPad 配置 `UIRequiresFullScreen`，避免窗口模式使设备旋转与容器尺寸改变成为两个不同场景；这不是库的默认方向配置。
- 视觉验收还需检查录屏/截图。没有覆盖真机、iOS 26 或更早系统，以及 iPad 分屏拖动；不能将模拟器结果称为这些场景的通过证据。

## 行为约定

拖拽/减速中的尺寸变化保留旧布局的最近页；程序化滚动中保留目标页。转场期间的新刷新或有效导航更新同一个最新目标，完成时按实际尺寸校正。此期间的 `scrollToPage(animated: true)` 即时选中目标，由尺寸转场统一定位，不叠加独立分页动画；转场外仍保留原来的动画导航行为。

## 原 PR 复现

原 PR head 为 `45315994694dd4c9c19fd40f40c5c5256d99f6bc`。可把该提交的 `Sources` 导出到临时目录，再通过 `ROTATION_SOURCE_ROOT` 指向它生成测试工程；测试源仍使用本目录。

```sh
mkdir -p /tmp/PhotoBrowser-Rotation-Baseline
git archive 45315994694dd4c9c19fd40f40c5c5256d99f6bc Sources | tar -x -C /tmp/PhotoBrowser-Rotation-Baseline
ROTATION_SOURCE_ROOT=/tmp/PhotoBrowser-Rotation-Baseline \
  ruby Validation/Rotation/generate_project.rb /tmp/PhotoBrowser-Rotation-Baseline/project
```

运行 `testNavigationDuringTransition`、`testReloadEmptyDuringTransition`、`testReloadSmallerDuringTransition`，原代码会把新索引 1/0 写回 4，并在数据缩减/清空后发出越界缩略图隐藏回调。2026-09-26 实测这 3 项共 5 个断言失败，修复后通过。

## 构建证据（2026-09-26）

Xcode 27.0（27A266a）下主框架、UIKit/CocoaPods 示例和 SwiftUI/SwiftPM 示例均构建成功，产物中均找到库的 `PrivacyInfo.xcprivacy`。

主框架和 UIKit 示例原命令因 Xcode 27 不接受 iOS 12/10 部署目标而失败，验证时额外传入 `IPHONEOS_DEPLOYMENT_TARGET=15.0`。未修改项目最低系统版本；这不证明 iOS 12 兼容性。SwiftUI 示例无需覆盖参数即可构建通过。

原 PR 的远端 CI `35569746302`：主框架、Pod lint、UIKit 构建成功，SwiftUI 构建 exit 65，后续 SwiftPM 隐私及 Carthage 步骤跳过。授权后日志确认：Xcode 16.4 编译 `PhotoBannerView.Coordinator` 时，在非隔离的委托回调中调用 Kingfisher 的 `@MainActor setImage` 失败；该编译器不支持项目中新版 Xcode 的默认 MainActor 隔离设置。

SwiftUI 示例显式标注两个图片加载委托回调为 `@MainActor`，并使用 `@preconcurrency` 桥接库既有的非隔离委托协议。回调来自 UIKit 主线程；不改变库的公开协议或通过异步任务推迟 Cell 配置。Xcode 27 下使用 `SWIFT_DEFAULT_ACTOR_ISOLATION=nonisolated SWIFT_APPROACHABLE_CONCURRENCY=NO` 可复现同类错误（`PhotoBrowserPresenter` 的加载回调）；修复后分别验证此配置和项目默认配置。远端 Xcode 16.4 的完整集成结果以最新 PR CI 为准。

## 模拟器证据（2026-09-26）

环境为 iPhone 17 / iPad Pro 11-inch (M5)，均运行 iOS 27.0（24A434）。状态回归 12 项在两台模拟器均通过。系统交互覆盖旋转中刷新/跳页、远距离程序化滚动、循环首尾、手指拖拽中与减速中旋转、纵向分页、双击模式切换、固定倍数缩放和轮播恢复。

iPad 的原始自动捏合步骤未通过：在旋转前合成手势未触发缩放，最大观测 zoomScale 和 pinch.scale 都保持 1；同一用例在原 PR `4531599` 上也失败。它不能记为通过，也不能据此证明真实手势在库中损坏。iPhone 的自动捏合已通过；iPad 使用固定倍数双击完成了“已放大后旋转重置及恢复轮播”验证。测试保留原始捏合断言，未跳过或放宽。

本机结果包：

- `/tmp/PhotoBrowserPR241-Baseline.xcresult`：原 PR 三项状态回归失败。
- `/tmp/PhotoBrowserPR241-Regression.xcresult`：iPhone 12 项状态回归通过；当时 UI 用例的阶段标记断言失败，随后修正测试观测对 isDecelerating 的优先级，未修改库代码。
- `/tmp/PhotoBrowserPR241-Final.xcresult`：iPhone 其余旋转 UI 场景通过。
- `/tmp/PhotoBrowserPR241-Deceleration.xcresult`：iPhone 减速中循环跨首尾通过，截图明确记录 `phase=decelerating` 和索引 0。
- `/tmp/PhotoBrowserPR241-iPadFinal.xcresult`：iPad 12 项状态回归及 5 项 UI 用例通过，捏合步骤失败。
- `/tmp/PhotoBrowserPR241-iPadOriginalPinch.xcresult`：原 PR 同样无法触发 iPad 自动捏合。
- `/tmp/PhotoBrowserPR241-iPhoneZoom.xcresult`：iPhone 最终版本的捏合、固定倍数双击、旋转及轮播恢复通过。
- `/tmp/PhotoBrowserPR241-iPadZoom.xcresult`：iPad 固定倍数双击、旋转及轮播恢复通过。

已检查系统录屏的远距离跳页、放大后旋转帧序列及 iPhone/iPad 结束画面；所检查画面中未见旋转结束后回滚或图片错位。此结论只覆盖上述本地图片和宿主，不替代所有宿主/系统版本的视觉验收。
