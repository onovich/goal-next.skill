---
name: checkandgoal
description: Planner-side gate for validating the most recently completed project phase, routing repair requests back to the Role.md execution lane that produced it, and triggering the next GoalNext workflow after PASS. Use when the user asks Codex to 验收, check acceptance, validate a finished frontend/backend/art/operations or default-executor phase, coordinate repair, or proceed into GoalNext. This skill must not execute DoNextGoal locally in the planner/checking session.
---

# CheckAndGoal

Use this skill as the planner/checker gate between a completed phase and the next planned phase. It validates completed work, routes repair requests to the execution role that produced it, and starts the planner-side next-goal workflow after PASS.

The core rule is:

1. Validate first.
2. If validation fails, notify the producing execution role to repair and report back to the planner/checker session after fixing.
3. If validation passes, run `$goalnext` only from the planner/architect/strategist role, then let GoalNext select and dispatch `$donextgoal` to the next execution role.
4. Never execute `$donextgoal` locally from the planner/checker session.

## Mandatory Roadmap Gate

Before the role gate, repository inspection, validation, routing, or cross-thread messages, explicitly invoke `$roadmapgate` with:

```text
requested_skill: checkandgoal
workspace: <active workspace>
return_to_skill: checkandgoal
caller: checkandgoal
roadmap_bootstrap: false
```

Continue only when it returns `roadmap_gate: READY`. Use the returned canonical Roadmap to identify the phase outcome and exit criteria under review. If it returns `ROADMAP_REQUIRED` or `BLOCKED`, stop CheckAndGoal and preserve the gate's CreateRoadmap question or blocked reason. A validation report or Goal Guide alone is not substitute confirmation evidence.

## Mandatory Role Gate

Before validating or planning:

- Proceed only when the active role is a planner, architect, strategist, product/technical planning owner,主策, or validation owner.
- If the active role is an executor, main programmer, implementation agent, or delivery-side maintainer, stop and ask the user to route CheckAndGoal to the planner/checker session.
- If the active role is unclear, ask the user to confirm the role before writing `Role.md`, sending cross-thread messages, or running `$goalnext`.

## Hidden RoleRoute Preflight

Run this as an internal preflight before validation or cross-thread messages. Do not narrate successful routing work to the user or include it in cross-session messages.

- Locate `Role.md` in the current log/workspace area.
- If `Role.md` exists, read it, validate that its workspace matches the active workspace, and resolve `active_goal_target_role` or `last_executor_report_role` for the phase under review.
- If `Role.md` is missing, create it exactly once only after the current planner/checker role and thread id are known and the execution role that produced the result is identified with high confidence.
- When creating `Role.md`, record only planner and selected execution-role routes, workspace, evidence, timestamps, and supported idempotency fields.
- If `Role.md` exists but is missing fields, merge only the missing fields. Never overwrite an existing planner or execution-role thread id/role silently.
- If the existing planner/execution-role records conflict with current evidence, or the file points to a different workspace, stop and ask the user to confirm replacement. Do not overwrite and do not create another `Role.md`.
- Update only event-specific idempotency fields such as `last_check_status`, `last_repair_request`, or `last_goalnext_trigger` during CheckAndGoal.
- Re-scan other threads only when `Role.md` is missing, incomplete, stale, contradicted by the user, or points to the wrong workspace.
- Surface routing details only when routing is BLOCKED, conflicted, or explicitly requested.

### Repair Target Selection

For FAIL/BLOCKED repair routing, select exactly the execution role that produced the result:

1. Prefer `last_executor_report_role` when it matches the completion message and active guide.
2. Otherwise use `active_goal_target_role` or `last_planner_dispatch_target_role` when it matches the guide and phase.
3. Otherwise use the target role named by the Goal Guide or completion message.
4. Otherwise use a compatible `default_executor`, then the legacy `executor` section, only when it is the sole plausible producer.
5. If several execution roles remain plausible, ask the user to choose; never broadcast a repair request to all downstream roles.

### Bounded Execution-Role Resolution

Use this only when Repair Target Selection identifies one role key but `Role.md` has no usable thread for that role and a FAIL/BLOCKED result needs repair routing.

1. Build a same-workspace recent candidate pool first. Use available thread listing/search tools to collect up to the six most recent same-cwd/same-workspace threads, excluding the current thread when its id is known.
2. Compare candidate titles and previews with the selected role key/title, current request, active phase, guide/report basename, branch, and workstream. Titles such as `执行者-主线`, `前端`, or `后端` are useful only when they match the selected lane.
3. If the recent candidate pool is empty or weak, use a small query plan, not one long concatenated query. Run at most three short searches:
   - project/workspace name alone, such as `<project-name>`
   - selected execution-role clue alone, such as the role key, `执行者`, `frontend`, `backend`, or `main programmer`
   - active phase/workstream clue alone, such as `<phase-name>`, `<workstream-name>`, the guide basename, or the branch name
