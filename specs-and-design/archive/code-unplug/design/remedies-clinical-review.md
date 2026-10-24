# Remedies — what is in, what is out, and why

`assets/design/supplement.remedies.json` holds six practices. They are the same
in all eleven programmes, and that is a clinical decision rather than a
shortcut.

## The rule

**A remedy ships only if it is safe for anybody, in any programme, with any
combination of the eleven conditions.**

The app does not know who is reading it. Somebody in the kidney & liver
programme may be on a fluid restriction. Somebody in cardiovascular may have
unstable angina. Somebody in nutrition may have an eating disorder — the
`disordered_eating_guard` safeguard exists for exactly that. A library that
filtered advice by programme would still be wrong, because people are in more
than one programme and because a condition somebody has not enrolled in is
still a condition they have.

So there is no `areaId` on `Remedy`, and `test/tether_remedies_test.dart`
asserts there is nothing that looks like one.

## What shipped

| Remedy | Timed | Stop rule |
|---|---|---|
| Slow your breathing | 5 min | dizziness; breathless at rest |
| Get back in the room | 3 min | thoughts of self-harm → 988 |
| Wait it out | 15 min | physical withdrawal symptoms |
| Wind down for sleep | — | signs of a sleep disorder |
| Write it down before you go | — | none — it has no failure mode |
| Move for two minutes | 2 min | cardiac and syncope symptoms → 911 |

Every timed remedy carries a stop rule, and a test enforces that: a clock asks
somebody to keep going for a set period, which is the moment they override
their own body.

`appointment_prep` deliberately has no warning. Inventing one would teach people
to skim the warnings that matter.

## What was deliberately left out

These are the obvious per-condition remedies, and each is genuinely dangerous
to somebody in the population this app serves.

| Not shipped | Who it harms |
|---|---|
| Fluid intake targets ("drink more water") | Fluid-restricted dialysis and heart-failure patients |
| Dietary rules, carbohydrate counting, portion targets | Eating-disorder risk; renal and hepatic diets conflict |
| Activity or step targets | Unstable angina, recent cardiac events, severe COPD |
| "Check your reading when you feel off" | Reinforces checking behaviour; substitutes for a clinician's thresholds |
| Anything about medication — timing, splitting, skipping, restarting | Prescribing. `product.glucosewise` states outright that the app "will never tell you what to take" |
| Herbal and supplement remedies | Interactions, hepatotoxicity, no regulatory footing |
| Breathing techniques for breathlessness (pursed-lip, huff cough) | Respiratory-specific; needs a clinician to teach and to rule out acute causes |

## To add a condition-specific remedy

It needs all four:

1. A named clinician who has reviewed the text and accepts it for that
   programme's population.
2. A source with a date — a guideline, not a recollection. Nothing in this app
   should be written from memory; see `design/helplines-to-verify.md` for what
   happened when four phone numbers were.
3. A contraindication list, and a mechanism to act on it. Today there is none:
   the library has no per-person gating, so "safe unless X" cannot be expressed
   and must not be faked with a sentence somebody can scroll past.
4. A stop rule in the person's own language.

Until 3 exists, condition-specific remedies stay out of the app, and the
`no remedy is bound to a program` test is the thing that keeps that true.

## Provenance

Authored in this repository. **Not clinically reviewed.** Not from
`files/tether-design.zip`. The six practices are widely published
self-management techniques rather than novel advice, which makes them plausible
and does not make them reviewed.
