# Tasks

## 1. 工具接入

- [x] 1.1 初始化 OpenSpec 1.13.2 的 spec-driven 配置和 Codex / Claude Code 技能；通过 openspec context 确认根目录，各客户端生成 6 个 SKILL.md。
- [x] 1.2 使用 CodeGraph 1.6.0 重建已有索引；codegraph status 不再报告旧引擎版本，MCP 返回带行号源码，数据库与日志被 git ignore。

## 2. 工作流与规格

- [x] 2.1 建立共享入口、任务分流、授权边界、查询回退和验证矩阵；检查指南链接、既有 CI 构建路径与场景覆盖一致。
- [x] 2.2 写入 OpenSpec 项目 context、rules、operations 和工作流 delta；严格校验成功，instructions 返回项目规则。
- [x] 2.3 增加独立 CI 校验 job；解析 YAML 并在本地运行 job 中相同 OpenSpec 校验命令。

## 3. 集成检查

- [x] 3.1 检查改动范围、生成技能一致性、Markdown 链接和新文件空白；确认无库源码、依赖或全局配置修改。

## Evidence

- 初始化前 master 工作区干净；已有 .codegraph/，无 openspec/。
- 索引重建后初次状态为 37 files / 544 nodes / 907 edges；运行时文件被现有 .codegraph/.gitignore 忽略。
- OpenSpec 严格校验通过；apply instructions 返回项目 context 和 2 条 operation guidance，tasks instructions 返回 2 条规则。
- 检查 25 个改动 / 新增文件、10 个本地链接及锚点、空白格式；6 对技能仅客户端调用语法不同，CI YAML 可解析，校验命令与本地执行一致。
- 后续配置改动曾被 CodeGraph 报告为 pending，已执行一次 sync 同步；MCP 与 CLI 均完成真实查询。
- 本次只涉及开发流程、配置与文档，不需要 iOS 构建或模拟器验收。
- GitHub CI 的远端运行不属于本次本地验证；未执行提交、推送或发布。

## Follow-up

- 2026-09-26：按用户后续要求移除 Claude Code 接入；项目指南迁入 AGENTS.md，删除 CLAUDE.md 和 .claude/skills/，重建命令改为仅 --tools codex。上文双客户端接入与验证是初始化时的历史记录，当前支持范围以 AGENTS.md 和 Documentation/AgentWorkflow.md 为准。