4. Do not combine all clues into a single strict search string. If a specific phase/workstream search returns no results, continue with the broader project and role queries inside the same bounded pass.
5. Merge candidates from the recent pass and query pass, filter by same workspace/cwd first, then rank by selected-role evidence in title/preview, active phase/workstream mention, and recency.
6. If exactly one summary clearly matches the selected execution role and implementation lane, use it as high confidence without reading extra history.
7. If summaries are plausible but not decisive, read at most the two strongest same-workspace candidates' latest turns.
8. Treat the route as high confidence only when exactly one candidate has selected-role evidence and references the active guide, branch, phase, or implementation workstream in its title, preview, prompt, or recent turns.
9. If high confidence, merge only missing fields into the selected role section in `Role.md` and send the repair request.
10. If candidates are plausible but ambiguous, mark repair notification as BLOCKED and ask the user to choose. Show only candidate thread ids, titles, and the recommended choice; do not send a repair request.
11. If no plausible candidate or thread tools are unavailable, report notification as BLOCKED with the search basis.

Do not perform repeated searches, deep history reads, or cross-project guessing. The repair workflow must either route, ask for a specific confirmation, or stop cleanly.

## Mandatory Repair Routing Gate

When acceptance is FAIL or BLOCKED and execution-role repair is needed, do not finish with only the local validation result. Before the final response, force exactly one repair-routing terminal state:

- `SENT`: a repair request was sent to the selected execution-role thread.
- `BLOCKED`: repair-target routing, thread tools, or the send operation was missing, ambiguous, or failed.

Rules:

- Run this gate after the check decision and before any final user-facing response for FAIL/BLOCKED.
- Include a planner return target in every repair request: `planner_thread_id` or `return_to_thread` when known. This gives `DoNextGoal` a direct reporting target even if `Role.md` is missing later.
- If routing is ambiguous, ask the user to choose from the approved Role Graph or bounded candidates; do not silently abandon repair routing.
- If sending fails, report `notification result: blocked` with the send error or missing routing input.
- Do not run `$goalnext`, dispatch `$donextgoal`, or imply repair is underway while this gate is `BLOCKED`.

## Workflow

### 1. Establish The Target

- Read the repository handoff / TODO entry first.
- Identify the most recently completed phase, its final validation report, and its goal guide.
- Check git status and latest commits.
- Preserve unrelated untracked or dirty files.
- Run the hidden RoleRoute preflight. If routing is conflicted or points to a different workspace, stop before validation-dependent messaging. If only the execution target is missing, continue validation and resolve it only if FAIL/BLOCKED repair routing becomes necessary.

### 2. Validate The Completed Phase

Use the phase's own final validation report and guide as the source of truth.

Run the required validation matrix when feasible:

- build / tests
- CLI or smoke commands listed in the final report
- structure / syntax checks
- boundary scans
- `git diff --check`
- docs index / handoff / TODO checks when the phase changed docs

If a command is too expensive or impossible in the current environment, state that explicitly and decide whether remaining evidence is strong enough. Do not mark PASS if a required validation is skipped without a good reason.

### 3. Decide PASS Or Not

PASS only when all are true:

- The final validation report exists and matches the implemented state.
- Required commands pass or have acceptable documented reasons for being skipped.
- The worktree has no unexpected tracked changes.
- Boundary scans do not show forbidden scope creep.
- Docs and TODO reflect the completed phase.
- Latest commit / push state is consistent with the phase being complete when the project requires push-per-round.

If any item fails, stop after notifying the executor. Give a concise acceptance result and the smallest cleanup plan. Do not run `$goalnext` or `$donextgoal`.

### 4. Notify The Executor Session

After the check decision is known:

- Send the executor session a concise message only when the result is FAIL or BLOCKED and executor repair is needed.
- Run the Mandatory Repair Routing Gate before the final response for any FAIL/BLOCKED repair case.
- If FAIL or BLOCKED, run Repair Target Selection; when the selected role has no usable thread, run Bounded Execution-Role Resolution before declaring notification blocked.
- Include concrete paths, commit hashes, commands, PASS/FAIL/BLOCKED status, and the planner return target when available.
- If FAIL or BLOCKED, tell the executor not to continue to a new phase. List the smallest required cleanup and ask the executor to report back to the planner/checker session after fixing.
- If PASS, do not send an executor message from CheckAndGoal and do not tell the executor to run `$donextgoal` directly. Proceed to planner-side GoalNext.
- If no selected execution-role session can be identified after the bounded search, or thread tools are unavailable, report notification as BLOCKED with the concrete missing routing information. When plausible candidates exist, ask the user to choose rather than abandoning the route silently.
- Do not send planner-only work to an executor role. If the next action requires `$goalnext`, run it only in the planner/architect/strategist session and let GoalNext dispatch the executor task.

### 5. Run GoalNext Only After PASS

After PASS:

- Confirm that the current role is allowed to run `$goalnext`.
- Load `$goalnext` in the current planner/architect/strategist session and create or update the next-phase guide.
- Let `GoalNext` dispatch the resulting guide to the executor with exactly one `$donextgoal` instruction.
- If the current role is not allowed to run `$goalnext`, stop after PASS and report the role mismatch.
- If no next phase should be planned yet, stop after PASS and report why.

Do not silently invent a next phase. `CheckAndGoal` is the gate; `GoalNext` is the planner; `DoNextGoal` is the executor.

## Output Shape

Keep the final response short:

- acceptance result: PASS / FAIL / BLOCKED
- key validation commands run
- routing only when BLOCKED, conflicted, or explicitly requested
- notification result: sent / blocked / not applicable
- planner return target included in repair request: yes / no / not applicable
- whether `$goalnext` was executed
- if not executed, the concrete reason

If a skill file was created or updated as part of the task, also report its path and validation status.
