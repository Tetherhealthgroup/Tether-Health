import 'dart:async';

import 'package:breathefree_patient/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final actions = <(int, String, String, String)>[
    (26, 'Call 1-800-QUIT-NOW', 'Call 1-800-QUIT-NOW?', 'Copy number'),
    (
      26,
      'Request a counselor call-back',
      'Request a counselor call-back?',
      'Review consent'
    ),
    (27, 'Download a copy of your data', 'Prepare your data copy?', 'Continue'),
    (
      27,
      'Delete account and data',
      'Delete account and data?',
      'Review deletion'
    ),
    (27, 'Sign out', 'Sign out', 'Done'),
  ];

  for (final (screen, label, title, confirm) in actions) {
    testWidgets('$label opens and cancels without navigating', (tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(BreatheFreeApp(initialScreen: screen));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(label));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(find.widgetWithText(FilledButton, confirm), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(
          find.byKey(ValueKey('screen-image-${screen + 1}')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('quitline copy writes number and displays confirmation',
      (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clipboardCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboardCalls.add(call);
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 26));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Call 1-800-QUIT-NOW'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy number'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(clipboardCalls, hasLength(1));
    expect(clipboardCalls.single.arguments, {'text': '1-800-784-8669'});
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Quitline number copied'), findsOneWidget);
  });
  for (final fails in [false, true]) {
    for (final dispose in [false, true]) {
      testWidgets('quitline pending copy: failure=$fails, disposed=$dispose',
          (tester) async {
        tester.view.physicalSize = const Size(1290, 2796);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final pendingCopy = Completer<void>();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              await pendingCopy.future;
              if (fails) throw PlatformException(code: 'clipboard_unavailable');
            }
            return null;
          },
        );
        addTearDown(() => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null));

        await tester.pumpWidget(const BreatheFreeApp(initialScreen: 26));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Call 1-800-QUIT-NOW'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Copy number'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Quitline number copied'), findsNothing);
        if (dispose) await tester.pumpWidget(const SizedBox.shrink());

        pendingCopy.complete();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (!dispose) {
          expect(
            find.text(fails
                ? 'Could not copy. Call 1-800-784-8669.'
                : 'Quitline number copied'),
            findsOneWidget,
          );
          if (fails) {
            expect(find.text('Quitline number copied'), findsNothing);
          }
        }
      });
    }
  }
}
