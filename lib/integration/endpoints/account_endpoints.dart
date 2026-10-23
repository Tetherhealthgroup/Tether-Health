// Onboarding consent, catalogue enrolment, programme settings, leaving,
// privacy and notification settings, the quit plan, guest merge, export and
// deletion. None of these is queued: offline they fail with the generic
// message.
import 'package:tether_ui/ui/ui.dart';

import '../../api/tether_api.dart';
import '../../quit_plan/guest_quit_plan_store.dart';
import '../../quit_plan/quit_plan.dart';
import '../deletion_records.dart';
import '../pending_onboarding.dart';
import '../../data/sync_codec.dart';
import '../registry.dart';
import 'device_endpoints.dart';
import 'sync_endpoints.dart';
import 'common.dart';

/// ob_consent toggles and the consent each one grants.
const Map<String, ConsentPurpose> onboardingConsents = {
  'essential_app_data': ConsentPurpose.core,
  'private_reminders': ConsentPurpose.reminders,
  'connect_screen_time': ConsentPurpose.screenTime,
  'de_identified_research': ConsentPurpose.research,
};

/// The onboarding programme choices: the first two chosen are in focus,
/// the others learn only, unless ob_third swapped one.
List<PendingProgramme> onboardingProgrammes(Snapshot s) {
  final codes = <String>[];
  const names = {
    'BreatheFree': 'bf', 'ScrollFree': 'sf', 'ClearAir': 'ca',
    'Heartwise': 'hw', //
    'Steady': 'st', 'Ease': 'ea', 'Nourish': 'nu', 'Stride': 'sd',
  };
  for (final label in s.list('programs', screen: 'ob_programs')) {
    final code = names[label];
    if (code != null && !codes.contains(code)) codes.add(code);
  }
  final focus = codes.take(2).toList();
  final third = s.one('value', screen: 'ob_third');
  if (codes.length > 2 && third != null && third.startsWith('Swap with ')) {
    final out = names[third.substring('Swap with '.length)];
    if (out != null && focus.remove(out)) focus.add(codes[2]);
  }
  return [
    for (final code in codes)
      PendingProgramme(
        code,
        focus.contains(code)
            ? EnrolmentStatus.focus
            : EnrolmentStatus.learnOnly,
        mode: code == 'bf' || code == 'sf' ? EnrolmentMode.quit : null,
      ),
  ];
}

/// The quit plan built from the BreatheFree answers and the quit date the
/// member chose, or null for "Explore first" (which writes no plan).
QuitPlan? quitPlanOf(Snapshot s, String userId, DateTime quitDate) {
  const daily = {
    'I don’t smoke every day': 'notEveryDay',
    '10 or fewer': 'tenOrFewer',
    '11–20': 'elevenToTwenty',
    '21–30': 'twentyOneToThirty',
    '31 or more': 'thirtyOneOrMore',
  };
  const triggers = {
    'Stress': 'stress', 'After meals': 'afterMeals', 'Driving': 'driving', //
    'With coffee': 'coffee', 'Social': 'socialSettings',
    'Work breaks': 'workBreaks',
    'Alcohol': 'alcohol', 'Boredom': 'boredom', 'Morning': 'morning',
    'Scrolling': 'scrolling',
  };
  const reasons = {
    'Protect my family': 'family', 'Breathe easier': 'breatheEasier', //
    'Save money': 'saveMoney', 'Feel in control': 'control',
    'My health': 'improveHealth', 'Be there for my future': 'future',
  };
  const paths = {
    'Set a quit date': 'setQuitDate',
    'Quit today': 'quitToday',
    'Reduce gradually': 'reduceGradually',
  };
  final path = s.one('path', screen: 'bf_path');
  if (path == 'Explore first') return null;
  final pathCode = paths[path];
  if (pathCode == null) return null;
  final chosenReasons = [
    for (final r in s.list('value', screen: 'bf_q3'))
      if (reasons[r] case final code?) code,
  ];
  final custom = s.text('add_your_own', screen: 'bf_q2');
  return QuitPlan(
    userId: userId,
    dailyCigaretteUse: daily[s.one('value', screen: 'bf_q1')],
    smokingTriggers: [
      for (final t in s.list('value', screen: 'bf_q2'))
        if (triggers[t] case final code?) code,
    ],
    customSmokingTrigger: custom,
    readinessPath: 'prepare',
    quitPlanPath: pathCode,
    quitDate: DateTime(quitDate.year, quitDate.month, quitDate.day),
    quitDayCheckIn:
        s.flag('quit_day_check_in_at_7_00_am', screen: 'bf_date') ?? false,
    quitReasons: chosenReasons,
    customQuitReason: null,
    topQuitReason: chosenReasons.isEmpty ? null : chosenReasons.first,
    supportPeople: const [],
    preparationTasks: const [],
    treatmentSupport: false,
    careTeamReminder:
        s.flag('remind_me_to_discuss_quit_medici', screen: 'bf_support') ??
            false,
  );
}

