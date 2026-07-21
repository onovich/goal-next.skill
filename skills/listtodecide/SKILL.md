---
name: listtodecide
description: Decision clarification skill for listing upcoming work that needs the user's decision before execution. Use when the user asks Codex to list what needs their approval, compare options, explain tradeoffs, provide a recommendation, distinguish high-priority decisions from low-priority agent choices, or stop for user sign-off before continuing.
---

# ListToDecide

Use this skill to turn "what needs my call next?" into a structured decision brief. The goal is to help the user decide without making them arbitrate every small implementation detail.

## Canonical Prompt

Use this polished prompt when the user asks for a reusable wording:

```text
请把接下来需要我拍板的事项列出来。

对每个事项请说明：
- 为什么这个事项需要我决定
- 有哪些可选方案
- 每个选项的意义、影响、取舍和风险
- 你基于当前项目共识和上下文的推荐倾向
- 如果暂不决定，会阻塞什么或默认保持什么状态

请优先基于当前项目文档、对话和已达成共识来判断。低优先级、可由你按既有共识自行处理的事项，请单独列为“你可自行处理”，不要混入必须拍板清单。高优先级或会影响方向、范围、架构、发布、预算、数据、安全、兼容性、跨会话工作流的事项，必须停下来让我决定。

最后请停在等待我选择，不要继续执行需要我拍板的事项。
```

## Workflow

1. Build only the context needed for the decision brief.
   - Read the current request, recent relevant conversation, project docs, plans, TODO/handoff files, and known constraints.
   - Avoid open-ended archaeology. If the missing context is not necessary to form the decision menu, do not chase it.

2. Separate decisions by required authority.
   - Must ask the user for high-priority choices affecting product direction, scope, architecture, sequencing, public release, cost or effort budget, data contracts, security/privacy, compatibility, irreversible workflow, external commitments, cross-session routing, or owner approvals.
   - Use agent judgment for low-priority choices that are local, reversible, implementation-level, or already determined by project consensus.
   - If project consensus already decides an issue, do not re-ask it unless evidence conflicts.

3. Collapse the list.
   - Group duplicate or tightly coupled decisions.
   - Prefer the smallest set of decisions that unlocks the next meaningful work.
   - Do not overwhelm the user with speculative future choices unless they are about to block execution.

4. Explain each decision.
   - State the decision question in one sentence.
   - Explain why it matters now.
   - Offer 2-4 realistic options.
   - For each option, explain meaning, tradeoff, risk, and when it fits.
   - Give a clear recommendation and why.
   - State what remains blocked or what default is safest if the user defers.

5. Stop for the user.
   - Ask the user to pick options or approve the recommendation.
   - Do not execute high-priority undecided work.
   - Continue only on low-priority items explicitly marked as agent-owned.

## Output Shape

Use this structure by default:

```markdown
我把接下来需要你拍板的事项分成两类：必须你决定的，以及我可以按既有共识自行处理的。

**需要你拍板**

1. <decision title>
   - 为什么现在要定：<reason>
   - 选项 A：<meaning/tradeoff/risk>
   - 选项 B：<meaning/tradeoff/risk>
   - 我的倾向：<recommendation>
   - 暂不决定的影响：<blocked/default>

**我可以自行处理**

- <low-priority item>: <planned conservative choice>

请先决定上面的 <n> 个事项。我会在你拍板后继续推进。
```

If there are no user-level decisions, say that clearly, list the agent-owned assumptions, and proceed only if the user's request already authorized execution.
