// Acceptance — one case per user-facing outcome for the controls the approved
// artwork draws. Each of these was unreachable: a bilingual product had a
// monolingual safety route, and the settings that exist to help disabled
// users could not be opened.

import 'package:tether_health/models/tap_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Support hub tap targets', () {
    test('both quitlines are reachable and carry their own contact', () {
      final targets = tapTargetsFor(26); // Screen 27.
      final quitlineTargets =
          targets.where((t) => t.action == TapAction.quitline).toList();

      expect(quitlineTargets, hasLength(2));
      expect(
        quitlineTargets.map((t) => t.quitline?.language),
        containsAll(<String>['English', 'Español']),
      );

      // Every quitline target must say which line it dials, or the handler
      // cannot tell them apart.
      for (final target in quitlineTargets) {
        expect(target.quitline, isNotNull);
        expect(target.label, contains(target.quitline!.vanityNumber));
      }
    });

    test('the supporter and quit-coach rows are reachable', () {
      final labels = tapTargetsFor(26).map((t) => t.label);
      expect(labels, contains('Message or call your supporter'));
      expect(labels, contains('Send a secure message to your quit coach'));
    });
  });

  group('Settings tap targets', () {
    test('accessibility settings are reachable', () {
      final labels = tapTargetsFor(27).map((t) => t.label); // Screen 28.
      expect(labels, contains('Open accessibility settings'));
    });
  });
}
