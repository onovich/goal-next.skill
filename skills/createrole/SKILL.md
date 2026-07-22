---
name: createrole
description: Design an explicit Role Graph for a confirmed-Roadmap project, obtain approval for the exact visible Codex threads and any model, effort, environment, or budget choices, create those threads sequentially, and register their roles and upstream/downstream routes in Role.md. Use when a user wants the recommended GoalNext workflow entry, asks a central or HR-style thread to create and assign role threads, or needs to resume a partially created role topology without hidden subagents or duplicate fan-out.
---

# CreateRole

CreateRole is the recommended initialization entry for a new GoalNext workflow. It turns a confirmed project Roadmap into a small, user-visible set of Codex Role Threads, records the routing contract, and stops with the central thread ready to invoke `$goalnext`.

Create visible Codex tasks only. Never substitute collaboration subagents, implicit agents, background fan-out, or projectless tasks for the approved Role Graph.

## Mandatory Roadmap Gate

Before reading project documents, inspecting threads, drafting a role, invoking another support skill, editing `Role.proposed.md` or `Role.md`, or creating a thread, explicitly invoke `$roadmapgate` with:

```text
requested_skill: createrole
workspace: <active workspace>
return_to_skill: createrole
caller: createrole
roadmap_bootstrap: false
```

Continue only when it returns `roadmap_gate: READY`. If it returns `ROADMAP_REQUIRED` or `BLOCKED`, stop CreateRole and preserve the gate's CreateRoadmap question or blocked reason. A chat plan, role list, `Role.proposed.md`, or existing thread is not substitute Roadmap evidence.

## Authorization Boundary

An explicit `$createrole` invocation authorizes discovery and proposal work only. It does not yet authorize thread creation.

Create threads only after the user approves one exact Role Graph revision through the approval question in this skill. That approval authorizes only:

- the listed number of new visible threads;
- the listed local or worktree target for each thread;
- the listed explicit model and reasoning-effort overrides;
- the listed optional goal token budgets; and
- registration and initialization messages for those exact roles.

Any material change to the graph revision, thread count, role responsibility, target environment, model/effort override, goal token budget, or upstream/downstream route invalidates the approval and requires a new one. Reusing a current or existing thread is not thread creation, but replacing its recorded role still requires explicit approval.

## Input And Defaults

Accept a request in this shape, deriving omitted facts from the confirmed Roadmap and current workspace:

```text
workspace: <active workspace>
objective: <optional role-topology objective>
current_thread_role: planner-checker | coordinator-only | discover
requested_roles:
- <optional role or workstream>
existing_threads:
- <optional role and known thread reference>
environment_policy: local | worktree-for-isolated-executors | mixed
default_new_thread_limit: <positive integer; default 4>
question_budget: <positive integer; default 5>
```

Defaults:

- Reuse the current visible thread as the central `planner`/`checker` when its role is compatible. Create a separate coordinator or planner only when the user wants that separation.
- Start from the smallest useful topology: one central planner/checker and one executor.
- Add frontend, backend, art, business, QA, operations, or other roles only when the confirmed Roadmap contains a durable responsibility boundary or the user explicitly requests it.
- Use `local` for shared-workspace roles only when the selected workspace is the saved project's local checkout. Propose a worktree only for an execution lane that benefits from isolation, and show its exact starting-state choice before approval.
- Limit one proposal to four new threads by default. If more are justified, use `$askme` for a separate fan-out decision before the final approval; never silently raise the limit.
- Treat a round limit as an instructional work boundary. Treat `goal_token_budget` as unset unless the user explicitly requests or approves a positive value; do not infer it from plan tier, quota, or model availability.

## Discover Facts Before Asking

