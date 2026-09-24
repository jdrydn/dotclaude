---
name: gh-pr-review
description:
  Review a GitHub pull request the way the user would — verify-don't-trust, precision over volume, severity-ranked
  findings with file:line links, a clear blocking/non-blocking verdict, then asks whether to approve or request changes
  with the findings posted inline.
disable-model-invocation: true
---

# Review PR: $ARGUMENTS

Review the target PR (URL or number). Follow these tactics.

## 1. Check out the PR branch

Reviewing against real files on disk is what makes angles 3, 11 and 12 possible — grep, cross-file tracing and reading
whole files all see the actual PR state instead of whatever branch happened to be checked out.

**Check the PR is still open.** Before anything else:

```bash
gh pr view <ref> --json state,mergedAt,closedAt
```

If `state` is `MERGED` or `CLOSED`, stop and ask with `AskUserQuestion` — say which, and when, and offer
`Review it anyway` or type to discuss. A merged or closed PR is usually the wrong number or a stale link, and a review
can no longer block anything. If they decline, end there — don't check anything out. If they confirm, carry on, and:

- Frame the verdict as follow-ups rather than approve / request-changes — there's nothing left to gate.
- **Merged only:** take the diff from `gh pr diff <ref>`, not `git diff origin/<baseRefName>...HEAD` (section 2). Once a
  PR is merge-committed its head is an ancestor of the base, so the three-dot diff comes back empty. Closed-unmerged PRs
  diff normally.

**Check whether you've already reviewed it.** Look for the user's own latest review and the commit it was left on:

```bash
gh api user --jq .login
gh pr view <ref> --json headRefOid
gh api "repos/{owner}/{repo}/pulls/<n>/reviews" --paginate \
  --jq '[.[] | select(.user.login == "<login>")] | last | {state, submitted_at, commit_id, html_url}'
```

- **No previous review** — carry on as normal.
- **Reviewed at the current head** (`commit_id` equals `headRefOid`) — stop. There's nothing new to review: say so, with
  the review's state, date and link, and don't check anything out. Only review again if the user explicitly asks.
- **Commits since the review** — treat it as a re-review. Carry on through this section, then follow section 8 with the
  review's `commit_id` as the SHA you last reviewed. If that commit no longer exists locally after checkout (the branch
  was force-pushed), say so and fall back to a full review.

Other people's reviews don't count — only the user's own.

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
  data/tenancy models — angles 4 and 11 depend on it.
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

These are honed to the reasons the user has historically requested changes, ordered by impact rather than frequency. Run
every angle; the order decides severity when you rank findings.

1. **Correctness & data integrity** — the most common real blocker. Look for:
   - Partial updates that wipe data: an optional field passed as `undefined` into a nested JSON/relation write, or a
     single incoming flag resetting derived state (e.g. `status`) that should be computed from the _merged_ record.
   - Missing existence checks: a looked-up record used without an `assert`/404 when it's missing.
   - Multi-write operations without a transaction — if one write fails, do they all fail and can the job be re-driven?
   - Non-idempotent scripts, imports and migrations: what happens if it runs twice (duplicate rows, doubled totals)?
   - Queries that can overwrite records already processed — prefer the `WHERE` clause excluding them over an `if` gate.
   - Inverted booleans and wrong status sets (`!= "prod"` when `== "prod"` was meant, `IN_PROGRESS` vs `DRAFT`).
   - Knock-on effects the author missed: a data migration/backfill for existing rows, `updatedAt` bumps that downstream
     syncs (reporting/BI) rely on, fallback values when a nullable field is empty.
   - The usual suspects: off-by-one and boundary operators, null deref, falsy-zero checks, missing `await`,
     wrong-variable copy-paste, swallowed errors, effect/state races, `?? default` paths.
2. **Removed-behaviour audit** — for every deleted/replaced line, name the invariant it enforced (an `assert`, a
   `padStart`, a status in a list, a filter) and confirm the new code re-establishes it.
3. **Cross-file tracer** — for each changed function, grep its callers/callees across the checked-out tree: does the
   change break a call site (new precondition, changed return shape, new throw)? A call site that never appears in the
   diff is exactly the kind of break this catches.
