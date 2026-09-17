# context-joke

Recaps what just happened in the session and tells exactly one joke about it. Runs on Haiku, so it's cheap.

See [`SKILL.md`](./SKILL.md) for the skill itself.

## Use it for

- Straight after a commit — the diff is rich material and it's already in context.
- The end of a long session, as a full stop.
- A red build, a gnarly migration, or the fourth attempt at the same fix.

## Example

```text
/context-joke

Recap: added an AssumeMigrationRoles statement to the Support permission set in
global-permissions.tf:1234 — sts:AssumeRole on role/migration-*-role, wildcarded
so future migration roles need no policy change.

Why did the IAM policy go to therapy? Too many unresolved AssumeRole issues —
pushing now so it can finally find its principal in life.
```

The recap is the point: the joke has to be about the actual work, not about programming in general.
