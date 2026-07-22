# Repository Instructions

## Scope

- Keep distributable Codex skills under `skills/<skill-name>/`.
- Keep the bundle inventory and workflow edges in `skill-set.json`.
- Classify every bundled skill as `core-entry`, `support`, `workflow-transition`, or `internal` in `skill-set.json`.
- Treat CreateRole as roadmap scope until its design is implemented.
- Treat the root `ROADMAP.md` as canonical only when it contains exactly one standalone `<!-- codex-roadmap: confirmed -->` marker.
- Require every operational skill except CreateRoadmap and RoadmapGate to explicitly invoke RoadmapGate before other preflight or work.
- Permit pre-confirmation AskMe/ListToDecide use only when CreateRoadmap supplies both `caller: createroadmap` and `roadmap_bootstrap: true`.
- Treat Roadmap design as user-owned. Recommend self-authored Roadmaps first and `$grill-me` when AI assistance is wanted; present CreateRoadmap only as an explicit fallback.
- Classify CreateRoadmap as `support`, disable its implicit invocation, and never position it as the default onboarding entry.
- Write README for a first-time user, not as release history or migration guidance.
- Keep ChooseModel as a decision-only support skill: discover model/effort combinations from the current runtime, never hardcode model ids or infer quota, and never create a thread.
- Require explicit user confirmation before a caller applies any ChooseModel model or effort override; otherwise preserve the configured default.

## Privacy

- Never commit credentials, auth state, real Codex thread ids, email addresses, user-specific absolute paths, private conversation content, or project-specific identities used only by the source installation.
- Use explicit placeholders such as `<codex-thread-id>` and `<absolute-workspace-path>` in examples.
- Keep Role Route examples minimal; they are routing records, not conversation or project archives.

## Skill Files

- Write every `SKILL.md` and `agents/openai.yaml` as UTF-8 without BOM.
- Start `SKILL.md` directly with `---` and `agents/openai.yaml` directly with `interface:`.
- Keep folder names and frontmatter `name` values identical and lowercase.
- Keep UI display names memorable and verify every `default_prompt` explicitly names its `$skill`.
- Set `policy.allow_implicit_invocation: false` for every `internal` skill.
- Internal skills must be explicitly and visibly invoked by their caller; they are not normal user entry points.
- Declare references to optional external skills in the caller's `optionalDependencies` entry in `skill-set.json`.

## Validation

Before commit or push, run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/Validate-Skills.ps1
powershell -ExecutionPolicy Bypass -File scripts/Test-WorkflowContracts.ps1
git diff --check
```

After installation changes, restart Codex and test both explicit `$skill-name` loading and UI `@DisplayName` autocomplete.
