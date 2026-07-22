# Repository Instructions

## Scope

- Keep distributable Codex skills under `skills/<skill-name>/`.
- Keep the bundle inventory and workflow edges in `skill-set.json`.
- Classify every bundled skill as `core-entry`, `support`, `workflow-transition`, or `internal` in `skill-set.json`.
- Classify CreateRole as an explicit-only `core-entry`: it may design freely after RoadmapGate, but it may create only the exact visible Role Threads approved by the user.
- Require CreateRole to prefer the smallest useful Role Graph, create threads sequentially, stop fan-out after the first failure, preserve a resumable `Role.proposed.md` ledger, and never fall back to implicit subagents.
- Keep `Role.proposed.md` as unapproved or partial filename evidence and `Role.md` as the active local route. Never commit either file when it contains real thread ids.
- Require CreateRole to consume AskMe, ChooseModel, and NameYou explicitly; an approved graph must expose upstream/downstream routes, handoff boundaries, environments, Thread Profiles, and any optional goal token budget before creation.
- Treat a substantive root `ROADMAP.md` as the canonical confirmed Roadmap. Keep unconfirmed drafts in `ROADMAP.proposed.md`; do not use embedded confirmation markers.
- Require every operational skill except CreateRoadmap and RoadmapGate to explicitly invoke RoadmapGate before other preflight or work.
- Permit pre-confirmation AskMe/ListToDecide use only when CreateRoadmap supplies both `caller: createroadmap` and `roadmap_bootstrap: true`.
- Treat Roadmap design as user-owned. Keep optional external AI-assisted Roadmap recommendations in README only; present CreateRoadmap only as an explicit fallback.
- Classify CreateRoadmap as `support`, disable its implicit invocation, and never position it as the default onboarding entry.
- Write README for a first-time user, not as release history or migration guidance.
- Keep `README.md` English-first and maintain the complete Chinese translation in `README.zh-CN.md`; place reciprocal language links at the top of both files.
- Keep ChooseModel as a decision-only support skill: discover model/effort combinations from the current runtime, never hardcode model ids or infer quota, and never create a thread.
- Require explicit user confirmation before a caller applies any ChooseModel model or effort override; otherwise preserve the configured default.

## Privacy

- Never commit credentials, auth state, real Codex thread ids, email addresses, user-specific absolute paths, private conversation content, or project-specific identities used only by the source installation.
- Use a GitHub noreply address for Git author and committer metadata; privacy validation must report only the affected commit, never echo the email value.
- Use explicit placeholders such as `<codex-thread-id>` and `<absolute-workspace-path>` in examples.
- Keep Role Route examples minimal; they are routing records, not conversation or project archives.

## Skill Files

- Write every `SKILL.md` and `agents/openai.yaml` as UTF-8 without BOM.
- Start `SKILL.md` directly with `---` and `agents/openai.yaml` directly with `interface:`.
- Keep folder names and frontmatter `name` values identical and lowercase.
- Keep UI display names memorable and verify every `default_prompt` explicitly names its `$skill`.
- Set `policy.allow_implicit_invocation: false` for every `internal` skill.
- Internal skills must be explicitly and visibly invoked by their caller; they are not normal user entry points.
- Keep bundled Roadmap workflows self-contained. Skills and the manifest must not reference or invoke external interview or roadmapping Skills.
- Declare references to optional external skills in the caller's `optionalDependencies` entry in `skill-set.json`.

## Validation

Before commit or push, run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/Validate-Skills.ps1
powershell -ExecutionPolicy Bypass -File scripts/Test-WorkflowContracts.ps1
git diff --check
```

After installation changes, restart Codex and test both explicit `$skill-name` loading and UI `@DisplayName` autocomplete.
