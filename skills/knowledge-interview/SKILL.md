---
name: knowledge-interview
description:
  Extract knowledge that lives in someone's head and turn it into documentation by interviewing them — one question at a
  time — and then drafting the doc in the right structure for them. Use this whenever the user wants to document
  something, write up how a system/process/decision works, "get something out of my head", brain-dump a topic, onboard
  others, or says they have the knowledge but don't know how to structure it or fit it in a single prompt. Trigger on
  phrases like "interview me about X", "help me document X", "I need to write up how Y works", "write docs for Z", or
  any request where the user clearly holds the knowledge and the hard part is eliciting and organising it rather than
  researching it.
---

# Knowledge Interview

Turn tacit knowledge (what's in the user's head) into a clear document, by **interviewing them**, then **drafting the
doc** in a structure that fits the material.

The user has the knowledge. They usually don't know the best way to structure the doc, and they can't dump it all in one
prompt — that's exactly why this skill exists. Do the structuring and the eliciting for them.

## The one rule that matters most

**Ask one question at a time.** A single, focused question, then wait for the answer.

Batching five questions feels efficient but wrecks the interview: the user answers the easy ones, skims the hard ones,
and you lose the thread to follow up on the interesting bits. A real expert interviewer asks one thing, listens, and
pulls the next question out of the answer. Do that. Resist the urge to dump a questionnaire.

The exception is the very first framing step below, where two or three quick scoping questions up front save time.

## Workflow

### 1. Frame the session (fast)

Establish three things, then move straight into the interview:

- **Topic** — what are we documenting?
- **Reader** — who reads this, and what should they be able to _do_ after reading it? ("A new engineer who needs to
  deploy this safely" produces a very different doc from "future me, six months from now, debugging an incident.")
- **Doc type** — pick the shape that fits (see Document structures below). State your pick and why; don't ask
  permission. The reader answer usually decides it. If the reader is genuinely unclear, ask that one question. Otherwise
  state your assumption and proceed — don't stall on small decisions. Keep this step to a sentence or two of framing,
  then ask question 1.

### 2. Interview

Run an adaptive interview against the coverage checklist for the chosen doc type (listed in Document structures). Track
what's covered in your head and steer toward the gaps.

**Sequencing:**

- Start broad, then drill. "Walk me through X end to end" before "what's the retry behaviour on step 3".
- Build each question on the previous answer. If they mention a component, a tool, or a decision in passing, that's your
  next thread.
- Move on once a topic is solid; don't grind. Aim for roughly 8–15 substantive questions for a normal doc, not fifty.
  **What to dig for** — these are the things that live in heads and never make it into docs:

- **The why.** Rationale behind decisions is the highest-value, least-documented knowledge. "Why this and not the
  obvious alternative?"
- **Tacit knowledge.** "What would a new joiner get wrong here? What do you know that isn't written down anywhere?"
- **Failure modes.** "What breaks? How do you know it broke? What do you do about it?"
- **Concrete examples.** Pull abstractions down to specifics: "Tell me about the last time this happened" beats
  "describe the general case."
- **Boundaries.** What this explicitly does _not_ cover, and where the edges are. **Chase vagueness.** When an answer is
  hand-wavy — "it usually just works", "we normally do X" — that's a signal, not a stopping point. "Usually" implies
  "sometimes not": ask about the exception. Surface unstated assumptions and confirm them.

**Don't waste questions.** Skip anything you can look up, anything already answered, and anything the reader wouldn't
care about. The user's time is the scarce resource.

**Keep questions short and answerable.** One concrete thing. If you catch yourself writing three sentences of setup
before the question, cut it.

### 3. Reflect periodically

Every handful of questions, play back a tight summary of what you've got and name the gaps you still want to fill: "So
far I have A, B, C. Still fuzzy on D and the failure path for E — let's do those next." This confirms you understood
correctly and lets the user correct framing or add things you didn't think to ask. It also shows progress.

### 4. Draft the doc

When the checklist is covered and follow-ups stop yielding new information, stop interviewing and write, using the
template for the chosen type (below).

- Match the user's stated communication style (concise, opinionated, code blocks for code, KISS — don't pad).
- Use their words and examples; don't launder their voice into generic doc-speak.
- Where a gap remains, leave an explicit `> TODO:` marker rather than inventing an answer or quietly omitting it. A
  flagged hole is useful; a confident fabrication is dangerous.
- Default to a Markdown file unless they asked for another format.

### 5. Review pass

After drafting, give a short list of: what's still marked TODO, anything you inferred rather than heard directly (so
they can correct it), and any section you suspect is thinner than it should be. Then offer to do another short round of
questions on the weak spots or to ship it as-is.

## Letting the user drive

This is their session. If they say "skip ahead and draft it now", do it — fill what you can and mark the rest TODO. If
they want to free-associate instead of answering questions, let them, and steer with the occasional probe. If they
correct your framing, take the correction and adjust the checklist. The structure here serves the interview; it isn't a
script to force them through.