/// The BreatheFree setup screens whose answers are kept through sync.
const List<String> breatheFreeAnswerScreens = [
  'bf_q1', 'bf_q2', 'bf_q3', 'bf_path', 'bf_date', 'bf_support', //
];

/// Saves the BreatheFree setup answers to the sync document (area bf,
/// screens q1, q2, q3, path, date, support), creating the enrolment when
/// it is missing.
Future<TResult> saveBreatheFreeAnswers(HandlerKit kit, Snapshot s) async {
  final refused = await ensureEnrolment(kit, 'bf');
  if (refused != null) return TResult.failed(refused);
  await kit.services.openSync();
  for (final screen in breatheFreeAnswerScreens) {
    final values = screenValues(screen, s.call.payload);
    if (values.isEmpty) continue;
    await kit.services.sync
        .saveAnswers('bf', screen.substring(3), encodeScreen(screen, values));
  }
  return afterSyncSave(kit);
}

/// The programme a programme-scoped screen acts on.
String? programOf(String screenId) {
  if (screenId == 'program_settings_sf') return 'sf';
  final intro = RegExp(r'^([a-z]{2})_intro$').firstMatch(screenId);
  if (intro != null) return intro.group(1);
  return HandlerKit.programOfScreen?.call(screenId);
}

/// Handlers of the account endpoints.
Map<String, EndpointHandler> accountHandlers(
  HandlerKit kit, {
  GuestQuitPlanStore? guestPlans,
}) {
  final guest = guestPlans ?? SecureGuestQuitPlanStore();

  Future<Enrolment?> enrolmentOf(String code) async {
    final list = await kit.api.enrolments.list();
    for (final e in list.valueOrNull?.enrolments ?? const <Enrolment>[]) {
      if (e.programmeCode == code) return e;
    }
    return null;
  }

  Future<TResult> setConsent(Enrolment e, ConsentPurpose purpose, bool on,
      {String? recipient}) async {
    final live =
        e.consents.any((c) => c.purpose == purpose && c.revokedAt == null);
    if (live == on) return const TResult.ok();
    if (!on) {
      return resultOf(await kit.api.enrolments
          .revokeConsent(enrolmentId: e.id, purpose: purpose));
    }
    final document = await kit.services.consentDocument(purpose);
    if (document == null) {
      return const TResult.failed('consent_document_unavailable');
    }
    final (version, locale) = document;
    return resultOf(await kit.api.enrolments.grantConsent(
      enrolmentId: e.id,
      purpose: purpose,
      consentVersion: version,
      locale: locale,
      recipientRef: recipient,
    ));
  }

  return {
    'POST /v1/enrolments/consents': (call) => guarded(() async {
          final s = Snapshot(call);
          await kit.pending.setProgrammes(onboardingProgrammes(s));
          await kit.pending.setConsents({
            for (final MapEntry(:key, :value) in onboardingConsents.entries)
              if (s.flag(key) == true) value,
          });
          if (!kit.services.signedIn) return const TResult.ok();
          try {
            await kit.pending.commit(kit.services);
          } catch (_) {
            return const TResult.failed('onboarding_commit_failed');
          }
          return const TResult.ok();
        }),
    'POST /v1/enrolments': (call) => guarded(() async {
          final code = programOf(call.screenId);
          if (code == null) {
            return const TResult.failed(HandlerCodes.programUnknown);
          }
          if (!kit.services.signedIn) {
            await kit.pending.addProgramme(
                PendingProgramme(code, EnrolmentStatus.learnOnly));
            return const TResult.ok();
          }
          final result = await kit.api.enrolments
              .create(programmeCode: code, status: EnrolmentStatus.learnOnly);
          if (result.errorOrNull?.code == ApiProblemCode.alreadyEnrolled) {
            return const TResult.ok();
          }
          await kit.data.refresh();
          return resultOf(result);
        }),
    'PATCH /v1/enrolments/:id': (call) => guarded(() async {
          if (!kit.services.signedIn) {
            return const TResult.failed(HandlerCodes.signInRequired);
          }
          final code = programOf(call.screenId);
          if (code == null) {
            return const TResult.failed(HandlerCodes.programUnknown);
          }
          final e = await enrolmentOf(code);
          if (e == null) return const TResult.failed('enrolment_not_found');
          final s = Snapshot(call);
          const statuses = {
            'Focus': EnrolmentStatus.focus,
            'Learn only': EnrolmentStatus.learnOnly,
            'Pause': EnrolmentStatus.paused,
          };
          final status = statuses[s.one('status')];
          if (status != null && status != e.status) {
            final r = await kit.api.enrolments.update(e.id, status: status);
            if (!r.isSuccess) return resultOf(r);
          }
          final research = s.flag('de_identified_research');
          if (research != null) {
            final r = await setConsent(e, ConsentPurpose.research, research);
            if (r is TFailed) return r;
          }
          final sharing = s.flag('care_team_sharing');
          if (sharing != null) {
            String? recipient;
            if (sharing) {
              final connections = await kit.api.care.connections();
              final list = connections.valueOrNull?['connections'];
              if (list is List && list.isNotEmpty) {
                recipient = (list.first as Map)['id'] as String?;
              }
              if (recipient == null) {
                return const TResult.failed('connection_required');
              }
            }
            final r = await setConsent(e, ConsentPurpose.shareCareTeam, sharing,
                recipient: recipient);
            if (r is TFailed) return r;
          }
          await kit.data.refresh();
          return const TResult.ok();
        }),
    'DELETE /v1/enrolments/:id': (call) => guarded(() async {
          if (!kit.services.signedIn) {
            return const TResult.failed(HandlerCodes.signInRequired);
          }
          final code = programOf(call.screenId);
          if (code == null) {
            return const TResult.failed(HandlerCodes.programUnknown);
          }
          final e = await enrolmentOf(code);
          if (e == null) return const TResult.failed('enrolment_not_found');
          final deleteNow =
              Snapshot(call).one('value')?.startsWith('Delete') ?? false;
          final result = deleteNow
              ? await kit.api.enrolments.delete(e.id)
              : await kit.api.enrolments
                  .update(e.id, status: EnrolmentStatus.left);
          await kit.data.refresh();
          return resultOf(result);
        }),
    'PATCH /v1/enrolments/consents': (call) => guarded(() async {
          if (!kit.services.signedIn) {
            return const TResult.failed(HandlerCodes.signInRequired);
          }
          final s = Snapshot(call);
          final list = (await kit.api.enrolments.list()).valueOrNull;
          if (list == null) {
            return const TResult.failed('enrolments_unavailable');
          }
          if (call.screenId == 'sf_unplug_off') {
            if (!(s.one('scope')?.contains('Screen Time') ?? false)) {
              return const TResult.ok();
            }
            for (final e
                in list.enrolments.where((e) => e.programmeCode == 'sf')) {
              final r = await setConsent(e, ConsentPurpose.screenTime, false);
              if (r is TFailed) return r;
            }
            return const TResult.ok();
          }
          final research = s.flag('de_identified_research');
          if (research != null) {
            for (final e in list.enrolments) {
              if (e.status == EnrolmentStatus.left) continue;
              if (research &&
                  !e.consents.any((c) => c.purpose == ConsentPurpose.core)) {
                continue;
              }
              final r = await setConsent(e, ConsentPurpose.research, research);
              if (r is TFailed) return r;
            }
          }
          // Cross-programme insights and app diagnostics have no stored
          // consent: the app sends no diagnostics and makes no
          // cross-programme insight on the server, so there is nothing to
          // change there.
          await kit.data.refresh();
          return const TResult.ok();
        }),
    'PATCH /v1/notifications/preferences': (call) => guarded(() async {
          if (!kit.services.signedIn) {
            return const TResult.failed(HandlerCodes.signInRequired);
          }
          final s = Snapshot(call);
          final r = await kit.api.records.updateNotificationPreferences(
            remindersEnabled: s.flag('check_ins_and_plan_reminders'),
            sensitiveDetails: s.flag('show_sensitive_details'),
            quietHoursEnabled: s.flag('quiet_hours'),
          );
          await kit.data.refresh();
          return resultOf(r);
        }),
    'PUT /v1/quit-plan': (call) => guarded(() async {
          final s = Snapshot(call);
          // The quit date only as the member chose it; never invented.
          final date = s.date('quit_date', screen: 'bf_date');
          final plan = date == null
              ? null
              : quitPlanOf(s, kit.services.accountId ?? 'guest', date);
          if (plan == null) {
            // "Explore first", or no date chosen: no quit plan row. The
            // answers are kept through the sync document instead.
            return saveBreatheFreeAnswers(kit, s);
          }
          if (!kit.services.signedIn) {
            await guest.save(GuestQuitPlanSnapshot(
                plan: plan,
                stage: GuestPlanStage.active,
                savedAt: DateTime.now().toUtc()));
            return const TResult.ok();
          }
          final r = await kit.api.account.putQuitPlan(plan);
          await kit.data.refresh();
          return resultOf(r);
        }),
    'POST /v1/quit-plan/guest-import': (call) => guarded(() async {
          if (!kit.services.signedIn) {
            return const TResult.failed(HandlerCodes.signInRequired);
          }
          final choice = Snapshot(call).one('value') ?? '';
          if (choice.startsWith('Keep both')) return const TResult.ok();
          // "Merge": this phone's answers and entries go to the account.
          await kit.services.openSync();
          await kit.services.sync.adoptGuest();
          await kit.services.outbox.adoptGuest();
          await adoptGuestSafetyPlan(kit.services, kit.services.accountId!);
          if (choice.startsWith('Use this phone')) {
            final plan = (await guest.load())?.plan;
            if (plan != null) {
              var r = await kit.api.account.importGuestQuitPlan(plan);
              if (r.errorOrNull?.status == 409) {
                r = await kit.api.account.putQuitPlan(plan);
              }
              if (!r.isSuccess) return resultOf(r);
            }
          }
          await guest.clear();
          await kit.services.sync.sync();
          await kit.services.outbox.flush();
          await kit.data.refresh();
          return const TResult.ok();
        }),
    'POST /v1/account/export': (call) async {
      if (!kit.services.signedIn) {
        return const TResult.failed(HandlerCodes.signInRequired);
      }
      return resultOf(await kit.api.account.export());
    },
    'DELETE /v1/account/data': (call) => guarded(() async {
          final id = kit.services.accountId;
          if (id == null) {
            return const TResult.failed(HandlerCodes.signInRequired);
          }
          final s = Snapshot(call);
          if (s.text('type_delete_to_confirm') != 'DELETE') {
            return const TResult.failed('confirmation_required');
          }
          final password = s.raw('password');
          if (password is String && password.isNotEmpty) {
            try {
              await kit.services.backend.auth
                  .reauthenticate(password: password);
            } catch (_) {
              return const TResult.failed('invalid_credentials');
            }
          }
          final records = DeletionRecords(kit.services.local);
          // Recorded before the server is asked, so an interrupted deletion
          // is found again on the next start.
          await records.put(id, {'state': 'requested'});
          final r = await kit.api.account.deleteData();
          final receipt = r.valueOrNull;
          if (receipt == null) {
            // The server deleted nothing: neither does the phone.
            await records.remove(id);
            return resultOf(r);
          }
          await records
              .put(id, {'state': 'server_done', 'receipt': receipt.toJson()});
          final cleaned =
              await cleanUpAccount(kit.services, kit.cleaners, kit.pending, id);
          if (cleaned) {
            await records
                .put(id, {'state': 'complete', 'receipt': receipt.toJson()});
          }
          try {
            await kit.services.backend.wipeLocal();
            await kit.services.backend.auth.signOut();
          } catch (_) {
            // The account is gone on the server; the session ends with it.
          }
          await kit.data.refresh();
          return const TResult.ok();
        }),
  };
}
