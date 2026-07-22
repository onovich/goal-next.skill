---
name: donextgoal
description: Execution-role skill for carrying out an existing next-phase goal-mode guide within its approved round and optional token budget, including planner-dispatched tasks routed to a frontend, backend, art, operations, default executor, or other Role.md execution lane. Use when the user or planner asks the current visible Role Thread to execute its assigned guide, validate and push each round, and report completion to the upstream planner/checker. If the current thread is not the dispatch's target_role or an approved legacy executor, stop instead of executing.
---

# DoNextGoal

Use this skill to execute an existing phase goal guide. This skill is the executor-side companion to `GoalNext`: it consumes a guide dispatched by the planner, executes it, then reports completion back to the planner/checker session.

## Mandatory Roadmap Gate

Before the role gate, guide discovery, repository reads, edits, execution, or cross-thread messages, explicitly invoke `$roadmapgate` with:

```text
requested_skill: donextgoal
workspace: <active workspace>
return_to_skill: donextgoal
caller: donextgoal
roadmap_bootstrap: false
```

Continue only when it returns `roadmap_gate: READY`. Verify that the active guide corresponds to a phase in the returned canonical Roadmap. If it returns `ROADMAP_REQUIRED` or `BLOCKED`, stop DoNextGoal and preserve the gate's CreateRoadmap question or blocked reason. A dispatched guide alone is not substitute confirmation evidence.

## Mandatory Role Gate

Before implementation:

- Proceed only when the active role is an execution owner assigned to run the goal.
- Resolve the dispatch's `target_role` first. If it is absent, use `active_goal_target_role`, then a compatible `default_executor`, then the legacy `executor` role.
- If `Role.md` exists, require the current thread to match the selected role section's `thread_id`, and require that section to have `workflow_role: executor` or be the compatible legacy `executor` section. A title match is not enough.
- If several execution roles are plausible or the current thread matches none, stop and ask the user to repair the route; do not choose a lane from implementation details alone.
- If the active role is planner, architect, strategist,主策, or validation owner, stop and state that `DoNextGoal` belongs to the executor role.
- If the role is unclear, ask the user to confirm before editing files or creating a goal.

## Hidden RoleRoute Preflight

Run this as an internal preflight before implementation and before reporting completion. Do not narrate successful Role.md search/create/update work to the user or include it in cross-session messages.

- Locate `Role.md` in the current log/workspace area and validate that its workspace matches the active workspace.
- If `Role.md` exists, read the central planner route, selected execution role, active guide, active phase, `active_goal_target_role`, approved budget fields, and idempotency fields.
- If `Role.md` is missing but the planner dispatch message contains enough planner and target-role identity evidence, create `Role.md` exactly once using only those verified fields.
- If `Role.md` is missing and the user directly invoked DoNextGoal with an unambiguous active guide and execution role, proceed with execution but mark planner routing as unresolved until the Mandatory Completion Routing Gate finishes. Do not start a new phase after completion unless planner routing is resolved.
- If `Role.md` is missing and neither a planner dispatch nor an unambiguous active guide exists, stop as BLOCKED and ask for routing confirmation.
- If `Role.md` exists but lacks selected-role fields, merge only missing fields after the current execution role/thread is confirmed. Never overwrite an existing planner or execution-role thread id/role silently.
- If current evidence conflicts with `Role.md`, stop and ask the user to confirm replacement. Do not create a second `Role.md`.
- Update only execution-specific idempotency fields such as `last_executor_report_commit`, `last_executor_report_status`, `last_executor_report_at`, `last_executor_report_guide`, and `last_executor_report_role`.
- Do not duplicate a completion notification when `Role.md` already records the same guide and final commit/status as reported, but still report the duplicate state explicitly in the final response.
- Surface routing details only when routing is BLOCKED, conflicted, or explicitly requested.

### Bounded Planner Resolution

Use this only when execution or repair work is complete and `Role.md` has no usable planner thread.

