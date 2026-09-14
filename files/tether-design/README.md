# Tether design data

Ten health areas, one set of shared machinery. This encodes the strategy already on the
site — *build the machinery once, then shape it to each area* — as data rather than as
twenty-eight hand-written specs per product.

    tools/validate.py          run before every commit

## Three layers, deliberately separate

**1. Catalogue — `data/areas.json`**
The ten areas, forty-one service lines, their status, what each one measures, and which
safeguards apply. This mirrors what the website publishes. It changes when strategy
changes, which is rarely.

**2. Machinery — `data/archetypes.json`**
Twenty-three reusable screen archetypes: welcome, consent, baseline, plan, check-in,
rescue, lapse, progress, support hub, settings. Each names its purpose, its slots, and
what it cannot ship without.

**This is the layer that pays for itself.** Twenty-three of twenty-six archetypes are
already shared between two products. Improve the lapse screen once and every area that
has lapses inherits it — cessation, nutrition, digital overuse, activity.

**3. Products — `data/products/*.json`**
Thin. A product is an area, a vocabulary, a screen list, and its helplines. BreatheFree
is 40 lines. Most of a product's design lives in the archetypes it borrows.

## Constraints are data too — `data/safeguards.json`

Twenty safeguards with explicit `requires` and `forbids` lists. `no_dosing_advice`
forbids a dose calculator. `crisis_routing_first` requires the crisis card to be pinned
first. `slip_never_resets` forbids zeroing a counter on a lapse.

These are the rules most likely to be quietly violated by someone shipping fast, so
they are machine-checkable rather than living in a document nobody rereads.

## Adding an area

1. Add it to `data/areas.json` with its service lines, measures and safeguards.
2. Map each service line to existing archetypes. Most will already fit.
3. Anything that doesn't fit goes in the product's `proposedArchetypes` — and must name
   which *other* areas could reuse it. That test is what stops the shared library
   fragmenting into ten bespoke products.
4. Run `tools/validate.py`.

## Current state

    10 areas · 41 service lines · 23 archetypes · 20 safeguards · 2 products
    3 proposed archetypes awaiting promotion: age_gate, intercept, environment

`intercept` is the one that may never generalise — it only works where the trigger
lives inside the device. That is worth knowing before it is built into the shared layer.
