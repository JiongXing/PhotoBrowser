# AI Agent 开发工作流

项目以 Codex 为开发 Agent，统一入口是 [AGENTS.md](../AGENTS.md)。OpenSpec 管理需求与任务，CodeGraph 提供源码和影响范围，编译器与实际运行提供验证证据。

## 开始任务

```bash
git status --short
git branch --show-current
openspec list --json
openspec list --specs
```

先确认目标、范围、验收标准和已有修改，再读取相关规格；不要为获得干净工作区而覆盖用户修改。只读分析、文档勘误、小范围修复且不改变既定契约，可以直接实施。新功能、公开 API / 行为变化、跨组件重构，或用户指定 OpenSpec 时，建立 change。

没有相应主规格不代表行为没有约束：结合公开文档和实现取证，明确现状与新要求，逐步补充受影响能力；初始化不要求把整库反向生成成规格。

## 标准流程

1. **需求 / 规格**：明确问题、范围、兼容性和可观察的验收场景；只为相关能力编写 delta。
2. **实现定位**：使用 CodeGraph 查询相关文件、符号、调用链和影响范围，读取尚未覆盖的配置与文档。
3. **设计 / 任务**：选择最小充分方案，拆成可验证任务；边界、所有权、生命周期或兼容性变化需要设计说明。
4. **实施**：按任务修改，实际完成才勾选；新发现若改变需求或方案，先更新 artifacts。遇到影响业务行为的歧义才询问。
5. **验证 / 审查**：检查当前 diff、规格场景和受影响集成；把静态检查、构建、交互验证分别记录。
6. **归档 / 交付**：必要验证完成后合并 delta 到主规格并归档；报告改动、证据与剩余限制，Git 提交 / 推送 / 发布分别按授权执行。

用户只要求提案或探索时，完成相应产物即可；用户已明确要求实施时，在其授权范围内继续完成。自动选择工具或技能不能缩小用户已经授权的范围。

## OpenSpec 操作

本项目使用 `spec-driven` schema 和中文 artifacts；结构标题保留英文，规格使用 `SHALL` / `MUST`、`WHEN` / `THEN`。配置见 [openspec/config.yaml](../openspec/config.yaml)。

| 目录 | 职责 |
| --- | --- |
| `openspec/specs/<capability>/spec.md` | 已落地的行为契约 |
| `openspec/changes/<change>/proposal.md` | 问题、范围与能力变化 |
| `openspec/changes/<change>/specs/` | 对主规格的增删改 delta |
| `openspec/changes/<change>/design.md` | 必要的技术决策与取舍 |
| `openspec/changes/<change>/tasks.md` | 实施和验证清单 |
| `openspec/changes/archive/` | 已完成的变更记录 |

已生成 Codex（`.agents/skills/`）技能，包含 `openspec-explore`、`openspec-propose`、`openspec-update-change`、`openspec-apply-change`、`openspec-sync-specs`、`openspec-archive-change`。可以直接用自然语言指定动作和 change 名；技能尚未被当前会话发现时，使用 CLI 与 artifacts 完成同样工作。

以下 `<change>` 是占位符，执行时换成实际 kebab-case 名称：

```bash
openspec new change <change>
openspec status --change <change> --json
openspec instructions proposal --change <change> --json
```

根据 `status` 的依赖顺序，逐项获取 `proposal`、`specs`、`design`、`tasks` 的 `instructions` 后写入对应文件。新能力 delta 包含明确 `Purpose`，避免归档后留下占位内容。纯内部重构若无契约变化，可在该 change 的 `.openspec.yaml` 声明 `skip_specs: true`，不要为校验编造需求。

实施前读取：

```bash
openspec instructions apply --change <change> --json
```

`status` 的 artifacts 为 `done` 只表示文件已存在，不代表任务完成或行为通过验收。任务证据写在任务条目附近；暂时无法完成的必要验收保留未勾选，并说明原因。

完成后：

```bash
openspec validate --all --strict --no-interactive --json
git diff --check
openspec archive <change> --yes --json
openspec validate --all --strict --no-interactive --json
openspec list --json
```

