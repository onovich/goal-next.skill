# Roadmap

Status: confirmed

## Destination

交付一套可分发、去敏感、人类可见且文档驱动的 Codex 多会话工作流。项目以已确认 Roadmap 作为所有日常技能的共同前置状态，以显式 Role Thread 承担规划、执行、验收和专业分工，并让新会话可以从项目文档与 Git 证据恢复上下文。

## Baseline And Evidence

- 已导入并去敏感化 NameYou、ListToDecide、GoalNext、DoNextGoal、CheckAndGoal。
- 已实现自包含内部决策访谈 AskMe。
- 已提供技能清单、关系边、UTF-8 无 BOM/敏感信息验证和可重复安装脚本。
- 已实现作为兜底的 CreateRoadmap、统一证据门禁 RoadmapGate 及全工作流 Roadmap 前置契约。
- 已实现 ChooseModel，用运行时能力证据为拟建会话建议模型与推理强度，但不负责创建线程。
- 已实现 CreateRole：通过 Role Graph 提案、逐角色 Thread Profile、一次确切批准、顺序创建与可恢复账本来建立可见 Role Thread，并把多执行角色路由接入 GoalNext 闭环。

## Constraints And Non-scope

- 所有 Role Thread 与跨线程交接必须对用户可见、可干预，不以隐式 subagent 扩张替代角色设计。
- Roadmap 由用户设计和确认；可选的外部 AI 辅助建议只出现在 README，所有捆绑 Skill 保持自包含，CreateRoadmap 只作为用户明确选择的兜底。
- 日常技能只能在发现一份内容完整、文件名为 `ROADMAP.md` 的规范 Roadmap 后继续；未确认草案使用 `ROADMAP.proposed.md`。
- 分发内容不得包含凭据、真实 thread id、个人邮箱、用户专用绝对路径或私有对话。
- Roadmap 描述阶段成果与依赖，不替代 Goal Guide、ticket、实现轮次或聊天计划。
- 本阶段不把技能包封装为 plugin，也不以隐式 subagent 或未经批准的批量线程扩张替代 Role Graph。

## Phase Map

| Phase | Status | Depends on | Outcome |
| --- | --- | --- | --- |
| P0 可分发基线 | accepted | none | 五个初始技能完成去敏感、校验与安装闭环。 |
| P1 工作流分级与 AskMe | accepted | P0 | 调用层级明确，并具备受控的内部决策访谈。 |
| P2 Confirmed Roadmap Gate | accepted | P1 | 用户确认规范 Roadmap，所有日常技能共享同一证据门禁。 |
| P3 CreateRole | accepted | P2 | 用户确认 Role Graph 与 Thread Profile 后，显式创建、分配并登记一组 Role Thread。 |
| P4 集成与发布 | ready | P3 | 端到端拓扑经过验证并具备明确发布策略。 |

## P0 可分发基线

- Status: accepted
- Outcome: 初始技能、闭环依赖、Role Route 约束、安装与分发验证形成可重复基线。
- Depends on: none
- Non-scope: 自动角色创建与发布包装。
- Exit criteria: 五个技能通过闭包、元数据、无 BOM、敏感信息、安装覆盖与 Git 推送验证。
- Decision gates: 使用显式 Role Thread 而非隐式 subagent。
- Required capabilities: 技能设计、PowerShell 验证、Git。

## P1 工作流分级与 AskMe

- Status: accepted
- Outcome: 核心入口、辅助能力、工作流转移和内部依赖完成分类；AskMe 以有限问题预算写回调用方草案。
- Depends on: P0
- Non-scope: 通用访谈框架、线程创建、实现执行。
- Exit criteria: AskMe 自包含、关闭隐式调用、一次处理一个高影响决策，并能以明确终态返回。
- Decision gates: 内部能力仍须由调用方显式、可见地调用。
- Required capabilities: 决策建模、技能契约设计。

## P2 Confirmed Roadmap Gate

- Status: accepted
- Outcome: 用户拥有并确认阶段路线；RoadmapGate 通过 `ROADMAP.md` 文件名统一判断确认凭证，在缺失时优先提示自行设计，并仅在用户同意后调用自包含的 CreateRoadmap 兜底。
- Depends on: P1
- Non-scope: 创建角色线程、执行阶段工作、把普通任务清单当作 Roadmap。
- Exit criteria:
  - CreateRoadmap 将未确认内容保存在 `ROADMAP.proposed.md`，仅在用户明确确认后提升为 `ROADMAP.md`。
  - README 以自行设计 Roadmap 为默认路径，可单独提供外部 AI 辅助建议，并将 CreateRoadmap 标为自包含兜底。
  - ChooseModel、NameYou、ListToDecide、AskMe、GoalNext、DoNextGoal、CheckAndGoal 在其他前置动作前显式调用 RoadmapGate。
  - CreateRoadmap 自身以及它明确标记的 AskMe/ListToDecide 引导调用具有最小启动例外。
  - 清单关系边、验证器、README、上下文、ADR 与安装烟雾测试全部通过。
- Decision gates: 缺失或只有草案时先说明用户自有方案，再询问是否调用 CreateRoadmap 兜底；不得静默调用外部规划工具、创建或提升草案。
- Required capabilities: 路线规划、文档协调、决策访谈、契约验证。

## P3 CreateRole

- Status: accepted
- Outcome: 根据已确认 Roadmap 设计 Role Graph，在用户批准后显式创建会话、分配职责并登记上下游。
- Depends on: P2
- Non-scope: 未确认的批量扩张、隐式 subagent、在 Role Route 中保存对话或项目档案。
- Exit criteria:
  - 展示角色、线程数量、模型/强度、预算、上下游和交接合同并取得确认。
  - 每个拟建线程先由 ChooseModel 基于创建工具当前暴露的能力生成 Thread Profile；默认配置优先，显式覆盖另行确认。
  - 创建失败可恢复且重复执行具备幂等检查。
  - 新会话按 NameYou 契约登记，既有 `Role.md` 消费者保持兼容。
- Evidence: CreateRole 已作为显式 `core-entry` 加入清单与安装闭包；Role Graph 使用 `Role.proposed.md`/`Role.md` 文件名区分提案和激活状态；GoalNext、DoNextGoal、CheckAndGoal 已支持 `target_role` 与多执行角色修复回路；验证器覆盖批准、顺序创建、部分恢复和隐私边界。
- Decision gates: Role Graph、资源预算与任何显式模型/强度覆盖必须由用户明确批准。
- Required capabilities: 引导式架构访谈、动态模型配置决策、Codex thread 工具、路由登记。

## P4 集成与发布

- Status: ready
- Outcome: `Confirmed Roadmap → CreateRole → GoalNext → DoNextGoal → CheckAndGoal` 在典型多角色拓扑中形成可恢复闭环，并可安全分发。
- Depends on: P3
- Non-scope: 尚未决定的商业发布渠道。
- Exit criteria: 验证典型拓扑、模糊输入、问题预算、部分失败、恢复流程、显式 `$skill` 调用和 UI `@DisplayName` 自动补全；确定许可证、版本和 plugin 策略。
- Decision gates: 发布许可证、版本策略以及是否包装为 Codex plugin。
- Required capabilities: 集成测试、发布工程、文档。

## Deferred Or Dropped

- Codex plugin 包装：deferred，待 P4 根据独立技能包的使用反馈决策。
- 隐式 subagent 编排：dropped，与项目的人类可见性目标冲突。

## Next Ready Phase

P4 集成与发布。
