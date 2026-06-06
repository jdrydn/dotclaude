# Claude Code

My [Claude Code](https://claude.com/claude-code) config, installed into `~/.claude/` via symlinks.

## Install

```sh
./setup.sh
```

Idempotent — re-run any time. Symlinks everything below, cleans up dead links into this repo, and rebuilds the
concatenated global `CLAUDE.md`. See [`CLAUDE.md`](./CLAUDE.md) for what it does and how to extend it.

## Contents

- `CLAUDE.md.d/*.md` — numbered parts of the global instruction set, concatenated into `~/.claude/CLAUDE.md`
  - Add `<num>-<name>.local.md` files to customise the global instruction set on a per-setup basis
- `agents/*.md` — subagents (`committer`, `pr-creator`, `researcher`, `reviewer`, `test-runner`)
- `skills/*/` — skills (`commit`, `init2`, `pull-request`)
- `rules/` — rule docs, surfaced as `~/.claude/rules/dotclaude`
- `settings.json` — permissions, allowed commands, hooks _(copied to `~/.claude/` on first run; edit per-machine after)_
- `statusline-command.sh` — custom statusline _(copied to `~/.claude/` on first run; screenshot below)_

![Screenshot](./statusline-screenshot.png)
