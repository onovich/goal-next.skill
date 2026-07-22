---
name: goalnext
description: Architect/strategist-only skill for creating the next-phase goal-mode execution guide after a phase is accepted, then dispatching that guide to the executor session recorded in Role.md. Use when the user asks an architecture or strategy role to output the next stage/phase goal document, estimate conversation rounds, define Debug and architecture self-checks, require validation before push, and require push before moving to the next round. If the active role is a programmer, implementation executor, maintainer executing the current goal, or other delivery-side agent, trigger this skill only to refuse the role-inverted request and route it to the architect/strategist.
---

# GoalNext

Use this skill to produce a reusable next-phase goal guide, not merely a chat answer. It is the planner-side companion to `DoNextGoal`: after writing the guide, dispatch the executor through `Role.md` instead of asking the user to relay the plan.

## Mandatory Roadmap Gate

Before the role gate, project reads, planning, `Role.md` work, guide creation, or dispatch, explicitly invoke `$roadmapgate` with:

```text
requested_skill: goalnext
workspace: <active workspace>
return_to_skill: goalnext
caller: goalnext
roadmap_bootstrap: false
```

Continue only when it returns `roadmap_gate: READY`. Use the returned canonical Roadmap as the source for phase ordering. If it returns `ROADMAP_REQUIRED` or `BLOCKED`, stop GoalNext and preserve the gate's CreateRoadmap question or blocked reason. A handoff, TODO, Goal Guide, or Role Route is not substitute confirmation evidence.

## Mandatory Role Gate

Before writing or updating a next-phase guide, check the active role in system, developer, user, and project instructions.

- Proceed only when the active role is explicitly an architect, strategist, product/technical planner, or phase-planning owner.
- Refuse when the active role is a programmer, main programmer, coding agent, implementation executor, release executor, QA executor, or maintainer who is currently supposed to implement or validate the existing plan.
- Refuse when the same request also asks the agent to execute current-phase work, because planning the next phase and implementing the current phase are separate ownership lanes.
- If refusing, keep it brief: state that `goalnext` belongs to the architect/strategist role, do not create or edit a goal guide, and suggest handing the request to that role. You may still read or point to an existing guide when needed for execution.
- Only bypass this guard when the user explicitly reassigns the current agent into an architecture/strategy role for this turn, and no higher-priority instruction conflicts.
- If the active role is unclear, ask the user to confirm before creating or updating a guide, writing `Role.md`, or sending cross-thread dispatches.

## Hidden RoleRoute Preflight

Use `Role.md` as the cross-session routing source of truth, but keep routing mechanics internal. Do not narrate successful Role.md search/create/update work to the user or include it in cross-session dispatch messages.

- Locate `Role.md` in the current log/workspace area before dispatching.
- If `Role.md` exists, read it and validate that its workspace matches the active workspace.
- If `Role.md` is missing, create it exactly once only after the planner role and planner thread id are known. Record only the planner route, workspace, evidence, timestamps, and supported idempotency fields. If the planner thread id is unavailable, do not invent it; dispatch must be blocked unless the return target is otherwise explicit.
- Resolve the executor from `Role.md` first. If executor fields are missing, inspect same-workspace Codex threads and identify the session that actually owns implementation for the current requirement. Merge only those missing executor fields into `Role.md`.
- Never overwrite an existing planner or executor thread id/role silently. If current evidence conflicts with `Role.md`, stop and ask the user to confirm replacement.
- Do not create a second `Role.md` when one already exists. If the current log area is ambiguous, use the active workspace root only when no existing `Role.md` is found in the searched areas.
- Keep idempotency fields in `Role.md`: `active_goal_guide`, `active_goal_phase`, `last_planner_dispatch`, `last_planner_dispatch_status`, `last_planner_dispatch_guide`, `last_planner_dispatch_commit`, `last_executor_report_commit`, and `last_check_status`.
- Re-scan other threads only when `Role.md` is missing, incomplete, stale, contradicted by the user, or points to the wrong workspace.
- Surface routing details only when routing is BLOCKED, conflicted, or explicitly requested.

### Bounded Executor Resolution

Use this before dispatch when `Role.md` has no usable executor.

1. Build a same-workspace recent candidate pool first. Use available thread listing/search tools to collect up to the six most recent same-cwd/same-workspace threads, excluding the current thread when its id is known.
2. Compare candidate titles and previews with the current thread title/recent request, active phase, guide basename, branch, and implementation lane. A same-workspace title such as `执行者-主线` or `执行者-多模块` is useful even when a specific guide query returns no results.
3. If the recent candidate pool is empty or weak, use a small query plan, not one long concatenated query. Run at most three short searches:
   - project/workspace name alone
   - executor role clue alone, such as `执行者`, `executor`, or `main programmer`
   - guide-specific phase/workstream clue alone, such as the phase name, guide basename, branch name, or implementation lane
