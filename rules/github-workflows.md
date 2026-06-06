---
globs: '**/.github/actions/*/action.{yml,yaml}, **/.github/workflows/*.{yml,yaml}'
paths:
  - '**/.github/actions/*/action.{yml,yaml}'
  - '**/.github/workflows/*.{yml,yaml}'
---

# GitHub Actions workflows

Most repos need exactly two workflows. Don't sprawl into a dozen single-purpose files — it splits the dependency graph
across runs you can't sequence, and makes "is this PR green?" ambiguous. One workflow orchestrates everything a PR
needs; one orchestrates deployment.

## First decision: is this a deployable?

A **deployable** ships to a running environment (Serverless/CloudFormation stacks, Lambda APIs, anything with a URL). A
**library** publishes an artifact (an npm package).

- **Deployable** → build both workflows below in full.
- **Library** → the Pull Request workflow stops at unit tests (no ephemeral env, no integration stage), and "Deploy"
  becomes a **publish** workflow triggered on a tag/release using npm Trusted Publishing (OIDC), not a test→prod deploy.
  Don't bolt environment deploys onto a package.

If it's ambiguous, ask which one it is before scaffolding — the shape diverges hard.

## Non-negotiable conventions

Apply these to every workflow you write:

- **OIDC, never long-lived secrets.** Use `aws-actions/configure-aws-credentials` with `role-to-assume` and
  `permissions: id-token: write`. Never reference `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`. Same posture for npm:
  Trusted Publishing, not an `NPM_TOKEN` secret.
- **Single source for the Node version.** `actions/setup-node` with `node-version-file: .nvmrc` and `cache: npm`. Don't
  hardcode versions in two places.
- **`npm ci`, never `npm install`** in CI.
- **Concurrency groups.** Cancel superseded PR runs; do **not** cancel in-flight deploys (a half-cancelled
  `serverless deploy` leaves a broken stack).
- **GitHub Environments for gating.** `test` and `production` as Environments so prod can require a reviewer in repo
  settings — keep the approval gate in GitHub config, not as a manual step in YAML.
- **Factor out shared deploy logic.** The ephemeral PR deploy and the main deploy run the same steps against different
  stages. Pull that into a reusable workflow (`workflow_call`) or a composite action so the deploy command lives in one
  place.
- **Least-privilege `permissions:`** declared per-workflow. Default to `contents: read` and add only what's needed.

---

## Workflow 1 — Pull Request (`.github/workflows/pull-request.yml`)

Orchestrates the full PR lifecycle as one dependency graph: validate and unit-test in parallel, then (for deployables)
spin up an ephemeral stage keyed to the PR number, run integration tests against it, and tear it down when the PR
closes.

```yaml
name: Pull Request

on:
  pull_request:
    types: [opened, synchronize, reopened, closed]

concurrency:
  group: pr-${{ github.event.pull_request.number }}
  cancel-in-progress: true

permissions:
  id-token: write # OIDC -> AWS
  contents: read
  pull-requests: write # to comment the ephemeral URL

jobs:
  validate:
    if: github.event.action != 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck

  unit-test:
    if: github.event.action != 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm run test:unit

  # --- Deployables only: remove the next two jobs for libraries ---
  deploy-ephemeral:
    if: github.event.action != 'closed'
    needs: [validate, unit-test]
    runs-on: ubuntu-latest
    environment:
      name: pr-${{ github.event.pull_request.number }}
      url: ${{ steps.deploy.outputs.url }}
    outputs:
      url: ${{ steps.deploy.outputs.url }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_DEPLOY_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}
      - id: deploy
        run: |
          STAGE="pr-${{ github.event.pull_request.number }}"
          npx serverless deploy --stage "$STAGE"
          URL=$(npx serverless info --stage "$STAGE" --verbose | grep -oP 'https://\S+')
          echo "url=$URL" >> "$GITHUB_OUTPUT"

  integration-test:
    if: github.event.action != 'closed'
    needs: [deploy-ephemeral]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm run test:integration
        env:
          BASE_URL: ${{ needs.deploy-ephemeral.outputs.url }}

  cleanup:
    if: github.event.action == 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_DEPLOY_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}
      - run: npx serverless remove --stage "pr-${{ github.event.pull_request.number }}"
```

Notes that matter:

- The single `on.pull_request` trigger with `types: [..., closed]` lets one workflow both build _and_ tear down. Every
  build job carries `if: github.event.action != 'closed'`; the `cleanup` job carries
  `if: github.event.action == 'closed'`. This keeps the whole ephemeral lifecycle in one file.
- `deploy-ephemeral` declares `outputs.url` so `integration-test` can target the live stage. Tests run against a real
  deployment, not a mock.
- Keying the stage on the PR number (`pr-123`) gives each PR an isolated stack and a deterministic name to remove on
  close. For multi-tenant work, this also gives you an isolated tenant per PR.

---

## Workflow 2 — Deploy (`.github/workflows/deploy.yml`)

Runs on merge to `main`: deploy to `test`, verify it with the same integration suite, then deploy to `production` behind
the Environment's approval gate.

```yaml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: deploy
  cancel-in-progress: false # never interrupt an in-flight deploy

permissions:
  id-token: write
  contents: read

jobs:
  deploy-test:
    runs-on: ubuntu-latest
    environment: test
    outputs:
      url: ${{ steps.deploy.outputs.url }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_DEPLOY_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}
      - id: deploy
        run: |
          npx serverless deploy --stage test
          URL=$(npx serverless info --stage test --verbose | grep -oP 'https://\S+')
          echo "url=$URL" >> "$GITHUB_OUTPUT"

  integration-test:
    needs: [deploy-test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm run test:integration
        env:
          BASE_URL: ${{ needs.deploy-test.outputs.url }}

  deploy-prod:
    needs: [integration-test]
    runs-on: ubuntu-latest
    environment: production # configure required reviewers in repo settings
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_DEPLOY_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}
      - run: npx serverless deploy --stage prod
```

Notes that matter:

- `test` is a real gate, not a smoke step: prod only runs if `integration-test` against the freshly-deployed test stage
  passes. That's the whole point of having two environments in one pipeline.
- The `production` Environment carries the approval rule. Set required reviewers in repo settings so a merge to `main`
  deploys to test automatically but pauses for sign-off before prod. Don't reimplement approval as YAML.
- `cancel-in-progress: false` is deliberate — cancelling a running deploy is how you get a wedged stack.

---

## Reuse

`deploy-ephemeral`, `deploy-test`, and `deploy-prod` are the same steps with a different `--stage`. Once a third copy
appears, extract them into a reusable workflow that takes the stage as an input:

```yaml
# .github/workflows/_deploy.yml
on:
  workflow_call:
    inputs:
      stage: { required: true, type: string }
    outputs:
      url: { value: ${{ jobs.deploy.outputs.url }} }
```

Then call it with `uses: ./.github/workflows/_deploy.yml` and `with: { stage: ... }`. Keep the deploy command in exactly
one place.
