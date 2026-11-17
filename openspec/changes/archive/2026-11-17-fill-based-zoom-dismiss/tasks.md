# Tasks

## 1. 铺满基准缩放

- [x] 1.1 先添加长图/全景图 0.25、1、2 倍几何、宿主上限保留和混合手势回归，运行失败后实现统一基础尺寸和最小倍率；以 ZoomTests 通过为证。
- [x] 1.2 验证图片替换、清空再加载、近似比例、旋转与复用期间的倍率/偏移恢复，更新状态宿主原生倍率及完整显示断言；以 ZoomTests 与 RotationTests 通过为证。
- [x] 1.3 更新中英文缩放指南及 UIKit 视频子类中受基础几何影响的说明；以文档示例和测试中的原生倍率一致为证。

## 2. 顶部下拉关闭

- [x] 2.1 先添加放大顶部/中间、非零 inset、低于 1 倍和 2 倍跟手与取消恢复回归，运行失败后实现单指准入与坐标换算；以 LifecycleTests 通过为证。
- [x] 2.2 在系统手势宿主加入长图、到顶后重新下拉、放大顶部取消/完成和双指捏合隔离场景，同步关闭行为指南；以对应 LifecycleUITests、混合缩放及旋转 UI 测试通过并检查截图为证。

## 3. 集成与审查

- [x] 3.1 运行完整行为回归和主库、UIKit/CocoaPods、SwiftUI/SwiftPM 构建，保存测试结果及构建日志；所有必需检查通过后记录验证说明。
- [x] 3.2 完成全分支独立 review，处理重要问题并验证；运行 OpenSpec 严格校验和 git diff --check，通过后保留审查结论。

## Workflow follow-up

- 必需验收完成后使用 OpenSpec archive 同步主规格并归档，随后再次严格校验。
- 按用户授权提交本地分支，保留 PR #244 作者提交；不推送、不合并远端 master。

## Verification evidence

- 先失败后通过的独立数值用例见 `Validation/Zoom.md`；完整套件首轮的 51 项状态/文件测试已通过，含 12 Zoom、13 Rotation、22 Lifecycle 及 4 视频保存检查。
- 放大顶部跟手/取消、非零 inset、5 点临界起拖、交互中换图均通过；长图铺满/到顶重拉、2 倍取消/完成与捏合隔离系统手势已通过。
- 最新代码的主框架、UIKit/CocoaPods、SwiftUI/SwiftPM 设备构建均通过（Xcode 27.0，关闭签名）。
- 独立 review 无 Critical/Important；当前验证记录要求已按 Task 3 补齐。首轮 65/67，通过明确中部触点及加大缩小手势完成新倍率语义迁移；最终完整套件 67/67 通过、无跳过。
- 最终结果 `/tmp/PhotoBrowser-FillZoom-Final/Results.xcresult`：51 项状态/文件检查 + 16 项系统 UI 测试全部通过；长图、取消、混合缩放和旋转截图已检查。
