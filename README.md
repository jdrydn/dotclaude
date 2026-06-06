# Claude Code

My [Claude Code](https://claude.com/claude-code) config, installed into `~/.claude/` via symlinks.

## Install

```sh
./setup.sh
```

Idempotent — re-run any time. Symlinks everything below, cleans up dead links into this repo, and rebuilds the concatenated global `CLAUDE.md`. See [`CLAUDE.md`](./CLAUDE.md) for what it does and how to extend it.

## Contents

- `CLAUDE.md.d/*.md` — numbered parts of the global instruction set, concatenated into `~/.claude/CLAUDE.md`
- `agents/*.md` — subagents (`committer`, `pr-creator`, `researcher`, `reviewer`, `test-runner`)
- `skills/*/` — skills (`commit`, `init2`, `pull-request`)
- `rules/` — rule docs, surfaced as `~/.claude/rules/dotclaude`
- `settings.json` — permissions, allowed commands, hooks *(not auto-installed)*
- `statusline-command.sh` — custom statusline *(not auto-installed; screenshot below)*

![Screenshot](./statusline-screenshot.png)

## License

[MIT](./LICENSE.md)
