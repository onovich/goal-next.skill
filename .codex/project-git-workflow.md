<!-- codex-project-git-workflow: initialized -->
<!-- initialized-at: 2026-07-21T15:47:26.3950496+08:00 -->

# Codex Git Workflow

Initialization status: initialized

Project: GoalNext Skill Workflows

Machine config: `.codex/project-git-workflow.json`

Skill: `project-git-workflow`

This document and the adjacent config are the repository source of truth. The config intentionally uses repository-relative commands so clones do not inherit a contributor's local paths.

## Status

```powershell
git status --short --branch
```

## Validation

Run these before every commit and push:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/Validate-Skills.ps1
git diff --check
```

## Staging Policy

Stage selected files only. Inspect status first and preserve unrelated changes.

## Commit

Use the global `project-git-workflow` wrapper with a concise conventional commit message. The wrapper uses built-in `git commit` after explicit staging.

## Push

```powershell
git push -u origin HEAD
```

## Documentation

Update `README.md` and `ROADMAP.md` whenever the public workflow scope changes.

## Safety And Branch Policy

- Do not force-push.
- Do not commit credentials, auth state, real thread ids, personal paths, or other sensitive data.
- Keep `SKILL.md` and `agents/openai.yaml` as UTF-8 without BOM.
