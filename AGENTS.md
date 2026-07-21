# Repository Instructions

## Scope

- Keep distributable Codex skills under `skills/<skill-name>/`.
- Keep the bundle inventory and workflow edges in `skill-set.json`.
- Treat CreateRole as roadmap scope until its guided design session is complete.

## Privacy

- Never commit credentials, auth state, real Codex thread ids, email addresses, user-specific absolute paths, private conversation content, or project-specific identities used only by the source installation.
- Use explicit placeholders such as `<codex-thread-id>` and `<absolute-workspace-path>` in examples.
- Keep Role Route examples minimal; they are routing records, not conversation or project archives.

## Skill Files

- Write every `SKILL.md` and `agents/openai.yaml` as UTF-8 without BOM.
- Start `SKILL.md` directly with `---` and `agents/openai.yaml` directly with `interface:`.
- Keep folder names and frontmatter `name` values identical and lowercase.
- Keep UI display names memorable and verify every `default_prompt` explicitly names its `$skill`.

## Validation

Before commit or push, run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/Validate-Skills.ps1
git diff --check
```

After installation changes, restart Codex and test both explicit `$skill-name` loading and UI `@DisplayName` autocomplete.
