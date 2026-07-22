---
name: nameyou
description: Record the current Codex thread's role and thread id in a workspace Role.md file while preserving an approved CreateRole graph. Use when the user asks to name this session, record this agent/thread's role, update Role.md, create Role.md if missing, verify a newly created Role Thread, or maintain thread-role routing for planner, execution, business, art, operations, or cooperation roles.
---

# NameYou

## Purpose

Maintain a workspace-local `Role.md` that maps Codex thread ids to concise role responsibilities. Use it to record who this thread is and preserve an approved Role Graph, not to store conversation content or project decisions.

## Mandatory Roadmap Gate

Before locating `Role.md`, resolving a thread id, asking about a role, or editing any file, explicitly invoke `$roadmapgate` with:

```text
requested_skill: nameyou
workspace: <active workspace>
return_to_skill: nameyou
caller: nameyou
roadmap_bootstrap: false
```

Continue only when it returns `roadmap_gate: READY`. If it returns `ROADMAP_REQUIRED` or `BLOCKED`, stop NameYou and preserve the gate's CreateRoadmap question or blocked reason. A `Role.md`, thread route, task plan, or chat assertion is not substitute Roadmap evidence.

## Workflow

1. Find the target workspace root.
   - Prefer the current working directory's git root when available.
   - Otherwise use the current working directory or the workspace root the user named.
   - If multiple workspace roots are active and the user did not specify one, choose the current turn cwd.

2. Protect local route state from Git history.
   - In a Git workspace, check whether root `Role.md` and `Role.proposed.md` are tracked or ignored before writing a real thread id.
   - Prefer the repository-local exclude file for machine-local route files. Do not stage or commit either route file.
   - If `Role.md` is already tracked, stop before writing a real thread id and ask the user how to untrack or relocate it. Never remove a tracked file from the index without explicit approval.

3. Find `Role.md`.
   - Search only the selected workspace root first.
   - Prefer `<workspace-root>/Role.md`.
   - If multiple `Role.md` files exist under the selected root, use the root-level file when present; otherwise ask before editing.
   - If no `Role.md` exists, create `<workspace-root>/Role.md`.

4. Identify the current thread id.
   - Prefer Codex thread tools when available: list recent threads for the current workspace, then pick the thread whose `cwd`, title, preview, and recent update match the current conversation.
   - If several threads are plausible, read candidates or ask the user for the thread id.
   - Never invent a thread id.
   - If the user supplies a thread id explicitly, use it after a basic UUID-shaped sanity check.

5. Identify the role.
   - Use the role the user provided, or the current thread title when it is clearly the intended role.
   - Store a stable ASCII role key in `role`; store the human-facing label in `title`.
   - If the role label is ambiguous, ask once before writing. Homophones or typos in Chinese should be resolved from nearby context or current thread title only when obvious.

6. Edit with a minimal patch.
   - Use `apply_patch` for manual file edits.
   - Preserve existing role entries, approved graph metadata, extended role fields, and the existing `idempotency` block.
   - Update top-level `updated_at`.
   - Set `created_at` only when creating the file.
   - Add or replace only the target role section.
   - When CreateRole invokes NameYou after an approved graph, treat that exact approval as authorization for the listed graph fields. Do not reinterpret or broaden them.

7. Verify.
   - Read the final `Role.md` and confirm the role key, `thread_id`, `title`, timestamp, and any approved graph fields that were supposed to be preserved.

## Standard Format

Use this root-level format:

```yaml
# Role Route

workspace: <absolute-workspace-path>
created_at: <iso-local-time>
updated_at: <iso-local-time>
graph_revision: 1
central_role: planner
default_executor: executor

planner:
  role: architect
  workflow_role: planner-checker
  thread_id: <planner-thread-id>
  title: 架构师
  responsibility: Own phase goals, dispatch, and acceptance.
  upstream: []
  downstream: [executor]
  handoff: Goal Guide out; acceptance result retained.
  environment: local
  creation_checkout: <absolute-workspace-path>
  selection_mode: existing-thread
  model: unchanged
  reasoning_effort: unchanged
  round_budget: planning-only
  goal_token_budget: not-set
  status: ready
  evidence: current active planning thread in the same workspace.

executor:
  role: executor
  workflow_role: executor
  thread_id: <executor-thread-id>
  title: 执行者
  responsibility: Execute one approved Goal Guide at a time.
  upstream: [planner]
  downstream: [planner]
  handoff: Return validation, commit, push, and completion evidence.
  environment: local
  creation_checkout: <absolute-workspace-path>
  selection_mode: configured-default
  model: omit
  reasoning_effort: omit
  round_budget: inherit-from-goal-guide
  goal_token_budget: not-set
  status: ready
  evidence: visible thread created for the approved executor route.

idempotency:
  active_goal_guide: docs/example-goal-mode-execution-guide.md
  active_goal_phase: Example Phase
  last_check_status: pass
```

