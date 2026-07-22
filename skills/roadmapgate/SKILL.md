---
name: roadmapgate
description: Internal prerequisite gate for every operational GoalNext workflow skill. Explicitly invoke $roadmapgate before the caller does other preflight or work; it accepts a substantive ROADMAP.md as confirmed filename evidence, treats ROADMAP.proposed.md as an unconfirmed draft, recommends user-owned Roadmap design, offers $createroadmap only as an approved fallback, and returns a small terminal status to the caller without invoking external planning skills.
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

A confirmed candidate must have the exact basename `ROADMAP.md`. An explicit path with another basename is not confirmation evidence. Use only readable project files and never scan outside the selected workspace.

When no confirmed candidate exists, check the matching `ROADMAP.proposed.md` path and then `<workspace-root>/ROADMAP.proposed.md` so the user can continue an existing draft. Do not treat a chat assertion, README link, unchecked TODO item, Goal Guide, issue list, task plan, or arbitrary filename as confirmation evidence.

If the explicit and root candidates identify different `ROADMAP.md` files, or a path leaves the workspace, return `BLOCKED` and identify the ambiguity. A proposal beside an already confirmed `ROADMAP.md` does not invalidate the current confirmed Roadmap; it remains inactive until explicitly promoted.

## Verify Confirmation

Read the complete candidate. The exact filename is necessary but not sufficient: `ROADMAP.md` must contain substantive phase outcomes or equivalent long-term sequencing and must be related to the active workspace. An empty, malformed, or clearly unrelated file returns `BLOCKED`.

Classify evidence as:

- `confirmed`: one canonical, substantive `ROADMAP.md` exists.
- `unconfirmed`: no confirmed file exists, but one substantive `ROADMAP.proposed.md` exists.
- `none`: neither filename exists.
- `ambiguous`: confirmed candidates conflict or the selected path is unsafe.

Return `READY` immediately for `confirmed`, including the canonical path and evidence classification. Return `BLOCKED` for `ambiguous` or malformed evidence.

## Offer The Bootstrap

For `none` or `unconfirmed`, stop the requested skill before its role checks, routing, edits, messages, planning, or execution. Ask exactly one permission question:

```text
Roadmap prerequisite
requested_skill: <requested_skill>
evidence: none | unconfirmed
candidate: <path or none>
preferred_path: Design, review, and confirm the canonical Roadmap yourself.
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
roadmap_path: <confirmed ROADMAP.md, proposed draft path, or none>
return_to_skill: <name>
reason: <short reason when not READY>
```

Only `READY` authorizes the caller to continue. `ROADMAP_REQUIRED` and `BLOCKED` are terminal for the requested skill.
