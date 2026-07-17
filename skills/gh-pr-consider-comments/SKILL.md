---
name: gh-pr-consider-comments
description: >
  Pull unresolved review comments on a pull request, read them alongside the diff and any suggested changes, and discuss
  the response with the user before touching any code — then, once agreed, implement, commit, push, and reply to/resolve
  the threads. Use whenever the user wants to work through PR feedback — phrases like "look at the PR comments", "what's
  outstanding on my PR", "go through the review feedback", "address the comments on #123", or right after a reviewer
  leaves comments. Optional argument is a PR number or URL; otherwise auto-detects from session context or the current
  branch. This skill is discussion-first — it never implements or acts on threads without agreeing an approach first.
---

# Consider GitHub PR Comments

Pull the **unresolved** review threads on a pull request, read each one against the diff and any suggested change, then
**discuss the plan with the user before writing any code**. Once an approach is agreed, carry it through: implement the
agreed changes, offer to commit & push, then offer to reply to and resolve the threads. The discussion gate always comes
first — nothing is written or posted until the user agrees.

## Arguments

1. **PR** _(optional)_ — a PR number (`123`), a full URL (`https://github.com/OWNER/REPO/pull/123`), or nothing (auto-
   detect from session context or the current branch).

## Tools required

- `gh` CLI (authenticated) — for the PR, its diff, the review threads (GraphQL), and posting replies/resolving threads.
- `git` — for pushing after committing.
- `AskUserQuestion` — to confirm before the outward-facing actions (push, reply, resolve).

## Steps

### 1. Resolve the PR

Try in order, stop at the first hit:

**a) Explicit argument** — if the user gave a number or URL, use it. Extract `OWNER`, `REPO`, and the number.

**b) Current session context** — if a PR was raised, pushed, or discussed earlier in this same conversation (e.g. the
user opened/reviewed a PR a few turns ago), use that PR. You already have its number and URL in context — don't
re-derive it. When the user says "the PR" right after this kind of activity, they mean that one.

**c) Current branch** —

```bash
gh pr view --json number,title,url,headRefName,state,baseRefName 2>/dev/null
```

**d) Most recent open PR by this user** —

```bash
gh pr list --author @me --state open --limit 5 \
  --json number,title,url,headRefName,createdAt \
  --jq 'sort_by(.createdAt) | reverse'
```

If `gh` isn't installed or authed, stop and tell the user. If nothing resolves, ask for the PR number/URL. If multiple
open PRs match and it's ambiguous, list them and ask.

Derive `OWNER` and `REPO` from `gh repo view --json owner,name` or the PR URL — the GraphQL query in step 2 needs both.

### 2. Pull the unresolved review threads

REST doesn't expose thread resolution state — use GraphQL. Review threads carry `isResolved`, so filter to the
unresolved ones:

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          originalLine
          comments(first: 50) {
            nodes {
              author { login }
              body
              diffHunk
              createdAt
              url
            }
          }
        }
      }
    }
  }
}' -F owner="$OWNER" -F repo="$REPO" -F pr=$PR_NUMBER \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)'
```

Notes:

- **Only unresolved threads.** The `select(.isResolved == false)` filter drops anything already resolved. If a thread is
  `isOutdated` but still unresolved, keep it — flag it as outdated so the user knows the code may have moved.
- **Keep each thread's `id`.** You'll need it in step 6 to post replies and resolve threads. Track which unresolved
  thread maps to which item you present in step 4.
- **Read whole threads.** Each thread's `comments` array is the original comment plus every reply. Read all of them — a
  later reply may already answer, retract, or reframe the original point.
- **Also pull top-level review bodies and general PR comments** — these aren't review threads but often carry summary
  feedback:
  ```bash
  gh pr view $PR_NUMBER --json reviews,comments \
    --jq '{reviews: [.reviews[] | select(.body != "") | {author: .author.login, state: .state, body: .body}], comments: [.comments[] | {author: .author.login, body: .body}]}'
  ```
- If there are **zero unresolved threads and no substantive review/PR comments**, say so plainly and stop — there's
  nothing to consider.

### 3. Read each comment against the diff

For every unresolved thread, build a real understanding before forming an opinion:

- The `diffHunk` in each comment shows the exact lines the reviewer commented on. Cross-reference it against the current
  file — the code may have changed since (especially if `isOutdated`).
- If a comment is a **GitHub suggestion** (its body contains a ` ```suggestion ` block), treat the suggested replacement
  as a concrete proposed change — quote it verbatim when you present it.
- Read the surrounding code (open the file) so you can judge whether the suggestion is correct, partially right, or
  would break something. Don't take a reviewer's suggestion on faith — verify it against the code.

### 4. Present a summary and discuss — do NOT implement

Group the unresolved feedback and present it clearly. For each item, give the user what he needs to decide:

