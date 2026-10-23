// Settings screens: the app's class lists match the kit's, the
// registry sends only touched keys on consent screens and refuses plan
// screens that are not loaded, and the stored values come from the backend.
import 'dart:io';

import 'package:breathefree_patient/api/tether_api.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_api.dart';
import 'package:breathefree_patient/data/app_services.dart';
import 'package:breathefree_patient/data/sync_codec.dart';
import 'package:breathefree_patient/integration/registry.dart';
import 'package:breathefree_patient/integration/settings_data.dart';
import 'package:breathefree_patient/sync/sync_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/ui/ui.dart';

import '../backend/sandbox/support.dart';

Set<String> _kitSet(String name) {
  final text = File('tether_ui/flutter/lib/router/settings_screens.dart')
      .readAsStringSync();
  final block =
      RegExp('$name = <String>\\{([^}]*)\\}').firstMatch(text)!.group(1)!;
  return {
    for (final m in RegExp(r"'([a-z0-9_]+)'").allMatches(block)) m.group(1)!
  };
}

void main() {
  tearDown(() => TSession.clear());

  test('the class lists are the kit\'s', () {
    expect(consentSettingsScreens, _kitSet('consentSettingsScreens'));
    expect(planSettingsScreens, _kitSet('planSettingsScreens'));
  });

  group('registry', () {
    test('a consent screen with nothing changed sends nothing', () async {
      var calls = 0;
      final api = AppApi(handlers: {
        'PATCH /v1/notifications/preferences': (_) async {
          calls++;
          return const TOk();
        },
      });
      TSession.set('account_notifications.quiet_hours', false);
      expect(
          await api.submit('PATCH /v1/notifications/preferences',
              screenId: 'account_notifications'),
          const TResult.ok());
      expect(calls, 0);
    });

    test('a consent screen sends only the touched keys', () async {
      Map<String, Object?>? got;
      final api = AppApi(handlers: {
        'PATCH /v1/notifications/preferences': (call) async {
          got = call.payload;
          return const TOk();
        },
      });
      TSession.set('account_notifications.quiet_hours', false);
      TSession.set('account_notifications.show_sensitive_details', true);
      TSession.markTouched(
          'account_notifications.show_sensitive_details', true);
      await api.submit('PATCH /v1/notifications/preferences',
          screenId: 'account_notifications');
      expect(got, {'account_notifications.show_sensitive_details': true});
    });

    test('a plan screen with a control not loaded is not sent', () async {
      var calls = 0;
      final api = AppApi(handlers: {
        'PUT /v1/program-data/st/range': (_) async {
          calls++;
          return const TOk();
        },
      });
      final missing = await api.submit('PUT /v1/program-data/st/range',
          screenId: 'st_range');
      expect(missing, const TResult.failed(RegistryCodes.notLoaded));
      for (final key in boundKeysOf('st_range')) {
        TSession.set(key, 'mg/dL');
      }
      await api.submit('PUT /v1/program-data/st/range', screenId: 'st_range');
      expect(calls, 1);
    });
  });

  group('stored values', () {
    late SandboxHarness h;
    late AppServices services;

    setUp(() async {
      h = SandboxHarness();
      await h.signUp();
      services = AppServices(h.backend,
          syncStore: MemorySyncDocumentStore(),
          outboxStore: MemorySyncDocumentStore());
    });

    test('nothing stored: notifications and enrolments are unset', () async {
      final values = (await SettingsSource(services).load())!;
      expect(values.containsKey('notifications.quiet_hours'), isFalse);
      expect(values.containsKey('enrolment.bf.status'), isFalse);
    });

    test('saved preferences, enrolment status and live consents', () async {
      await h.api.records.updateNotificationPreferences(
          remindersEnabled: true, quietHoursEnabled: false);
      final bf = await h.enrol('bf', status: EnrolmentStatus.focus);
      await h.api.enrolments.grantConsent(
          enrolmentId: bf,
          purpose: ConsentPurpose.research,
          consentVersion: sandboxConsentVersion,
          locale: ConsentLocale.en);
      final values = (await SettingsSource(services).load())!;
      expect(values['notifications.check_ins_and_plan_reminders'], isTrue);
      expect(values['notifications.quiet_hours'], isFalse);
      expect(values['enrolment.bf.status'], 'Focus');
      expect(values['enrolment.bf.de_identified_research'], isTrue);
      expect(values['enrolment.bf.care_team_sharing'], isFalse);
    });

    test('plan controls come from the sync document', () async {
      await services.openSync();
      await services.sync.saveAnswers(
          'st', 'range', encodeScreen('st_range', {'value': 'mmol/L'}));
      final values = (await SettingsSource(services).load())!;
      expect(values['st.range.unit'], 'mmol/L');
      expect(values.containsKey('bf.meds.medicine'), isFalse);
    });

    test('covers the settings keys only', () {
      final source = SettingsSource(services);
      expect(source.covers('notifications.quiet_hours'), isTrue);
      expect(source.covers('enrolment.sf.status'), isTrue);
      expect(source.covers('enrolment.sf.summary'), isFalse);
      expect(source.covers('consents.de_identified_research'), isTrue);
      expect(source.covers('hw.last_bp'), isFalse);
    });
  });
}
