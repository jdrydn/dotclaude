# gh-pr-consider-comments

Pulls the **unresolved** review threads on a PR, reads each against the diff, and gives you its read plus a
recommendation — then stops. Nothing is written, pushed, replied to or resolved until you've agreed the approach.

See [`SKILL.md`](./SKILL.md) for the skill itself.

## Use it for

- Working through a round of review feedback without losing track of which threads are still open.
- Deciding which suggestions to take and which to push back on, with the code in front of you.
- A reviewer's ` ```suggestion ` block that looks plausible but might be wrong — it verifies before recommending.
- Closing threads out properly afterwards: reply, resolve the fixed ones, leave the contested ones open.

## Example

````text
/gh-pr-consider-comments 418

2 unresolved threads (1 already resolved, skipped).

### 1. api/exams.ts:42 — @reviewer
> This should use the shared `assertCanRead` helper.
My read: correct, and the helper already selects the tenant id — no extra query.
Proposed action: accept.

### 2. hooks/use-timer.ts:18 — @reviewer  [outdated]
> Suggested change:
> ```suggestion
> const remaining = total - elapsed ?? 0;
> ```
My read: this breaks it. `??` binds tighter than `-`, so the fallback applies to
`elapsed`, not the subtraction — and `elapsed` is never nullish anyway.
Proposed action: push back.

How do you want to handle these?

> take 1, push back on 2

[change made] → Commit & push? → yes → pushed 4d1e77a
Reply & resolve? → yes
  Thread 1: "Done in 4d1e77a." → resolved
  Thread 2: reasoning posted, left open for the reviewer to close.
````

The discussion gate is the whole point — it's why this is separate from a skill that just applies review feedback. Push,
reply and resolve are all outward-facing, so each one is confirmed separately, and a thread you pushed back on is never
resolved on your behalf.
