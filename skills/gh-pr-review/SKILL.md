---
name: gh-pr-review
description:
  Review a GitHub pull request the way the user would — verify-don't-trust, precision over volume, severity-ranked
  findings with file:line links, and a clear blocking/non-blocking verdict.
disable-model-invocation: true
---

# Review PR: $ARGUMENTS

Review the target PR (URL or number). Follow these tactics.

## 1. Check out the PR branch

Reviewing against real files on disk is what makes angles 3 and 8 possible — grep, cross-file tracing and reading whole
files all see the actual PR state instead of whatever branch happened to be checked out.

**Confirm you're in the right repo first.** The local repo must be the PR's base repo:

```bash
gh repo view --json nameWithOwner --jq .nameWithOwner
gh pr view <ref> --json baseRepository,headRepositoryOwner,headRefName,isCrossRepository
```

If it isn't (or `gh` is unavailable, or you're not in a git repo), **skip this whole section** and review read-only via
`gh pr diff` and `gh api`. Never check out into an unrelated repo. Forks are fine — `gh pr checkout` handles
`isCrossRepository` PRs itself.

**Record the starting state before touching anything** — not to undo it, but so you can tell the user exactly where they
came from:

```bash
git rev-parse --abbrev-ref HEAD   # branch name, or literally "HEAD" if detached
git rev-parse HEAD                # SHA — the way back if HEAD was detached
git status --porcelain            # MUST be empty
```

**If the working tree is dirty, abort.** Never stash, never `checkout --force`, never work around it. Tell the user
which files are uncommitted and stop — they decide whether to commit, stash or discard, and they re-run the review.
Their in-progress work is not yours to move.

**Check out:**

```bash
gh pr checkout <ref>
```

**If checkout fails for any reason, abort too** — report the error verbatim and stop. Don't retry with force, don't
improvise a `git fetch` fallback, don't quietly downgrade to a read-only review. A failed checkout means the repo isn't
in the state this review assumed, and that's the user's call to resolve.

Note whether checkout created a new local branch — mention it in the wrap-up, but don't delete it.

**You stay on this branch when the review ends** — see section 9. That's deliberate: the user will want to poke at the
code and post comments off the back of the review.

## 2. Gather — the PR diff is the ONLY review scope

- `gh pr view <ref> --json title,body,author,baseRefName,headRefName,state,additions,deletions,changedFiles,labels,commits`
- **Still pull the diff — the checkout doesn't replace it.** The working tree gives you the PR's end state; the diff
  gives you what actually changed, and that delta is the review scope. Now the branch is local, take it from git instead
  of the network:

  ```bash
  git fetch origin <baseRefName>
  git diff origin/<baseRefName>...HEAD --stat      # shape and size first
  git diff origin/<baseRefName>...HEAD -- <path>   # then file by file
  ```

  Three dots, not two — that diffs against the merge base, which is what GitHub shows. Two dots drags in everything that
  landed on the base branch since this one forked, and you'd review changes the author never made.

  Going file by file is the point of having it locally: on a big PR you can work through it in real chunks instead of
  swallowing one enormous blob. `--stat` orders the work, it is never a substitute — read every changed file, and never
  review from a truncated preview. Save the full diff to `.tmp/` if you need to page back through it.

  **On the read-only path** (checkout skipped), use `gh pr diff <ref>` instead.

- The diff defines the scope even though the whole tree is now readable — don't drift into reviewing untouched code.
- With the PR checked out, local files ARE the PR state: read them freely for surrounding context, and grep across the
  tree with confidence. Sanity-check once with `git rev-parse HEAD` against the PR's head SHA before relying on it.
- **If you skipped the checkout**, never trust local working-tree files as the PR state. Fetch instead:
  - `git fetch origin <headRef>` then `git show origin/<headRef>:<path>`, or
  - `gh api "repos/<owner>/<repo>/contents/<path>?ref=<headRef>" --jq '.content' | base64 -d` (URL-encode brackets in
    paths, e.g. `[id]` → `%5Bid%5D`)
- Read the author's "notes for reviewers". Respect what they've explicitly deferred, but still call it out if it's
  user-visible.
- Read the repo's `CLAUDE.md` (root, plus the nearest one to the changed files) for conventions and any documented
  data/tenancy models — angles 4 and 8 depend on it.
- **Read-only analysis.** Don't install dependencies and don't run the project's tests, build or lint — that executes
  code from the PR branch. Reason about the code; don't run it.
