# ADR 0003: 以已批准 Role Graph 顺序创建可见会话

- Status: accepted
- Date: 2026-07-22

## Context

CreateRole 会产生真实、持续存在且消耗资源的 Codex 会话。若仅凭一次宽泛的“初始化工作流”请求就并行扩张，用户仍会遇到隐式 subagent 的原问题：数量失控、职责重叠、上下游不清、部分失败后难以追踪。另一方面，模型、推理强度、worktree 起点和 token budget 都可能改变成本或工作边界，不能把推荐当作授权。

## Decision

CreateRole 先把最小 Role Graph 写入 `Role.proposed.md`，必要时用 AskMe 逐个解决高影响决策，并为每个新会话通过 ChooseModel 生成 Thread Profile。它必须向用户展示确切 revision、线程数、职责、上下游、交接合同、环境、模型/强度和可选预算，再通过一个明确问题取得仅适用于该 revision 的创建授权。

批准后只允许顺序调用可见线程创建工具：每次创建后立即记录真实结果，完成登记和身份解析后才处理下一角色；首次失败会停止后续扩张。部分结果保留在 `Role.proposed.md` 供幂等恢复，不自动删除已创建会话。全部角色激活后才移除提案文件，并以本地 `Role.md` 作为生效路由；含真实 thread id 的两个文件不得提交。CreateRole 不得退化为隐式 subagent 编排。

## Consequences

用户能在资源产生前审查完整拓扑，也能在每个可见会话中介入；失败不会继续放大，重复调用可以复用已登记角色。多执行角色通过 `target_role`、`default_executor` 和产出角色记录保持修复回路一致。代价是初始化需要一次完整批准，创建速度慢于并行 fan-out，且 worktree 角色需要显式处理中央本地 Route 的可见性。
