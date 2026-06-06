# Claude Code

My [Claude Code](https://claude.com/claude-code) config, installed into `~/.claude/` via symlinks.

## Install

```sh
./setup.sh
```

Idempotent — re-run any time. Symlinks everything below, cleans up dead links into this repo, and rebuilds the
concatenated global `CLAUDE.md`. See [`CLAUDE.md`](./CLAUDE.md) for what it does and how to extend it.

## Contents

| Reference                | Description                                                                                                |
| ------------------------ | ---------------------------------------------------------------------------------------------------------- |
| `CLAUDE.md.d/*.md`       | Numbered parts of the global instruction set, concatenated into `~/.claude/CLAUDE.md`                      |
| `CLAUDE.md.d/*.local.md` | Local parts files to customise the global instruction set on a per-setup basis                             |
| `agents/*.md`            | Shared global instruction agents                                                                           |
| `rules/`                 | Rules, surfaced as `~/.claude/rules/dotclaude` to co-exist with other rules                                |
| `skills/*.md`            | Shared global instruction skills                                                                           |
| `settings.json`          | Permissions, allowed commands, hooks, etc. _(copied to `~/.claude/` on first run; edit per-machine after)_ |
| `statusline-command.sh`  | Custom statusline _(copied to `~/.claude/` on first run; screenshot below)_                                |

![Screenshot](./statusline-screenshot.png)

## References

- [How CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load)
- [User-level Claude rules](https://code.claude.com/docs/en/memory#user-level-rules)
- [Common workflows](https://code.claude.com/docs/en/common-workflows)
