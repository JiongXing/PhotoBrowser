# Design

## Context

当前项目以 CLAUDE.md 为共用指南，AGENTS.md 指向它；已有本机 CodeGraph 索引和 Xcode CI，无 OpenSpec 主规格或独立测试 target。初始化 CLI 版本为 OpenSpec 1.13.2，CodeGraph 1.6.0。动机见 proposal.md。

## Goals / Non-Goals

**Goals:** 用项目文档和标准 CLI 建立可审查流程，按真实改动选择验证，并留下本次迁移的完成证据。

**Non-Goals:** 不新增自定义编排器、脚本框架、产品测试 target，不改库源码和全局 Agent 配置。

## Decisions

1. 保留 CLAUDE.md 为共享入口，详细操作独立到 Documentation/AgentWorkflow.md；相较复制两套 Agent 规则，减少漂移。
2. 使用内置 spec-driven schema 和 core profile，为 Codex / Claude Code 生成各 6 个技能。项目定制放 config.yaml 与共享指南，避免直接修改生成技能而被升级覆盖。
3. 规格只基线化开发流程，产品能力随未来实际任务逐步补充；不把源码扫描当成已验收的完整产品需求。
4. 保留 CodeGraph 已有安装、MCP 与忽略规则，按版本提示重建本机索引；代码调查失败时允许回退，不为查询要求增设全局工具配置。
5. 为 CI 增加固定 OpenSpec 版本的独立 job；本地文档工作只做静态与工具集成验证，iOS 构建规则与现有 CI 对齐。
6. 已明确授权的实施连续推进；仅规划请求停在 artifacts，保留用户对 scope 和交付动作的控制。

## Risks / Trade-offs

- [生成技能可能带有独立规划边界] → 共享指南明确尊重用户原始授权，定制不写入生成文件。
- [调用图的关联不等于运行时事实] → 明确要求构建、模拟器和设备证据分开记录。
- [升级 CLI 改变生成格式或校验] → 固定 CI 版本，升级时审查生成 diff 并严格验证。
- [新增 CI job 尚未在 GitHub 执行] → 本地执行相同校验命令并解析 YAML；远端执行结果独立报告。

## Migration Plan

初始化配置与技能，重建旧索引，更新共用指南与 CI，验证后通过 CLI 同步主规格并归档。本次仅涉及开发文档与工具配置；若需回滚，恢复这些文件即可，索引可按当前源码重新生成。
