# Tasks

## 1. 状态和 Cell 修复

- [x] 1.1 建立可重复的 UIKit 回归用例，先在 PR 原始代码复现旋转中刷新/跳页的旧页码覆盖，记录失败证据。原 PR 三项测试共 5 个断言失败，见 `/tmp/PhotoBrowserPR241-Baseline.xcresult`；首轮修复后三项通过。
- [x] 1.2 修复转场定位有效性和轮播生命周期，通过数据缩减/清空、动画前后导航、轮播暂停与恢复断言。iPhone/iPad 各 12 项状态回归通过。
- [x] 1.3 补齐进入及复用 Cell 的尺寸转场和布局协调，通过首次布局准备、缩放恢复、后续图片更新断言。包含旧转场完成回调不能结束新转场的回归。

## 2. 系统交互与集成

- [x] 2.1 在允许旋转的模拟器宿主执行横/纵分页、非零间距、循环首尾、拖拽/减速、远距离跳页、轮播、缩放和双击；断言页码与画面对齐并检查动画截图，记录设备/OS 和运行配置。见 `Validation/Rotation/README.md`；iPhone 17 和 iPad Pro 11-inch (M5)，iOS 27.0。iPad 的真实合成捏合未生效且原 PR 同样失败，未记为通过；固定倍数双击覆盖已放大状态的旋转。
- [ ] 2.2 构建主框架、UIKit 和 SwiftUI 示例；定位并按需修复 SwiftUI 集成失败，记录实际构建及隐私清单结果。本地三种构建及隐私检查通过（Core/UIKit 命令覆盖部署目标为 15）；远端 SwiftUI exit 65 未重现、详细日志需登录，根因和新 CI 待确认。
- [ ] 2.3 完成代码审查、git diff --check 和 OpenSpec 严格校验，整理回归说明；必需验收通过后同步主规格并归档。代码审查、diff 和严格校验已通过；远端 CI 仍待验证，暂不归档。

## 3. 原 PR 交付

- [x] 3.1 创建独立修复提交，保留作者两次提交；验证差异范围。主工作区修复提交 `f24db18`；交付分支 `codex/pr241-delivery` 提交 `004d1b9`，父提交就是原 PR `4531599`；仅包含两个库文件及独立验证目录，两处的 Sources/Validation 内容一致。
- [ ] 3.2 认证可用时回推原 PR，确认 CI 全部通过后合并；若认证或 CI 阻塞，记录具体原因并保留可交付提交。2026-09-26 已尝试 HTTPS 回推，失败：`could not read Username for https://github.com: terminal prompts disabled`。SSH 也无可用身份，未推送、未合并；CI 和归档保持待办。

## Delivery

交付工作区：`/Users/jxing/.codex/worktrees/pr241-delivery/PhotoBrowser`。

该分支只在原作者两个提交后追加修复，没有混入本地主线的工作流配置。GitHub 凭据配置好后，在该工作区执行：

```sh
git push https://github.com/Vinzius/PhotoBrowser.git codex/pr241-delivery:fix/rotation
```

之后确认 PR #241 新 CI，查明并处理仍存在的 SwiftUI 构建失败，再完成规格归档和合并。当前不能宣称整个 PR 已交付完成。
