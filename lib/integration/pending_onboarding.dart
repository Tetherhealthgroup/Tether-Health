// Onboarding answers recorded on the phone before an account exists, and
// the commit that sends them after sign-up, in order: enrolments, consents,
// plans, events (then the profile basics).
//
// The member gave their consent to sending on ob_consent. "Continue on this
// phone only" keeps everything here. Signing in to an existing account does
// not commit: that account's data is merged only after "Merge".
import 'dart:convert';

import '../api/tether_api.dart';
import '../backend/post_auth_hooks.dart';
import '../data/app_services.dart';
import '../sync/sync_store.dart';

/// A programme choice from onboarding.
class PendingProgramme {
  const PendingProgramme(this.code, this.status, {this.mode});

  final String code;
  final EnrolmentStatus status;
  final EnrolmentMode? mode;

  Map<String, Object?> toJson() => {
        'code': code,
        'status': status.wire,
        if (mode != null) 'mode': mode!.wire
      };

  static PendingProgramme fromJson(Map<String, Object?> json) =>
      PendingProgramme(
        json['code']! as String,
        EnrolmentStatus.fromWire(json['status']),
        mode: EnrolmentMode.fromWire(json['mode']),
      );
}

/// The pending onboarding record (one, on this phone).
class PendingOnboarding {
  PendingOnboarding(this._store);

  final SyncDocumentStore _store;
  static const String _scope = 'onboarding';

  Future<Map<String, Object?>> read() async {
    try {
      final text = await _store.read(_scope);
      return text == null
          ? <String, Object?>{}
          : (jsonDecode(text) as Map).cast<String, Object?>();
    } catch (_) {
      return <String, Object?>{};
    }
  }

  Future<void> _write(Map<String, Object?> record) =>
      _store.write(_scope, jsonEncode(record));

  /// Records the programme choices (replacing earlier ones).
  Future<void> setProgrammes(List<PendingProgramme> programmes) async {
    final record = await read();
    record['programmes'] = [for (final p in programmes) p.toJson()];
    await _write(record);
  }

  /// Adds one programme choice (a catalogue "Learn only" before sign-up).
  Future<void> addProgramme(PendingProgramme programme) async {
    final record = await read();
    final list = [
      for (final p in (record['programmes'] as List<Object?>?) ?? const [])
        if ((p! as Map)['code'] != programme.code) p,
      programme.toJson(),
    ];
    record['programmes'] = list;
    await _write(record);
  }

  /// Records the consent choices of ob_consent, by purpose.
  Future<void> setConsents(Set<ConsentPurpose> purposes) async {
    final record = await read();
    record['consents'] = [for (final p in purposes) p.wire];
    await _write(record);
  }

  /// Records the profile basics (name and baseline bands).
  Future<void> setBasics(Map<String, Object?> basics) async {
    final record = await read();
    record['basics'] = basics;
    await _write(record);
  }

  Future<List<PendingProgramme>> programmes() async => [
        for (final p
            in ((await read())['programmes'] as List<Object?>?) ?? const [])
          PendingProgramme.fromJson((p! as Map).cast<String, Object?>()),
      ];

  Future<Set<ConsentPurpose>> consents() async => {
        for (final p
            in ((await read())['consents'] as List<Object?>?) ?? const [])
          ConsentPurpose.fromWire(p),
      };

  Future<void> clear() => _store.delete(_scope);

  /// The post-auth step: after sign-up, sends what was recorded. Throws on
  /// a failure so the step can be retried; what was sent stays sent.
  PostAuthHook commitHook(AppServices services) => (event) async {
        if (!event.isNewAccount) return;
        await commit(services);
      };

  /// Sends the record: enrolments, then consents, then plans, then events,
  /// then the basics. Clears it when everything was accepted.
  Future<void> commit(AppServices services) async {
    final record = await read();
    if (record.isEmpty) return;
    final api = services.api;
    // 1. Enrolments.
    final ids = <String, String>{};
    final existing = await api.enrolments.list();
    for (final e in existing.valueOrNull?.enrolments ?? const <Enrolment>[]) {
      ids[e.programmeCode] = e.id;
    }
    for (final p in await programmes()) {
      if (ids.containsKey(p.code)) continue;
      final created = await api.enrolments
          .create(programmeCode: p.code, status: p.status, mode: p.mode);
      final id = created.valueOrNull?.id;
      if (id == null) throw StateError('enrolment failed');
      ids[p.code] = id;
    }
    // 2. Consents, core first, on each enrolment.
    final list = (await api.enrolments.list()).valueOrNull;
    if (list == null) throw StateError('enrolments unavailable');
    final version = list.currentCoreConsentVersions[ConsentLocale.en];
    final wanted = await consents();
    if (version != null && wanted.contains(ConsentPurpose.core)) {
      final order = [
        ConsentPurpose.core,
        for (final p in wanted)
          if (p != ConsentPurpose.core) p,
      ];
      for (final e in list.enrolments) {
        for (final purpose in order) {
          if (purpose == ConsentPurpose.screenTime && e.programmeCode != 'sf') {
            continue;
          }
          if (e.consents.any((c) => c.purpose == purpose)) continue;
          final granted = await api.enrolments.grantConsent(
            enrolmentId: e.id,
            purpose: purpose,
            consentVersion: version,
            locale: ConsentLocale.en,
          );
          final code = granted.errorOrNull?.code;
          if (code != null && code != ApiProblemCode.consentAlreadyGranted) {
            if (purpose == ConsentPurpose.core) {
              throw StateError('consent failed');
            }
          }
        }
      }
    }
    // 3. Plans (the guest sync document), 4. events (the guest outbox).
    await services.openSync();
    await services.sync.adoptGuest();
    await services.sync.sync();
    await services.outbox.adoptGuest();
    await services.outbox.flush();
    // 5. Basics.
    final basics = (record['basics'] as Map?)?.cast<String, Object?>();
    if (basics != null) {
      final name = basics['displayName'] as String?;
      if (name != null) await api.account.updateProfile(displayName: name);
      await api.account.putBaseline(Baseline(
        ageRange: basics['ageRange'] as String?,
        sleepBand: basics['sleepBand'] as String?,
        stressBand: basics['stressBand'] as String?,
      ));
    }
    await clear();
  }
}
