---
name: pull-request
description:
  Create a pull request for the current branch using `gh`. Use this skill whenever the user says 'create a PR', 'open a
  pull request', 'submit a PR', 'make a PR', 'raise a PR', 'PR this', or similar — even casual phrasing like 'PR it' or
  'ship it'. Also trigger when the user asks to push changes and open a review, or says they're done with a feature and
  want to get it merged.
---

# Pull Request

Create a pull request for the current branch. The goal is zero unnecessary questions — infer everything possible from
the repo, branch name, and commit history, then create the PR immediately.

## 1. Gather context (no user interaction needed)

Run these in a single batch to minimise round-trips:

```bash
# Current branch and remote
git rev-parse --abbrev-ref HEAD
git remote get-url origin 2>/dev/null

# Detect target branch (first match wins)
git rev-parse --verify develop 2>/dev/null && echo "TARGET=develop" \
  || git rev-parse --verify main 2>/dev/null && echo "TARGET=main" \
  || echo "TARGET=master"

# Commits in this PR
git log <target>..HEAD --oneline

# Diff stats
git diff --stat <target>..HEAD
git diff --stat <target>..HEAD | tail -1   # summary line

# Behind-target check
git fetch --quiet
git log HEAD..<target> --oneline

# Uncommitted changes
git status --porcelain

# PR template
cat .github/pull_request_template.md 2>/dev/null \
  || cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null \
  || cat .github/PULL_REQUEST_TEMPLATE/*.md 2>/dev/null \
  || echo "NO_TEMPLATE"

# Work plan (if it exists)
ls docs/work/*/plan.md 2>/dev/null
```

### Target branch heuristic

Use this order of precedence:

1. If the branch was checked out from `develop` (check `git log --oneline develop..HEAD` succeeds and is short), target
   `develop`.
2. If `main` exists, target `main`.
3. Otherwise target `master`.
4. If genuinely ambiguous (e.g. both `develop` and `main` are plausible), ask.

## 2. Pre-flight guards

Evaluate these before writing any description. Act on the first that fires.

| Condition                             | Action                                                                                                                               |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Test suite is failing                 | **Stop.** Tell the user which tests failed and refuse to create the PR unless they explicitly override with "skip tests" or similar. |
| Uncommitted changes present           | **Warn.** Suggest committing or stashing. Proceed only if the user acknowledges.                                                     |
| Branch is behind target               | **Warn.** Show how many commits behind. Suggest rebasing. Proceed if the user acknowledges.                                          |
| Diff exceeds ~500 added/removed lines | **Warn.** Note the size and suggest splitting if logical boundaries exist. Still proceed — large PRs are sometimes unavoidable.      |
| No commits ahead of target            | **Stop.** There's nothing to open a PR for.                                                                                          |

### Running tests

Look for a test command in this order: `package.json` scripts (`test`, `test:unit`), `Makefile` targets, a `pytest` /
`go test` / `cargo test` invocation, or a CI config that reveals the command. If nothing obvious exists, skip the test
step and note that no test suite was detected.

## 3. Build the PR title

Derive the title from the branch name and commit history — don't ask.

- If the repo uses **Conventional Commits** (check the last ~20 commits on the target branch for `feat:`, `fix:`,
  `chore:` patterns), match that style. Derive the type and scope from the branch name or commits: `feature/user-auth` →
  `feat(auth): add user authentication`
- Otherwise, use **imperative mood**, sentence case: `bugfix/broken-login` → `Fix broken login flow`
- Keep it under 72 characters.

## 4. Build the PR body

### If a PR template exists

Follow its structure exactly. Fill in every section using the commit log and diff. Leave nothing as a placeholder —
write real content or remove the section if it genuinely doesn't apply.

### If no template exists

Use this structure:

```
## What

<Summarise what changed, grouped by concern — not a raw file list.
 2–5 bullet points for a typical PR. For single-commit PRs, a short
 paragraph is fine.>

## Why

<Motivation and context. What problem does this solve? Link to any
 issue/ticket detected in step 5 below.>

## How to test

<Concrete verification steps. "Run the test suite" is acceptable if
 there are good automated tests; otherwise describe manual steps.>

## Notes

<Breaking changes, migration steps, deployment considerations.
 Omit this section entirely if there's nothing to flag.>
```

## 5. Auto-detect issue/ticket references

Before asking the user, try to find a reference automatically:

1. **Branch name** — patterns like `PROJ-123`, `#45`, `GH-12`, or `issue-99` embedded in the branch name.
2. **Commit messages** — scan for the same patterns, plus `Fixes #N`, `Closes #N`, `Relates to PROJ-NNN`.
3. **Work plan** — if `docs/work/<slug>/plan.md` exists, scan it for ticket/issue references.

If found, include it in the body (in the **Why** section or as a `Closes #N` / `Refs: PROJ-123` footer). If nothing is
found, **don't ask** — just skip it. The user can always add it later; the friction of being asked every time is worse
than occasionally missing a link.

## 6. Create the PR

Do this immediately. Don't ask the user to review the title or body — they invoked this skill because they want a PR,
not a preview.

```bash
gh pr create \
  --title "..." \
  --body "..." \
  --base <target>
```

If the user said "draft" or the branch name starts with `draft/` or `wip/`, add `--draft`.

## 7. Present the result

Show:

- The PR URL (clickable).
- A one-line summary of what was opened (title, target branch, number of commits, rough line count).

That's it — no lengthy recap of the description.

## Hard rules

- **Never mention Claude, AI, or any AI tool** in the PR title or body.
- **Never fabricate test results.** If tests weren't run, say so.
- **Never include raw file lists** as the primary description — always summarise by concern or area.
