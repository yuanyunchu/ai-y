---
name: openspec-sync-specs
description: Sync delta specs from a change to the main specs directory. Use when archiving a change that has delta specs that should be merged into the canonical specs.
---

# OpenSpec Sync Specs

Sync delta specs from `openspec/changes/<name>/specs/` to `openspec/specs/<capability>/`.

## When to Trigger

- When archiving a change that has delta specs
- When user explicitly wants to sync specs from a change to main specs
- Called by openspec-archive-change during archive flow

## Input

- Change name (required)

## Steps

1. **Find delta specs**

   Check `openspec/changes/<name>/specs/` for delta spec files.

   If no delta specs exist: report "No delta specs to sync" and exit.

2. **Analyze each delta spec**

   For each spec file found:
   - Read the delta spec content
   - Determine the target capability name (from filename or directory structure)
   - Check if a corresponding main spec exists at `openspec/specs/<capability>/spec.md`

3. **Determine sync strategy**

   For each delta spec, determine:
   - **Add**: Main spec doesn't exist → create new
   - **Modify**: Main spec exists → merge changes
   - **Remove**: Delta indicates removal → confirm before deleting
   - **Rename**: Delta indicates rename → update references

4. **Show summary to user**

   Present a clear summary BEFORE making any changes:

   ```
   ## Spec Sync Summary for change '<name>'

   | Delta Spec | Target | Action | Status |
   |------------|--------|--------|--------|
   | user-auth.md | specs/auth/spec.md | Modify | Ready |
   | payment.md | specs/payment/spec.md | Add | Ready |

   Total: N specs to sync
   ```

5. **Wait for user confirmation**

   Use the `question` tool to ask:
   > "Sync these specs to main? This will modify openspec/specs/."

   Options:
   - "Sync all"
   - "Skip sync"
   - "Review individually"

6. **Execute sync**

   If confirmed:
   - For **Add**: Create directory if needed, write new spec.md
   - For **Modify**: Read main spec, apply delta changes, write back
   - For **Remove**: Ask for extra confirmation, then remove
   - For **Rename**: Move file and update any internal references

   After each operation, verify the file was written correctly.

7. **Report results**

   ```
   ## Spec Sync Complete

   ✓ specs/auth/spec.md — Updated
   ✓ specs/payment/spec.md — Created
   Total: N specs synced
   ```

## Rules

- NEVER sync without showing summary and getting user confirmation
- Back up the original main spec content before modifying (copy to .bak)
- If merge conflicts exist (same section changed), highlight them and ask user
- Preserve YAML frontmatter when modifying existing specs
- If target directory doesn't exist, create it with mkdir -p

## Output On No Delta Specs

```
No delta specs found in openspec/changes/<name>/specs/.
Nothing to sync.
```

## Output On Success

```
## Spec Sync Complete

<list of synced specs>

All delta specs have been merged into openspec/specs/.
```

## Output On User Cancellation

```
Spec sync cancelled. No changes made to openspec/specs/.
```
