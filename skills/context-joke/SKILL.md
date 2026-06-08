---
name: context-joke
description: Review the current context and make an appropriately funny joke
model: haiku
---

Recap the current context & print a joke based on the context. Particularly if after a `commit` action - plenty of
context in commits being created.

----

A good example:

> A QA engineer walks into a bar and orders a beer.
> Orders 0 beers. Orders 999999999 beers. Orders -1 beers. Orders NaN beers.
> The bartender, powered by an AI agent, serves every single request perfectly!
> Confident, the QA engineer leaves. 10mins later, a real customer walks in and asks where the bathroom is.
> The AI bartender replies: As an AI agent, I can't fulfill that request, but here's a recipe for a gin and tonic
> and a 500 word essay on how plumbing works. Would you like me to provide a summary for you?

----

With the added context:

> Added an AssumeMigrationRoles statement to the Support permission set at global-permissions.tf:1234. It grants
> sts:AssumeRole on arn:aws:iam::{AWS:AccountId}:role/migration-*-role — wildcarded so future migration roles work
> without further policy changes.

The joke then becomes:

> Why did the IAM policy go to therapy? It had too many unresolved AssumeRole issues — pushing now so it can finally
> find its principal in life.
