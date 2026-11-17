# Fill-based Zoom and Top Dismiss Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 原生缩放以铺满为 1 倍、默认最大 2 倍，并允许图片在手势开始时到顶后单指下拉关闭。

**Architecture:** 保留 PR #244 的统一 UIScrollView 缩放，以 aspect-fill bounds 和 fit/fill minimum 表示完整显示。浏览器沿用现有关闭状态机，只调整单指准入和缩放父坐标中的变换，取消精确恢复。

**Tech Stack:** Swift 5.4+、UIKit、XCTest、Xcode iOS Simulator。

**Spec:** 同目录 design.md、specs/image-zoom/spec.md、specs/browser-lifecycle/spec.md。

## Global Constraints

- iOS 15+，不新增第三方依赖；不手工修改 Pods/、.build/ 等生成目录。
- 以铺满为 1 倍，默认 maximumZoomScale = 2；100 × 800 图片在 400 × 800 容器的 minimum 为 0.25。
- 手势开始时未在顶部，本次触摸序列不切换关闭；纵向分页维持禁用下拉关闭。
- 原生最大倍率和指定双击倍率采用新语义，更新公开指南；仅本地提交。

## Review Focus

- 图片为空、重新加载或比例改变时，倍率范围有效且没有越界偏移；Task 1 的清空与图片替换回归。
- minimum 接近 1 或很小时，双击可重复返回 minimum；Task 1 的近似比例及极长图回归。
- 宿主更改 maximum 后普通布局、旋转和复用不覆盖该配置；Task 1 的宿主配置回归。
- 缩放父容器与自定义图片变换下，关闭触摸点跟手且取消准确恢复；Task 2 的几何回归。
- 双指捏合、从中间滚到顶、旧回弹与数据刷新交叉时不误关闭或覆盖状态；Task 2 的状态与系统手势回归。

### Task 1: 铺满基准与混合缩放

**Files:** Sources/JXZoomImageCell.swift；Validation/Rotation/ZoomTests.swift、RotationTests.swift、RotationHost.swift、RotationUITests.swift；Documentation/Guides.md、Guides_EN.md；Demo-UIKit/Demo/HomePage/VideoPlayerCell.swift（仅过期的几何说明）。

**Interfaces:** 保持公开类型和方法；doubleTapZoomScale 和 UIScrollView 倍率改用铺满语义。内部集中更新图片几何，其他任务以 minimum 判断完整显示。

- [x] 写入 `testFillBasedLongImageScales` 和全景图回归：400 × 800 容器、100 × 800 图片 minimum=0.25，双击=1、显示400 × 3200，最大=2、显示800 × 6400。
- [x] 用现有生成工程运行新用例，Expected: 旧实现的 minimum、铺满尺寸和最大尺寸断言失败。
- [x] 实现铺满基础尺寸、浮点 minimum 判定、默认 maximum=2，调整图片替换和旋转/复用的几何恢复；普通布局保留最大倍率。
- [x] 更新既有 ZoomTests 的新语义和 RotationTests 的真实显示尺寸断言；UI 状态提供原生 zoom 与实际 fit，完整显示用 fit 验证。
- [x] 运行 ZoomTests、RotationTests，Expected: 全部通过；用真实混合手势和旋转 UI 完成集成验收。
- [x] 更新双语倍率/迁移指南。实现提交安排在 Task 3 review 之后，符合用户“review 提交”的顺序。

### Task 2: 顶部下拉的跟手与恢复

**Files:** Sources/JXPhotoBrowserViewController.swift、Sources/JXZoomImageCell.swift；Validation/Rotation/LifecycleTests.swift、LifecycleHost.swift、LifecycleUITests.swift；Documentation/Guides.md、Guides_EN.md。

**Interfaces:** 沿用 canBeginDismissInteraction 和 photoBrowserDismissInteractionDidChange；依赖 Task 1 的 minimum、铺满 bounds 与原生 zoomScale。

- [x] 写入顶部/非零 inset 准入及中间拒绝回归；低于1倍、2倍和自定义原始图片变换下，将触摸点沿浏览器坐标移动80点后应跟手，取消后几何、倍率和偏移不变。
- [x] 运行新增 LifecycleTests，Expected: 旧缩放准入或旧屏幕/父坐标混用导致失败。
- [x] 实现单指识别限制、顶部/捏合准入、父坐标位移转换与原变换组合；确保交互期间缩放不抢占，取消恢复状态。
- [x] 更新旧的“放大一律拒绝”断言，保留自定义 Cell、旧回弹隔离、轮播和缩略图恢复测试。运行状态套件，Expected: 全部通过。
- [x] 添加系统长图拖到顶后不直接关闭、松手重拉关闭、放大顶部取消恢复的 UI 场景，并检查截图；同步指南。

### Task 3: 集成验证、review 与交付

**Files:** Validation/Zoom.md 和本 change 的 tasks.md；完成后由 CLI 同步主规格。

**Interfaces:** 消费前两任务代码和测试；保留原 PR 提交历史，最终只提交本地分支。

- [x] 执行 Validation/run-tests.sh 的完整套件，Expected: 状态及系统手势全部通过，失败项必须调查并如实记录。
- [x] 构建主库、UIKit workspace、SwiftUI project，Expected: BUILD SUCCEEDED；Xcode 若需兼容部署目标覆盖，仅在命令中传参并记录。
- [x] 检查截图、OpenSpec 严格校验、git diff --check，Expected: 无错误。
- [x] 请求独立 reviewer 按原始需求和 Review Focus 审查整个分支及未提交实现；重要问题以回归先失败后修复的方式处理。
- [x] 全部通过后记录证据、勾选任务、正常 OpenSpec archive 并再次严格校验，再 git commit。Expected: 工作区干净，当前分支保留原作者提交和本次追加提交，无远端推送。