The file is Markdown containing a YAML-like routing block. Do not add fenced code blocks around the real content.

## Allowed Information

Top-level fields:

- `workspace`: absolute workspace path.
- `created_at`: ISO 8601 local timestamp, only set on file creation.
- `updated_at`: ISO 8601 local timestamp for the most recent Role.md route update.
- optional `graph_revision`: positive revision of the approved Role Graph.
- optional `central_role`: role key that owns planning and validation.
- optional `default_executor`: execution role key used only when a phase does not name `target_role`; use `none` when no safe default exists.
- role sections keyed by short stable names such as `planner`, `executor`, `business`, `artist`, `reviewer`, `qa`, or another user-approved role key.
- optional `idempotency` section when already used by the project workflow.

Role section fields:

- `role`: stable ASCII role identifier, for example `business`, `executor`, `architect`, `artist`.
- optional `workflow_role`: `planner-checker`, `executor`, `support`, or `coordinator`.
- `thread_id`: Codex thread id.
- `title`: human-facing role title, such as `商务`, `执行者`, `架构师`, `美术`.
- optional `responsibility`: one concise approved ownership boundary.
- optional `upstream`: approved role keys that may dispatch to this role.
- optional `downstream`: approved role keys this role may dispatch to.
- optional `handoff`: one concise artifact or evidence contract.
- optional `environment`: approved `local` or `worktree` boundary.
- optional `creation_checkout`: actual saved-project checkout or created worktree path used by the visible thread; it must not be confused with a different central workspace.
- optional `selection_mode`: `existing-thread`, `configured-default`, or `explicit-override`.
- optional `model`: `unchanged`, `omit`, or the exact user-approved model id.
- optional `reasoning_effort`: `unchanged`, `omit`, or the exact user-approved supported effort.
- optional `round_budget`: an instructional round boundary or `inherit-from-goal-guide`.
- optional `goal_token_budget`: `not-set` or a positive value explicitly approved by the user; it is not an account quota claim.
- optional `status`: `initializing`, `ready`, `blocked`, or another state defined by an approved CreateRole recovery ledger.
- `evidence`: one short sentence explaining why this thread id maps to this role.

Allowed `idempotency` fields, when present:

- `active_goal_guide`
- `active_goal_phase`
- `active_goal_target_role`
- `last_planner_dispatch`
- `last_planner_dispatch_status`
- `last_planner_dispatch_guide`
- `last_planner_dispatch_commit`
- `last_planner_dispatch_target_role`
- `last_executor_report_commit`
- `last_executor_report_status`
- `last_executor_report_at`
- `last_executor_report_guide`
- `last_executor_report_role`
- `last_check_status`
- `last_repair_request`
- `last_goalnext_trigger`

Do not add other fields unless the user explicitly approves a Role.md schema change. Approval of an exact CreateRole graph authorizes only the graph fields listed above for that revision.

## Prohibited Information

Do not write any of the following into `Role.md`:

- Full conversation text, prompts, hidden instructions, or summaries of private user discussion.
- Secrets, tokens, credentials, local auth state, or API keys.
- Project strategy, negotiation details, implementation decisions, or technical reports.
- Full command outputs, diffs, logs, tool traces, or file contents.
- Personal information beyond the role title needed for routing.
- Generated guesses about thread ids, responsibilities, or current work status.
- Thread Profile availability catalogs, plan tier, quota, or account identifiers.

If existing `Role.md` content violates these rules, do not silently delete it while recording a role. Tell the user and ask whether to clean it up, unless the user explicitly requested schema cleanup.

## Creation Template

When creating a missing `Role.md`, start with only the known role entry:

```yaml
# Role Route

workspace: <absolute workspace root>
created_at: <iso-local-time>
updated_at: <iso-local-time>

<role_key>:
  role: <stable-ascii-role>
  thread_id: <codex-thread-id>
  title: <human-facing-title>
  evidence: current active <role-title> thread in the same workspace.
```

Add `idempotency` only when the project already has an active goal-dispatch workflow that needs it.

When a confirmed CreateRole graph exists, preserve its optional top-level and role fields instead of shrinking the file to this minimal manual template. `Role.md` is local routing state and must not be committed with real thread ids.
