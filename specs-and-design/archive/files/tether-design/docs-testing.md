# Testing the flow before implementing

Five tests, cheapest first. Each has a pass condition. Stop and fix before building
anything native — the intercept alone is three separate implementations.

---

## 1 · Cold read (30 minutes, alone)

Open the prototype and click every button. You are looking for structural faults, not
opinions.

Pass when: no dead ends, no screen with two competing primary actions, every screen
reachable from `/today` in three taps or fewer, and the back button never traps you.

The generator reports dead ends in the coverage panel. Fix the JSON, regenerate.

---

## 2 · Timed task test (5 people, 20 minutes each)

Give the task, say nothing else, and read the trace afterwards. Do not explain the app.

| Task | Pass condition |
|---|---|
| "You feel the pull to scroll. Deal with it." | Reaches a running tool in under 15 seconds, without you prompting |
| "You went way over last night. Tell the app." | Reaches the slip screen and does not say anything self-critical while doing it |
| "Find out what the app shares with your coach." | Finds it in under 60 seconds |
| "You need to talk to a person right now." | Reaches the crisis card without scrolling past anything |

Hold the phone yourself and hand it over. One-handed, standing up. The rescue flow was
designed for someone in bed at 11pm, not someone at a desk.

**The trace panel timestamps every tap.** If task one takes longer than 15 seconds, the
problem is structural, not copy.

---

## 3 · The interruption test (3 days, 3 people)

This is the one that matters, and the one a lab cannot give you. The prototype cannot
block apps — but you can fake the moment.

Set a phone automation to open the prototype at `S22` at random times over three days:
iOS Shortcuts personal automation, or Android Tasker. Ask the tester to respond honestly
each time, then note one line about what they were actually doing.

You learn three things nothing else will tell you:
- whether the 8-second breath is tolerable when someone genuinely wanted the app
- whether the two-button shield is enough, or whether people want a third way out
- how often the intercept fires at a genuinely wrong moment

Pass when: at least half of the intercepts end in "do something else instead", and no
tester asks to stop the study early.

If people rage-quit, the friction is too high — that is a much cheaper thing to learn
now than after three native implementations.

---

## 4 · Safeguard tabletop (90 minutes, with a clinician)

Walk the clinician through the prototype with `data/safeguards.json` open. For each
safeguard, ask: where in this flow could it be violated?

Specific things to press on:
- Does anything on the check-in screen read as a diagnosis?
- Is the crisis card genuinely first, always, on every path into support?
- Where does a distress signal go on the coach track, and who is accountable?
- Does the slip screen ever reset a number?
- Would the lock-screen notification copy reveal anything in a shared household?

Pass when the clinician signs off on the escalation policy in writing. That is the item
most likely to block release later.

---

## 5 · Spanish read (1 bilingual reviewer)

Generate `lookup.es.json` and run the same prototype. Long compounds break layouts —
check every button and badge at the longest translation.

Pass when: no truncation at 320px width, and the crisis helpline text is correct for
Spanish-language callers rather than a literal translation.

---

## Regenerating

    python3 tools/prototype.py lookup en > prototype.html

Change the JSON, regenerate, retest. The prototype is disposable; the JSON is the asset.

## What the prototype deliberately cannot do

- Block a real app. Only the OS can. See test 3 for the workaround.
- Show real usage numbers. Everything is fixture data.
- Prove the iOS shield fits. Apple allows two buttons; check every intercept variant
  collapses to two before designing a third.
