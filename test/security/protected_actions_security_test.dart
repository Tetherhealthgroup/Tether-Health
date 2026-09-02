// Security — what the protected and safety-critical controls must never do.
//
// This screen set carries three things worth protecting: a clipboard the app
// writes to, destructive account actions, and telephone routes. The tests
// below assert the negative in each case, because the failure mode is a
// silent success — a number dialled without being asked for, an account
// action that acts on first tap, or arbitrary text pushed to the clipboard.

import 'package:breathefree_patient/config/contact_info.dart';
import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/models/tap_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records clipboard writes without touching a real clipboard.
List<String> _installClipboardRecorder() {
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

/// Records any attempt to hand a URI to the platform (a dial, a browser open).
List<String> _installUrlLauncherRecorder() {
  final launched = <String>[];
  const channel = MethodChannel('plugins.flutter.io/url_launcher_android');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(channel, (call) async {
    launched.add('${call.method}:${(call.arguments as Map?)?['url']}');
    return true;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

  return launched;
}

void _useIphoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tapTarget(WidgetTester tester, AppTapTarget target) async {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  await tester.tapAt(
    Offset(
      (target.normalizedRect.left + target.normalizedRect.width / 2) *
          size.width,
      (target.normalizedRect.top + target.normalizedRect.height / 2) *
          size.height,
    ),
  );
  await tester.pumpAndSettle();
}

AppTapTarget _targetWhere(int screenIndex, bool Function(AppTapTarget) test) =>
    tapTargetsFor(screenIndex).firstWhere(test);

void main() {
  testWidgets('a quitline control never places a call by itself',
      (tester) async {
    _useIphoneViewport(tester);
    final launched = _installUrlLauncherRecorder();
    _installClipboardRecorder();

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 26));
    await tester.pumpAndSettle();

    await _tapTarget(
      tester,
      _targetWhere(26, (t) => t.action == TapAction.quitline),
    );

    // The dialog must be the whole effect of the tap. Dialling is an action a
    // person takes deliberately, and the copy says so.
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      launched,
      isEmpty,
      reason: 'tapping a quitline handed a URI to the platform',
    );
    expect(
      find.textContaining('Phone launching is intentionally disabled'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the clipboard only ever receives an approved contact value',
      (tester) async {
    _useIphoneViewport(tester);
    final copied = _installClipboardRecorder();

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 26));
    await tester.pumpAndSettle();

    await _tapTarget(
      tester,
      _targetWhere(26, (t) => t.action == TapAction.quitline),
    );
    await tester.tap(find.byKey(const ValueKey('quitline-copy')));
    await tester.pumpAndSettle();

    final approved = <String>{
      ContactInfo.supportEmail,
      ContactInfo.emergencyNumber,
      for (final q in ContactInfo.quitlines) q.dialledNumber,
      for (final q in ContactInfo.quitlines) q.telUri,
    };

    expect(copied, isNotEmpty, reason: 'Copy number wrote nothing');
    for (final value in copied) {
      expect(
        approved,
        contains(value),
        reason: '"$value" is not one of the approved contact routes',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a destructive account action only opens a confirmation',
      (tester) async {
    _useIphoneViewport(tester);
    _installClipboardRecorder();
    final launched = _installUrlLauncherRecorder();

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 27));
    await tester.pumpAndSettle();

    await _tapTarget(
      tester,
      _targetWhere(27, (t) => t.action == TapAction.deleteAccount),
    );

    // First tap must describe what a production build would require, not act.
    expect(find.text('Delete account and data?'), findsOneWidget);
    expect(find.textContaining('recent authentication'), findsOneWidget);

    // Confirming in this preview must still not reach the platform.
    await tester.tap(find.text('Review deletion'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(launched, isEmpty);
    expect(tester.takeException(), isNull);
  });

  test('the support address is never presented as a clinical route', () {
    // A product-support inbox must not be reachable as a safety route, and the
    // two must not share a value that could later be edited into one.
    expect(ContactInfo.supportEmail, isNot(ContactInfo.emergencyNumber));
    for (final quitline in ContactInfo.quitlines) {
      expect(quitline.dialledNumber, isNot(ContactInfo.supportEmail));
      expect(quitline.telUri, isNot(ContactInfo.supportEmail));
    }
  });
}
