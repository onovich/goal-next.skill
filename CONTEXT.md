# GoalNext Workflow

本上下文描述一组跨 Codex 会话协作的规划、执行、验收与路由概念。

## Language

**Role**:
一个 Codex 会话在协作流程中承担的稳定责任边界。
_Avoid_: Persona, Agent Type

**Role Route**:
工作区内角色与具体 Codex 会话之间的最小映射，并携带防止重复派发所需的状态。
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
