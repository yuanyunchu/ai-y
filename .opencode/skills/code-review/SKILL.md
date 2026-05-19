---
name: code-review
description: Perform red-blue adversarial code review on core code changes. Use after core development is complete and before merge. Ensures quality through cross-model review.
---

# Code Review — Red/Blue Adversarial Review

Perform structured code review on core code changes. This skill maps to AGENTS.md's red-blue team review requirement.

## When to Trigger

- After completing core development tasks (Apply phase ③)
- Before merging code to main branch
- When user explicitly requests code review

## Pre-review Checklist

1. **Identify the developer model** — Ask or infer which AI model wrote the code:
   - DeepSeek-v4-pro
   - Kimi-k2.6
   - GPT-4o
   - Other

2. **Determine review focus** based on developer model:

| Developer Model | Review Focus (You act as) | Key Areas |
|----------------|---------------------------|-----------|
| DeepSeek-v4-pro | Claude 3.7 / o3-mini reviewer | Boundary conditions, concurrency safety, exception handling |
| Kimi-k2.6 | DeepSeek-v4-pro reviewer | Logical consistency, architecture compliance |
| GPT-4o | Claude 3.5 Sonnet reviewer | Code smells, over-engineering, simplicity |

3. **Get the code context**:
   - Read the changed files
   - Read related tests
   - Read design.md / architecture.md if available

## Review Process

### Step 1: Read all changed code
Use bash/git diff or read files to understand the full scope of changes.

### Step 2: Structured review checklist

For each file changed, check:

**Boundary Conditions**
- [ ] Edge cases handled (empty input, max values, nulls)
- [ ] Off-by-one errors checked
- [ ] Resource limits respected

**Concurrency Safety** (if applicable)
- [ ] Thread safety verified
- [ ] Race conditions analyzed
- [ ] Lock ordering correct
- [ ] Deadlock potential eliminated

**Exception Handling**
- [ ] All error paths covered
- [ ] Exceptions don't leak resources
- [ ] Error messages are actionable
- [ ] Fallback behavior defined

**Logical Consistency**
- [ ] Code matches design文档
- [ ] Naming consistent with codebase
- [ ] No contradictions in logic flow
- [ ] State transitions are valid

**Architecture Compliance**
- [ ] Follows project conventions
- [ ] Doesn't bypass intended layers
- [ ] Dependencies are appropriate
- [ ] No circular dependencies introduced

**Code Quality**
- [ ] No code smells (duplication, long methods, deep nesting)
- [ ] Not over-engineered (YAGNI principle)
- [ ] Clear intent, minimal cleverness
- [ ] Comments explain why, not what

### Step 3: Severity classification

Tag each finding:
- 🔴 **Critical** — Must fix before merge (bugs, security, data loss)
- 🟡 **Warning** — Should fix (maintainability, edge cases)
- 🟢 **Suggestion** — Nice to have (style, optimization)

### Step 4: Output format

```
## Code Review Report

**Change:** <change-name or PR description>
**Developer Model:** <model-name>
**Reviewer Role:** <reviewer-model>
**Files Reviewed:** <list>

### Critical Issues 🔴
1. **[File:line]** Issue description
   - **Why it matters:** ...
   - **Suggested fix:** ...

### Warnings 🟡
1. **[File:line]** Issue description
   - **Concern:** ...
   - **Suggested fix:** ...

### Suggestions 🟢
1. **[File:line]** Suggestion
   - **Rationale:** ...

### Summary
- 🔴 Critical: N | 🟡 Warning: N | 🟢 Suggestion: N
- **Verdict:** Approve / Approve with changes / Request changes
```

## Rules

- Be specific: cite file names and line numbers
- Explain WHY, not just WHAT is wrong
- Suggest concrete fixes, don't just point out problems
- If unsure, ask for clarification rather than guess
- Don't nitpick style unless it impacts readability significantly
- If no issues found in a category, say "No issues found" rather than omitting

## Post-review

After presenting findings:
- If 🔴 critical issues exist: "Please address critical issues before merging"
- If only 🟡/🟢: "Approved with minor changes" or "Approved"
- Wait for user to fix issues, then re-review if requested