1. Resolve the selected workspace and read the complete canonical `ROADMAP.md` returned by RoadmapGate.
2. Read root project instructions, `CONTEXT.md` or its map, relevant ADRs, current handoff/TODO documents, and recent Git evidence needed to understand stable responsibility boundaries.
3. Locate `Role.md` and `Role.proposed.md` only in the selected workspace. Read either file completely when present.
4. Locate current thread-management capabilities. Required capabilities are project listing, visible thread creation, thread listing/reading, title updates, messaging, and bounded waiting. If visible `create_thread` capability is unavailable, return `BLOCKED`; never fall back to subagents.
5. Invoke `list_projects` before planning creation so the target project is explicit. Record both the current workspace path and the saved project path returned by the creation surface. Use thread listing and, at most, bounded candidate reads to resolve the current and existing same-workspace threads. Never invent a thread id.
6. Inspect the current working tree and branch. Preserve unrelated changes. For a proposed worktree, disclose whether the target starts from the default branch or an explicitly requested current working-tree state.
7. When the current workspace differs from the saved project path, treat the creation checkout as a high-impact unresolved decision. A `local` creation target will run in the saved checkout, not the current linked worktree. Explicitly invoke `$askme` and recommend running the long-lived central workflow from the saved local checkout; alternatively, let the user approve exact worktree targets and the central-only Role Route limitation. Never label the target merely `local` without showing the actual creation checkout.
8. Before writing real thread ids in a Git workspace, verify that root `Role.md` and `Role.proposed.md` are untracked and ignored. Prefer the repository-local exclude file for these machine-local routes. If either path is already tracked, stop and ask the user how to remove or relocate sensitive route state; never commit a real thread id.

Do not ask for facts that can be established from these sources. Surface conflicts between the Roadmap, existing Role Route, and current user request instead of silently choosing one.

## Design The Minimal Role Graph

Build roles around stable ownership, not around individual tickets. Every role must have one narrow responsibility, a bounded set of accepted inputs, an explicit return route, and at least one durable artifact or evidence contract.

Use these topology rules:

- The central planner/checker owns phase selection, Goal Guides, dispatch, and acceptance. It does not implement the dispatched phase.
- An execution role owns a coherent implementation lane and returns validation, commit, and push evidence to its upstream planner/checker.
- A support role such as operations, project status, business, or art owns only its named lane. It is not a general overflow thread.
- Use `workflow_role: executor` for every role allowed to run DoNextGoal. When several execution roles exist, select one `default_executor` only if it is a safe fallback; otherwise require GoalNext to receive an explicit `target_role` for each phase.
- Relationships are directed. `upstream` identifies who may dispatch to the role; `downstream` identifies whom the role may dispatch to. Avoid cycles other than the documented planner-executor validation loop.
- Created Role Threads may not create further role threads or implicit subagents as part of initialization. Additional roles require another explicit CreateRole approval.

Role examples are illustrative, not mandatory:

- `planner`: central planner/checker and GoalNext owner.
- `executor`: default implementation owner for a two-role topology.
- `frontend` and `backend`: separate execution lanes when interfaces and handoffs are documented.
- `artist`: visual asset or art-direction lane.
- `ops`: deterministic Git, command, environment, and project-status work suited to a lower-intensity Thread Profile.
- `coordinator`: HR-style role creation and registry owner when the current thread should not also plan phases.

## Persist The Proposal

Write the unapproved or partially executed graph to root `Role.proposed.md`. The filename is the human-readable evidence that it is not active. Do not use an embedded confirmation marker.

Use this compact shape:

```yaml
# Role Graph Proposal

workspace: <absolute-workspace-path>
graph_revision: <monotonic positive integer>
central_role: planner
default_executor: executor | none
new_thread_limit: 4
new_thread_count: 1

planner:
  disposition: reuse-current
  workflow_role: planner-checker
  title: Central Planner / Checker
  responsibility: Own phase goals, dispatch, and acceptance.
  upstream: []
  downstream: [executor]
  handoff: Goal Guide out; acceptance result retained.
  environment: local
  creation_checkout: <saved-project-path>
  selection_mode: existing-thread
  model: unchanged
  reasoning_effort: unchanged
  round_budget: planning-only
  goal_token_budget: not-set
  creation_status: reused

executor:
  disposition: create
  workflow_role: executor
  title: Implementation Executor
  responsibility: Execute one approved Goal Guide at a time.
  upstream: [planner]
  downstream: [planner]
  handoff: Validation, commit, push, and completion report returned.
  environment: local
  creation_checkout: <saved-project-path>
  selection_mode: configured-default
  model: omit
  reasoning_effort: omit
  round_budget: inherit-from-goal-guide
  goal_token_budget: not-set
  creation_status: pending
```

Keep responsibilities and handoffs to one concise line each. Do not copy Roadmap content, private conversation, implementation reports, credentials, account data, or full prompts into the proposal.

## Resolve High-Impact Ambiguity With AskMe

If role ownership, current-thread role, fan-out above the default limit, execution-lane boundaries, current-workspace versus saved-project placement, worktree use, routing, or a budget materially changes the graph, explicitly invoke `$askme` after `Role.proposed.md` exists:

