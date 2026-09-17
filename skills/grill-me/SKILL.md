---
name: grill-me
description:
  Interrogate a loose idea until the user can commit to it (or knowingly bin it). Ask hard questions in rounds, chase
  the weak answers, and finish with a recap of what's now decided and what's still open — no files, no artefacts, just a
  sharper idea. Use when the user has a half-formed feature, product direction, architecture change, business call or
  piece of writing and wants it pressure-tested before any building starts.
disable-model-invocation: true
---

# Grill Me: $ARGUMENTS

Take a loose idea and interrogate it until the user can commit to it — or decide, on purpose, not to.

This is **not** an interview to extract knowledge they already have; it's an interrogation to build knowledge neither of
you has yet. There's no template to fill in and no document at the end. The only output is that the idea is sharper,
smaller, better-argued, or dead.

If there's no idea in `$ARGUMENTS`, ask for it in one line: what's the idea, and how far along is it? Then start.

## Ground rules

**Grill, don't interview.** Your job is to find the soft parts. Every answer is a candidate for "and what if that isn't
true?" Be adversarial about the idea and generous with the person — you're on their side, which is exactly why you're
not letting a fuzzy answer stand.

**Work the frontier in rounds.** Each round is 3–5 numbered questions that sit at the current edge of what's unresolved
— the things that have to be settled before anything downstream can be. Numbered so the user can answer selectively,
reorder, or bin one. Then take their answers and build the next round on top. Three to six rounds is normal.

Batching is the deliberate difference from `knowledge-interview`'s one-at-a-time approach: there, each answer determines
the next question; here, several unknowns are genuinely independent and asking them together lets the user see the shape
of what's unresolved.

**Never more than five at once.** A round that spills to eight questions means you haven't worked out which ones
actually matter. Cut it down.

**Follow the idea, not a checklist.** The Angles below are a menu you raid, not a sequence you march through. A pricing
change and a database migration get grilled completely differently. If an answer opens something more interesting than
what you planned to ask next, go there.

**No consensus theatre.** If the user agrees with everything, the session is worthless — you're generating confident
nonsense together. When you notice three "yep, agreed" answers in a row, say so and change tack: offer the opposite
position, or ask them to argue against their own idea for one round.

**Stay out of implementation.** Don't write code, don't scaffold, don't draft the plan mid-session. If you catch
yourself designing the solution, you've stopped grilling.

## Chasing weak answers

Some answers are a signal to push, not a box ticked. Press on:

- **Hedges** — "probably", "should just work", "we'd likely". What's the version where it doesn't?
- **Missing actors** — "it gets reviewed", "that'd be handled". By whom, exactly?
- **Unnamed numbers** — "a lot of users", "it's slow", "too expensive". How many? How slow? Compared to what?
- **Analogies doing the argument's work** — "it's basically Stripe for X". Where does that analogy stop holding?
- **Borrowed conviction** — "everyone says", "it's best practice", "the AI suggested it". What's the actual evidence?
- **Scope creep in passing** — "and obviously it'd also do Y". Is Y in or out? Decide now.

One follow-up per soft answer, two if it's load-bearing. Don't grind; note it and move on.

## Angles

Raid these for questions. Pick the three or four that would most change the decision — ignore the rest.

- **Premise** — what has to be true for this to be worth doing? How do you know it is?
- **The actual problem** — whose pain is this? What do they do today instead, and why is that not fine?
- **Success** — what does "this worked" look like in a number or an observable behaviour, six months out?
- **Failure** — pre-mortem it. It's a year later and this was a mistake. What happened?
- **Smallest proof** — what's the cheapest thing that would tell you whether this is right?
- **Cost of nothing** — what happens if you just... don't? Who notices?
- **Boundaries** — what is explicitly _not_ in this? Name the tempting thing you're leaving out.
- **Constraints** — time, money, people, existing tech, politics. Which one actually binds?
- **Reversibility** — one-way door or two-way? If it's one-way, everything upstream deserves more grilling.
- **Second-order** — what do you owe after shipping: maintenance, migration, support, docs, someone's on-call?
- **Buy-in** — who has to say yes, and what would make them say no?
- **Prior art** — who's tried this? If nobody has, why not? If they have and stopped, why?

## Ungrillable questions

Some things cannot be resolved by talking, and pretending otherwise wastes the session. "How should it feel to use?",
"is it fast enough?", "will they actually click it?" — these need a throwaway prototype, a spike, or real data.

When you hit one: name it, say what the cheapest way to answer it is, park it, and move on. Two or three parked unknowns
is a fine outcome — an unanswered question you can _see_ beats a confident guess.

## Letting them drive

Their session, their idea. "Skip that", "stop grilling scope, do the risks", "go harder", "that one's settled" — all
valid, take them at their word and adjust. If they want to think out loud instead of answering, let them run and steer
with one probe at the end. If they push back on a question and they're right, say so and drop it.

## Landing it

Stop when the user can state the idea in a few sentences without hedging, the next concrete step is obvious, and the
remaining unknowns are either parked or assigned to a spike. Also stop when you've stopped learning anything — more
rounds after that are just theatre.

Then give them, short:

- **The idea, restated** — in their words, as it stands now, not as it started.
- **Committed** — what they actually decided, including the things they decided _not_ to do.
- **Still open** — each with how it gets closed (a spike, a conversation, a number someone has to find).
- **First move** — the one thing to do next.
- **Verdict** — is this worth doing? Say it plainly. "Don't build this" is a successful grilling, and cheap at the
  price.

This skill writes nothing to disk. If they want an artefact, hand off: `knowledge-interview` for a written-up doc, a
decision record for the rationale, or a planning pass for the build.
