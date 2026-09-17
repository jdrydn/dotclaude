# grill-proj

[`grill-me`](../grill-me), with the repository in the room. Reads the codebase first, then spends its questions only on
what the code can't answer, and puts what you say side by side with what the repo actually does.

See [`SKILL.md`](./SKILL.md) for the skill itself.

## Use it for

- "Should we move X onto Y" in a repo that already has opinions about how X works.
- Scoping a refactor — especially working out what the smallest safely-mergeable slice is.
- A proposal about a codebase you've inherited and don't fully trust your model of yet.
- Pre-ADR grounding: get the trade-offs straight against real code before writing the decision up.
- A ticket-shaped idea that needs breaking into PRs, where the blast radius is the unknown.

## Example

```text
/grill-proj move the enrolment emails onto the shared notification service

Read: src/enrolment/**, notifications/client.ts, the two ADRs in docs/adr,
git log on that area (12 commits, 3 authors, last touched in March).

Round 1
1. `sendEnrolmentEmail` (src/enrolment/email.ts:41) retries 5 times with no backoff; the
   shared client retries twice with jitter. Is the 5 load-bearing, or drift?
2. You said these are transactional-only — but src/enrolment/email.ts:120 sends a
   "your course starts soon" nudge off a cron. Which is true?
3. Three other services import this module (billing, reporting, admin). In scope, or do
   they keep the old path while enrolment moves?
4. The tests mock the transport, not the client (email.test.ts:8). Moving to the shared
   client means rewriting all 14 — is that cost telling you something?

> 2 — ah. the nudge shouldn't be in there at all, that was a hack for a 2023 campaign
```

That answer was the session: the real change was deleting the nudge, and the migration got a lot smaller.

## Attribution

Same source as its sibling: this is my take on [`/grill-with-docs`](https://www.aihero.dev/skills-grill-with-docs) by
[Matt Pocock](https://github.com/mattpocock), from [`mattpocock/skills`](https://github.com/mattpocock/skills) (MIT, ©
2026 Matt Pocock). The original is the maintained one — install it with:

```sh
npx skills@latest add mattpocock/skills
# or
claude plugins install mattpocock-skills
```

## What's actually in this folder

An independent reimplementation, written from Matt's public write-up rather than from his source. The concept is his;
the prompt text was written from scratch and no wording was copied.

## Where it diverges

The big one: **Matt's `grill-with-docs` is stateful and this isn't.** His writes as it goes — vocabulary lands in
`CONTEXT.md` the moment a term crystallises, and qualifying decisions become ADRs in `docs/adr/`. That's a genuinely
good design and worth reading. This version writes nothing at all, for two reasons: it keeps the pair consistent (both
`grill-*` skills leave only a sharper idea), and ADRs here belong to `local-bpp-write-adr`, which already knows the
house style. Decisions that deserve an ADR get handed off at the end instead.

Otherwise:

- **It doesn't restate the shared rules.** Rounds, weak-answer tells, the Angles menu and "letting them drive" live in
  `grill-me`'s SKILL.md and are referenced, not duplicated, so the two can't drift apart.
- **"Never ask what you can read"** is the defining rule — every question spent on something greppable is one not spent
  on something only you know.
- **Questions cite `file:line`**, and the skill has to say when it's guessing at the call graph.
- **Contradictions get their own section** — where what you say and what the repo does diverge, with three named
  outcomes (your model drifted / the code is wrong / both true at different layers) and a different follow-up for each.
- **Repo-only angles**: blast radius, prior art already in the codebase, pattern fit and who migrates the old way,
  migration and rollout, test cost as a design smell, ownership via `git log`, and the smallest safely-mergeable PR.
- **It's allowed to end early.** If recon makes the answer obvious, "this is a 20-line change, go and do it" beats four
  more rounds.
