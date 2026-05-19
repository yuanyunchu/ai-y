---
name: git-sync-guard
description: Use before editing any file to check git status and pull latest changes. Triggers automatically when the user asks to modify, create, or delete files in a git repo. Prevents conflicts by ensuring local is up-to-date with remote.
---

# Git Sync Guard

Before making any file changes in a git-tracked project, always perform these steps:

## Pre-edit Checklist

1. **Check git status**: Run `git status` to see:
   - Are there uncommitted changes that might conflict?
   - Are there untracked files that could be affected?
   - Is the branch ahead/behind remote?

2. **Check remote sync**: Run `git fetch origin && git status` to see if the local branch is behind the remote. If behind:
   - If there are NO local uncommitted changes: `git pull --rebase origin <branch>`
   - If there ARE local uncommitted changes: stash first, pull, then pop:
     ```
     git stash
     git pull --rebase origin <branch>
     git stash pop
     ```
   - If stash pop has conflicts, report to user and ask how to resolve.

3. **Check branch**: Verify you're on the correct branch. If the user mentions a feature branch, switch to it first.

## When to Trigger

- ANY time you are about to use the Edit or Write tool on a file in a git repo
- When the user asks to commit or push changes
- When the user mentions syncing, updating, or pulling code
- At the start of a new session in a git-tracked project

## Rules

- If `git status` shows the repo is clean and up-to-date, proceed with edits immediately.
- If there are conflicts during pull/stash-pop, STOP and inform the user. Do not attempt auto-resolution.
- If the remote doesn't exist or network fails, warn the user but proceed with local edits.
- Never force push or reset without explicit user approval.
- After completing edits and the user asks to push, always run `git pull --rebase` before pushing to avoid rejected pushes.

## Quick Reference

```bash
# Fast check (run before every edit session)
git fetch origin && git status

# Full sync (when behind remote, clean working tree)
git pull --rebase origin <current-branch>

# Sync with dirty working tree
git stash && git pull --rebase origin <current-branch> && git stash pop

# Pre-push safety
git pull --rebase origin <current-branch> && git push origin <current-branch>
```