- **Scratch files go in `.tmp/`** in the repo root — the saved diff, review notes, `--body-file` payloads, JSON payloads
  for `gh api`. Not `/tmp`; writes inside the working directory avoid permission prompts. Make sure `.tmp/` is ignored
  before writing, so it doesn't dirty the tree the user keeps working in (section 9) or trip the dirty-tree abort on a
  later re-review:
  ```bash
  mkdir -p .tmp
  grep -qxF '.tmp/' .git/info/exclude || echo '.tmp/' >> .git/info/exclude
  ```

## 3. Verify, don't trust

This is the most important habit. Don't take the PR description, code comments, or test names at face value. For every
suspected issue, confirm it against the actual code before reporting:

- Grep for referenced symbols — event-name enums, DB columns, schema nullability, feature flags, helper signatures — and
  confirm they exist and mean what the code assumes (e.g. what index `[0]` actually represents).
- Check helper/function signatures the code calls (what a shared access-check selects, what a util returns, the shape of
  a query result) before claiming something is redundant, missing, or wrong.
- When a business rule is enforced in the UI, check whether the server/mutation also enforces it. Flag client-only
  enforcement of a "hard" rule, and mismatched operators between client and server (`<` vs `<=`).
- When the change computes a "canonical" figure, find where it's computed elsewhere (dashboards, other queries) and
  confirm the query matches EXACTLY — same filters, status sets, ordering.
- Before flagging "wrong data source" / "mislabeled value", trace where the value actually comes from and whether the
  behaviour is a REGRESSION vs pre-existing. If it matches existing behaviour, it's a product question, not a defect.
