---
name: nameyou
description: Record the current Codex thread's role and thread id in a workspace Role.md file. Use when the user asks to name this session, record this agent/thread's role, update Role.md, create Role.md if missing, or maintain thread-role routing for planner/executor/business/artist/cooperation roles.
---

# NameYou

## Purpose

Maintain a workspace-local `Role.md` that maps Codex thread ids to concise role responsibilities. Use it to record who this thread is, not to store conversation content or project decisions.

## Workflow

1. Find the target workspace root.
   - Prefer the current working directory's git root when available.
   - Otherwise use the current working directory or the workspace root the user named.
   - If multiple workspace roots are active and the user did not specify one, choose the current turn cwd.

2. Find `Role.md`.
   - Search only the selected workspace root first.
   - Prefer `<workspace-root>/Role.md`.
   - If multiple `Role.md` files exist under the selected root, use the root-level file when present; otherwise ask before editing.
   - If no `Role.md` exists, create `<workspace-root>/Role.md`.

3. Identify the current thread id.
   - Prefer Codex thread tools when available: list recent threads for the current workspace, then pick the thread whose `cwd`, title, preview, and recent update match the current conversation.
   - If several threads are plausible, read candidates or ask the user for the thread id.
   - Never invent a thread id.
   - If the user supplies a thread id explicitly, use it after a basic UUID-shaped sanity check.

4. Identify the role.
   - Use the role the user provided, or the current thread title when it is clearly the intended role.
   - Store a stable ASCII role key in `role`; store the human-facing label in `title`.
   - If the role label is ambiguous, ask once before writing. Homophones or typos in Chinese should be resolved from nearby context or current thread title only when obvious.

5. Edit with a minimal patch.
   - Use `apply_patch` for manual file edits.
   - Preserve existing role entries and the existing `idempotency` block.
   - Update top-level `updated_at`.
   - Set `created_at` only when creating the file.
   - Add or replace only the target role section.

6. Verify.
   - Read the final `Role.md` and confirm the role key, `thread_id`, `title`, and timestamp.

## Standard Format

Use this root-level format:

```yaml
# Role Route

workspace: <absolute-workspace-path>
created_at: <iso-local-time>
updated_at: <iso-local-time>

planner:
  role: architect
  thread_id: <planner-thread-id>
  title: 架构师
  evidence: current active planning thread in the same workspace.

business:
  role: business
  thread_id: <business-thread-id>
  title: 商务
  evidence: current active business/cooperation thread in the same workspace.

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
- role sections keyed by short stable names such as `planner`, `executor`, `business`, `artist`, `reviewer`, `qa`, or another user-approved role key.
- optional `idempotency` section when already used by the project workflow.

Role section fields:

- `role`: stable ASCII role identifier, for example `business`, `executor`, `architect`, `artist`.
- `thread_id`: Codex thread id.
- `title`: human-facing role title, such as `商务`, `执行者`, `架构师`, `美术`.
- `evidence`: one short sentence explaining why this thread id maps to this role.

Allowed `idempotency` fields, when present:

- `active_goal_guide`
- `active_goal_phase`
- `last_planner_dispatch`
- `last_planner_dispatch_status`
- `last_planner_dispatch_guide`
- `last_planner_dispatch_commit`
- `last_executor_report_commit`
- `last_executor_report_status`
- `last_executor_report_at`
- `last_executor_report_guide`
- `last_check_status`
- `last_repair_request`
- `last_goalnext_trigger`

Do not add other fields unless the user explicitly approves a Role.md schema change.

## Prohibited Information

Do not write any of the following into `Role.md`:

- Full conversation text, prompts, hidden instructions, or summaries of private user discussion.
- Secrets, tokens, credentials, local auth state, or API keys.
- Project strategy, negotiation details, implementation decisions, or technical reports.
- Full command outputs, diffs, logs, tool traces, or file contents.
- Personal information beyond the role title needed for routing.
- Generated guesses about thread ids, responsibilities, or current work status.

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