## A note on sensitive data

Interviews about real systems can surface secrets, customer data, or PII. Don't solicit credentials, customer records,
or personal data — document the _shape_ of things ("an API key from KMS", "the user's NI number") rather than capturing
real values. If the user volunteers a real secret, note it shouldn't go in the doc and reference a secret store instead.

---

# Document structures

Pick the type that fits what the reader needs to _do_. Many docs are a hybrid (e.g. an architecture overview with a
runbook section); compose rather than force-fit. Each type gives a **coverage checklist** (what to make sure the
interview pulls out) and a **template** (how to lay the doc out).

Quick selector:

| Reader needs to…                                          | Type                  |
| --------------------------------------------------------- | --------------------- |
| Understand how a system fits together                     | Architecture overview |
| Do a specific operational task / recover from an incident | Runbook               |
| Understand _why_ a choice was made                        | Decision record (ADR) |
| Accomplish a task step by step                            | How-to guide          |
| Build a correct mental model of a concept                 | Explainer             |
| Get productive on a team/codebase                         | Onboarding doc        |
| Look up exact behaviour/contract                          | Reference             |

## Architecture overview

**Coverage checklist:** the problem it solves · major components and their responsibilities · how data/requests flow
through · the key technology choices and _why_ · the boundaries (what's in scope vs external) · failure modes and how
they're handled · the non-obvious bits a newcomer would misread.

**Template:**

```markdown
# [System] architecture

## What it does and why it exists

## High-level shape

(components + how they fit; a diagram or ASCII sketch if it helps)

## Key flows

(walk the main request/data path end to end)

## Design decisions

(the choices that matter, each with its rationale and the alternative rejected)

## Boundaries & dependencies

(what's ours, what's external, what we assume)

## Failure modes & operations

(what breaks, how you'd know, what to do)

## Gotchas

(the things that surprise people)
```

## Runbook

**Coverage checklist:** when you run this · prerequisites/access needed · exact steps in order · how to verify each step
worked · what the failure looks like and how to recover · who/what to escalate to · rollback path.

**Template:**

```markdown
# Runbook: [task / incident]

## When to use this

## Prerequisites

(access, tools, context you need before starting)

## Steps

1. [action] → expected result: [...]
2. ...

## Verifying success

## If it goes wrong

(symptom → cause → fix, and the rollback path)

## Escalation
```

## Decision record (ADR)

**Coverage checklist:** the decision · the context/forces that made it necessary · options considered · why the chosen
one won · what was traded away · consequences and follow-ups. The rationale is the whole point — dig hardest here.

**Template:**

```markdown
# ADR: [decision]

## Status

(proposed / accepted / superseded)

## Context

(the situation and constraints that forced a choice)

## Options considered

(each with its real trade-offs, not strawmen)

## Decision

(what we chose and the deciding reason)

## Consequences

(what this makes easy, what it makes hard, what we now owe)
```

## How-to guide

**Coverage checklist:** the goal · starting assumptions · ordered steps · a worked concrete example · common mistakes ·
how to confirm it worked.

**Template:**

```markdown
# How to [accomplish goal]

## Before you start

(assumptions, prerequisites)

## Steps

(numbered, imperative, one action each)

## Worked example

(a real, concrete run-through)

## Common mistakes

## Confirming it worked
```

## Explainer (concept / mental model)

**Coverage checklist:** the core idea in one sentence · the problem it addresses · the right mental model / analogy ·
how it actually works · where the analogy breaks down · common misconceptions.

**Template:**

```markdown
# Understanding [concept]

## In one sentence

## The problem it solves

## How to think about it

(the mental model; an analogy if one genuinely helps)

## How it actually works

## Where the simple model breaks down

## Common misconceptions
```

## Onboarding doc

**Coverage checklist:** what the team/system owns · the map (repos, services, key people, where things live) · how to
get set up · the first useful thing a newcomer should do · the team's conventions and unwritten rules · who to ask about
what.

**Template:**

```markdown
# Getting started with [team / area]

## What we own and why it matters

## The map

(repos, services, dashboards, docs — where everything lives)

## Getting set up

## Your first task

(something real and low-risk to build confidence)

## How we work

(conventions, ceremonies, unwritten rules)

## Who knows what
```

## Reference

**Coverage checklist:** every item documented uniformly · exact inputs/outputs/contracts · defaults and constraints ·
edge-case behaviour · stable structure that's easy to scan and `Ctrl-F`.

**Template:**

```markdown
# [Thing] reference

## Overview

(one paragraph; point to an explainer for the "why")

## [Item]

- Signature / shape:
- Parameters / fields:
- Returns / behaviour:
- Constraints & defaults:
- Edge cases: (repeat uniformly per item)
```