```text
caller: createrole
topic: role-graph
target_document: <workspace>/Role.proposed.md
objective: Resolve every high-impact choice needed for an exact Role Graph approval.
known_facts:
- <facts established from Roadmap, Role Route, project docs, and thread tools>
source_documents:
- <workspace>/ROADMAP.md
- <other selected project documents>
required_decisions:
- <blocking role, route, environment, fan-out, or budget decision>
question_budget: <positive integer; default 5>
```

AskMe's one-question-at-a-time interview is the bundled guided-design mechanism. Do not invoke any external interview or roadmapping skill from CreateRole. Resume only after AskMe returns `RESOLVED`; any other result preserves the proposal and ends CreateRole as `PROPOSED`, `BLOCKED`, or `CANCELLED` as appropriate.

## Build A Thread Profile For Every New Thread

For each role with `disposition: create`, explicitly invoke `$choosemodel` with its responsibility, risk, context breadth, coordination burden, expected artifacts, environment, and return target `createrole`.

Consume the result exactly:

- `DEFAULT_READY`: record `selection_mode: configured-default`, `model: omit`, and `reasoning_effort: omit`. The later `create_thread` call must omit both fields.
- `OVERRIDE_PROPOSED`: record the exact supported pair and rationale in the proposal, mark approval required, and include it in the final Role Graph approval question. Do not create yet.
- `CONFIRMED_PROFILE`: record the exact pair and the user's direct request or approval evidence.
- `BLOCKED`: stop before approval or creation and name the missing capability evidence.

Do not run ChooseModel for a reused thread because CreateRole cannot change an existing thread's creation profile. Record `selection_mode: existing-thread` and preserve its current configuration.

Immediately before each creation, re-read the target creation surface. If an approved pair is no longer supported, do not substitute another pair or silently fall back to the default; update the proposal and obtain new approval. Availability evidence is short-lived and is not plan or quota evidence.

## Show The Exact Approval Packet

Before asking for approval, present a concise table containing every role and these columns:

- reuse/create disposition;
- responsibility and workflow role;
- upstream and downstream role keys;
- handoff artifact/evidence;
- local or worktree environment, actual creation checkout, and starting state;
- configured default or exact model/effort override;
- round boundary and optional goal token budget;
- whether a new visible thread will be created.

Show the graph revision, exact new-thread count, default executor, any fan-out exception, and the paths `Role.proposed.md` and future `Role.md`. Then ask exactly:

```text
Do you approve this Role Graph and authorize CreateRole to create exactly <N> listed visible Codex threads, apply the listed explicit model/effort overrides and goal token budgets, and register these routes in Role.md?
```

Wait for the answer. A request to adjust the graph is not approval. An approval of revision N does not cover revision N+1. When the answer is no or deferred, create nothing and return `PROPOSED` or `CANCELLED`.

## Register The Current Role

After approval and before creating new threads:

1. Revalidate the selected workspace, project, current thread id, `Role.proposed.md` revision, and creation ledger.
2. If the current thread is a role in the approved graph, explicitly invoke `$nameyou` to register that current role in `Role.md`.
3. Extend the NameYou-compatible role section only with approved Role Graph fields: `workflow_role`, `responsibility`, `upstream`, `downstream`, `handoff`, `environment`, `creation_checkout`, `selection_mode`, `model`, `reasoning_effort`, `round_budget`, `goal_token_budget`, and `status`.
4. Preserve existing routes and idempotency fields. Never overwrite a conflicting thread id or role without a replacement decision in the approved graph.
5. Use `Role.md` as active filename evidence only after the current central/coordinator route is valid. Keep `Role.proposed.md` as the creation ledger until all new roles are active.

## Create Visible Threads Sequentially

Create only entries whose ledger still says `creation_status: pending`.

For each approved new role, in graph order:

