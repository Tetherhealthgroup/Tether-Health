# Helplines to verify

Four organisation helpline numbers were written into the new programmes and then
**removed before shipping**, because they could not be verified from the
environment they were written in — web access was blocked.

They are recorded here rather than left in the app. A wrong number on a health
screen is worse than no number: somebody in difficulty dials it, reaches a
disconnected line or the wrong organisation, and the screen that was supposed to
help has cost them the attempt.

## Verify, then add back

| Organisation | Number as written | Programme | Check against |
|---|---|---|---|
| American Diabetes Association | 1-800-342-2383 | GlucoseWise (metabolic) | diabetes.org |
| American Heart Association | 1-800-242-8721 | SteadyBeat (cardiovascular) | heart.org |
| American Cancer Society | 1-800-227-2345 | Worth Asking (cancer) | cancer.org |
| CDC-INFO | 1-800-232-4636 | Groundwork (preventive) | cdc.gov |

Each was recalled rather than looked up. Three are derivable from a published
mnemonic — DIABETES, AHA-USA-1 — which makes them plausible and does not make
them checked.

To restore one: confirm the number *and* its stated hours on the organisation's
own site, add it back to that product's `helplines[]` in
`assets/design/supplement.product.<area>.json`, and update the `$helplineNote`.
The support-hub copy currently points at the organisation's domain instead, so
it needs no change — but it reads better with a number.

## Still missing entirely

These programmes have no organisation line at all, because their authors could
not verify one and correctly declined to invent one. Each says so on screen.

| Programme | Line that should exist |
|---|---|
| OneChange (nutrition) | An eating-disorder support line — `disordered_eating_guard` makes this the one most worth having |
| Steady (aging) | An aging-services line, e.g. the Eldercare Locator |
| SteadyAir (respiratory) | American Lung Association Lung HelpLine |
| Longview (kidney & liver) | NKF Cares, or the American Liver Foundation |

## What was kept, and why

- **988** — Suicide & Crisis Lifeline. A fixed three-digit national code, call or
  text, English and Spanish. Already used verbatim in the shipped
  `content.lookup.en.json`, so it is the bundle's own number rather than one
  anybody here recalled.
- **911** — fixed national emergency number.
- **1-800-QUIT-NOW / 1-855-DÉJELO-YA** in SteadyAir — copied from
  `product.breathefree.json` in this repository, not recalled.

Every number that remains is one where being wrong could hurt somebody, and every
one of them came from a source in the repository rather than from memory.
