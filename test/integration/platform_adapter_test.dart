// The platform adapter: calls and texts only to dialable numbers, bounded
// by the kit's timeout; only https links and the email app; the app's own
// settings page; codes only, never values; and the native channel's fixed
// two methods.
import 'dart:async';
import 'dart:io';

import 'package:breathefree_patient/integration/platform_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/ui/ui.dart';
import 'package:url_launcher/url_launcher.dart';

const _channel = MethodChannel(AppPlatform.channelName);
const _mainActivity =
    'android/app/src/main/kotlin/com/TetherHealthLLC/tetherhealth/MainActivity.kt';

/// A launcher that records each call and answers as told.
class _Launcher {
  _Launcher([this.answer]);

  /// Null: never completes.
  Future<bool> Function()? answer;
  final List<(Uri, LaunchMode)> calls = [];

  Future<bool> call(Uri uri, LaunchMode mode) {
    calls.add((uri, mode));
    final reply = answer;
    return reply == null ? Completer<bool>().future : reply();
  }

  static _Launcher returning(bool value) => _Launcher(() async => value);
  static _Launcher throwing() =>
      _Launcher(() async => throw PlatformException(code: 'synthetic'));
  static _Launcher hanging() => _Launcher();
}

/// Mocks the app channel; records method names and arguments.
List<MethodCall> _mockChannel(Future<Object?> Function(MethodCall) handler) {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) {
    calls.add(call);
    return handler(call);
  });
  addTearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, null));
  return calls;
}

late BuildContext _context;

Future<void> _host(WidgetTester tester) => tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (c) {
        _context = c;
        return const SizedBox();
      })),
    ));

bool _toastShown(String message) => find.text(message).evaluate().isNotEmpty;