4. **Authz, tenant scoping & transactions** — first check the repo's `CLAUDE.md` (root and nearest package) for the data
   and tenancy model; if absent, infer it from existing endpoints before flagging. Then: auth gating on every new
   procedure, cross-tenant leaks, endpoints that take a bare id without verifying access (ESPECIALLY when sibling
   endpoints in the same PR do scope), TOCTOU windows (precondition checked outside the tx), missing guards on
   concurrent writes, and partial-failure paths (does a retry after a post-commit failure leave the user stuck?).
   Inconsistent scoping is a real finding even for reference data.
5. **Logging, observability & PII** — **PII in logs is always a Required finding**: emails, names, free/rich text,
   anything a user typed. Log the record's id instead. Also check the log shape matches the project's logger convention
   (e.g. pino: `logger.error({ err, someId }, 'Static message')` — ids in the object, a constant message string so
   queries can match exactly, the whole `Error` passed as `err`), and that caught-and-continued errors are at least
   logged rather than silently dropped.
6. **Types & validation** — server-side validation for every rule the UI enforces (and matching operators, `<` vs `<=`);
   schema validation (e.g. Zod) for JSON columns and procedure inputs; internal ids never exposed raw if the project
   encodes them (e.g. `encodeId` out / `zSqid` in); type casts or `@ts-expect-error` papering over a real mismatch;
   nullability that's correct at the source rather than patched downstream; identifiers and values escaped properly in
   raw SQL.
7. **Infra & CI** — actions pinned to a SHA with a `# vX.Y.Z` comment; least-privilege roles (test runners shouldn't use
   the deploy role); no prod config in non-prod builds (or the reverse); copy-paste errors when cloning Terraform or
   workflows for a new app (wrong service name, the other app's secrets/config, resources that aren't needed); handler
   paths and `dist` layouts that match what the bundler actually outputs; runtime versions that match `.nvmrc`.
8. **What's missing from the diff** — new files/procedures with no unit test; colocated specs that should have changed
   when a component/import was renamed or swapped (a stale test that still passes for the wrong reason is a finding);
   orphaned/dead code left behind (grep for the removed symbol repo-wide).
9. **Test quality** — tests whose name claims coverage they don't provide; untested boundaries; only one side of a
   comparison tested; the final assertion that proves the change actually happened is missing. Prefer accessible queries
   (`getByRole`/`getByText`) over `data-testid` or positional selectors ("the second button") — `data-testid` is a last
   resort, not a default. Integration and unit runners shouldn't pick up each other's files.
10. **Readability over cleverness** — needless abstractions (helpers extracted for one call site, HOCs, `export *`
    barrel files), `if (await ...)` conditions, hand-rolled date maths where the project already has `date-fns`, string
    parsing where a platform API exists (`window.location.search`), and two lists that must be kept in sync by hand
    instead of deriving one from the other. Only a finding when it genuinely costs the next reader; otherwise a note.
11. **Naming & consistency** — names that don't match the established convention: resource/secret names that don't
    follow the repo/service name, plural table names where the project uses singular, enum or type names too generic for
    project-wide scope, event payload shapes that differ from existing events. Quote the rule or the sibling file you're
    comparing against (from `CLAUDE.md` or the real tree) — no vibes. A name you'd merely prefer is a note.
12. **Repo hygiene** — stray lockfiles (e.g. a nested `yarn.lock`/`package-lock.json` in a workspace), unrelated or
    unexplained changes outside the ticket's scope, generated/log files that should be gitignored, empty files, debug
    code left in. These are minor findings. Formatter drift, EOL changes, unsorted `package.json` keys and linter-only
    complaints are notes.
