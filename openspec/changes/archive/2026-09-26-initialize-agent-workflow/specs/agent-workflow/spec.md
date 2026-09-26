# Spec Delta

## Purpose

为 JXPhotoBrowser 的 AI Agent 开发提供共用行为契约，使任务范围、需求规格、代码调查、实施状态和验证证据可追溯，并能按改动影响完成规格同步与归档，避免将静态调查误报为运行时验收。

## ADDED Requirements

### Requirement: Scope-aware task routing

Agent SHALL 在修改前确认用户目标、工作区已有修改及验收标准；不改变既定契约的小修复可直接实施，新增行为、公开 API 变化或跨组件重构 MUST 建立可跟踪的 OpenSpec change。

#### Scenario: Small correction
- **WHEN** 任务仅修正文档或恢复既定行为，且用户未要求正式变更
- **THEN** Agent 可直接完成最小修改并报告对应验证，无需强制创建提案

#### Scenario: Contract or architecture change
- **WHEN** 任务引入新行为、改变公开 API 或进行跨组件重构
- **THEN** Agent 在实施前记录范围、相关需求、必要设计和可验证任务

### Requirement: Authorization follows user intent

Agent SHALL 区分仅规划与实施请求，并保留用户在当前任务中已经明确授予的权限；工具自动选择 MUST NOT 抹去用户已授权的实施范围。

#### Scenario: End-to-end implementation requested
- **WHEN** 用户已要求完成明确范围内的初始化或实施
- **THEN** Agent 连续完成必要工作，只在歧义影响行为、兼容性或验收时请求澄清

#### Scenario: Proposal only
- **WHEN** 用户仅要求探索或提案
- **THEN** Agent 交付调查或 artifacts，不将其视为实施或发布授权

### Requirement: Indexed code investigation with fallback

仓库有 CodeGraph 索引时，Agent SHALL 优先通过索引定位代码和影响范围；未覆盖、明确过期或不可用时 SHALL 使用当前文件作为补充依据。

#### Scenario: Index is available
- **WHEN** Agent 需要理解或修改已索引代码
- **THEN** 先查询相关符号、文件或调用流程，复用返回源码，不重复全文扫描

#### Scenario: Index cannot supply current source
- **WHEN** 索引不存在、工具不可用或结果明确提示文件过期
- **THEN** Agent 使用普通搜索和当前文件继续调查，并不将缺失结果当作代码不存在的证据

### Requirement: Verification matches change scope

Agent SHALL 按受影响范围选择验证，区分静态校验、构建、交互和设备证据；任务只有在约定的完成证据存在时才可勾选。

#### Scenario: Documentation-only change
- **WHEN** 修改只涉及文档、Agent 配置或规格
- **THEN** 执行对应静态和规格检查，无需为此运行 iOS 构建或安装 Pods

#### Scenario: Runtime interaction change
- **WHEN** 修改影响手势、滚动、转场或生命周期
- **THEN** 验证受影响构建和交互；环境阻塞的必要验证保持待办，不以调用图或 Demo 引用替代

### Requirement: Completed changes preserve specification history

Agent SHALL 在必要任务与验证完成后同步 delta 到主规格并归档，保留实施证据；归档 MUST NOT 被表述为 Git 提交、推送或发布。

#### Scenario: Change is ready to archive
- **WHEN** 任务与必要验证已完成，规格严格校验通过
- **THEN** 使用 CLI 完成规格同步和归档，再验证主规格并报告归档位置

#### Scenario: Required acceptance remains pending
- **WHEN** change 仍有未完成任务或必要验收
- **THEN** 保留活动变更和未勾选任务，明确剩余工作，不宣称整体完成
