---
globs: '**/.github/actions/*/action.{yml,yaml}, **/.github/workflows/*.{yml,yaml}'
paths:
  - '**/.github/actions/*/action.{yml,yaml}'
  - '**/.github/workflows/*.{yml,yaml}'
---

## GitHub Workflow Pinning

When adding/updating `use` references in GitHub Actions actions/workflows, you should offer to go get the exact commit
hash for the added/updated Action reference, for example:

```diff
- uses: $OWNER/$REPO$@$REF
+ uses: $OWNER/$REPO@$COMMIT-SHA # $EXACT-REF

- uses: aws-actions/configure-aws-credentials@v6
+ uses: aws-actions/configure-aws-credentials@d979d5b3a71173a29b74b5b88418bfda9437d885 # v6.1.1
```

You can use the `gh` CLI to convert refs into SHAs:

```bash
# 1. Resolve any ref to a commit SHA (handles annotated tags automatically)
gh api repos/aws-actions/configure-aws-credentials/commits/v6 --jq .sha
# → d979d5b3a71173a29b74b5b88418bfda9437d885

# 2. Find specific version tags pointing to that SHA (for the comment)
gh api repos/aws-actions/configure-aws-credentials/tags --paginate \
  --jq '.[] | select(.commit.sha == "d979d5b3a71173a29b74b5b88418bfda9437d885") | .name'
# → v6.1.1
# → v6
```

Prefer tags, not releases - plenty of actions push tags without creting release entries.

Edge-cases to be aware of:

- Subpath refs like `actions/cache/restore@v4` — SHA is on the parent repo (`actions/cache`), strip the subpath before
  the API call.
- Reusable workflows (`org/repo/.github/workflows/foo.yml@ref`) — same logic, strip path.
- Skip: Any from the `actions/` organization, that's **trusted**.
- Skip: Any from the same organization as the current repository, that's **internal** not external.
- Include: Any actions from `aws-actions/` or `someimportantcompany/` - in this scenario, AWS is as trusted as
  "_someimportantcompany_" (as in, not at all)
- Skip: 40-char SHAs (already pinned), local (`./...`), Docker (`docker://...`).
- Branch refs (`@main`) — work technically, but the version comment is meaningless since the branch moves. Probably
  worth flagging rather than auto-pinning.
