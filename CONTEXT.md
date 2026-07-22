# GoalNext Workflow

本上下文描述一组跨 Codex 会话协作的规划、执行、验收与路由概念。

## Language

**Role**:
一个 Codex 会话在协作流程中承担的稳定责任边界。
_Avoid_: Persona, Agent Type

**Role Thread**:
一个用户可见、被分配稳定 Role 与有限工作流的 Codex 会话。
_Avoid_: Hidden Subagent, General-purpose Thread

**Role Route**:
工作区内角色与具体 Codex 会话之间的本地最小映射，可包含已批准的上下游关系、交接边界与防止重复派发所需的状态。
_Avoid_: Conversation Archive, Session Log

**Planner**:
负责定义阶段目标、边界、验收标准并将工作派发给 Executor 的角色。
_Avoid_: Executor, Implementer

**Executor**:
负责实施已确认 Goal Guide、验证结果并回报 Planner 的角色。
_Avoid_: Planner, Checker

**Checker**:
负责依据 Goal Guide 验收已完成阶段，并决定进入下一目标或要求修复的角色。
_Avoid_: Executor

**Goal Guide**:
一个已确认阶段的可执行目标合同，包含范围、非范围、轮次预算、验证与完成条件。
_Avoid_: Chat Reply, Uncommitted Idea

**Dispatch**:
一个角色把带有明确返回目标的工作合同发送给另一个角色的行为。
_Avoid_: Broadcast, Informal Mention

**Role Graph**:
多个 Role 及其有向上下游关系；它定义谁可以向谁派发，以及结果应回传给谁。
_Avoid_: Flat Role List

**Role Graph Proposal**:
保存在 `Role.proposed.md`、尚未生效或正处于部分创建恢复中的 Role Graph；它同时保存每个拟建会话的最小创建账本。
_Avoid_: Active Role Route, Chat-only Plan, Hidden Approval Marker

**Role Graph Approval**:
用户对一个确切 Role Graph revision 的创建授权，覆盖明确的会话数量、职责、路由、环境、Thread Profile 与可选预算；任何实质变更都会使该授权失效。
_Avoid_: CreateRole Invocation, Recommendation, Open-ended Permission

**Active Role Graph**:
保存在本地 `Role.md`、已经完成真实会话登记与激活验证的 Role Graph；文件名本身表示该路由已生效。
_Avoid_: `Role.proposed.md`, Embedded Confirmation Marker, Committed Thread Registry

**Thread Profile**:
为一个拟建 Role Thread 记录的短期创建建议，包含任务类别、模型参数是否省略、经确认的覆盖组合及其运行时证据。
_Avoid_: Account Settings, Permanent Model Policy, Thread Creation

**Work Budget**:
Role Thread 的已批准工作边界，可由 Goal Guide 轮次上限和可选的正整数 goal token budget 组成；轮次是流程约束，token budget 只有在用户明确批准且运行时支持时才由执行会话应用。
_Avoid_: Inferred Quota, Plan Tier, Silent Token Limit

**Target Role**:
GoalNext 为一个 Goal Guide 从已批准 Role Graph 中选出的唯一执行角色；优先使用明确的 `target_role`，安全时才使用 `default_executor`。
_Avoid_: Broadcast, All Executors, Title-only Guess

**Model Availability Evidence**:
当前账号/目标主机的线程创建工具或显式账户能力接口所公布的模型与推理强度组合。
_Avoid_: Hardcoded Catalog, Subscription Guess, Historical Assumption

**Explicit Model Override**:
相对于账号配置默认值，由用户直接指定或批准后传给线程创建工具的模型/推理强度组合。
_Avoid_: Recommendation-as-Authorization, Silent Substitution

**Workflow Entry**:
由用户有意调用、用于建立或推进协作流程的入口能力。
_Avoid_: Workflow Transition

**Workflow Transition**:
满足已记录条件后，一个 Role Thread 向另一个 Role Thread 发起的自动化阶段转移。
_Avoid_: User Entry, Hidden Delegation

**Decision Interview**:
面向调用方草案、按依赖顺序逐个解决高影响决策的有限问答过程。
_Avoid_: Open-ended Grilling, Survey

**Durable Coordination State**:
位于单个会话之外、可供新 Role Thread 重建项目状态的文档与版本证据。
_Avoid_: Conversation Memory

**Roadmap**:
描述项目阶段成果、先后依赖和退出条件的长期路线图。
_Avoid_: Task List, Goal Guide

**Roadmap Ownership**:
Roadmap 的方向、阶段和确认权属于用户；默认由用户自行设计，README 可提供可选的外部 AI 辅助建议，本项目 CreateRoadmap 仅作自包含兜底。
_Avoid_: Skill-owned Strategy, Automatic Confirmation, Default CreateRoadmap

**Confirmed Roadmap**:
经过用户明确确认并保存为规范文件名 `ROADMAP.md` 的 Roadmap；它是日常工作流技能继续运行的共同前置状态。
_Avoid_: `ROADMAP.proposed.md`, Embedded Confirmation Marker, Chat Approval

**Roadmap Evidence**:
RoadmapGate 在工作区根目录或调用方明确指定的项目内路径找到的、文件名严格为 `ROADMAP.md` 的可复核证据。
_Avoid_: Conversation Claim, TODO Checkbox, Goal Guide, Arbitrary Filename

**Roadmap Gate**:
每个日常技能在其他预检和工作之前显式进入的统一证据检查；只返回 `READY`、`ROADMAP_REQUIRED` 或 `BLOCKED`。
_Avoid_: Hidden Creation, Implicit Confirmation, Duplicated Caller Logic

**Roadmap Bootstrap Exception**:
仅供 CreateRoadmap 自身以及它明确标记的 AskMe/ListToDecide 调用使用的最小启动例外，用于避免在创建前置条件时产生循环依赖。
_Avoid_: General Bypass, Caller-controlled Escape Hatch

**Phase**:
Roadmap 中以可验证成果为边界的推进单元。
_Avoid_: Conversation Round, Ticket
