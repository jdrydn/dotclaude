# gh-pr-review

Reviews a GitHub PR the way you would: checks the branch out, verifies every suspicion against real code before
reporting it, and hands back numbered severity-ranked findings with a clear blocking verdict.

See [`SKILL.md`](./SKILL.md) for the skill itself.

## Use it for

- Reviewing a teammate's PR properly — not a skim of the diff, but grep-the-callers, read-the-whole-file properly.
- A pass over your own PR before you request review.
- Re-review after "changes pushed" — it diffs only the new commits and re-checks each prior finding by its original
  number.
- Picking a PR back up in a fresh session — it finds your last GitHub review and diffs from there, or tells you there's
  nothing new if no commits have landed since.
- Posting the outcome to GitHub in one pick: it asks afterwards whether to request changes, approve with the findings,
  approve with a one-liner, or approve silently — findings land as inline comments on the lines they're about.
- Looking back at a merged or closed PR — it checks first and asks you to confirm, since that's usually a wrong number.

## Example

```text
/gh-pr-review 847

On feat/exam-timer (was main). 7 files, +412/-98, diffed against the merge base.

Overall: solid, well-tested. One real correctness bug and a scoping inconsistency.

1. [medium] Missing await in fetchExam() — api/exams.ts:42
   CONFIRMED. Returns a pending promise, so `exam.duration` is undefined on the
   first render; the timer then starts at NaN.
2. [medium] getExam takes a bare id with no tenant check — api/exams.ts:88
   The sibling endpoint added in this same PR does scope (line 61).
3. [minor] Test name claims it covers expiry, only asserts the happy path
   — exam-timer.test.ts:34

📝 Notes (not for the PR):
N1. `package.json` dependencies no longer sorted — package.json:14

✅ Done well: timer state moved to context rather than threaded through props.
❓ Q1: should a resumed exam keep wall-clock or elapsed time?

Verdict: request-changes. Blocking: 1, 2. Follow-up: 3.

On `feat/exam-timer` (was `main` — `git checkout main` to return).

? What should I post to #847?
  › Request changes for high/medium
    Approve with comments
    Approve with one-liner
    Approve, no message
    Other
```

Five habits do the work: the numbers stay stable for the rest of the conversation, so "fix 1 and 2" is unambiguous;
nothing gets reported unless it's been confirmed against the actual lines; low-impact notes are shown to you but never
posted to the PR; nothing goes to GitHub until you pick an option, and then findings go inline rather than as one wall
of text (request changes is only offered when there's a high or medium finding); and it reviews but never fixes, leaving
the branch checked out and clean for you.