4. Do not combine all clues into a single strict search string. If the specific guide query returns no results, continue with the broader project and role queries inside the same bounded pass.
5. Merge candidates from the recent pass and query pass, filter by same workspace/cwd first, then rank by executor role in title/preview, relevant implementation lane, active guide/phase mention, and recency.
6. If exactly one summary clearly matches the executor role and implementation lane, use it as high confidence without reading extra history.
7. If summaries are plausible but not decisive, read at most the two strongest same-workspace candidates' latest turns.
8. Treat the executor as high confidence only when exactly one candidate has executor role evidence and is already working on the relevant implementation lane.
9. If high confidence, create or update `Role.md` once with the planner fields, executor fields, active guide, active phase, and idempotency fields, then dispatch.
10. If candidates are plausible but ambiguous, stop after writing and validating the guide. Ask the user to choose, show candidate thread ids/titles, and recommend one. Record dispatch as BLOCKED when `Role.md` can be updated safely.
11. If no plausible candidate or thread tools are unavailable, report dispatch as BLOCKED with the missing routing detail.

Do not keep searching beyond this bounded pass. GoalNext's job is to produce a guide and route it when the route is clear, not to perform open-ended thread archaeology.

## Mandatory Dispatch Routing Gate

Do not finish GoalNext after guide creation alone. After the guide is written, validated, and committed/pushed when required, force exactly one dispatch terminal state:

- `SENT`: one `$donextgoal` dispatch message was sent to the executor thread.
- `DUPLICATE`: the same guide + commit was already dispatched and the user did not request resend.
- `BLOCKED`: executor routing, planner return identity, thread tools, or the send operation was missing, ambiguous, or failed.

Rules:

- Run this gate for initial planning and for post-CheckAndGoal PASS planning.
- The final response must include `dispatch result: SENT | DUPLICATE | BLOCKED`.
- If dispatch is `SENT`, include the executor thread id in the final response and update `Role.md` idempotency fields when possible.
- If dispatch is `DUPLICATE`, do not resend, but include the prior executor thread id and dispatch evidence when available.
- If dispatch is `BLOCKED`, keep the guide as a planner artifact, but do not imply the executor has been notified. Include candidate thread ids/titles or the exact missing input the user must provide.
- Every dispatch message must include a return target for executor completion: `planner_thread_id` or `return_to_thread` when known. This lets `DoNextGoal` report back even if `Role.md` is later missing.
- Never send a dispatch without a usable executor route and a usable planner return target.

## Workflow

1. Confirm the next phase from project context.
   - Read the project handoff / TODO / latest validation report first.
   - Identify the last accepted phase, its PASS evidence, and the next candidate phase.
   - If the next phase is unclear, state the ambiguity and choose the safest narrow candidate already supported by docs.
   - When invoked after `CheckAndGoal` PASS, consume that PASS result as the validation gate and do not repeat the full CheckAndGoal workflow unless evidence is stale.
   - When invoked directly for an initial planning session and there is no completed phase to check, proceed as the first-planning path after the role gate and RoleRoute preflight. Do not require a CheckAndGoal PASS for this initial path.

2. Apply decision authority while designing the goal.
   - For key planning decisions, first follow consensus already established in the current project through repository docs, handoff/TODO files, prior conversation context, and memory. Treat explicit consensus as binding unless higher-priority instructions conflict.
   - For low-priority unresolved decisions that do not materially affect architecture, scope, sequencing, product direction, data contracts, security/privacy, compatibility, effort budget, or irreversible workflow, choose a conservative option using planner judgment. Briefly record the assumption when it affects execution.
   - For high-priority unresolved decisions that materially affect architecture, scope, sequencing, product direction, data contracts, security/privacy, compatibility, effort budget, or irreversible workflow, stop before finalizing or dispatching the guide and ask the user to decide. Provide a recommended option and rationale as advice, but do not treat it as decided.
   - Do not use planner preference to override documented project consensus.

3. Estimate the round budget.
   - Give a concrete total number of rounds.
   - Split the budget into main implementation rounds, buffer rounds, and final validation.
   - Default pattern for substantial implementation phases: 16 rounds, with rounds 1-12 as main work, 13-15 as buffer fixes, and 16 as final validation.
   - Use fewer rounds only for a clearly documentation-only or narrow scoped phase.

4. Write the goal guide as a document.
   - Prefer a repo document under `docs/` when working inside a repository.
   - Name it consistently with local conventions, for example `phase-5-goal-mode-execution-guide.md`.
   - Include a direct goal-mode prompt that another executor can paste into goal mode.
   - Include consensus-based assumptions and low-priority planner choices that affect execution; leave high-priority unresolved choices out of dispatch and ask the user first.
   - Include required reading, scope, non-scope, architecture boundaries, per-round plan, validation matrix, PASS criteria, and final report template.