13. **Functional & UX** — does the change do what the ticket/PR says? Walk the user flow in the code (and say if it
    needs checking in the PR's deployed environment); controls that don't drive what they appear to; copy, spacing and
    back-link targets. Then **performance** (N+1, a query per item where one query would do) and **a11y** (known
    trade-offs, not blockers).

Also note any **process blocks** the user may want to raise but that aren't code findings: the PR depends on another PR
or service that hasn't landed, the branch is behind the base and needs `main` merged in, or the ticket's scope has
changed. List them in the overview; don't number them as findings.

## 5. Precision, not volume

Every finding must be one a maintainer would act on. For each surviving candidate, confirm the trigger by reading the
actual lines and classify:

- **CONFIRMED** — name the inputs → wrong output, quote the line.
- **PLAUSIBLE** — mechanism real, trigger uncertain; say what would confirm it.
- **REFUTED** — drop silently.

Then decide whether each surviving candidate is worth the author's time:

- **Finding** — something a maintainer would change before merging, or would regret not changing. These are numbered and
  may be posted to GitHub.
- **Note** — low-impact or barely worth mentioning: formatting, key order, style preferences, naming you'd merely
  prefer, linter-only complaints, cosmetic nits. **Notes are for the user only.** They get one line each in the write-up
  and are never posted to the PR (see section 7). If you're unsure whether something is a finding or a note, it's a
  note.

When a candidate turns on an assumption ("IDs are guessable", "this data is sensitive"), check the assumption against
the actual schema/code before it survives — don't let severity inflate on an unverified premise. If nothing survives,
say so plainly.

## 6. Write-up format

- **Overview** — 2–3 lines on what the PR does and an honest overall take ("solid, well-tested" / "needs work"). Don't
  bury the verdict.
- **Findings, most severe first** — each with a severity tag (high / medium / minor), a clickable `file.tsx:line` link,
  the concrete failure scenario, and a suggested fix. Be honest about severity — if something's really cosmetic, say so.
- **Number every finding from 1**, in a single sequence that runs unbroken through the minor section — so #7 means
  exactly one thing and the user can say "fix 3 and 7" or "2 is wrong because…" without quoting file paths back at you.
  Lead each finding heading with its number, e.g. `### 3. [minor] Missing await in fetchExam() — api/exams.ts:42`.
  Product questions get their own numbering (Q1, Q2, …) and notes get theirs (N1, N2, …), so they never collide with
  findings.
- **Minor** — separated from high and medium findings so severity is never ambiguous, but keep counting up from wherever
  they stopped. Never restart at 1 per section.
- **📝 Notes (not for the PR)** — the low-impact items from section 5, one line each: `N1. <what> — file.ts:12`. No
  failure scenario, no suggested fix, no code. Label the section clearly so the user knows these stay local.
- **✅ Things done well** — genuinely good decisions: correct scoping, justified design choices, sensible rule-of-3
  extractions, candid PR notes. Reviews aren't only fault-finding.
- **❓ Product questions** — behaviour that's a product call, not a code bug.
- **Verdict** — approve / approve-with-changes / request-changes, stating exactly which findings are merge-blocking vs
  deferrable follow-ups — refer to them by number (e.g. "blocking: 1, 2; follow-ups: 4–6").
- **Keep the numbers stable for the rest of the conversation.** When the user says "2" or "the third one" in a
  follow-up, it means that finding — restate the title before acting so you both agree on what's being fixed.

## 7. Ask what to post

Never post anything to GitHub off your own bat. Once the write-up is done (after the section 9 one-liner), ask with
`AskUserQuestion` what to do next — the user's pick is the go-ahead. Options, in this order:

| Option                            | Posts                                                                    |
| --------------------------------- | ------------------------------------------------------------------------ |
| `Request changes for high/medium` | A `REQUEST_CHANGES` review with every finding inline (see below)         |
| `Approve with comments`           | An `APPROVE` review with every finding inline                            |
| `Approve with one-liner`          | An `APPROVE` review whose body is one short, PR-specific line; no inline |
| `Approve, no message`             | An `APPROVE` review with an empty body                                   |

`Other` (type your own) comes free with `AskUserQuestion` — treat whatever they type as the instruction, e.g. "post 1
and 3 as comments only" or "don't post anything".

- **Leave out `Request changes`** when there are no high or medium findings — minors alone never block.
- **Merged or closed PR** (section 1): there's nothing left to approve or block, so skip the prompt. Offer to post the
  findings as a `COMMENT` review instead, and only if there are any.
- **The user's own PR**: GitHub rejects approve and request-changes from the author. Check `gh api user --jq .login`
  against the PR author; if they match, offer `Comment with findings` in place of the approve and request-changes
  options.
- **Nothing selected, nothing posted.** If they decline or change the subject, leave the PR alone.

### Findings go inline, not in one big comment

Every posted finding is an inline review comment on the line it's about — never a single catch-all PR comment.

- Post one review via `gh api --method POST repos/{owner}/{repo}/pulls/{n}/reviews` with `commit_id` (the PR head SHA),
  `event` (`REQUEST_CHANGES` / `APPROVE` / `COMMENT`), a short `body`, and a `comments` array.
- Each comment anchors with `path` + `line` (plus `start_line` for a range) + `side`: `RIGHT` for added or unchanged
  lines, `LEFT` for deleted ones. The line **must sit inside a diff hunk** or GitHub rejects the whole review — check it
  against the diff before building the payload.
- For a clean, self-contained fix on changed lines, include a one-click `suggestion` block in the comment.
- A finding that can't anchor — its line is outside the diff, or the fix spans several files — goes in the review `body`
  instead, with its `file:line` and any fix as a fenced `diff` block. That's the only thing the body carries beyond a
  one or two line summary.
- Label each comment **Required** (high/medium: correctness, security, data integrity, PII in logs) or **Optional**
  (minor), and keep the finding's number (`**3. Optional** — …`) so the user can map GitHub back to this conversation.
- Each comment is self-contained — what's wrong, why it matters, the fix. It'll be read without this conversation.
- Build the JSON payload in Python (safe escaping of backticks and newlines) in `.tmp/` (see "Scratch files" in section
  2), then `gh api ... --input .tmp/review.json`.
- The approve-only options use `gh pr review <ref> --approve` (with `--body "<one-liner>"` for the one-liner option).

### What never goes up

- **Notes** (N1, N2, …) — not inline, not in the body, not summarised as "a few nits". "Post everything" means every
  numbered finding, and you say the notes were left out. A note only goes up if the user names it (e.g. "post N2"), and
  then as a one-line optional suggestion.
- Product questions (Q1, …) and process blocks, unless the user asks.
- Anything the user didn't pick. If they ask for a subset ("post 1, 3 and 5"), the numbers are the selection — post
  exactly those and say which you left out.
- Mention of AI or Claude. Keep the tone collegial; light emoji sparingly.

Confirm it posted via `gh pr view <ref> --json reviews`, and give the user the review URL.

## 8. Re-review (when told "changes pushed / re-review")

- Usually you're still on the PR branch from the first pass — pull the new commits (`git pull --ff-only`) before reading
  anything. If the user has switched away since, run section 1 again from the top — record state, then `gh pr checkout`.
- Take the SHA you last reviewed from this conversation, or from the user's last GitHub review (section 1) in a fresh
  session.
- Re-pull `gh pr view` for the commit list, then diff **only what's new** — you've already reviewed the rest:
  `git diff <sha-you-last-reviewed>..HEAD` (two dots here — you want exactly the commits added since), or
  `git show <sha> -- <paths>` per commit.
- Verify EACH prior finding against the new code, **keeping its original number** — Fixed / Partially / Not. Confirm
  fixes are resolved _coherently_: tests updated to match, no stale references to removed symbols (grep), types
  tightened where relevant. Don't take the commit message's word for it.
- Scrutinise the NEW code too — scan for regressions the fixes introduced. Don't rubber-stamp because a commit appeared.
- Credit fixes that went further than asked or found a deeper root cause; note residual trade-offs.
- Don't chase notes on a re-review: mention in one line if they were addressed, and never escalate an unaddressed note
  into a finding.
- Number any NEW findings from where the last pass stopped — never reuse a number from the first review, even if the
  original finding is now fixed and gone from the list.
- Restate the verdict, reaffirming leftover non-blocking items as follow-ups (by number), then ask what to post exactly
  as in section 7 — the options reflect the findings still open.

## 9. Stay on the PR branch

**Don't switch back.** The review ends with the PR still checked out so the user can read the code, try things, and
follow up with inline comments or an approval without a second checkout. Never `git checkout -` on your own initiative —
only when they ask.

Close the write-up with a one-liner saying where they now are and how to get back, e.g.:

> On `feat/exam-timer` (was `main` — `git checkout main` to return).

If HEAD was detached before the checkout, give the recorded SHA as the way back instead of a branch name. Then ask what
to post (section 7).

Because the branch persists past the review, keep it clean for them:

- Scratch files live in `.tmp/` and nowhere else, and `.tmp/` is ignored — so `git status` stays clean for them.
- Don't edit, stage or commit anything. This skill reviews; it doesn't fix.
- If the user later asks to get back to their branch, use the values you recorded in section 1.