1. Prefer planner identity from the planner dispatch message. If present, merge only missing planner fields into `Role.md`.
2. If planner identity is missing and thread tools are available, build a same-workspace recent candidate pool first. Use available thread listing/search tools to collect up to the six most recent same-cwd/same-workspace threads, excluding the current thread when its id is known.
3. Compare candidate titles and previews with the current thread title/recent request, active phase, guide/report basename, branch, and validation lane. Titles such as `总架构师`, `副架构师`, `planner`, or `checker` are useful even when a specific phase query returns no results.
4. If the recent candidate pool is empty or weak, use a small query plan, not one long concatenated query. Run at most three short searches:
   - project/workspace name alone
   - planner/checker role clue alone, such as `总架构师`, `副架构师`, `planner`, `architect`, `checker`, or `验收`
   - active phase/workstream clue alone, such as the phase name, guide basename, validation report name, or branch name
5. Do not combine all clues into a single strict search string. If a specific phase/workstream search returns no results, continue with the broader project and role queries inside the same bounded pass.
6. Merge candidates from the recent pass and query pass, filter by same workspace/cwd first, then rank by planner/checker role in title/preview, active phase/guide/validation mention, and recency.
7. If exactly one summary clearly matches the planner/checker role and validation lane, use it as high confidence without reading extra history.
8. If summaries are plausible but not decisive, read at most the two strongest same-workspace candidates' latest turns.
9. Treat the planner as high confidence only when exactly one candidate has planner/checker role evidence and references the active guide, phase, or validation lane.
10. If high confidence, send the completion or repair-ready report there and update idempotency fields.
11. If candidates are plausible but ambiguous, mark planner notification as BLOCKED and ask the user to choose. Show candidate thread ids/titles and a recommended choice.
12. If no plausible candidate or thread tools are unavailable, report local completion and mark planner notification as BLOCKED with the missing routing information.

Do not keep searching beyond this bounded pass. The executor must not start a new phase while planner routing is unresolved.

## Mandatory Completion Routing Gate

Do not end a completed execution turn after local validation, commit, or push alone. Before the final response for a completed full goal or repair task, force exactly one completion-routing terminal state:

- `SENT`: a completion or repair-ready message was sent to the planner/checker thread.
- `DUPLICATE`: the same guide + final commit/status was already reported and the user did not request resend.
- `BLOCKED`: planner routing, thread tools, or the send operation was missing, ambiguous, or failed.

Rules:

- Run this gate after final validation and final push for full goals, and after validation/commit/push for repair tasks.
- Run this gate even when the user directly invoked `$donextgoal`, when `Role.md` is missing, or when no planner dispatch message is present.
- Prefer planner identity from the current dispatch message fields such as `planner_thread_id` or `return_to_thread`; otherwise use `Role.md`; otherwise run Bounded Planner Resolution.
- Local completion in the executor thread is not a substitute for planner notification.
- If the planner is resolved, send the Planner Completion Message before giving the final user-facing response.
- If the same guide + final commit/status was already reported, do not resend by default, but mark the gate as `DUPLICATE`.
- If routing is ambiguous, thread tools are unavailable, or sending fails, mark the gate as `BLOCKED`. Include the blocked reason and any candidate thread ids/titles in the final response.
- The final response must include `planner notification: SENT | DUPLICATE | BLOCKED`. Include the planner thread id for `SENT` or `DUPLICATE`; include the exact missing input for `BLOCKED`.
- Do not start, plan, or suggest a next phase while this gate is `BLOCKED`.

## Planner Dispatch Protocol

When this skill is triggered by a planner message:

