# ADR 0001: Confirmed Roadmap 作为统一工作流前置条件

- Status: accepted
- Date: 2026-07-21

## Context

GoalNext 工作流跨越多个可见会话。若 NameYou、规划、执行、验收或决策技能在没有共同长期方向时各自推进，阶段边界与验收标准会随会话上下文漂移。把发现规则复制到每个技能又会造成行为分叉。

## Decision

所有日常技能在其他预检或工作前显式调用内部 RoadmapGate。RoadmapGate 是确认凭证发现与判断的唯一深模块：一份内容完整、文件名严格为 `ROADMAP.md` 的规范 Roadmap 即为已确认凭证；未确认草案使用 `ROADMAP.proposed.md`。证据缺失或只有草案时，它先说明 Roadmap 应由用户设计，再询问是否调用自包含的 CreateRoadmap 兜底。可选的外部 AI 辅助建议只属于 README，不进入 Skill 依赖链。CreateRoadmap 只有在单独取得用户明确确认后，才把草案提升为 `ROADMAP.md`，随后让原技能重新通过门禁。

为避免启动循环，CreateRoadmap 与 RoadmapGate 本身免于该前置检查；AskMe 和 ListToDecide 仅在 CreateRoadmap 同时声明 `caller: createroadmap` 与 `roadmap_bootstrap: true` 时获得限于 Roadmap 制定的例外。其他调用方没有绕过机制。

## Consequences

所有会话共享可审计的阶段方向，缺失前置状态时不会静默推进，调用方只需维护薄接口。文件名约定比隐藏标记更符合日常文档习惯，也让草案与生效版本一眼可辨。代价是即使 NameYou 或恢复性调用也会先经过 RoadmapGate，并且启动流程需要一个严格受限的例外。统一验证器负责防止技能遗漏门禁、关系边或文件名契约。
