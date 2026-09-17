# knowledge-interview

Gets knowledge out of your head and into a document by interviewing you — one question at a time — then drafts the doc
in whichever shape fits the material.

See [`SKILL.md`](./SKILL.md) for the skill itself.

## Use it for

- The thing only you know how to do, that nobody has ever written down.
- A runbook before you go on holiday, or before you hand a system over.
- An ADR for a decision that's already been made and is living in your memory and a Slack thread.
- Onboarding docs for a team or an area, where you know the material but not the structure.
- Any "I could write this up but I don't know where to start, and it won't fit in one prompt".

It's the mirror image of [`grill-me`](../grill-me): that one interrogates an idea nobody has worked out yet, this one
extracts what you already know. If you find yourself unsure which you need — if you _had_ the answer you'd be
documenting it, so start here.

## Example

```text
/knowledge-interview how the exam timer resync works

Reader sounds like a new engineer debugging it at 2am, so: runbook, with an
explainer section up front for the clock model.

Q1. Walk me through what happens, end to end, when a learner refocuses the tab
    after 20 minutes away.

> [answer]

Q2. You said it "usually" recovers. What's the case where it doesn't?

> [answer]

Q3. If a new joiner touched this, what would they get wrong first?
```

Two things keep it useful: one question at a time (so it can follow the interesting thread in your answer instead of
handing you a questionnaire), and chasing every "usually" and "it just works" — those words are where the undocumented
knowledge actually lives. Gaps you can't fill come out as explicit `> TODO:` markers, never as invented answers.