/// A widget test run with [platform] as the default target platform. The
/// override is reset inside the test body, as the framework requires.
void _testOn(
  TargetPlatform platform,
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  group('dialable', () {
    test('normalises to digits with an optional leading +', () {
      expect(AppPlatform.dialable('911'), '911');
      expect(AppPlatform.dialable('988'), '988');
      expect(AppPlatform.dialable('1-800-784-8669'), '18007848669');
      expect(AppPlatform.dialable('(555) 010-0199'), '5550100199');
      expect(AppPlatform.dialable('+1 555.010.0199'), '+15550100199');
      expect(AppPlatform.dialable(' 9 1 1 '), '911');
    });

    test('refuses fewer than 3 or more than 15 digits, and non-numbers', () {
      for (final value in [
        '',
        '12',
        '+12',
        '1234567890123456',
        'Jordan',
        '1-800-QUIT-NOW',
        '++1555',
        '555+1',
        '911;988',
        '#911',
        '*988',
      ]) {
        expect(AppPlatform.dialable(value), isNull, reason: value);
      }
      expect(AppPlatform.dialable('123456789012345'), '123456789012345');
    });
  });

  group('call', () {
    testWidgets('launches tel:<digits> externally and returns its result',
        (tester) async {
      await _host(tester);
      for (final answer in [true, false]) {
        final launcher = _Launcher.returning(answer);
        final result = await AppPlatform(launcher: launcher.call)
            .call(_context, '1-800-784-8669', 'Quitline');
        expect(result, answer);
        expect(launcher.calls.single.$1.toString(), 'tel:18007848669');
        expect(launcher.calls.single.$2, LaunchMode.externalApplication);
      }
    });

    testWidgets('911, 988 and a + number', (tester) async {
      await _host(tester);
      final launcher = _Launcher.returning(true);
      final platform = AppPlatform(launcher: launcher.call);
      await platform.call(_context, '911', '911');
      await platform.call(_context, '988', '988');
      await platform.call(_context, '+1 555 010 0199', 'x');
      expect(launcher.calls.map((c) => c.$1.toString()),
          ['tel:911', 'tel:988', 'tel:+15550100199']);
    });

    testWidgets('a number that is not dialable launches nothing',
        (tester) async {
      await _host(tester);
      final launcher = _Launcher.returning(true);
      expect(
        await AppPlatform(launcher: launcher.call).call(_context, '12', '12'),
        isFalse,
      );
      expect(launcher.calls, isEmpty);
    });

    testWidgets('a launcher that throws gives false', (tester) async {
      await _host(tester);
      expect(
        await AppPlatform(launcher: _Launcher.throwing().call)
            .call(_context, '988', '988'),
        isFalse,
      );
    });

    testWidgets('a launcher that never completes gives false at 8 s',
        (tester) async {
      await _host(tester);
      bool? result;
      unawaited(AppPlatform(launcher: _Launcher.hanging().call)
          .call(_context, '988', '988')
          .then((value) => result = value));
      await tester.pump(const Duration(seconds: 7));
      expect(result, isNull, reason: 'still waiting before the timeout');
      await tester.pump(const Duration(seconds: 1));
      expect(result, isFalse);
    });
  });

  group('sms', () {
    testWidgets('a dialable recipient opens sms:<digits>', (tester) async {
      await _host(tester);
      final launcher = _Launcher.returning(true);
      expect(await AppPlatform(launcher: launcher.call).sms(_context, '988'),
          isTrue);
      expect(launcher.calls.single.$1.toString(), 'sms:988');
      expect(launcher.calls.single.$2, LaunchMode.externalApplication);
    });

    testWidgets('a name opens Messages with no recipient', (tester) async {
      await _host(tester);
      final launcher = _Launcher.returning(false);
      expect(await AppPlatform(launcher: launcher.call).sms(_context, 'Jordan'),
          isFalse);
      expect(launcher.calls.single.$1.toString(), 'sms:');
    });

    testWidgets('a throw gives false; a hang gives false at 8 s',
        (tester) async {
      await _host(tester);
      expect(
        await AppPlatform(launcher: _Launcher.throwing().call)
            .sms(_context, '988'),
        isFalse,
      );
      bool? result;
      unawaited(AppPlatform(launcher: _Launcher.hanging().call)
          .sms(_context, '988')
          .then((value) => result = value));
      await tester.pump(const Duration(seconds: 7));
      expect(result, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(result, isFalse);
    });
  });

  group('openUrl', () {
    testWidgets('an https link opens in the external browser', (tester) async {
      await _host(tester);
      final codes = <String>[];
      final launcher = _Launcher.returning(true);
      await AppPlatform(launcher: launcher.call, onCode: codes.add)
          .openUrl(_context, 'https://www.tetherhealthgroup.com/privacy/');
      expect(launcher.calls.single.$1.toString(),
          'https://www.tetherhealthgroup.com/privacy/');
      expect(launcher.calls.single.$2, LaunchMode.externalApplication);
      expect(codes, isEmpty);
    });

    testWidgets('other schemes are refused without launching', (tester) async {
      await _host(tester);
      final channelCalls = _mockChannel((_) async => true);
      for (final url in [
        'http://www.tetherhealthgroup.com/',
        'javascript:alert(1)',
        'intent://scan/#Intent;scheme=zxing;end',
        'file:///etc/hosts',
        'data:text/html,hi',
        'tel:988',
        'sms:988',
        'tether://open',
        'https://user:pw@example.test/',
        'https:///no-host',
        'MESSAGE://',
        'message://inbox',
        'message:',
        '',
        'not a url',
      ]) {
        final codes = <String>[];
        final launcher = _Launcher.returning(true);
        for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
          await AppPlatform(
            launcher: launcher.call,
            onCode: codes.add,
            platform: () => platform,
          ).openUrl(_context, url);
        }
        expect(launcher.calls, isEmpty, reason: url);
        expect(codes, [PlatformCodes.urlRefused, PlatformCodes.urlRefused],
            reason: url);
      }
      expect(channelCalls, isEmpty);
    });

    for (final failure in ['false', 'throw', 'hang']) {
      testWidgets('nothing opening ($failure) shows a toast and a code',
          (tester) async {
        await _host(tester);
        final codes = <String>[];
        final launcher = switch (failure) {
          'false' => _Launcher.returning(false),
          'throw' => _Launcher.throwing(),
          _ => _Launcher.hanging(),
        };
        var done = false;
        unawaited(AppPlatform(launcher: launcher.call, onCode: codes.add)
            .openUrl(_context, 'https://example.test/help')
            .then((_) => done = true));
        await tester.pump(const Duration(seconds: 8));
        await tester.pump();
        expect(done, isTrue, reason: 'bounded by the timeout');
        expect(codes, [PlatformCodes.urlOpenFailed]);
        expect(_toastShown(PlatformCopy.linkFailed), isTrue);
        await tester.pump(const Duration(seconds: 2));
      });
    }

    _testOn(TargetPlatform.iOS, 'message:// uses the launcher on iOS',
        (tester) async {
      await _host(tester);
      final channelCalls = _mockChannel((_) async => true);
      final launcher = _Launcher.returning(true);
      await AppPlatform(launcher: launcher.call)
          .openUrl(_context, 'message://');
      expect(launcher.calls.single.$1.toString(), 'message://');
      expect(channelCalls, isEmpty);
    });

    _testOn(TargetPlatform.android,
        'message:// uses openEmailApp on Android, with no arguments',
        (tester) async {
      await _host(tester);
      final codes = <String>[];
      final channelCalls = _mockChannel((_) async => true);
      final launcher = _Launcher.returning(true);
      await AppPlatform(launcher: launcher.call, onCode: codes.add)
          .openUrl(_context, 'message://');
      expect(channelCalls.map((c) => (c.method, c.arguments)),
          [('openEmailApp', null)]);
      expect(launcher.calls, isEmpty);
      expect(codes, isEmpty);
    });

    _testOn(TargetPlatform.android, 'no email app on Android: toast and code',
        (tester) async {
      await _host(tester);
      final codes = <String>[];
      final unused = _Launcher.returning(true);
      _mockChannel((_) async => false);
      await AppPlatform(launcher: unused.call, onCode: codes.add)
          .openUrl(_context, 'message://');
      await tester.pump();
      expect(codes, [PlatformCodes.urlOpenFailed]);
      expect(_toastShown(PlatformCopy.linkFailed), isTrue);
      expect(unused.calls, isEmpty);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('openOsSettings', () {
    _testOn(TargetPlatform.iOS, 'iOS opens app-settings: through the launcher',
        (tester) async {
      await _host(tester);
      final codes = <String>[];
      final launcher = _Launcher.returning(true);
      await AppPlatform(launcher: launcher.call, onCode: codes.add)
          .openOsSettings(_context);
      expect(launcher.calls.single.$1.toString(), 'app-settings:');
      expect(codes, isEmpty);
    });

    _testOn(TargetPlatform.android,
        'Android calls openAppSettings with no arguments', (tester) async {
      await _host(tester);
      final channelCalls = _mockChannel((_) async => true);
      final launcher = _Launcher.returning(true);
      await AppPlatform(launcher: launcher.call).openOsSettings(_context);
      expect(channelCalls.map((c) => (c.method, c.arguments)),
          [('openAppSettings', null)]);
      expect(launcher.calls, isEmpty);
    });

    _testOn(TargetPlatform.android,
        'a missing channel gives a toast and a code, no throw', (tester) async {
      await _host(tester);
      final codes = <String>[];
      final unused = _Launcher.returning(true);
      // The platform side has no handler: invokeMethod throws
      // MissingPluginException.
      _mockChannel((_) async => throw MissingPluginException());
      await AppPlatform(launcher: unused.call, onCode: codes.add)
          .openOsSettings(_context);
      await AppPlatform(launcher: unused.call, onCode: codes.add)
          .openUrl(_context, 'message://');
      await tester.pump();
      expect(codes,
          [PlatformCodes.settingsOpenFailed, PlatformCodes.urlOpenFailed]);
      expect(unused.calls, isEmpty);
      expect(_toastShown(PlatformCopy.linkFailed), isTrue);
      await tester.pump(const Duration(seconds: 2));
    });

    _testOn(
        TargetPlatform.android, 'a hanging channel is bounded by the timeout',
        (tester) async {
      await _host(tester);
      final codes = <String>[];
      final unused = _Launcher.returning(true);
      _mockChannel((_) => Completer<Object?>().future);
      var done = false;
      unawaited(AppPlatform(launcher: unused.call, onCode: codes.add)
          .openOsSettings(_context)
          .then((_) => done = true));
      await tester.pump(const Duration(seconds: 7));
      expect(done, isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(done, isTrue);
      expect(codes, [PlatformCodes.settingsOpenFailed]);
      expect(_toastShown(PlatformCopy.settingsFailed), isTrue);
      await tester.pump(const Duration(seconds: 2));
    });

    _testOn(TargetPlatform.iOS,
        'a launcher failure on iOS gives a toast and a code', (tester) async {
      await _host(tester);
      final codes = <String>[];
      await AppPlatform(
        launcher: _Launcher.returning(false).call,
        onCode: codes.add,
      ).openOsSettings(_context);
      await tester.pump();
      expect(codes, [PlatformCodes.settingsOpenFailed]);
      expect(_toastShown(PlatformCopy.settingsFailed), isTrue);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  testWidgets('no number, recipient or URL reaches a code or the log',
      (tester) async {
    await _host(tester);
    final printed = <String>[];
    final previous = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
    final codes = <String>[];
    try {
      _mockChannel((_) async => throw MissingPluginException());
      final platform = AppPlatform(
        launcher: _Launcher.throwing().call,
        onCode: codes.add,
      );
      await platform.call(_context, '555-010-0199', 'Synthetic Person');
      await platform.sms(_context, 'Synthetic Person');
      await platform.openUrl(
          _context, 'https://example.test/synthetic-user-01');
      await platform.openUrl(_context, 'http://example.test/synthetic-user-01');
      await platform.openOsSettings(_context);
      await tester.pump(const Duration(seconds: 2));
    } finally {
      debugPrint = previous;
    }
    expect(
        codes.toSet().difference({
          PlatformCodes.urlRefused,
          PlatformCodes.urlOpenFailed,
          PlatformCodes.settingsOpenFailed,
        }),
        isEmpty);
    expect(printed, isEmpty);
    final source =
        File('lib/integration/platform_adapter.dart').readAsStringSync();
    expect(source, isNot(contains('debugPrint')));
    expect(source, isNot(contains('print(')));
    expect(source, isNot(contains('canLaunchUrl')));
  });

  testWidgets(
      'through TNav.call, a failing launcher still shows the call '
      'fallback with the number', (tester) async {
    await _host(tester);
    final previous = TPlatform.instance;
    addTearDown(() => TPlatform.instance = previous);
    TPlatform.instance = AppPlatform(launcher: _Launcher.returning(false).call);
    await TNav.call(_context, '988');
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('call_fallback')), findsOneWidget);
    final number = tester.widget<Text>(
      find.byKey(const ValueKey('call_fallback.number')),
    );
    expect(number.data, '988');
    TCallFallback.dismiss();
    await tester.pumpAndSettle();
  });

  group('MainActivity channel', () {
    late String kotlin;

    setUpAll(() => kotlin = File(_mainActivity).readAsStringSync());

    test('one channel, with the same name as the adapter', () {
      expect(RegExp(r'\bMethodChannel\(').allMatches(kotlin), hasLength(1));
      expect(kotlin, contains('"${AppPlatform.channelName}"'));
    });

    test(
        'exactly openAppSettings and openEmailApp; anything else is '
        'not implemented', () {
      final start = kotlin.indexOf('when (call.method)');
      expect(start, isNot(-1));
      final cases = RegExp(r'^\s*"([^"]+)"\s*->', multiLine: true)
          .allMatches(kotlin.substring(start))
          .map((m) => m.group(1))
          .toList();
      expect(cases, ['openAppSettings', 'openEmailApp']);
      expect(kotlin, contains('else -> result.notImplemented()'));
    });

    test('the intents take no data from Dart', () {
      expect(kotlin, isNot(contains('call.argument')));
      expect(kotlin, isNot(contains('arguments')));
      expect(kotlin, contains('Uri.fromParts("package", packageName, null)'));
      expect(kotlin, contains('Settings.ACTION_APPLICATION_DETAILS_SETTINGS'));
      expect(kotlin, contains('Intent.CATEGORY_APP_EMAIL'));
      expect(kotlin, contains('Intent.FLAG_ACTIVITY_NEW_TASK'));
    });

    test('a missing activity answers false', () {
      expect(kotlin, contains('catch (e: ActivityNotFoundException)'));
      expect(
          RegExp(r'catch \(e: ActivityNotFoundException\) \{\s*false')
              .hasMatch(kotlin),
          isTrue);
    });
  });
}