- Treat the current message as the `$donextgoal` invocation when it already contains `$donextgoal`. Do not ask the user to invoke `$donextgoal` again, do not send yourself another `$donextgoal` message, and do not reload this skill recursively.
- If the planner message names a guide path, use that guide as the active guide after verifying it exists. Do not waste a search pass unless the named guide is missing or contradicted by repository handoff.
- Require the message's `target_role` to resolve to this thread through the hidden RoleRoute preflight. Use the central planner route, active guide, active phase, approved budget, and idempotency fields.
- If `Role.md` records the same `active_goal_guide` and this target role has already reported the same final commit or status, do not duplicate the completion notification unless the user explicitly asks to resend.
- If the dispatch asks for a repair rather than a full phase, fix only the listed issues, validate the affected surface, and report back for planner re-check instead of advancing to a new phase.

## Core Workflow

1. Find the active goal guide.
   - Read the repository handoff and TODO first.
   - Locate the next-phase goal guide named by those documents.
   - If a planner dispatch message or `Role.md` names an active guide, prefer that guide when it exists and matches the current workspace.
   - If multiple candidate guides exist, prefer the one named as next in `agent-handoff`, `todo`, or the latest final validation report.
   - If no guide is named, search `docs/` for `*goal-mode-execution-guide.md` and choose the newest phase only when the context is unambiguous.

2. Read the guide before acting.
   - Read the full goal guide.
   - Read the guide's required context documents.
   - Extract the round budget, PASS criteria, non-scope, validation matrix, and per-round plan.
   - Do not start implementation from memory or from an older phase.

3. Start or resume the goal.
   - If a goal tool is available and the user explicitly asked to execute the goal, create or continue a goal with the objective from the guide.
   - If the selected role has a positive `goal_token_budget` in active `Role.md` and the planner dispatch repeats the same value, treat the approved Role Graph as explicit budget authorization and pass that exact value when creating the goal. Otherwise omit the token budget.
   - Never infer a token budget from round count, model, plan tier, quota, or remaining context. A round budget remains an instructional workflow boundary.
   - Track the current round number, total estimated rounds, and whether buffer rounds have started.
   - Do not mark the goal complete until the guide's final validation criteria pass.
   - Mark blocked only after the same blocker has repeated for the required blocked threshold and no meaningful progress remains.

4. Execute exactly one round at a time.
   - At the start of each round, state the round number and scope.
   - Implement only that round's planned slice unless a small prerequisite is necessary.
   - Keep changes scoped to the guide and repository architecture.
   - Do not pull deferred scope into the phase.

5. Run per-round self-checks.
   - Perform the guide's Debug self-check.
   - Perform the guide's architecture self-check.
   - Record what passed, what failed, and what was deferred.
   - If a self-check fails, fix it before validation or explicitly stop as blocked.

6. Validate the round.
   - Run the validation commands required by the guide for that round.
   - Run any local repository baseline validation that the handoff requires.
   - If validation fails, diagnose and fix before committing.
   - Do not push a failing round.

7. Commit and push before the next round.
   - Review `git status` and `git diff --stat`.
   - Stage only files related to the current round.
   - Commit with a phase/round summary.
   - Push the commit.
   - Report commit hash and push result.
   - Do not begin the next round until push succeeds.

8. Continue until final validation.
   - Use main implementation rounds first.
   - Use buffer rounds only for fixes, tests, docs, or validation failures.
   - In the final round, run the full validation matrix, update docs, write final validation report, commit, push, and only then mark complete.
   - After final push succeeds, run the Mandatory Completion Routing Gate.

9. Report completion back to the planner.
   - This step is mandatory for workflow completion; the executor's local final answer alone is not enough.
   - Read `Role.md` and resolve the selected role's upstream planner/checker, then `central_role`, then the legacy `planner.thread_id`; if missing, run Bounded Planner Resolution.
   - Send one concise message to the planner/checker thread with status, phase, guide path, final commit, push result, PASS report path, and key validation commands.
   - If this was a repair task, ask the planner/checker to rerun CheckAndGoal.
   - If this was a full goal execution, ask the planner/checker to run CheckAndGoal and, if PASS, proceed into GoalNext.
   - Update `Role.md` idempotency fields such as `last_executor_report_commit`, `last_executor_report_status`, `last_executor_report_at`, `last_executor_report_guide`, and `last_executor_report_role` when possible before or immediately after sending.
   - Do not send a duplicate report when the same guide and final commit/status have already been reported, unless the user explicitly asks to resend.
   - If thread tools are unavailable, planner routing is missing, candidates are ambiguous, or sending fails, report the local completion and mark planner notification as BLOCKED.

