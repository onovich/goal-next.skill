# Roadmap

## P0：可分发基线

- [x] 导入 NameYou、ListToDecide、GoalNext、DoNextGoal、CheckAndGoal 及其闭环依赖。
- [x] 移除真实本机路径、thread id 和旧项目专用名称。
- [x] 统一 Role Route 的 idempotency 字段约束。
- [x] 增加 UTF-8 无 BOM、元数据、闭包与敏感信息验证。
- [x] 增加可重复安装脚本和项目级 Git 工作流。

## P1：CreateRole 设计访谈

- [ ] 在实现前运行 `grill-with-docs`，并结合 `grilling` 与 `domain-modeling` 完成引导式访谈。
- [ ] 一次只问一个决策问题；每个问题提供推荐答案与理由。
- [ ] 能从代码库和 Codex 能力中查到的事实直接查证，只把方向性决策交给用户。
- [ ] 未形成共享理解前不实现 CreateRole。
- [ ] 访谈过程中即时维护 `CONTEXT.md`；只有当决定同时满足“难以逆转、缺少上下文会令人意外、存在真实取舍”时才新增 ADR。

设计需要明确：

- Role Graph 的节点、上游/下游边、任务派发与结果回传语义。
- 一次创建多少会话、角色模板从何而来，以及用户可以覆盖哪些默认值。
- 规划者、执行者、检查者、领域专家和协作者之间的推荐拓扑。
- 重复调用、部分创建失败、恢复执行、角色替换和路由冲突的处理方式。
- Role Route 的版本演进与现有 `Role.md` 消费者的向后兼容策略。
- 隐私边界：路由文件只保存最小身份与幂等信息，不保存会话内容。

## P2：CreateRole 实现

- [ ] 新增 `createrole/SKILL.md` 与 `createrole/agents/openai.yaml`，显示名使用易记的 `CreateRole`。
- [ ] 仅在用户明确要求创建 Codex 会话时调用会话创建能力。
- [ ] 根据已确认的 Role Graph 创建会话、分配职责、写入上下游关系并发送首条任务。
- [ ] 为重复执行提供幂等检查；对部分失败给出可恢复状态，不静默创建重复会话。
- [ ] 将新 Skill 纳入 `skill-set.json`、安装脚本和验证闭包。

## P3：集成与发布

- [ ] 在一次性测试工作区中前向测试典型拓扑、模糊角色、部分失败和恢复流程。
- [ ] 验证显式 `$createrole` 调用与 UI `@CreateRole` 自动补全。
- [ ] 决定发布许可证与版本策略。
- [ ] 评估是否包装为 Codex plugin；在此之前维持独立 Skill bundle 安装方式。
