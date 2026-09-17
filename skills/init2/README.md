# init2

Reads a repository highest-signal-first and writes a project `CLAUDE.md` full of derived knowledge — so future sessions
don't have to re-read the whole codebase to get oriented.

See [`SKILL.md`](./SKILL.md) for the skill itself.

## Use it for

- A repo with no `CLAUDE.md` at all.
- A `CLAUDE.md` that's gone generic — the kind that says "follow standard conventions" and saves nobody any time.
- A codebase you've inherited: the output doubles as your own orientation notes.
- After a big architectural change, when the existing file describes a layout that no longer exists.

## Example

```text
/init2

Reading in signal order: README, CONTRIBUTING → docs/adr (4 ADRs) → package.json
→ tsconfig, biome.json → .github/workflows → tree -L 2 → src/index.ts, routes/*
→ vitest.config.ts + 3 example tests

Wrote CLAUDE.md:
  Overview · Stack · Key Commands · Architecture · Conventions
  Testing Patterns · Key Decisions (links to the 4 ADRs) · Gotchas
```

The hard rule is that every section has to be specific enough to be actionable — "files are kebab-case, components are
PascalCase, `undefined` never `null`", not "follow standard conventions". A section with nothing real to say gets
omitted rather than padded.
