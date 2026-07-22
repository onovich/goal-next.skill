---
name: askme
description: Internal guided-decision interview for resolving high-impact ambiguities in a caller-owned design draft. Use only when another workflow skill explicitly invokes $askme with an interview brief, or when the user explicitly invokes it for recovery or debugging. Ask one recommended question at a time, write confirmed decisions into the caller's draft, maintain project terminology and qualifying ADRs, enforce a bounded question budget, and return control without executing the design.
---

# AskMe

Use AskMe as a self-contained internal interview engine for workflow skills such as CreateRoadmap and CreateRole. Resolve only the decisions that block the caller's target document, persist confirmed outcomes as the interview proceeds, and return control to the caller.

## Mandatory Roadmap Gate

Before reading the interview brief or target draft, explicitly invoke `$roadmapgate` with:

```text
requested_skill: askme
workspace: <active workspace>
return_to_skill: askme
caller: <actual caller>
roadmap_bootstrap: false
```

Continue only when it returns `roadmap_gate: READY`. If it returns `ROADMAP_REQUIRED` or `BLOCKED`, stop AskMe and preserve the gate's CreateRoadmap question or blocked reason.

Skip this call only when CreateRoadmap explicitly supplies both `caller: createroadmap` and `roadmap_bootstrap: true`, and the interview is limited to decisions blocking production or confirmation of the canonical Roadmap. Do not infer the exception and do not honor the flag from another caller.

## Boundaries

- Start only after an explicit `$askme` invocation from another skill or the user.
- Do not invoke any external interview, roadmapping, or domain-modeling skill. AskMe is self-contained.
- Do not create threads, subagents, tasks, goals, tickets, or external messages.
- Do not implement the design, finalize the caller's artifact, or continue the caller's workflow.
- Do not create a separate interview log. The caller-owned target draft is the durable record.
- Do not write conversation transcripts, credentials, private discussion, or guessed identifiers into project documents.
- Return control only through one of the terminal states defined below.

## Interview Brief

Require the caller to supply this brief:

```text
caller: <calling skill or manual recovery>
topic: <design area being clarified>
target_document: <existing caller-owned draft path>
objective: <what must be clear when the interview ends>
known_facts:
- <verified fact or established consensus>
source_documents:
- <path or reference already selected by the caller>
required_decisions:
- <known blocking decision, when any>
question_budget: <positive integer; default 5>
```

Treat `caller`, `topic`, `target_document`, and `objective` as required. If a manual invocation omits them, ask one control question for the missing brief. Control questions do not consume the decision budget.

The target document must exist before decision questions begin. If it is missing or ambiguous, return `BLOCKED`; the caller owns creating and choosing the draft.

## Preflight

1. Read the target document and every relevant source document named by the caller.
2. Read the applicable root `CONTEXT.md`, or use `CONTEXT-MAP.md` to locate the relevant context when the repository has several.
3. Read relevant ADRs and repository instructions.
4. Inspect the codebase, Git history, or project files for facts that can be discovered locally.
5. Compare the brief with the evidence. Treat documented consensus as binding unless the user explicitly supersedes it.
6. Surface conflicts between current user intent and existing documents; never choose silently which source is newer.

Do not ask the user for discoverable facts. Do not perform open-ended archaeology after enough evidence exists to frame the blocking decisions.

## Intake Question

If the brief still lacks a usable project position, goal, or constraint statement, ask the user to provide a free-form paragraph and any relevant design-document paths. This is an intake question, not a decision question, and does not consume the budget.

Skip this question when the supplied documents and brief already establish the objective.

## Select Decisions

Build a private decision queue in dependency order. Ask only about unresolved choices that materially affect one or more of:

- product or project direction
- scope or phase order
- architecture or ownership boundaries
- data, security, privacy, or compatibility contracts
- role topology, routing, model strength, or budget
- irreversible workflow or external commitments
- acceptance criteria whose interpretation would change the outcome

For local, reversible, low-impact choices:

