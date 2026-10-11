TETHER HEALTH — ALL CONTENT
Exported October 6, 2026

WHAT'S IN THIS PACKAGE
======================

design/
  tether-health-design-specification.pdf
      The 821-page production design specification for the Tether Health
      app — all 11 programs (BreatheFree, Steady, WithYou, Heartwise,
      Nourish, ClearAir, Balance, SteadyMind, Ahead, Everwell, Present).
  tether-health-ui-manifest.json
      Machine-readable manifest of the UI spec (routes, screens).
  tether-health-spec-navigator.md
      One-page map: which page each program's plan and screen contracts
      start on in the PDF.

simulator/
  tether-health-ui-simulator.html
      Self-contained, JSON-driven interactive simulator — open in any
      browser, tap through all 706 screens including multi-program mode
      (merged Today view, batched check-in, per-program rescue routes).

json-spec/
  Tether Health UI JSON Specification.json
      The complete 706-screen Flutter-oriented UI contract: widget
      mappings, routes, button destinations, state effects, loading /
      error / offline states, privacy, accessibility, and acceptance
      criteria. Built for Dart/Flutter + Claude implementation.

code-develop/
      Full snapshot of the Tether-Health repo's `develop` branch —
      includes the 6-area code improvements (BreatheFree fixes plus the
      new Heartwise/cholesterol+hypertension, Steady/diabetes, and
      ClearAir/asthma modules with tests).

code-unplug/
      Full snapshot of the `veera/unplug-improvements` branch — the
      social-media-addiction (Present/unplug) module improvements, kept
      separate from PR #23.

NOTE
====
The code was hand-verified but not compiled in the build sandbox
(no Flutter tooling there). Run `flutter analyze` + `flutter test`
on a dev machine before merging or releasing.