5. Require every round to self-check.
   - Every round must include a Debug self-check.
   - Every round must include an architecture self-check.
   - Every round must report validation commands and results.
   - Every round must report whether a buffer round was consumed.

6. Gate progression through validation and push.
   - A round is not complete until its relevant validation passes.
   - After validation passes, commit and push that round before moving to the next round.
   - If push fails, the executor must not proceed to the next round.
   - Require reporting the commit hash and push result in each round summary.

7. Sync the project entry points.
   - Update the project docs index, TODO, and handoff document when those exist.
   - The entry points should link to the new goal guide and state the round budget.
   - Keep unrelated untracked files and unrelated user changes out of the update.

8. Validate the guide itself.
   - Run `git diff --check` for documentation edits.
   - Check that links to the new guide appear in the expected entry documents.
   - If the repository has a docs lint or structure check, run it.
   - For docs-only guide creation, do not run the full build unless local policy requires it.

9. Dispatch the guide to the executor.
   - After the guide is validated and any required commit/push is complete, resolve the executor from `Role.md` or Bounded Executor Resolution.
   - Update `Role.md` with the active guide path, phase, dispatch timestamp, and dispatch status when it is safe to do so.
   - Run the Mandatory Dispatch Routing Gate before the final response.
   - Send exactly one concise message to the executor thread recorded in `Role.md`.
   - Include the planner return target, guide path, phase name, round budget, latest commit/push evidence, key non-scope boundaries, and exactly one `$donextgoal` instruction.
   - Do not paste the full guide into the message. The executor must read the guide from the repository.
   - Do not send a duplicate dispatch when `Role.md` already records the same `active_goal_guide` or `last_planner_dispatch_guide` with `last_planner_dispatch_status: sent` for the same guide and commit, unless the user explicitly asks to resend.
   - If executor routing is ambiguous, ask the user to choose from the bounded candidates and do not send the dispatch yet.
   - If thread tools are unavailable or dispatch fails, report the guide as created but dispatch as BLOCKED.

## Dispatch Message Shape

Use a compact message like:

```text
Role routing message

from: planner
to: executor
workspace: <absolute workspace path>
planner_thread_id: <current planner/checker thread id when known>
return_to_thread: <same planner/checker thread id>
phase: <Phase N>
action: execute_goal
guide: <absolute or repo-relative guide path>
round_budget: <n>
status: READY
evidence:
- commit: <hash>
- validation: <commands/results>
next:
- Use $donextgoal to execute this guide. This message is the skill invocation; do not ask the user to invoke it again.
```

## Required Guide Sections

Use these sections unless the repository has a stronger local pattern:

```markdown
# <Phase Name> Goal 模式执行指南

日期：<date>
状态：给执行者使用的 <phase> 开发指令文档

## 0. 直接给执行者的 Goal Prompt
## 1. 必读上下文
## 2. 本阶段要完成什么
## 3. 本阶段不做什么
## 4. 每轮固定工作流
## 5. 每轮通过后提交推送工作流
## 6. 分轮安排
## 7. PASS 标准
## 8. 最终报告模板
```

## Per-Round Gate Template

Include a reusable gate like this in the guide:

```text
每轮回复必须包含：
- 本轮目标
- 本轮完成内容
- Debug 自检
- 架构自检
- 已运行验证命令与结果
- commit hash 与 push 结果
- 下一轮目标
- 是否消耗缓冲轮

推进规则：
- 验证失败：不得提交推送，不得进入下一轮。
- 验证通过但提交失败：不得进入下一轮。
- 提交成功但推送失败：不得进入下一轮。
- 推送成功：记录 commit hash 和远端分支，然后进入下一轮。
```

## Debug Self-Check Pattern

Tailor the bullets to the phase, but always include:

- Can the current change be explained by the smallest relevant fixture or user workflow?
- Can failures be localized to a specific project layer or boundary?
- Are success, failure, empty, stale, and incompatible states covered where relevant?
- If UI changed, was a repeatable UI or smoke verification added?
- If state changed, are export / import / validate / migration boundaries covered?

## Architecture Self-Check Pattern

Tailor the bullets to the project, but always include:

- Does the existing source-of-truth layer remain the source of truth?
- Did presentation and integration code avoid duplicating domain or source-of-truth semantics?
- Are contracts, orchestration, state ownership, and presentation responsibilities still separated?
- Did the phase avoid pulling deferred scope into the current stage?
- Are unrelated files, generated outputs, and user changes left alone?

## Push Workflow

Prefer the repository's documented commit/push wrapper when one exists. Otherwise use:

```powershell
git status --short --branch
git diff --stat
git add <phase-relevant files>
git commit -m "<phase>: <round summary>"
git push
git status --short --branch
```

The generated goal guide should explicitly tell the executor not to stage unrelated untracked files.
