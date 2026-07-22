---
name: choosemodel
description: Recommend a Codex model and reasoning effort for a task that may be assigned to a new visible thread. Use when the user, CreateRole, or another workflow planner needs to decide whether to keep the account's configured default or propose a supported model/effort override based on task complexity, ambiguity, risk, context breadth, latency, and cost sensitivity. Inspect the current runtime and account evidence instead of hardcoding model ids, distinguish supported combinations from unknown plan quota, require user confirmation before any override, and return a thread-profile contract without creating the thread.
---

# ChooseModel

Choose the smallest adequate model profile for one proposed Codex thread. Produce a decision artifact only; never create, fork, message, archive, rename, or otherwise mutate a thread.

## Mandatory Roadmap Gate

Before inspecting task documents or recommending a profile, explicitly invoke `$roadmapgate` with:

```text
requested_skill: choosemodel
workspace: <active workspace>
return_to_skill: choosemodel
caller: choosemodel
roadmap_bootstrap: false
```

Continue only when it returns `roadmap_gate: READY`. If it returns `ROADMAP_REQUIRED` or `BLOCKED`, stop ChooseModel and preserve the gate's CreateRoadmap question or blocked reason.

## Input Contract

Accept a concise request:

```text
task_summary: <what the new thread would own>
role: <optional Role name>
workspace: <active workspace>
expected_artifacts: <optional files, decisions, or reports>
constraints:
  latency: normal | prefer-fast | no-preference
  cost: normal | conserve | no-preference
  risk: low | medium | high | discover
  user_model_request: <optional explicit model id>
  user_effort_request: <optional explicit effort>
target_host: <optional host>
return_to_skill: <optional caller, normally createrole>
```

Require `task_summary` and `workspace`. Derive missing task facts from the confirmed Roadmap, a named Goal Guide, or caller-provided evidence. Do not ask the user for facts available in those documents. Ask one question only when a missing preference would materially change the recommendation.

## Discover Current Availability

Do not keep a model catalog in this skill.

1. Inspect the current thread-creation tool schema or an account/model capability tool exposed by the runtime.
2. Record the exact model ids and reasoning efforts that the target creation surface currently advertises.
3. Treat a calling-host list as provisional for a different destination host; the caller must revalidate the pair on that host immediately before creation.
4. Read plan tier, quota, rate limit, or remaining allowance only from explicit account metadata available in the current session. Never infer them from model names, latency, prior failures, or the mere presence of a model in a tool schema.
5. If no entitlement or quota source exists, report `plan_tier: unknown` and `quota: unknown`. Do not browse the web for account-specific availability and do not inspect credentials or auth state.
6. If no reliable model/effort matrix is discoverable, prefer the configured default and return `BLOCKED` for any requested override.

A runtime-advertised pair is evidence that the creation surface accepts that combination on the named host. It is not evidence of subscription tier, remaining quota, or future availability.

## Classify The Task

Evaluate the proposed thread on these axes:

- **Determinism**: mechanical commands and known procedures versus open-ended design.
- **Breadth**: one narrow artifact versus cross-module or cross-role context.
- **Ambiguity**: settled acceptance criteria versus discovery and competing interpretations.
- **Risk**: local/reversible work versus destructive, security, release, migration, or public-contract impact.
- **Coordination**: isolated execution versus planning, routing, review, or synthesis across roles.
- **Verification burden**: one direct check versus several independent evidence lanes.
- **Latency and cost preference**: explicit user preference only; do not invent pricing.

Classify the task into one profile:

| Profile | Typical task | Effort target |
| --- | --- | --- |
| mechanical | status checks, simple Git/ops, known one-file edits, deterministic formatting | low, or the lowest supported adequate value |
| routine | bounded implementation or review with clear criteria and ordinary repository context | medium |
| complex | multi-file implementation, difficult diagnosis, substantial integration, or several verification lanes | high |
| strategic | architecture, ambiguous planning, high-impact review, migration, security-sensitive reasoning, or cross-role synthesis | xhigh when supported |
| exceptional | unusually broad, adversarial, or high-risk work where an additional reasoning pass has a concrete benefit | max/ultra only when supported and explicitly justified |

Do not choose exceptional effort merely because it exists. Do not use a weak profile for a high-risk task just to optimize speed.

## Select A Supported Pair

Use runtime descriptions and capabilities, not model-name folklore:

1. For `mechanical`, prefer an advertised fast or cost-efficient model with the target effort.
2. For `routine`, prefer an advertised balanced/everyday model.
3. For `complex` or `strategic`, prefer an advertised frontier/strongest-capable model.
4. For `exceptional`, use the strongest suitable advertised model only when the task-specific justification explains what the extra effort protects or resolves.
5. Verify the exact model supports the exact effort. If it does not, prefer another adequate model that supports the required effort; otherwise propose the nearest safer supported pair and disclose the compromise.
6. Honor an explicit user model or effort request when the pair is supported. If unsupported, do not silently substitute; show the closest supported alternative and ask.

The thread-creation API may require callers to omit model and effort unless the user explicitly requests an override. Therefore:

- When the configured default is adequate, recommend `selection_mode: configured-default` and tell the caller to omit both arguments.
- When an override would materially help, return `OVERRIDE_PROPOSED`, show the exact pair and rationale, and wait for the user to approve it.
- Only a direct user request for that pair, or an unambiguous approval of the proposal, permits `CONFIRMED_PROFILE`.
- A recommendation alone is not authorization to pass model or effort fields.

## Compare Alternatives

Provide at most one alternative. Explain only the material tradeoff, such as faster/cheaper versus more robust reasoning. Never invent benchmark scores, token prices, quota consumption, or quality percentages.

If two profiles are effectively equivalent and no user preference breaks the tie, use the configured default. Avoid false precision.

## Revalidate Before Creation

The returned profile is short-lived capability evidence. The thread creator must re-read the target host's currently advertised combinations immediately before creating the thread.

- If the pair remains supported and already has user approval, it may be passed explicitly.
- If availability changed, return to ChooseModel or omit the override with the user's approval.
- If the target host validates combinations only at creation time, label the proposal provisional and never retry with a different pair silently.

ChooseModel does not call the thread-creation tool. The caller owns creation, idempotency, visible confirmation, and failure recovery.

## Terminal Contract

Return exactly one status:

```text
choosemodel: DEFAULT_READY | OVERRIDE_PROPOSED | CONFIRMED_PROFILE | BLOCKED
task_profile: mechanical | routine | complex | strategic | exceptional
availability_source: <runtime tool/account evidence or none>
availability_scope: <calling host, target host, or provisional>
plan_tier: <explicit value or unknown>
quota: <explicit value or unknown>
selection_mode: configured-default | explicit-override
model: omit | <exact advertised id>
reasoning_effort: omit | <exact supported value>
rationale: <task-specific reason>
alternative: <one supported pair or none>
approval_required: true | false
return_to_skill: <caller or none>
```

For `DEFAULT_READY`, set both arguments to `omit`. For `OVERRIDE_PROPOSED`, set `approval_required: true` and stop. For `CONFIRMED_PROFILE`, cite the user's explicit request or approval. For `BLOCKED`, name the missing capability evidence or unsupported constraint. Never include account ids, credentials, auth state, or private usage data in the durable output.
