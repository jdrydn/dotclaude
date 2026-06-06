# CLAUDE.md

This repo manages `~/.claude/` — global agents, skills, rules, and the global `CLAUDE.md` — by symlinking individual pieces back into `$HOME`. `./setup.sh` is the only entrypoint; it is idempotent and safe to re-run.

## Layout

| Source                | Destination                       | Symlink granularity |
| --------------------- | --------------------------------- | ------------------- |
| `agents/<name>.md`    | `~/.claude/agents/<name>.md`      | per-file            |
| `skills/<name>/`      | `~/.claude/skills/<name>`         | per-folder          |
| `rules/`              | `~/.claude/rules/dotclaude`       | whole folder        |
| `CLAUDE.md.d/*.md`    | `~/.claude/CLAUDE.md` (via concat) | generated file      |

`CLAUDE.md.d/` is the **folder** of source parts for the global `CLAUDE.md`. `setup.sh` concatenates the parts in glob order — alphabetical — into `CLAUDE.md.d/generated.md`, then symlinks that to `~/.claude/CLAUDE.md`. Numeric prefixes (`10-`, `20-`, …) control order; leave gaps for inserts.

## setup.sh behaviour

- Idempotent: already-correct links log `ok:`; stale links get replaced; non-symlink collisions are skipped with a warning.
- Bails (exit 1) if `~/.claude/{agents,skills,rules,CLAUDE.md}` is itself a stray symlink or regular file the script didn't create. Never silently clobbers existing state in `$HOME`.
- Cleanup pass per category: removes dead symlinks in `~/.claude/{agents,skills,rules}` whose targets point into this repo (i.e. you renamed or deleted a source).
- On regenerate, the previous `CLAUDE.md.d/generated.md` is moved to `CLAUDE.md.d/generated.YYYY-MM-DD.HH-MM-SS.md` before the new one is written.

## Adding things

- **Agent** — drop `agents/<kebab-name>.md`, run `./setup.sh`.
- **Skill** — create `skills/<kebab-name>/` with the skill's files, run `./setup.sh`.
- **Rule** — drop a markdown file into `rules/`. No re-run needed; the whole folder is one symlink.
- **Global CLAUDE.md section** — add `CLAUDE.md.d/<NN>-<TitleCase>.md` (matches the existing `10-Introduction.md`, `20-Security.md`… naming), run `./setup.sh`.

## Conventions

- Generated and machine-local files are gitignored: `CLAUDE.md.d/generated.md`, `CLAUDE.md.d/generated.*.md`, `CLAUDE.md.d/*.local.md`. Never commit them.
- Parts files in `CLAUDE.md.d/` use `<NN>-<TitleCase>.md`. Agents and skills use kebab-case.
- The folder name `CLAUDE.md.d` follows the `.d/` convention because a sibling file named `CLAUDE.md` (this file) needs the same root.
