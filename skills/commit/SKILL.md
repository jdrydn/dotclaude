---
name: commit
description: >
  Smart git commit workflow — analyzes staged (or unstaged) diffs, catches red flags (secrets, debug code, large
  binaries, .env files), generates conventional commit messages, and commits.
---

# Commit Authoring

## Workflow

### Step 1: Read

Run `git diff --staged` first.

- If there IS staged content, use that diff and proceed.
- If there is NO staged content, run `git diff` to see unstaged changes.
  - If unstaged changes exist in a single logical area (one file, or a few closely related files), stage them all with
    `git add` and proceed.
  - If unstaged changes span multiple unrelated areas, list the changed files grouped by likely concern and ask the user
    which files to include. Stage only the confirmed files, then proceed.
  - If there are no changes at all (staged or unstaged), tell the user there's nothing to commit and stop.

### Step 2: Analyze

Read through the full diff output. Determine:

1. **What changed and why** — understand the intent behind the change (new feature, bug fix, refactor, etc.)
2. **Scope** — how many files are affected, which area of the codebase
3. **Red flags** — scan for every one of these:
   - Secrets or credentials (API keys, tokens, passwords, private keys, connection strings)
   - `.env` files or other config files that typically contain secrets
   - Debug code left behind (`console.log`, `console.debug`, `console.warn` used for debugging, `debugger` statements,
     `print()` statements that look like debug output, `binding.pry`, `byebug`, `pdb.set_trace`)
   - Large binary files (images, videos, compiled artifacts, archives)
   - Generated or vendored files (lock files are fine; `dist/`, `build/`, `node_modules/`, `.min.js` are not)
   - New `TODO` or `FIXME` comments being added (additions only — existing ones in context lines are fine)

### Step 3: Blockers

If ANY red flags were found:

1. List each red flag clearly — file, line, what was found, why it's a concern.
2. **Stop.** Do not generate a commit message. Do not commit.
3. Ask the user to confirm they want to proceed, or fix the issues first.

Only continue to Step 4 after the user explicitly says to proceed.

If no red flags, go straight to Step 4.

### Step 4: Draft

Use Conventional Commits format:

```
<type>(<scope>): <description>
```

**Type** — choose the most accurate:

- `feat` — new feature or capability
- `fix` — bug fix
- `refactor` — restructuring without behavior change
- `test` — adding or updating tests
- `docs` — documentation only
- `chore` — maintenance, dependencies, tooling
- `perf` — performance improvement
- `ci` — CI/CD pipeline changes
- `style` — formatting, whitespace, linting (no logic change)
- `build` — build system or external dependency changes

**Scope** — derive from the primary area of change. Use the module name, directory, component, or feature area.
Examples: `auth`, `api`, `cli`, `db`, `config`, `deps`. Omit scope only if the change is truly cross-cutting.

**Description rules:**

- Imperative mood ("add", "fix", "update" — not "added", "fixes", "updated")
- Lowercase first letter
- No trailing period
- Under 72 characters total for the first line

**Body** — include only when the change is complex enough to warrant explanation. Use concise bullet points covering
what changed and why. Keep it short; the diff tells the full story.

**Footer** — if the conversation mentions a ticket or issue number (e.g., JIRA-123, #456, PROJ-789), include it as
`Refs: <ticket>`. Only include references that were actually mentioned — never fabricate them.

**Authorship** — never mention Claude, Anthropic, AI, LLM, "generated", "auto-generated", or any AI tooling anywhere in
the commit message. The commit should read as if a human developer wrote it, because a human developer is responsible
for it.

**Examples:**

Single-file bug fix:

```
fix(auth): prevent token refresh race condition
```

Multi-file feature with body:

```
feat(api): add pagination to list endpoints

- Add cursor-based pagination to /users and /projects
- Include total count in response headers
- Default page size of 50, max 200
```

Dependency update:

```
chore(deps): upgrade express to 4.19.2
```

### Step 5: Commit

Run `git commit -m "<message>"` immediately. Do not ask the user to confirm the message — they invoked this command
because they want a commit, not a review. If the message has a body, use multiple `-m` flags:

```bash
git commit -m "<subject line>" -m "<body>"
```

After committing, show the user the short log entry (`git log --oneline -1`) so they can see the result.

## Conventions

### Rules

- NEVER mention Claude, AI, or any AI tool in commit messages.
- Each commit should be atomic — one logical change that leaves the codebase in a working state.
- If a change touches more than 10 files, consider splitting into multiple commits.
- Don't commit generated files, build artifacts, or debug code.
- Don't commit .env files, secrets, or credentials.

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

- **type:** feat, fix, refactor, test, docs, chore, perf, ci, style, build
- **scope:** the primary area of change (module name, feature area)
- **description:** imperative mood, lowercase, no period, under 72 chars
- **body:** concise bullet points on what and why (not how), when the change is complex enough to warrant it
- **footer:** reference issue/ticket numbers if relevant

### Examples

```
Good:
  feat(auth): add password reset flow
  fix(api): handle null response from payment provider
  refactor(users): extract email validation to shared util
  test(checkout): add edge cases for expired discount codes

Bad:
  Updated files
  fix bug
  feat: Add New User Authentication Flow Using OAuth2
  refactor(users): refactored user service to extract email validation
    into a shared utility function
  fix(api): fixed the bug where payment provider returns null (AI-generated)
```

### Atomicity

A good commit should be:

- **Reviewable** in isolation — a reviewer can understand it without context from other commits
- **Reversible** cleanly — reverting it doesn't break other things
- **Describable** in under 72 characters — if you can't, it's doing too much

## Guards

- REFUSE to commit if .env, credentials, secrets, or API keys are staged
- WARN if committing generated/build files (dist/, build/, node_modules/)
- WARN if commit is unusually large (more than 10 files) — suggest splitting
- WARN if tests are failing in the affected area (flag it, don't block)