````
### 1. `path/to/file.ts:42` — @reviewer  [outdated?]

> <the reviewer's comment, condensed but faithful>

<If a suggestion block exists, show it:>
Suggested change:
​```suggestion
<the suggested code>
​```

**My read:** <your assessment — is it correct? what would the fix be? any risk or trade-off?>
**Proposed action:** <accept / accept-with-tweak / push back / needs-the-user's-call>
````

Then:

- Lead with your recommendation per item, but keep each one open for discussion.
- Where you'd push back on a reviewer, say why — grounded in the code, not deference.
- If items interact (one fix subsumes another, or two conflict), call that out.
- **End by asking the user how he wants to proceed.** This is the whole point of the skill: agree the approach together
  before any code is written. Do not start editing, do not open the files for writing, do not attempt to commit.

Only once the user has agreed an approach do you move on. Steps 5 and 6 below run **only after** that agreement and
after the agreed changes are made.

### 5. Implement the agreed changes, then commit & push

Once the user has agreed the approach:

- Make only the changes you both agreed in step 4 — nothing more. Skip items the user chose to push back on or defer.
- **Offer to commit and push.** Use `AskUserQuestion` with choices `Commit & push` / type to discuss more. Only proceed
  when the user says yes.
  - Commit per the user's global preference — might be a custom skill, or the generic commit skill.
  - Then push with `git push`.
- If nothing needed a code change (every item was a reply-only or push-back), skip straight to step 6.

### 6. Reply to and resolve the threads

After the changes are pushed (or immediately, for reply-only items), **offer to reply to and resolve each thread**. Ask
first via `AskUserQuestion` (`Reply & resolve` / type to discuss) — replying and resolving is outward-facing and visible
to reviewers, so don't do it unprompted. Show the reply text you intend to post before sending.

For each thread the user approves, using the thread `id` captured in step 2:

**Post a reply** (a short, courteous note — what you did, or why you're pushing back):

```bash
gh api graphql -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: { pullRequestReviewThreadId: $threadId, body: $body }) {
    comment { url }
  }
}' -F threadId="$THREAD_ID" -F body="$REPLY_BODY"
```

**Resolve the thread** (only for items that are genuinely addressed — leave push-backs open for the reviewer to close):

```bash
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: { threadId: $threadId }) {
    thread { isResolved }
  }
}' -F threadId="$THREAD_ID"
```

Guidance:

- **Match reply to outcome.** Addressed → "Done in <short ref>." / brief note on the fix. Pushing back → a courteous,
  reasoned reply, and **don't resolve** — that's the reviewer's call.
- Keep replies short and human. No "resolved via Claude" or AI attribution.
- Report a one-line summary at the end: what was committed/pushed, which threads got replies, which were resolved, which
  were left open and why.

## Hard rules

- **Discussion-first, always.** No code, commit, push, reply, or resolve happens before the user agrees the approach in
  step 4. Implementation and the outward-facing actions (push, reply, resolve) each need a clear go-ahead.
- **Ask before outward-facing actions.** Pushing, replying to threads, and resolving threads are visible to reviewers —
  always confirm via `AskUserQuestion` first, per step 5 and 6.
- **Don't resolve what you pushed back on.** Only resolve threads the change genuinely addresses; leave contested ones
  open for the reviewer.
- **Unresolved only.** Don't re-surface resolved threads — the user has already dealt with them.
- **Read the whole thread, including replies.** A reply may already resolve the point in spirit.
- **Verify suggestions against the code.** A reviewer's suggestion can be wrong or stale — check before recommending it.
- **Stay faithful.** Condense comments; never invent feedback or editorialise beyond your own clearly-labelled read.
- Never use the `§` character anywhere in output.

## Examples

**"Go through the review comments on my PR"** → auto-detect PR from branch → GraphQL pulls 4 review threads, 1 already
resolved → present the 3 unresolved with diff context and your read on each → ask the user how he wants to handle them.
Nothing is edited.

**"Look at the comments on #418"** → resolve PR #418 → 2 unresolved threads, one with a ` ```suggestion ` block that
would actually introduce a null-deref → present it, flag the problem, recommend pushing back → discuss.

**"What's outstanding on the PR?"** → all threads resolved, one non-empty review body with a general "nice work,
consider X later" note → report there's nothing unresolved to action, mention the review note, stop.

**"Address the comments on my PR"** → 3 unresolved threads presented with reads → user agrees to accept 2 and push back
on 1 → make the 2 agreed changes → `AskUserQuestion` "Commit & push?" → yes → commit then `git push` → `AskUserQuestion`
"Reply & resolve?" → yes → reply "Done in <ref>" + resolve on the 2 fixed threads; reply with the reasoning on the
pushed-back thread but leave it open → one-line summary of what was pushed, replied, and resolved.
