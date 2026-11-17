# Design

## Context

见 proposal.md。基于 master f725644 合入 PR #244（7511edc），38 项状态测试基线通过。CodeGraph 定位到 `Sources/JXZoomImageCell.swift` 的图片观察、几何计算与缩放回调，以及 `Sources/JXPhotoBrowserViewController.swift` 的下拉准入和 DismissInteraction。现有 browser-lifecycle 主规格保留旧的缩放准入规则，本次显式修改该契约；size-transition 的完整显示与生命周期恢复要求保持有效。

## Goals / Non-Goals

**Goals:** 原生 UIScrollView 倍率直接表达铺满基准；长图可铺满并进一步放大；在不同倍率下从顶部下拉跟手，取消不丢失浏览位置。

**Non-Goals:** 不接管同一次图片滚动到顶后的手势；不支持纵向分页下拉关闭；不新增倍率适配器、数据模型或依赖；不更新版本、不改远端 PR、不发布。

## Decisions

### Approaches

1. 保留 aspect-fit 基础尺寸、将外部倍率换算后写入 UIScrollView：可复用多数旧几何，但公开 `scrollView.maximumZoomScale = 2` 不再直接对应产品的 2 倍，需要额外 API。未采用。
2. **采用 aspect-fill 基础尺寸**：`zoomContentView` 的未变换 bounds 使用铺满尺寸；`minimumZoomScale = fitScale / fillScale`，初始使用 minimum，默认 maximum 为 2。与用户确认的原生属性语义直接对应。
3. 继续保留两套基础尺寸切换：无法可靠统一双击和捏合，未采用。

### Geometry and lifecycle

在图片 Cell 内集中更新基础尺寸、最小倍率、真实内容尺寸与居中位置，更新期间避免缩放委托回调用旧几何重复布局。普通布局和比例相同的图片更新不重置放大；比例变化时，原来在 minimum 则跟随新 minimum，否则保留钳制后的铺满倍率并校正越界偏移。旋转、复用和清空图片后的新加载恢复完整显示。maximum 只设置默认值，后续布局不覆盖宿主配置。

默认双击目标为 1，显式有效目标直接使用铺满倍率并钳制到缩放范围。检测当前是否在 minimum 使用适合浮点几何的小误差，必须保留近似宽高比图片的重复切换能力。

### Dismissal

保留浏览器 `gestureRecognizerShouldBegin` 的方向判断；设置单指限制，内置 Cell 按顶部及捏合/转场状态决定准入。未在顶部时识别器在本次触摸序列失败，不在 changed 阶段重新争抢手势。

现有 handlePanGesture 的位移来自浏览器坐标，而图片位于被缩放的父容器。将位移转换到该父容器，按原始触摸点缩放并与原图片变换组合，保持屏幕触摸点跟手。DismissInteraction 与 Cell 回调保存/恢复交互所需状态，取消后不重置到 minimum。关闭及旧回弹隔离沿用原生命周期流程。

### Compatibility

`zoomScale == 1` 表示铺满，不再表示初始；外部检测完整显示应比较 minimum。`doubleTapZoomScale` 改为铺满基准，默认最大由 3 改 2。更新中英文指南、示例说明和测试状态输出；验证宿主输出原生 zoomScale，并通过坐标转换后的实际显示尺寸报告 fit 状态；完整显示断言检查 fit，新倍率断言直接检查原生值。

## Risks / Trade-offs

- [极长/极宽图的 minimum 很小] → 用 100 × 800 / 400 × 800 等独立数值验证 0.25、1、2 倍真实几何，以及极端比例和反向全景图。
- [缩放父容器影响关闭坐标] → 在小于 1 倍和 2 倍时检查触摸点屏幕位移、取消后的倍率/偏移/变换，并执行系统手势。
- [原有宿主默认下拉语义变化] → 指南记录顶部关闭及重新下拉规则，保留自定义 Cell 拒绝能力。
- [异步图片更新和动画打断] → 真实 UIKit 测试覆盖比例替换、清空再加载、旋转、复用与未完成双击。

## Migration Plan

本地分支保留原贡献者提交，追加经验证的实现。宿主按铺满语义检查现有固定倍率，并以 minimum 判断完整显示。验证后通过正常 OpenSpec archive 同步主规格，提交本地分支；远端推送/替代 PR 留待用户单独授权。回退可撤销本次追加提交及原 PR 集成，恢复原 master 行为。
