# tether_ui (Flutter)

Generated screens + hand-written component kit for the Tether Health app.

- `lib/ui/components.dart` — every UI component (TScreen, TSheet, TCard, TButton, TChips, TField, charts…). Own this file.
- `lib/ui/tokens.dart` — colors, type, spacing, radius, motion (mirrors `../design/tokens.json`).
- `lib/ui/nav.dart` — the only place actions are implemented: `TNav.push/replace/tab/reset/back/close/sheet/call/sms/external/osSettings/toast/submit/branch`, plus the `TPlatform`, `TApi` and `TNav.branchResolver` hooks for production wiring.
- `lib/router/` — `Routes` constants and `AppRouter` (generated).
- `lib/screens/<flow>/<id>_screen.dart` — one widget per screen and state (generated). Each file’s doc comment lists its route, state, actions and API.
- `lib/dev/gallery.dart` — gallery of every screen; default start screen.

```bash
flutter pub get
flutter run                                # gallery
flutter run --dart-define=START=/welcome   # real first run
flutter analyze                            # no issues
flutter test                               # every screen at 100% + 130% text, plus end-to-end journeys
```

Regenerate after spec changes: `cd ../generator && python3 build_all.py`. Generated files are overwritten; move a screen out of `lib/screens/` if you want to own it by hand.
