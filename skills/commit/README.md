# commit

Reads the diff, stops dead on anything that shouldn't be committed, writes a Conventional Commits message, and commits
without asking you to approve the wording.

See [`SKILL.md`](./SKILL.md) for the skill itself.

## Use it for

- A finished change you want committed now — message drafted and committed in one step, no review round-trip.
- Unstaged work spanning unrelated areas: it groups the changed files by likely concern and asks which to include,
  rather than sweeping the lot in with `git add -A`.
- As a safety net. Secrets, `.env` files, leftover `console.log`/`debugger`, `dist/` and `node_modules/`, and newly
  added `TODO`/`FIXME` comments all stop the commit before a message is even drafted.

In BPP repos, prefer `/bpp-commit` — it adds the Jira and branch-guard steps. This one is the generic version for
everything else.

## Example

The happy path, no questions asked:

```text
/commit

Staged: src/auth/refresh.ts, src/auth/refresh.test.ts

  fix(auth): prevent token refresh race condition

8f2a1c9 fix(auth): prevent token refresh race condition
```

And the reason the red-flag step exists:

```text
/commit

Not committing — 2 red flags:
  src/config.ts:12   hardcoded AWS_SECRET_ACCESS_KEY
  .env.local         staged

Fix these, or tell me explicitly to proceed.
```