- follow established project consensus first;
- otherwise choose the most conservative option;
- record the choice as an explicit assumption in the target draft;
- do not spend a question on it.

Do not ask about speculative future branches that do not block the target document. Stop as soon as the objective is clear and no high-impact blocker remains.

## Ask One Decision At A Time

Use this shape:

```text
Decision <used>/<budget>: <short title>

Why this matters now:
<one concise explanation>

Options:
- A — <meaning, trade-off, and risk>
- B — <meaning, trade-off, and risk>

Recommendation:
<recommended option and concrete reason>

If deferred:
<what remains blocked or which state is preserved>

Question:
<one question only; the user may select an option or answer in free form>
```

Rules:

- Ask exactly one decision question per turn and wait for the answer.
- Provide two or three realistic options when options help; always accept a free-form answer.
- Never answer the user's side of a high-impact decision.
- If the user explicitly delegates a decision, choose the recommendation and record that delegation.
- A clarification about the same decision does not consume another budget unit.
- When an answer exposes a prerequisite decision, resolve the prerequisite before continuing the original branch.

## Persist Confirmed Outcomes

After each decision is explicit:

1. Apply a minimal update to the caller-owned target draft.
2. Preserve accepted history, unrelated content, and the caller's document structure.
3. Record low-impact agent choices as assumptions, not as user decisions.
4. Keep the overall artifact in its caller-owned draft or proposed state; AskMe does not approve it.

Update project terminology only when a project-specific term is genuinely resolved:

- Prefer the repository's existing `CONTEXT.md` structure.
- Define the canonical term in one or two sentences.
- List misleading synonyms under `_Avoid_` when useful.
- Keep implementation details out of the glossary.
- Do not create a glossary entry for general programming vocabulary.

Create a minimal ADR only when the confirmed decision is simultaneously:

1. costly to reverse;
2. surprising without its context; and
3. the result of a real trade-off.

Follow the repository's ADR convention. If none exists, use the next sequential file under `docs/adr/` and capture the context, decision, and reason in one to three sentences. If any criterion is missing, keep the decision in the target draft and skip the ADR.

## Enforce The Question Budget

- Default `question_budget` to 5 when the caller omits it.
- Count each distinct high-impact decision when its first question is asked.
- Do not count the intake question, control questions, clarifications of the same decision, or the extension gate.
- End early when all required decisions are resolved.

Before asking a decision beyond the current budget:

1. Summarize the confirmed decisions and remaining blockers.
2. Recommend the smallest useful extension, capped at five additional decision questions per extension.
3. Ask one uncounted extension question and wait.
4. If approved, increase the budget and continue.
5. If declined, return `NEEDS_MORE`.

Never extend the budget silently.

## Terminal States

Return exactly one status:

- `RESOLVED`: the objective, required boundaries, dependencies, and acceptance meaning are clear, with no high-impact blocker left.
- `NEEDS_MORE`: unresolved high-impact decisions remain and the user declined or deferred a budget extension.
- `BLOCKED`: progress requires missing external facts, authority, source documents, or an unambiguous target document.
- `CANCELLED`: the user explicitly stopped or discarded the interview.

Only `RESOLVED` authorizes the caller to resume its workflow. Other states preserve confirmed draft updates but prohibit the caller from treating the design as approved.

Use this handoff shape:

```text
AskMe result

status: RESOLVED | NEEDS_MORE | BLOCKED | CANCELLED
caller: <caller>
target: <target document>
questions_used: <n>
question_budget: <n>
decisions_recorded:
- <decision>
assumptions_recorded:
- <assumption>
context_updates:
- <path or none>
adrs_created:
- <path or none>
unresolved:
- <item or none>
next:
- Return control to <caller>, or state the exact unblock action.
```

## Manual Recovery

When the user invokes `$askme` directly, explain briefly that AskMe is an internal dependency exposed for recovery and debugging. Collect the missing Interview Brief with one control question, then follow the same workflow and terminal-state rules. Do not invent a separate user-facing mode.
