import 'package:flutter_test/flutter_test.dart';

import 'package:breathefree_patient/models/screen_spec.dart';
import 'package:breathefree_patient/models/tap_target.dart';

void main() {
  group('tapTargetsFor contract', () {
    test('every approved screen exposes at least one tap target', () {
      for (var index = 0; index < approvedScreens.length; index++) {
        final targets = tapTargetsFor(index);
        expect(
          targets,
          isNotEmpty,
          reason: 'screen ${index + 1} has no tap targets',
        );
      }
    });

    test('every navigation destination is a valid screen index', () {
      for (var index = 0; index < approvedScreens.length; index++) {
        for (final target in tapTargetsFor(index)) {
          final destination = target.destination;
          if (destination == null) continue;
          expect(
            destination,
            inInclusiveRange(0, approvedScreens.length - 1),
            reason: 'screen ${index + 1} target "${target.label}" '
                'points at $destination',
          );
          // Note: tab-bar targets may intentionally point at the current
          // screen (tapping the active tab is a no-op in _goTo).
        }
      }
    });

    test('every target has a non-empty label and a tappable rect', () {
      for (var index = 0; index < approvedScreens.length; index++) {
        for (final target in tapTargetsFor(index)) {
          expect(target.label.trim(), isNotEmpty,
              reason: 'screen ${index + 1} has an unlabeled target');
          expect(target.normalizedRect.isEmpty, isFalse,
              reason: 'screen ${index + 1} target "${target.label}" '
                  'has an empty rect');
        }
      }
    });

    test('home screens expose craving rescue and daily check-in', () {
      for (final screenNumber in [12, 22]) {
        final labels =
            tapTargetsFor(screenNumber - 1).map((t) => t.label).toSet();
        expect(labels, contains('Open craving rescue'),
            reason: 'screen $screenNumber missing rescue entry');
        expect(labels, contains('Start daily check-in'),
            reason: 'screen $screenNumber missing check-in entry');
      }
    });

    test('support hub exposes the quitline action', () {
      final actions =
          tapTargetsFor(26).map((t) => t.action).toSet();
      expect(actions, contains(TapAction.quitline));
    });

    test('settings screen exposes data export and deletion', () {
      final actions =
          tapTargetsFor(27).map((t) => t.action).toSet();
      expect(actions, contains(TapAction.exportData));
      expect(actions, contains(TapAction.deleteAccount));
    });
  });
}
