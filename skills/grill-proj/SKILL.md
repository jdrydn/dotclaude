---
name: grill-proj
description:
  Interrogate an idea with the codebase in the room — read the repo first, then ask only the questions the code can't
  answer, and put what the user says side by side with what the repo actually does. Use when the user wants to
  pressure-test a change against an existing project - a refactor, a migration, a new feature in a repo that already has
  opinions.
disable-model-invocation: true
---

# Grill Proj: $ARGUMENTS

`/grill-me`, with the repository in the room.

Everything in `~/.claude/skills/grill-me/SKILL.md` applies unchanged — the rounds of 3–5 numbered questions, the
weak-answer tells, the Angles menu, no consensus theatre, letting the user drive, and writing nothing to disk. Read it
and follow it. What's below is only what's different when there's real code to grill against.

If `$ARGUMENTS` names a path or an area, scope the recon to it. If it's a bare idea, work out which part of the repo it
lands in and confirm that in one line before starting. If there's no repo here, or the idea doesn't touch code, say so
and use `grill-me` instead.

## 1. Recon before round one

Read first. Time-box it — you're building enough of a model to ask sharp questions, not reviewing the codebase.

- The shape: `README`, `CLAUDE.md`, package scripts, the directory tree.
- The code the idea lands in, and its callers.
- The tests around it. Tests encode intent, and every edge case in them is a problem someone already hit.
- `git log` and `git blame` on the target area — why it looks like this, and how much it's been churning.
- Any ADRs, docs or `TODO`/`FIXME` comments in that area. Those are unfinished arguments; they're free questions.

Then say what you read in two lines and start. Don't narrate a guided tour of the codebase — they wrote it.

## 2. Never ask what you can read

This is the whole point of the variant. "What does the job queue use?" is a question you answer yourself in ten seconds.
Every question spent on something readable is one you didn't spend on something only they know.

Spend the questions on what isn't in the repo: intent, constraints, history, what they tried and abandoned, what they'd
do differently, what's coming next, and which trade-offs they actually accept.

## 3. Ground every question in evidence

Cite `file:line`. "Retries are capped at 3 in `src/queue/worker.ts:88` — deliberate, or is that a number someone typed
in 2022?" A grounded question gets a better answer and lets them correct you immediately when your reading is wrong.

Say when you're guessing. "I think X and Y are the only callers — is there a path I've missed?" beats asserting it.

## 4. Contradictions are the best material

When what they say and what the repo does diverge, that's the highest-value moment in the session. Don't smooth it over,
don't assume you misread. Put the two side by side and ask which one is true.

Usually it's one of three things, and they need different follow-ups:

- **The code drifted** — their mental model is a year out of date. What else has drifted?
- **The code is wrong** — you've just found a bug together. Is it in scope, or a separate ticket?
- **Both are true** — you're looking at different layers, or a special case they'd forgotten. Get the boundary named.

Also worth hunting: the abstraction they describe that doesn't exist, the "we always do it this way" with three
counter-examples in `src/`, and the module they think is live that nothing imports.

## 5. Angles that only exist with a repo

On top of `grill-me`'s menu:

- **Where it lands** — which files and modules actually change? Make them be specific.
- **Blast radius** — callers, consumers, tests, other services or repos. What breaks that isn't in this repo?
- **Prior art in here** — has someone already built 80% of this? Go and grep before you ask.
- **Pattern fit** — does this match how the codebase already does things, or add a second way of doing it? If it's a
  second way, is that deliberate, and who's migrating the first?
- **Migration & rollout** — existing data, in-flight work, backwards compatibility, flag or big bang.
- **Test cost** — what has to change in CI, and is that cost telling you something about the design?
- **Ownership** — who wrote this area (`git log`), and who has to approve the change?
- **The reversible slice** — what's the smallest PR that's safe to merge on its own?

## 6. Read, don't write

Reading, grepping and blaming: yes. Editing, scaffolding, branching, "let me just sketch it": no. If you catch yourself
writing the change, you've stopped grilling.

If recon makes the answer obvious, end the session early and say so — "this is a 20-line change in one file, go and do
it" is a better outcome than four rounds of theatre.

## Landing it

The same recap as `grill-me` — restated idea, committed, still open, first move, plain verdict — plus two lines only
this variant can give:

- **Lands in** — the files and modules that actually change.
- **Blast radius** — the callers, tests and consumers you found, and anything you're not sure about.

Then hand off rather than sprawling. A decision that's hard to reverse and has real trade-offs wants an ADR — offer
`local-bpp-write-adr`. A body of explanation wants `knowledge-interview`. A build wants a planning pass. This skill
still writes nothing to disk.
