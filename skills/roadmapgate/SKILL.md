---
name: roadmapgate
description: Internal prerequisite gate for every operational GoalNext workflow skill. Explicitly invoke $roadmapgate before the caller does other preflight or work; it locates canonical Roadmap evidence, requires the exact confirmed marker, recommends user-owned Roadmap design or $grill-me for AI assistance, offers $createroadmap only as an approved fallback, and returns a small terminal status to the caller.
---

# RoadmapGate

RoadmapGate is the single source of truth for the confirmed-Roadmap prerequisite. Keep callers thin: they pass a request, wait for this skill, and continue only after `READY`.

## Request Contract

The caller supplies:

```text
requested_skill: <lowercase bundled skill name>
workspace: <workspace root or current working directory>
roadmap_path: <optional explicit canonical Roadmap path>
return_to_skill: <skill to resume after confirmation; normally requested_skill>
caller: <calling skill or user>
roadmap_bootstrap: false
```

Treat `requested_skill`, `workspace`, and `return_to_skill` as required. Resolve the workspace to its Git root when one exists; otherwise use the selected workspace root.

## Bootstrap Exceptions

The prerequisite cannot gate the mechanism that creates the prerequisite. Return `READY` with `evidence: bootstrap-exception` only for these cases:

1. `requested_skill: createroadmap`.
2. `requested_skill: askme` or `requested_skill: listtodecide` when all of these are true:
   - `caller: createroadmap`
   - `roadmap_bootstrap: true`
   - the work is limited to producing or confirming the canonical Roadmap

Never infer a bootstrap exception from intent alone. Never let another caller set `roadmap_bootstrap: true` to bypass the gate. RoadmapGate itself performs only this check and needs no recursive self-check.

## Find Canonical Evidence

Check candidates in this order:

1. A caller-supplied `roadmap_path`, resolved inside the selected workspace.
2. `<workspace-root>/ROADMAP.md`.
3. One explicit canonical Roadmap link in a root README, TODO, or handoff document.

Use only readable project files. Do not scan outside the selected workspace. Do not accept a filename, chat assertion, unchecked TODO item, Goal Guide, issue list, or task plan as confirmation evidence.

If an earlier source identifies a candidate, do not silently switch to a later one. If a canonical link is malformed, leaves the workspace, or resolves to more than one candidate, return `BLOCKED` and identify the ambiguity.

## Verify Confirmation

Read the complete candidate and require this exact standalone marker near its top:

```text
<!-- codex-roadmap: confirmed -->
```

The file must also contain substantive phase outcomes or equivalent long-term sequencing. The marker is necessary but not sufficient when the file is empty, malformed, or clearly unrelated to the active workspace.

Classify evidence as:

- `confirmed`: one canonical, substantive Roadmap contains the marker.
- `unconfirmed`: one canonical Roadmap exists but lacks the marker.
- `none`: no canonical candidate exists.
- `ambiguous`: candidates or links conflict.

Return `READY` immediately for `confirmed`, including the canonical path and evidence classification. Return `BLOCKED` for `ambiguous` or malformed evidence.

## Offer The Bootstrap

For `none` or `unconfirmed`, stop the requested skill before its role checks, routing, edits, messages, planning, or execution. Ask exactly one permission question:

```text
Roadmap prerequisite
requested_skill: <requested_skill>
evidence: none | unconfirmed
candidate: <path or none>
preferred_path: Design, review, and confirm the canonical Roadmap yourself.
ai_assistance: Use $grill-me when installed, then review and confirm the resulting Roadmap yourself.
fallback: $createroadmap can create or reconcile a proposed Roadmap, but it is not the recommended path.

Should I invoke $createroadmap now as the fallback and return to $<return_to_skill> after confirmation?
```

Wait for the user's answer.

- If the answer is yes, explicitly and visibly invoke `$createroadmap` with `mode: create` for `none` or `mode: reconcile` for `unconfirmed`, plus the workspace, candidate path, and `return_to_skill`.
- If CreateRoadmap returns `CONFIRMED`, re-run this gate. Resume the original caller only after the second check returns `READY`.
- If CreateRoadmap returns another status, pass it through and keep the original caller stopped.
- If the user declines, return `ROADMAP_REQUIRED`. Do not ask repeatedly during the same invocation.

Do not create, edit, or confirm a Roadmap inside RoadmapGate. Do not invoke CreateRoadmap without permission.

## Terminal Contract

Return exactly one status:

```text
roadmap_gate: READY | ROADMAP_REQUIRED | BLOCKED
requested_skill: <name>
evidence: confirmed | unconfirmed | none | ambiguous | bootstrap-exception
roadmap_path: <canonical path or none>
return_to_skill: <name>
reason: <short reason when not READY>
```

Only `READY` authorizes the caller to continue. `ROADMAP_REQUIRED` and `BLOCKED` are terminal for the requested skill.
