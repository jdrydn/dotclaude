## Compaction Guidance

When compacting context, ALWAYS preserve:

1. The current plan.md contents (milestones, progress, current state)
2. Which milestone you're currently working on and its gate mode
3. Any deviations from the plan noted so far
4. The project CLAUDE.md contents
5. Any gotchas discovered during this session

Use this format for compacted state:

```md
## Session State

**Task:** <one-line description>

**Workflow:** simple | pipeline (gate mode: continuous|gated)

**Current milestone:** <number> — <title> (<status>)

**Completed:** <list of done milestone numbers>

**Blockers:** <any blockers or none>

**Gotchas found:** <list or none>

**Key files touched:** <list of files modified this session>
```

Deprioritize: file contents already committed, completed milestone details, exploratory reads that didn't yield useful
information.