归档前检查 tasks 和必要验证结果，CLI 不会替你运行构建或交互验收。通过 `openspec archive` 同步 delta 并归档；不要用手工移动目录、`--skip-specs` 或 `--no-validate` 绕过正常闭环。归档和 Git 提交是独立动作。

## CodeGraph 查询

存在索引时，代码定位先用 MCP `codegraph_explore`，明确当前项目路径及查询目标；MCP 不可用时：

```bash
codegraph explore "JXPhotoBrowserViewController reloadData scrollToItem"
codegraph explore "JXZoomPresentAnimator JXZoomDismissAnimator thumbnailViewAt"
```

将返回的当前源码视为已读，不重复全文扫描。只对遗漏内容、提示过期的文件或工具不可用情况使用 `rg` / 文件读取。图中的 caller、callee 和推断关联是调查线索，Demo 被标为 test 也不能作为测试通过的证据。

### CodeGraph 维护

```bash
codegraph status
```

- 新 checkout 尚无 `.codegraph/`：在用户要求初始化时执行 `codegraph init --yes .`；没有该授权时直接回退普通搜索。
- 正常 watcher 会同步文件变化，日常任务无需反复重建。
- 状态提示引擎版本变化、索引损坏时，执行 `codegraph index .` 重建。
- watcher 停止或明确报告落后时，先读当前文件，必要时执行 `codegraph sync .`，再检查状态与查询结果。
- `.codegraph/.gitignore` 已跟踪；数据库、日志、PID、socket 是本机产物，不提交。

## 验证矩阵

| 改动范围 | 必要验证 |
| --- | --- |
| 文档 / Agent 配置 / 规格 | diff 与链接；涉及 OpenSpec 时运行严格校验 |
| `Sources/` | 主框架构建 + 受影响示例构建；验证对应行为场景 |
| UIKit 示例 / Pod 配置 | 首次或依赖变化时 `pod install`，使用 `.xcworkspace` 构建 |
| SwiftUI 桥接 / SwiftPM 配置 | SwiftUI 示例构建；变化涉及显示 / 消失 / 数据同步时验证桥接交互 |
| Carthage / 发布配置 | 对应 XCFramework / 集成构建及 `PrivacyInfo.xcprivacy` 打包检查 |
| 手势 / 滚动 / 转场 / 生命周期 | 模拟器验证受影响的缩放、下拉取消与完成、循环、轮播、前后台或桥接；需要设备能力时补充真机 |

命令见 [AGENTS.md](../AGENTS.md#构建命令)，发布检查见 [CI](../.github/workflows/ci.yml)。当前无独立测试 target；静态检查与 Demo 构建不能替代交互验证，也不要将 `swift build` 的 macOS 目标作为 UIKit 库的验收。

CI 的 `agent-workflow` job 独立校验 OpenSpec；`behavior` job 通过 `Validation/run-tests.sh` 运行状态、文件与系统交互回归并保存结果包；iOS 构建和集成检查保留在原有 jobs 中。运行方式和覆盖边界见 [验证说明](../Validation/Rotation/README.md)。本地只运行与本次改动相符的检查。

## 工具版本与维护

本次初始化验证版本：OpenSpec **1.13.2**、CodeGraph **1.6.0**。开发者可用 `openspec --version`、`codegraph version` 检查本机；工具是开发依赖，不进入库的 SwiftPM / Pod 依赖。

- 新机器若缺少 OpenSpec：`npm install -g @fission-ai/openspec@1.13.2`。
- CodeGraph CLI 已在本机安装；其他机器装好 CLI 后按上文建立索引。MCP 接入由各 Agent 的本机配置管理；没有 MCP 时可使用相同 CLI 查询。
- 现有 checkout 的 skills 已随仓库提供，无需每次 `init`。重建接入文件的命令：`openspec init --tools codex --profile core --language zh-CN --no-animation .`。
- 升级 OpenSpec 后运行 `openspec update`，检查生成文件 diff、配置和严格校验，并同步 CI 中固定版本。CLI 生成技能不放项目定制内容，以免更新时丢失。
