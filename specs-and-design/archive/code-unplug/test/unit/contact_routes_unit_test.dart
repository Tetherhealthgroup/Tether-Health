// Unit — the approved contact routes, and the pure geometry of every tap
// target. No widgets and no I/O: these assert on data and rectangles only.

import 'package:tether_health/config/contact_info.dart';
import 'package:tether_health/models/screen_spec.dart';
import 'package:tether_health/models/tap_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContactInfo', () {
    test('carries both approved quitlines and the support address', () {
      expect(ContactInfo.supportEmail, 'support@tetherhealthgroup.com');
      expect(ContactInfo.emergencyNumber, '911');

      expect(ContactInfo.quitlines, hasLength(2));
      expect(
        ContactInfo.quitlines.map((line) => line.language),
        orderedEquals(<String>['English', 'Español']),
      );

      // The two services are genuinely different numbers, not a copy-paste.
      expect(
        ContactInfo.english.dialledNumber,
        isNot(ContactInfo.spanish.dialledNumber),
      );
      expect(ContactInfo.english.dialledNumber, '1-800-784-8669');
      expect(ContactInfo.spanish.dialledNumber, '1-855-335-3569');
    });

    test('tel URIs are E.164 and match the dialled digits', () {
      for (final line in ContactInfo.quitlines) {
        expect(line.telUri, startsWith('+1'));
        expect(
          line.telUri,
          '+1${line.dialledNumber.replaceAll('-', '').substring(1)}',
          reason: '${line.language} tel URI must match its dialled number',
        );
      }
    });
  });

  group('Tap target geometry', () {
    test('every rectangle stays inside the screen', () {
      for (var index = 0; index < approvedScreens.length; index++) {
        for (final target in tapTargetsFor(index)) {
          final rect = target.normalizedRect;
          expect(
            rect.left >= 0 &&
                rect.top >= 0 &&
                rect.right <= 1.0001 &&
                rect.bottom <= 1.0001,
            isTrue,
            reason:
                'Screen ${index + 1} target "${target.label}" falls outside '
                'the screen: $rect',
          );
        }
      }
    });

    test('no two targets on a screen overlap', () {
      // Overlapping targets are not a cosmetic problem: the one added last
      // wins the hit test, so the other silently loses touch area.
      for (var index = 0; index < approvedScreens.length; index++) {
        final targets = tapTargetsFor(index);
        for (var a = 0; a < targets.length; a++) {
          for (var b = a + 1; b < targets.length; b++) {
            final first = targets[a];
            final second = targets[b];
            // Deflate before comparing: rectangles that share an edge are
            // fine, and 0.40 + 0.20 evaluates to 0.6000000000000001 in
            // binary floating point, which would otherwise read as an
            // overlap of one ten-thousandth of a pixel.
            expect(
              first.normalizedRect
                  .deflate(1e-6)
                  .overlaps(second.normalizedRect.deflate(1e-6)),
              isFalse,
              reason: 'Screen ${index + 1}: "${first.label}" overlaps '
                  '"${second.label}"',
            );
          }
        }
      }
    });
  });
}
