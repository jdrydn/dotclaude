# grill-me

Takes a loose idea and interrogates it in rounds until you can commit to it — or decide, deliberately, not to. Writes
nothing to disk; the only output is a sharper idea.

See [`SKILL.md`](./SKILL.md) for the skill itself.

## Use it for

- A one-line idea from a stakeholder that everyone's nodding along to and nobody has interrogated.
- Build vs buy, or "should we even do this" — before anyone's written a ticket.
- An architecture change you're 60% convinced by and can't work out why the other 40% is nagging.
- A product or business call where the trade-off is real and the options are all defensible.
- Writing — a talk, a post, an RFC intro — where the argument isn't load-bearing yet.

Not for: anything you can already specify precisely. If you can write the ticket, write the ticket.

## Example

```text
/grill-me we should let learners resit a mock exam as many times as they want

Round 1
1. What's driving this — learners asking, or a retention number someone showed you?
2. What happens today when they want a second go? Hard-blocked, or just awkward?
3. "As many as they want" — what breaks first at 50 attempts: cost, the question pool,
   or the credibility of the score?
4. Who currently has to say yes to a resit, and what would they say about removing that?

> 3 is the one — we've only got 60 questions per paper
> 4 nobody, it's automatic

Round 2
1. So by attempt 4 they're mostly seeing repeats. Does a mock lose its point once the
   questions are familiar, or is the repetition the actual learning?
2. If it's the former, is the real ask "unlimited resits" or "more questions"?
3. Who writes new questions, and how long does one take to get approved?
```

Four rounds later the idea was "raise the cap from 1 to 3 and commission 40 more questions per paper" — smaller,
cheaper, and the thing that was actually wanted.

## Attribution

The idea is **not mine**. It's lifted from [`/grill-me`](https://www.aihero.dev/skills-grill-me) by
[Matt Pocock](https://github.com/mattpocock), part of his skill collection at
[`mattpocock/skills`](https://github.com/mattpocock/skills) (MIT, © 2026 Matt Pocock). If you want the original —
maintained, battle-tested, and part of a larger system that includes `grill-with-docs`, `wayfinder`, `triage` and
friends — install that instead:

```sh
npx skills@latest add mattpocock/skills
# or
claude plugins install mattpocock-skills
```

## What's actually in this folder

An independent reimplementation, written from Matt's public write-up of the skill rather than from his source. The
concept is his; the prompt text here was written from scratch and no wording was copied from the original. Any part of
it that works well is his idea, and any part that doesn't is mine.

## Where it diverges

- **Deliberately paired with [`knowledge-interview`](../knowledge-interview).** That skill extracts knowledge you
  already have into a document, one question at a time, against fixed doc templates. This one builds knowledge nobody
  has yet, in batched rounds, with no template. `grill-me`'s SKILL.md names that contrast directly, so the split stays
  obvious.
- **Rounds are capped at five questions**, numbered, so they can be answered selectively — a round that needs eight
  means the questions haven't been prioritised.
- **An explicit "chasing weak answers" section** — hedges, missing actors, unnamed numbers, analogies doing the
  argument's work, borrowed conviction, scope smuggled in with "and obviously it'd also…".
- **"No consensus theatre" is a hard rule**, not a warning: three agreements in a row and the skill has to say so and
  argue the other side.
- **Landing it ends with a plain verdict**, including "don't build this" as a successful outcome, then hands off to
  `knowledge-interview` or an ADR skill rather than producing an artefact itself.
