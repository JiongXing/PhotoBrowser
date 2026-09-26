# Proposal

## Why

项目已有 CodeGraph 索引与简要 Agent 指南，但没有可跟踪的规格、实施任务和归档流程；构建指引也混用了 macOS SwiftPM 和 iOS 验证方式。需要让 Codex 与 Claude Code 共用可复现、按任务范围选择验证的工作流。

## What Changes

- 初始化 OpenSpec 项目配置和双 Agent 技能，规范需求、任务与证据记录。
- 验证并重建已有 CodeGraph 索引，明确代码查询优先级与失效回退。
- 增加小修复 / 正式变更分流、授权边界、验证矩阵和归档流程。
- 修正 iOS / CocoaPods 构建说明，加入独立 OpenSpec CI 校验。
- 非目标：修改图片浏览器行为、完整反向生成产品规格、增加业务依赖或自动提交 / 发布。

## Capabilities

### New Capabilities

- `agent-workflow`: 跨 Agent 的任务分流、代码调查、验证证据和规格归档契约。

### Modified Capabilities

无。

## Impact

影响根目录 Agent 指南、Documentation、OpenSpec 配置 / 规格 / skills 和 CI。既有 CodeGraph 本机索引由 1.3.0 格式重建为 1.6.0；其数据库继续忽略。无公开 API 或运行时依赖变化。
