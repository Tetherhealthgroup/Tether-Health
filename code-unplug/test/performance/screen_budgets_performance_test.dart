// Performance — budgets for the work that repeats.
//
// Two things here run far more often than they look. `tapTargetsFor` is called
// from the screen player's build, so it runs on every frame that rebuilds, and
// its result is walked once per hit test. And a session navigates: the back
// history grows for as long as the app is open.
//
// The budgets are deliberately loose. A tight time budget on a shared CI
// runner fails for reasons that have nothing to do with the code, and a test
// that fails spuriously gets ignored. These are set to catch an order-of-
// magnitude regression — a linear walk becoming quadratic, or a const list
// becoming a rebuild — not to measure milliseconds.

import 'package:tether_health/main.dart';
import 'package:tether_health/models/screen_spec.dart';
import 'package:tether_health/models/tap_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolving every screen\'s tap targets stays inside a frame budget', () {
    // 60fps is 16.6ms for everything. Target resolution is a small slice of a
    // build, so 200 full passes over all 28 screens must stay well under a
    // second; if it does not, resolution is no longer the cheap lookup the
    // build path assumes.
    final stopwatch = Stopwatch()..start();
    for (var pass = 0; pass < 200; pass++) {
      for (var index = 0; index < approvedScreens.length; index++) {
        tapTargetsFor(index);
      }
    }
    stopwatch.stop();

    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(1000),
      reason: '200 passes over 28 screens took '
          '${stopwatch.elapsedMilliseconds}ms — target resolution is no '
          'longer cheap enough to sit in build()',
    );
  });

  test('no screen carries so many targets that hit testing walks a crowd', () {
    // Every tap walks this list. Measured maximum is 13, on screen 27 — the
    // Support hub carries both quitlines, the supporter and quit-coach rows,
    // the sharing control, five tabs and the settings button. 16 leaves room
    // for another declared control while still catching targets that are
    // being generated in a loop rather than declared.
    for (var index = 0; index < approvedScreens.length; index++) {
      expect(
        tapTargetsFor(index).length,
        lessThanOrEqualTo(16),
        reason: 'screen ${index + 1} declares '
            '${tapTargetsFor(index).length} tap targets',
      );
    }
  });

  test('target resolution allocates a fresh list but is otherwise stable', () {
    // Two calls must agree. If they ever disagree, the result is being derived
    // from mutable state and caching it in build() would be unsafe.
    for (var index = 0; index < approvedScreens.length; index++) {
      final first = tapTargetsFor(index);
      final second = tapTargetsFor(index);
      expect(first.length, second.length);
      for (var i = 0; i < first.length; i++) {
        expect(first[i].label, second[i].label);
        expect(first[i].normalizedRect, second[i].normalizedRect);
        expect(first[i].action, second[i].action);
      }
    }
  });

  test('the screen catalog is a fixed, unmodifiable surface', () {
    // The catalog is const, so it is built once and shared. Two properties
    // follow, and both matter: the size the other budgets assume is fixed,
    // and no caller can mutate the list every screen reads from. A computed
    // growable list would lose both — every build would pay to rebuild it,
    // and one careless `.add` would corrupt navigation for the whole app.
    expect(approvedScreens, hasLength(28));
    expect(
      () => approvedScreens.add(approvedScreens.first),
      throwsUnsupportedError,
      reason: 'the catalog is mutable, so it is no longer a const list',
    );
  });

  testWidgets('walking the whole 28-screen catalog stays inside a budget',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stopwatch = Stopwatch()..start();
    for (var screen = 0; screen < approvedScreens.length; screen++) {
      await tester.pumpWidget(TetherHealthApp(initialScreen: screen));
      await tester.pump();
    }
    stopwatch.stop();

    // Mounting all 28 screens once. Loose, for the reason in the header.
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(30000),
      reason: 'mounting 28 screens took ${stopwatch.elapsedMilliseconds}ms',
    );
    expect(tester.takeException(), isNull);
  });
}
