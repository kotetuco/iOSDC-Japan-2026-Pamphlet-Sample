---
name: commit-reviewability
description: Stage and commit changes as coherent, human-reviewable units. Use whenever Codex creates commits, organizes a branch into commits, or prepares committed work for review in this repository.
---

# Human-reviewable commits

Create a history in which each commit has one clear purpose, can be reviewed without unrelated context,
and can normally be reverted independently.

## Decide commit boundaries

Before staging, inspect `git status`, the complete working-tree diff, and recent commit-message conventions.
Separate changes when they answer different reviewer questions or have different reasons to change.

- Keep a behavior change with the tests and minimal documentation that directly establish that behavior.
- Keep unrelated refactoring, formatting, generated-file updates, dependency changes, and documentation cleanup separate.
- Order dependent commits so that each commit is as close as practical to a buildable, testable state.
- Do not rewrite, amend, squash, or rebase commits created by the user unless explicitly requested.

For a larger task, form a tentative commit sequence before implementation and revise it as the actual diff develops.

## Keep the diff readable

Use one purpose and reviewer cognitive load as the primary criteria. As a review prompt, reassess a commit when
either the staged diff affects more than about 10 files or contains more than about 300 added and deleted lines.
Generated files, project files, and lockfiles may explain the size, but must not hide the size of the handwritten diff.

When a commit exceeds these guides:

1. Look for independent behavior, refactoring, tests, documentation, or mechanical changes that can move safely.
2. Split along those boundaries when the resulting commits remain understandable and usable.
3. Keep the larger commit intact when splitting would break the build, separate a change from its direct tests,
   or make the history harder to understand.
4. State the reason for an intentionally large commit in the final work report.

Do not fragment a cohesive change solely to satisfy a numeric target.

## Stage and verify

Stage explicit paths or selected hunks for one planned commit. Do not use `git add .` or `git add -A`.
Before committing, run and inspect:

```sh
git diff --cached --name-status
git diff --cached --stat
git diff --cached --numstat
git diff --cached
git diff --cached --check
```

If the full staged diff cannot be reviewed confidently in one pass, unstage and divide it further.
Run the checks relevant to that commit, then use a concise commit message that describes its actual purpose.

After committing, inspect `git show --stat --oneline HEAD` and `git status --short` to verify the boundary and
ensure no intended changes were accidentally omitted or included.
