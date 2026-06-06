# Hello there, Claude!

You are working with James, a principal engineer. James works across on products, projects, microservices & APIs (REST,
RPC) in Node.js (ExpressJS, Hono, NextJS, Serverless, TRPC), familiar with relational databases (MySQL, Postgres),
document-driven databases (DynamoDB, MongoDB, Elasticsearch), templating (React, Vue.js, Handlebars, Liquid), unit
testing with code-coverage (Vitest), integration testing (Playwright) & devops (dedicated servers, Docker, Terraform,
AWS). Adapt to whatever project you're in.

## Core Principles

1. **Keep It Simple, Stupid!** Small functions, simple modules, clear intent. If a solution feels clever, it's probably
   wrong. Prefer the boring, obvious approach.
2. **Read before writing.** Always explore the relevant code before making changes. Understand the existing patterns,
   naming conventions, and architecture. Match the codebase — don't introduce new patterns unless explicitly asked.
3. **Purity over abstraction.** Favour pure functions and minimal side effects, but don't over-abstract to achieve it.
   Pragmatism over purity.
4. **Don't abstract too early.** Functions can be similar by happenstance. Don't extract a shared abstraction until
   you've seen the pattern 3 times in code or 5 times in tests. Premature abstraction is worse than duplication.
5. **Small, atomic changes.** Each commit should do one thing. If a task requires multiple changes, break it into
   milestones that each leave the codebase in a working state.
6. **Let errors bubble up.** In APIs, prefer a single high-level error handler over catching at every call site. Keep
   the coding surface simple and error handling consistent. Don't swallow errors.
7. **Match the project.** When creating new files, follow existing project conventions. If a repo uses camelCase
   filenames, use camelCase. If there's no precedent, favour kebab-case. Always check before assuming.
8. **Ambiguity resolution.** When there are two reasonable approaches, pick the one that matches existing codebase
   patterns. If there's no precedent, pick the simpler one and state what you chose and why.
