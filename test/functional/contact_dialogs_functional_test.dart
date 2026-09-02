// Functional — the contact dialogs, driven the way a screen drives them:
// tap the approved target, assert what the dialog says and what it copies.

import 'package:breathefree_patient/config/contact_info.dart';
import 'package:breathefree_patient/main.dart';
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
