## Security Rules

### Deletion Safety

- NEVER run `rm -rf` on any path that resolves outside the current project root
- For any `rm` command affecting more than 3 files, list what will be deleted and ask for confirmation before proceeding
- Prefer `git clean -fd` over manual `rm` for cleaning build artifacts

### Git Safety

- NEVER force-push to main, master, or develop branches
- NEVER commit .env files, secrets, credentials, API keys, or tokens
- NEVER reference Claude, AI, or any AI tool in commit messages or PR descriptions
- Always run `git diff --staged` and present a summary before committing
- NEVER rebase shared/protected branches without explicit permission

### Destructive Operation Gate

Any operation that deletes more than 3 files, drops a database table, modifies CI/CD config, or changes infrastructure
(terraform) requires presenting a summary of what will change and getting explicit confirmation before proceeding.

### Secrets

- NEVER read, display, or log the contents of .env files or any file containing secrets or credentials
- If you encounter a secret in code, flag it as a security issue
