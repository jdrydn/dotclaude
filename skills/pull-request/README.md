# pull-request

Opens a PR for the current branch with zero unnecessary questions — target branch, title, body and ticket references are
all inferred from the repo, the branch name and the commit log.

See [`SKILL.md`](./SKILL.md) for the skill itself.

## Use it for

- A branch that's ready to go, when you don't want to be asked four questions first.
- Repos with a `.github/pull_request_template.md` — it fills every section properly instead of leaving placeholders.
- `draft/` or `wip/` branches, which open as drafts automatically.
- Catching the things you'd rather know before a reviewer does: failing tests, uncommitted changes, a branch behind
  target, or a diff big enough to want splitting.

In BPP repos, prefer `/bpp-pr` — it handles the Jira ticket in the title and the house description format. This is the
generic version.

## Example

```text
/pull-request

Target: main (7 commits, +412/-98)
Ticket: LEX-432 (from branch name)
Template: .github/pull_request_template.md — filled

⚠ Branch is 3 commits behind main. Rebase first, or say go.

> go

https://github.com/BPP-Education-Group/example-project/pull/847
feat(exam): extract exam timer into a reusable hook → main, 7 commits, ~510 lines
```

Guards warn and continue; only failing tests and "no commits ahead of target" actually stop it. It never fabricates a
test result, and never uses a raw file list as the description.