- If a concern turns out to be justified by the surrounding code (an "extra" query that's actually needed), drop it —
  don't pad the review.

## 4. Angles to run (priority order)

1. **Correctness** — inverted conditions, off-by-one and boundary operators, null/undefined deref, falsy-zero checks,
   missing `await`, wrong-variable copy-paste, swallowed errors, effects/state races, query-resolution order, fallback
   (`?? default`) paths.
2. **Removed-behaviour audit** — for every deleted/replaced line, name the invariant it enforced and confirm it's
   re-established in the new code.
3. **Cross-file tracer** — for each changed function, grep its callers/callees across the checked-out tree: does the
   change break a call site (new precondition, changed return shape, new throw)? A call site that never appears in the
   diff is exactly the kind of break this catches.
4. **Authz / tenant scoping** — first check the repo's `CLAUDE.md` (root and nearest package) for the data model and
   tenancy model (what the tenant boundary is, which id scopes access); if absent, infer it from existing endpoints
   before flagging. Then: auth gating on every new procedure, cross-tenant leaks, and any endpoint that takes a bare id
   and returns data without verifying access — ESPECIALLY when sibling endpoints in the same PR do scope. Inconsistent
   scoping is a real finding even for reference data.
5. **Transactions & races** — TOCTOU windows (precondition checked outside the tx), missing conditional guards on
   concurrent writes, partial-failure paths (what happens on retry after a post-commit step fails — does the user get
   stuck?).
6. **What's missing from the diff** — colocated specs that should have changed when a component/import was renamed or
   swapped (a stale test that still passes for the wrong reason is a finding), and orphaned/dead code left behind (old
   components/routes no longer wired). With the tree checked out, grep for the removed symbol repo-wide to find what got
   left behind.
7. **Test quality** — tests whose name claims coverage they don't provide (false confidence is worse than no test);
   untested boundaries; the POSITIVE/happy path, not just the error path — call out when only one side of a comparison
   is tested.
8. **Conventions** — match project patterns (naming, file placement, design-system tokens, `undefined` over `null`).
   Quote the exact rule (e.g. from CLAUDE.md) — no vibes. Compare against real sibling files in the tree, not memory.
9. **UX inconsistencies** (controls that don't drive what they appear to), then **performance** (N+1, needless
   queries/renders), then **a11y** (known trade-offs, not blockers).

## 5. Precision, not volume

Every finding must be one a maintainer would act on. For each surviving candidate, confirm the trigger by reading the
actual lines and classify:

- **CONFIRMED** — name the inputs → wrong output, quote the line.
- **PLAUSIBLE** — mechanism real, trigger uncertain; say what would confirm it.
- **REFUTED** — drop silently.

When a candidate turns on an assumption ("IDs are guessable", "this data is sensitive"), check the assumption against
the actual schema/code before it survives — don't let severity inflate on an unverified premise. If nothing survives,
say so plainly.

## 6. Write-up format

- **Overview** — 2–3 lines on what the PR does and an honest overall take ("solid, well-tested" / "needs work"). Don't
  bury the verdict.
- **Findings, most severe first** — each with a severity tag (medium / minor / nit), a clickable `file.tsx:line` link,
  the concrete failure scenario, and a suggested fix. Be honest about severity — if something's really cosmetic, say so.
- **Number every finding from 1**, in a single sequence that runs unbroken through the minor/nits section — so #7 means
  exactly one thing and the user can say "fix 3 and 7" or "2 is wrong because…" without quoting file paths back at you.
  Lead each finding heading with its number, e.g. `### 3. [minor] Missing await in fetchExam() — api/exams.ts:42`.
  Product questions get their own numbering (Q1, Q2, …) so they never collide with findings.
- **Minor / nits** — separated from real findings so severity is never ambiguous, but keep counting up from wherever the
  real findings stopped. Never restart at 1 per section.
- **✅ Things done well** — genuinely good decisions: correct scoping, justified design choices, sensible rule-of-3
  extractions, candid PR notes. Reviews aren't only fault-finding.
- **❓ Product questions** — behaviour that's a product call, not a code bug.
- **Verdict** — approve / approve-with-changes / request-changes, stating exactly which findings are merge-blocking vs
  deferrable follow-ups — refer to them by number (e.g. "blocking: 1, 2; follow-ups: 4–6").
- **Keep the numbers stable for the rest of the conversation.** When the user says "2" or "the third one" in a follow-up,
  it means that finding — restate the title before acting so you both agree on what's being fixed.

## 7. Posting a review — only when asked

Never post comments or submit a GitHub review until explicitly asked. When asked:

- Default: a single review via `gh pr review <ref> --approve|--request-changes|--comment --body-file <path>` (write the
  body to a file, never inline a huge `--body`). Put it in `.tmp/` — see "Scratch files" in section 2.
- Split the body into **Required** (confirmed correctness/security/data-integrity) and **Optional** (test-quality,
  cleanup, conventions). Request changes ONLY on Required items.
- Each bullet must be self-contained (file:line, what's wrong, why it matters) — it'll be read on GitHub without this
  conversation's context. Keep the review's numbering on each bullet so the user can map a GitHub comment back to the
  finding discussed here.
- If asked to post only some findings ("post 1, 3 and 5"), the numbers are the selection — post exactly those and say
  which you left out.
- If asked for inline comments: `gh api --method POST repos/{owner}/{repo}/pulls/{n}/reviews` with an `event` and a
  `comments` array. Use one-click
  ``suggestion blocks anchored with `path` + `start_line`/`line` + `side:RIGHT` for clean, self-contained fixes on changed lines. Fixes spanning multiple files or touching files NOT in the diff go as a fenced ``diff
  in the review body instead. Build the JSON payload in Python (safe escaping of backticks/newlines), then
  `gh api ... --input payload.json`.
- Tone collegial; light emoji sparingly. No mention of AI/Claude in the review body.
- Confirm the review posted via `gh pr view <ref> --json reviews`.

## 8. Re-review (when told "changes pushed / re-review")

- Usually you're still on the PR branch from the first pass — pull the new commits (`git pull --ff-only`) before reading
  anything. If the user has switched away since, run section 1 again from the top — record state, then `gh pr checkout`.
- Re-pull `gh pr view` for the commit list, then diff **only what's new** — you've already reviewed the rest:
  `git diff <sha-you-last-reviewed>..HEAD` (two dots here — you want exactly the commits added since), or
  `git show <sha> -- <paths>` per commit.
- Verify EACH prior finding against the new code, **keeping its original number** — Fixed / Partially / Not. Confirm
  fixes are resolved _coherently_: tests updated to match, no stale references to removed symbols (grep), types
  tightened where relevant. Don't take the commit message's word for it.
- Scrutinise the NEW code too — scan for regressions the fixes introduced. Don't rubber-stamp because a commit appeared.
- Credit fixes that went further than asked or found a deeper root cause; note residual trade-offs.
- Number any NEW findings from where the last pass stopped — never reuse a number from the first review, even if the
  original finding is now fixed and gone from the list.
- Restate the verdict, reaffirming leftover non-blocking items as follow-ups (by number). Submit a formal approval only
  when explicitly asked.

## 9. Stay on the PR branch

**Don't switch back.** The review ends with the PR still checked out so the user can read the code, try things, and
follow up with inline comments or an approval without a second checkout. Never `git checkout -` on your own initiative —
only when they ask.

Close the write-up with a one-liner saying where they now are and how to get back, e.g.:

> On `feat/exam-timer` (was `main` — `git checkout main` to return).

If HEAD was detached before the checkout, give the recorded SHA as the way back instead of a branch name.

Because the branch persists past the review, keep it clean for them:

- Scratch files live in `.tmp/` and nowhere else, and `.tmp/` is ignored — so `git status` stays clean for them.
- Don't edit, stage or commit anything. This skill reviews; it doesn't fix.
- If the user later asks to get back to their branch, use the values you recorded in section 1.
