# BreatheFree Screen 20 Implementation

This package starts from the clean Screen 19 project checkpoint and adds the functional Screen 20 Craving Recheck implementation.

## Included

- `lib/screens/craving_recheck_screen.dart`
  - Functional 0–10 craving recheck
  - Slider and tappable number scale
  - Required rating before saving
  - Before/now comparison
  - Patient-reported, non-clinical wording
  - Optional rescue helpfulness feedback
  - Stronger-support message for ratings 7–10
  - English/Spanish UI
  - Repeat rescue action

- `lib/screens/approved_screen_player.dart`
  - Wires Screen 20 into the functional flow
  - Preserves the pre-rescue craving rating
  - Stores the recheck rating and helpfulness selection
  - Save → Screen 21
  - Repeat → Screen 19

- `test/widget_test.dart`
  - Screen 20 rendering
  - Required rating behavior
  - Before/after update
  - Helpful feedback
  - Save/navigation
  - Repeat rescue
  - Supported phone sizes

## Validation to run on the Mac

From the project folder:

```bash
flutter analyze
flutter test
```

Then test Screen 20 on the iPhone.

This package has not been run through Flutter tooling in this environment; the existing project files were preserved and the new code was checked for balanced Dart delimiters before packaging.
