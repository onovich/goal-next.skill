---
name: createroadmap
description: Fallback support for creating, reconciling, refreshing, replanning, or confirming the canonical project Roadmap required by GoalNext workflows. Use only when the user explicitly chooses this bundled fallback after being encouraged to design and confirm the Roadmap themselves, or to use $grill-me when they want AI-assisted roadmapping. Consume user-owned documents and decisions, require explicit confirmation, and return to $roadmapgate without creating roles, threads, or implementation work.
---

# CreateRoadmap

CreateRoadmap is the bundled fallback for turning project evidence and user intent into a durable, explicitly confirmed phase map. The preferred path is a user-designed Roadmap; when the user wants AI assistance, recommend `$grill-me`. Use this skill only after the user explicitly selects the fallback, including through RoadmapGate. It is a bootstrap exception to the Roadmap prerequisite; do not invoke `$roadmapgate` before it.

Do not present CreateRoadmap as the project's recommended onboarding path. A direct `$createroadmap` invocation or an affirmative answer to RoadmapGate counts as choosing the fallback; state the boundary briefly and proceed without adding another approval loop.

## Modes And Request

Support these modes:

- `create`: no canonical Roadmap exists.
- `reconcile`: a draft exists but is unconfirmed or conflicts with current evidence.
- `refresh`: update evidence or status without changing the accepted direction materially.
- `replan`: materially change outcomes, dependencies, boundaries, or sequencing.
- `confirm`: validate and ask for confirmation of an already proposed draft.
- `prerequisite`: shorthand used by RoadmapGate; resolve to `create` or `reconcile` from evidence.

Accept:

```text
mode: <mode; default create or reconcile from evidence>
workspace: <workspace root or current working directory>
roadmap_path: <optional canonical path; default ROADMAP.md>
return_to_skill: <optional skill that RoadmapGate paused>
project_description: <optional free-form positioning, goals, and constraints>
source_documents:
- <optional design document path>
```

Resolve all paths inside the selected workspace. Prefer the Git root and a root `ROADMAP.md`. If multiple plausible canonical files exist and no explicit path settles them, return `BLOCKED` rather than creating a competing Roadmap.

## Source Priority

Build the fallback Roadmap from the highest available source in this order:

1. Existing user-owned Roadmap material, design documents, product specifications, architecture decisions, handoffs, and accepted history.
2. The user's free-form project positioning, goals, success conditions, constraints, and any conclusions they already approved through `$grill-me`.
3. When the available evidence is too thin and the user wants AI assistance, recommend `$grill-me` as the preferred interview. Ask before invoking it and treat its output as proposed input that the user must still review.
4. The bundled `$askme` interview only as the final fallback for specific high-impact ambiguities when grill-me is unavailable, declined, or insufficient and the user still wants CreateRoadmap to continue.

Read supplied design documents before asking questions. Treat accepted project evidence as binding unless the user explicitly supersedes it. When documents and the user's latest description conflict, show the conflict and ask which should govern; never choose silently.

If neither usable documents nor a project description exists, make the first question an open intake request that lets the user paste one description covering project positioning, desired outcome, constraints, and any design-document paths. This is a control question, not an AskMe decision-budget question.

When evidence is insufficient and `$grill-me` is available, explain that it is the recommended AI-assisted roadmapping interview and ask whether to invoke it. Do not invoke it silently. If it is unavailable, declined, or still leaves a bounded ambiguity, create the proposed Roadmap draft first, then explicitly invoke `$askme` with:

```text
caller: createroadmap
roadmap_bootstrap: true
topic: roadmap
target_document: <canonical proposed Roadmap path>
objective: resolve only decisions that block confirmation
question_budget: 5
```

Use `$listtodecide` with the same `caller` and `roadmap_bootstrap` fields only when several high-impact choices need one decision menu. These are the only permitted pre-confirmation exceptions to their normal Roadmap gate.

## Draft The Roadmap

Create or update the caller-selected canonical file. A proposed Roadmap must not contain the confirmed marker. For `replan`, remove the marker in the same patch that introduces the first material proposal; preserve it during a purely evidentiary `refresh` only when phase meaning and ordering remain unchanged.

Use this default structure, adapting headings only when the project already has a compatible format:

```markdown
# Roadmap

Status: proposed

## Destination

## Baseline And Evidence

## Constraints And Non-scope

## Phase Map

## <Phase>
- Status: proposed | ready | active | accepted | blocked | deferred | dropped
- Outcome:
- Depends on:
- Non-scope:
- Exit criteria:
- Decision gates:
- Required capabilities:

## Deferred Or Dropped

## Next Ready Phase
```

Roadmap phases describe verifiable outcomes, dependencies, non-scope, exit criteria, decision gates, and required role capabilities. They are not tickets, implementation rounds, chat plans, or Goal Guides.

When updating an existing Roadmap:

- Preserve accepted phases, decisions, and evidence as history.
- Never rewrite an accepted result into a different outcome without explicitly recording the superseding decision.
- Prefer a minimal reconciliation over replacing the entire document.
- Keep deferred and dropped work visible with a reason.
- Do not invent dates, budgets, owners, or technical facts.

## Validate Before Confirmation

Before asking for confirmation, verify:

- the destination and non-scope are explicit;
- every phase has a verifiable outcome and exit criteria;
- dependencies have no cycle and reference real phases;
- at least one next phase is `ready`, or the Roadmap identifies the exact blocking decision;
- accepted work remains traceable;
- the document is a phase map rather than a disguised task list;
- sensitive paths, identifiers, credentials, and private conversation content are absent.

If validation fails, keep status `PROPOSED` or return `BLOCKED`; never add confirmation evidence to an invalid draft.

## Confirm Explicitly

Show the proposed phase map or a concise material-change summary. Ask one explicit question:

```text
Do you confirm this Roadmap as the current prerequisite for the workflow?
```

Only an unambiguous yes to this exact confirmation step authorizes adding this standalone marker near the top of the canonical file:

```text
<!-- codex-roadmap: confirmed -->
```

Also set the human-readable status to `confirmed` when the format has one. A prior request to create, edit, or use a Roadmap is not confirmation. Silence, partial approval, approval of one phase, or acceptance of an interview answer is not confirmation.

After writing the marker, re-read the complete file and verify it occurs exactly once.

## Handoff And Terminal Contract

Return exactly one status:

```text
createroadmap: CONFIRMED | PROPOSED | BLOCKED | CANCELLED
roadmap_path: <canonical path or none>
confirmation_evidence: exact-marker | none
next_ready_phase: <phase or none>
return_to_skill: <name or none>
reason: <short reason when not CONFIRMED>
```

For a RoadmapGate bootstrap, `CONFIRMED` returns control to the named skill so it can re-run `$roadmapgate`; it does not execute that skill itself. For direct use, visibly offer `$goalnext` when a suitable role route already exists, or CreateRole once that skill is implemented. Do not create threads, assign roles, write implementation code, dispatch execution, or start the next workflow invisibly.
