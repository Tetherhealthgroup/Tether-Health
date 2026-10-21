// AppDevice answers only the platform question; every other question gives
// no answer and a code, and it never throws or answers outside the set.
import 'dart:convert';
import 'dart:io';

import 'package:breathefree_patient/integration/device_outcomes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/ui/ui.dart';

TBranchRef _ref(TAsk ask) => TBranchRef('synthetic.${ask.name}', ask, 'screen');

void main() {
  late BuildContext context;

  Future<void> host(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(home: Builder(builder: (c) {
          context = c;
          return const SizedBox();
        })),
      );

  test('every question in branches.json, and every TAsk, has an owner', () {
    final branches =
        (jsonDecode(File('tether_ui/spec/branches.json').readAsStringSync())
                as List<dynamic>)
            .cast<Map<String, dynamic>>();
    final asked = {
      for (final b in branches)
        if (b['ask'] != null) b['ask'] as String,
    };
    expect(asked, isNotEmpty);
    expect(asked.difference(TAsk.values.map((a) => a.name).toSet()), isEmpty);
    expect(deviceAskOwners.keys.toSet(), TAsk.values.toSet());
    expect(deviceAskOwners, {
      TAsk.platform: 'TH-923',
      TAsk.notificationsRequest: 'TH-936',
      TAsk.notificationsCheck: 'TH-936',
      TAsk.healthRecordsRequest: 'TH-964',
      TAsk.screenTimeRequest: 'TH-949',
      TAsk.unplugAuthIos: 'TH-949',
      TAsk.usageAccessSettings: 'TH-949',
      TAsk.unplugAndroidCheck: 'TH-949',
      TAsk.unplugTrackingCheck: 'TH-949',
      TAsk.smartConnect: 'TH-934',
      TAsk.fhirServerCheck: 'TH-934',
      TAsk.reference: 'never answered',
    });
  });

  testWidgets('the platform question is answered from defaultTargetPlatform',
      (tester) async {
    await host(tester);
    final codes = <String>[];
    final device = AppDevice(onCode: codes.add);
    final expected = {
      TargetPlatform.iOS: TAnswer.ios,
      TargetPlatform.android: TAnswer.android,
      TargetPlatform.macOS: null,
      TargetPlatform.linux: null,
      TargetPlatform.windows: null,
      TargetPlatform.fuchsia: null,
    };
    for (final MapEntry(key: platform, value: answer) in expected.entries) {
      debugDefaultTargetPlatformOverride = platform;
      expect(await device.ask(context, _ref(TAsk.platform)), answer,
          reason: platform.name);
    }
    debugDefaultTargetPlatformOverride = null;
    expect(codes, isEmpty);
  });

  testWidgets('the reference question is never answered and reports nothing',
      (tester) async {
    await host(tester);
    final codes = <String>[];
    expect(
      await AppDevice(onCode: codes.add).ask(context, _ref(TAsk.reference)),
      isNull,
    );
    expect(codes, isEmpty);
  });

  testWidgets('every other question gives no answer and device_not_configured',
      (tester) async {
    await host(tester);
    final codes = <String>[];
    final device = AppDevice(onCode: codes.add);
    final others =
        TAsk.values.where((a) => a != TAsk.platform && a != TAsk.reference);
    for (final ask in others) {
      expect(await device.ask(context, _ref(ask)), isNull, reason: ask.name);
    }
    expect(codes, List.filled(others.length, deviceNotConfiguredCode));
    expect(deviceNotConfiguredCode, 'device_not_configured');
  });

  testWidgets('it never throws and never answers outside the set',
      (tester) async {
    await host(tester);
    final throwing = AppDevice(
      onCode: (_) => throw StateError('reporter down'),
      platform: () => throw StateError('no platform'),
    );
    for (final ask in TAsk.values) {
      final answer = await throwing.ask(context, _ref(ask));
      expect(answer, isNull, reason: ask.name);
    }
    for (final platform in TargetPlatform.values) {
      final device = AppDevice(platform: () => platform);
      for (final ask in TAsk.values) {
        final answer = await device.ask(context, _ref(ask));
        if (answer != null) expect(ask.answers, contains(answer));
      }
    }
  });
}
