// Regression — the tab bar silently stealing the primary action's touch area.
//
// On screens 13-21 the "Continue" target ran from 0.72 to 0.89 while the tab
// bar starts at 0.875. The tab bar is added to the Stack later and so won the
// hit test, taking the lowest 0.015 of the primary action. Nothing looked
// wrong: the control was drawn in full and a tap near its bottom edge
// navigated somewhere else entirely.
//
// The fix bounds a primary action on a tab-bar screen at the tab bar's own
// top edge, both reading one `_tabBarTop` constant so the two cannot drift.
// These tests assert the invariant rather than the constant, so they keep
// holding if the layout moves.

// The general "no two targets overlap" invariant is asserted in
// test/unit/contact_routes_unit_test.dart, which deflates each rectangle
// before comparing — adjacent tabs share an edge, and 0.40 + 0.20 evaluates
// to 0.6000000000000001 in binary floating point. What belongs here instead
// is the specific relationship the defect broke: a primary action and the tab
// bar that sits under it.

import 'package:tether_health/models/tap_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a primary action on a tab-bar screen stops above the tab bar', () {
    // Screens 13-21 are the ones that carry both a Continue target and the
    // tab bar — the exact set the defect affected.
    for (var number = 13; number <= 21; number++) {
      final targets = tapTargetsFor(number - 1);
      final primary = targets.firstWhere(
        (t) => t.label == 'Continue to the next step',
        orElse: () => throw StateError('screen $number has no primary action'),
      );
      final tabs = targets.where((t) => t.label.endsWith(' tab')).toList();

      expect(tabs, isNotEmpty, reason: 'screen $number has no tab bar');
      final tabTop = tabs.map((t) => t.normalizedRect.top).reduce(
            (a, b) => a < b ? a : b,
          );

      expect(
        primary.normalizedRect.bottom,
        lessThanOrEqualTo(tabTop),
        reason: 'on screen $number the primary action reaches '
            '${primary.normalizedRect.bottom} but the tab bar starts at '
            '$tabTop, so the overlap is unreachable',
      );
      // The control must still be big enough to be a comfortable target.
      expect(
        primary.normalizedRect.height,
        greaterThan(0.05),
        reason: 'screen $number: bounding the primary action left it '
            '${primary.normalizedRect.height} high',
      );
    }
  });

  test('a screen with no tab bar keeps the full-height primary action', () {
    // Screens 1-11 have no tab bar, so nothing should be trimmed there.
    for (var number = 2; number <= 11; number++) {
      final primary = tapTargetsFor(number - 1)
          .firstWhere((t) => t.label == 'Continue to the next step');
      expect(
        primary.normalizedRect.height,
        closeTo(0.17, 0.0001),
        reason: 'screen $number has no tab bar and should not be trimmed',
      );
    }
  });
}
