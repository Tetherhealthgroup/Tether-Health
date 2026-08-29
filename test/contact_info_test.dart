import 'package:breathefree_patient/config/contact_info.dart';
import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/models/screen_spec.dart';
import 'package:breathefree_patient/models/tap_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the app puts on the clipboard, without touching a real one.
///
/// Returns the list the handler appends to; it is cleared between uses by the
/// caller creating a fresh installation per test.
List<String> _installClipboardRecorder(WidgetTester tester) {
  final copied = <String>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      copied.add((call.arguments as Map)['text'] as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );

  return copied;
}

void _useIphoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

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

  group('Contact dialogs', () {
    testWidgets(
        'the Spanish quitline opens its own dialog and copies its '
        'own number', (tester) async {
      _useIphoneViewport(tester);
      final copied = _installClipboardRecorder(tester);

      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 26));
      await tester.pumpAndSettle();

      await tester.tap(
        find.bySemanticsLabel('Call ${ContactInfo.spanish.vanityNumber}'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Call ${ContactInfo.spanish.vanityNumber}?'),
        findsOneWidget,
      );
      expect(find.textContaining('Español'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('quitline-copy')));
      await tester.pumpAndSettle();

      expect(copied, <String>[ContactInfo.spanish.dialledNumber]);
      expect(find.text('Español quitline number copied'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the English quitline still copies the English number',
        (tester) async {
      _useIphoneViewport(tester);
      final copied = _installClipboardRecorder(tester);

      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 26));
      await tester.pumpAndSettle();

      await tester.tap(
        find.bySemanticsLabel('Call ${ContactInfo.english.vanityNumber}'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('quitline-copy')));
      await tester.pumpAndSettle();

      expect(copied, <String>[ContactInfo.english.dialledNumber]);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a protected action offers support, which shows and copies '
        'the address', (tester) async {
      _useIphoneViewport(tester);
      final copied = _installClipboardRecorder(tester);

      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 27));
      await tester.pumpAndSettle();

      // Any protected/demo action reaches the same information dialog.
      await tester.tap(find.bySemanticsLabel('Open accessibility settings'));
      await tester.pumpAndSettle();

      final supportButton =
          find.byKey(const ValueKey('information-contact-support'));
      expect(supportButton, findsOneWidget);

      await tester.tap(supportButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('support-dialog')), findsOneWidget);
      expect(
        find.textContaining(ContactInfo.supportEmail),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('support-copy')));
      await tester.pumpAndSettle();

      expect(copied, <String>[ContactInfo.supportEmail]);
      expect(find.text('Support address copied'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the support dialog routes emergencies away from the inbox',
        (tester) async {
      _useIphoneViewport(tester);
      _installClipboardRecorder(tester);

      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 27));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Open accessibility settings'));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('information-contact-support')));
      await tester.pumpAndSettle();

      // A support inbox must never be presented as the route for urgent
      // symptoms; the dialog has to name the emergency and quitline routes.
      final body = tester
          .widget<Text>(find.textContaining(ContactInfo.supportEmail))
          .data!;
      expect(body, contains(ContactInfo.emergencyNumber));
      expect(body, contains(ContactInfo.english.vanityNumber));
      expect(body, contains('cannot give'));
      expect(tester.takeException(), isNull);
    });
  });
}
