# ADR 0002: 动态选择新会话的模型与推理强度

- Status: accepted
- Date: 2026-07-22

## Context

CreateRole 需要为不同职责约束模型与推理强度，但 Codex 可用型号、支持的强度、目标主机和账户能力会变化。把型号表写进技能会快速过期；把“系统推荐”直接当作创建授权又会违反线程工具对显式模型覆盖的确认边界。

## Decision

新增用户可见的 support Skill `ChooseModel`。它在 confirmed Roadmap 门禁后，从当前线程创建 schema 或显式账户能力接口读取可用组合，按任务确定性、广度、歧义、风险、协调与验证负担提出 Thread Profile。套餐等级和额度没有明确数据源时必须记录为 unknown，不得根据型号或历史行为推断。

默认配置足够时，Thread Profile 要求创建方省略 model 与 effort 参数。确有收益时，ChooseModel 只返回 `OVERRIDE_PROPOSED`；用户直接指定或明确批准后才能变为 `CONFIRMED_PROFILE`。ChooseModel 永不创建、修改或关闭线程，创建方在执行前还必须重新验证目标主机支持该组合。

## Consequences

模型策略可以随账号和运行时能力演进，不需要频繁发布新的硬编码目录；用户也能看见每个角色为何使用某个强度。代价是额度不可见时无法做精确成本规划，并且显式覆盖需要一次额外确认。CreateRole 必须消费 Thread Profile，而不能把推荐结果当作授权。