1. Re-run same-workspace duplicate detection by role key, title, thread id, recent prompt, and existing ledger. Reuse an exact match; stop on ambiguity.
2. Invoke `create_thread` once and wait for its result before considering the next role. Use the selected project target; do not create projectless threads.
3. For `selection_mode: configured-default`, omit model and reasoning/thinking arguments. For `selection_mode: explicit-override`, pass only the exact approved and revalidated pair.
4. Use an approved `local` target only when its displayed `creation_checkout` is the saved project checkout. For an approved worktree target, pass only the approved starting state and never claim it contains uncommitted changes unless that state was explicitly selected.
5. Make the creation prompt an initialization packet only. It must state the role key, title, responsibility, upstream/downstream role keys, handoff contract, canonical Roadmap and Role Route paths, environment boundary, and approved work budget. It must instruct the new task not to edit files, create a goal, start implementation, create another task, or use subagents before route activation.
6. Record the returned real thread id in the local proposal ledger immediately. If creation returns only a queued client id, record it as queued without inventing a thread id, use bounded thread listing/waiting to resolve it, and stop as `PARTIAL` if it cannot yet be resolved safely.
7. Set the visible title to the approved role title when a real thread id is available.
8. Patch only that role into `Role.md` using the approved fields and actual thread id. Mark `status: initializing` until activation succeeds.
9. If creation, title update, registration, or identity resolution fails, stop before creating the next role. Keep all already created visible threads and the proposal ledger; never auto-delete or hide them.

Sequential creation is a safety property. Do not parallelize `create_thread` calls even when the tool permits it.

## Activate And Verify Each Role

After all approved thread ids are registered:

1. Send each created thread one activation message that explicitly invokes `$nameyou` to verify its current thread id and approved role entry, preserve all Role Graph fields, read `ROADMAP.md`, `Role.md`, and named handoff documents, and return `ROLE_READY` without starting implementation.
2. Include the planner/checker return target and the role's own key. Do not paste private conversation or the complete Roadmap into the message.
3. Use bounded `wait_threads` snapshots or thread reads to verify activation. Do not wait indefinitely and do not treat a sent message as a readiness response.
4. Mark each verified route `status: ready`. For an inaccessible canonical route from a worktree, keep the central `Role.md` authoritative, give the thread the compact route packet, and mark the limitation explicitly; never create a competing active `Role.md` silently.
5. When every approved role is ready, verify the active graph, remove `Role.proposed.md`, and leave only root `Role.md` as filename evidence of the active route.

Do not dispatch project work during activation. CreateRole initializes roles; `$goalnext` creates and dispatches the first Goal Guide.

## Idempotency And Partial Recovery

On every invocation or resume:

- Treat `Role.md`, `Role.proposed.md`, current thread listings, and actual task reads as one evidence set.
- Never create a role already mapped to a matching real thread.
- Never treat title similarity alone as identity.
- Preserve the approved graph revision and per-role `pending`, `queued`, `created`, `initializing`, `ready`, or `failed` state.
- Resume the first incomplete role only when the approved revision and all material creation inputs are unchanged.
- Reapprove any changed thread count, route, environment, explicit profile, or budget.
- Do not roll back or delete visible threads after a partial failure. Cleanup is a separate destructive action requiring a user request and exact targets.
- If a user cancels before creation, offer to keep or remove `Role.proposed.md`; do not decide silently.

## GoalNext Handoff

CreateRole is ready to hand off only when:

- the active planner/checker route has a real thread id;
- every approved created role has a real thread id and `status: ready`;
- exactly one `default_executor` exists or the Role Graph explicitly requires GoalNext to receive `target_role`;
- upstream/downstream relationships are reciprocal where intended;
- no unapproved profile or goal token budget was applied; and
- `Role.proposed.md` no longer exists.

Stop after reporting readiness. Tell the user to invoke `$goalnext` in the central planner/checker thread, or invoke it only when the user's original request explicitly included starting the first phase after role creation.

## Terminal Contract

Return exactly one status:

```text
createrole: READY | PROPOSED | PARTIAL | BLOCKED | CANCELLED
workspace: <workspace>
graph_revision: <revision or none>
role_graph: Role.md | Role.proposed.md | none
central_role: <role key or unresolved>
default_executor: <role key or none>
reused_threads:
- <role key and visible title, or none>
created_threads:
- <role key and visible title, or none>
queued_threads:
- <role key, or none>
failed_roles:
- <role key and exact failure, or none>
goalnext_ready: true | false
next:
- <invoke $goalnext, approve/revise the graph, resume the same revision, or exact unblock action>
```

Use `READY` only when the active route is verified and GoalNext can dispatch without guessing. Use `PROPOSED` while awaiting a graph decision or approval. Use `PARTIAL` after at least one approved external creation succeeded but the graph is not fully active. Use `BLOCKED` when no safe progress remains without missing capability, authority, identity, or document evidence. Use `CANCELLED` only when the user explicitly stops the workflow.