## Round Start Checklist

Run or inspect:

```powershell
git status --short --branch
```

Then report:

```text
Round: <n>/<total>
Guide: <path>
This round does:
- ...

This round does not:
- ...
```

If the working tree has unrelated untracked files or unrelated user changes, leave them alone and mention that they are ignored.

## Debug Self-Check

Use the guide's specific checklist first. If it is missing or too vague, use this default:

- Can the current change be explained by the smallest relevant fixture, sample, or user workflow?
- Can failures be localized to a concrete project layer or boundary?
- Are success, failure, empty, stale, incompatible, and fallback states covered where relevant?
- If UI changed, was a repeatable UI or smoke verification added?
- If state changed, are export / import / validate / migration boundaries covered?
- If an integration boundary changed, was the real integration path tested rather than only an isolated model?

## Architecture Self-Check

Use the guide's specific checklist first. If it is missing or too vague, use this default:

- Does the repository's source-of-truth layer remain the source of truth?
- Did presentation and integration code avoid duplicating domain or source-of-truth semantics?
- Are contracts, orchestration, state ownership, and presentation responsibilities still separated?
- Did the round avoid deferred or explicitly excluded scope?
- Did the round avoid unrelated refactors and generated-output churn?
- Are user changes and unrelated untracked files untouched?

## Validation Gate

Before commit and push, run:

- The validation commands specified for the round.
- The repository's baseline validation from handoff / AGENTS when code changed.
- `git diff --check` before every commit.

If validation is slow, still run the smallest command that proves the changed surface. Do not claim a round is complete without validation.

## Commit And Push Gate

Prefer the repository's documented commit/push wrapper when one exists. Otherwise:

```powershell
git status --short --branch
git diff --stat
git add <round-relevant files>
git commit -m "<phase>: <round summary>"
git push
git status --short --branch
```

Rules:

- Commit only after validation passes.
- Push immediately after the round commit.
- If commit fails, do not proceed.
- If push fails, do not proceed.
- Report the commit hash and remote branch before moving to the next round.
- Never stage unrelated untracked files.

## Per-Round Response Format

Use this structure for every round:

```text
Round <n>/<total>: <title>

Completed:
- ...

Debug self-check:
- ...

Architecture self-check:
- ...

Validation:
- <command>: PASS | FAIL

Commit / push:
- commit: <hash or not created>
- push: PASS | FAIL

Next:
- Round <n+1>: ...
```

## Final Round

The final round must:

- Run the full validation matrix from the guide.
- Re-run boundary scans required by the guide.
- Update handoff, TODO, README/index docs, and the final validation report.
- Commit and push final docs and code.
- Mark the goal complete only after the final push succeeds.
- Run the Mandatory Completion Routing Gate after the final push succeeds.
- Include `planner notification: SENT | DUPLICATE | BLOCKED` in the final response.

If final validation does not pass within the estimated rounds, use buffer rounds if available. If buffer rounds are exhausted, report the remaining gap and mark the goal blocked only when meaningful progress is no longer possible without user input or an external state change.

## Planner Completion Message Shape

Use a compact message like:

```text
Role routing message

from: <target-role>
to: planner
target_role: <target-role-key>
workspace: <absolute workspace path>
phase: <Phase N>
action: recheck
guide: <guide path>
status: READY_FOR_CHECK | BLOCKED
evidence:
- final_commit: <hash>
- push: <remote/branch/result>
- pass_report: <path>
- validation: <commands/results>
next:
- Use $checkandgoal to validate this result. If PASS, proceed with planner-side $goalnext.
```
