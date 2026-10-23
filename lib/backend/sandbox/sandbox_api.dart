// The sandbox's copy of the API routes the app calls: the same paths,
// validation, statuses and problem codes as `api/`, over the synthetic data
// of the signed-in sandbox account.
import 'day_window.dart';
import 'sandbox_store.dart';
import 'sandbox_validation.dart';

/// The eleven programme codes, as `public.programmes` holds them.
const List<String> sandboxProgrammes = [
  'bf', 'sf', 'ca', 'hw', 'st', 're', 'nu', 'sd', 'ea', 'ck', 'be', //
];

/// Names and slugs of the catalogue (synthetic).
const Map<String, (String, String, String)> _catalogue = {
  'bf': ('breathefree', 'BreatheFree', 'tobacco'),
  'sf': ('scrollfree', 'ScrollFree', 'screen_time'),
  'ca': ('clearair', 'ClearAir', 'asthma'),
  'hw': ('heartwise', 'HeartWise', 'heart'),
  'st': ('steady', 'Steady', 'diabetes'),
  're': ('renew', 'Renew', 'kidney'),
  'nu': ('nourish', 'Nourish', 'nutrition'),
  'sd': ('steadyon', 'SteadyOn', 'falls'),
  'ea': ('ease', 'Ease', 'mood'),
  'ck': ('checkup', 'CheckUp', 'prevention'),
  'be': ('beyond', 'Beyond', 'cancer'),
};

/// The sandbox's draft consent document version (all purposes, both
/// locales).
const String sandboxConsentVersion = 'sandbox-draft-1';

/// The care invite code that redeems in the sandbox.
const String sandboxInviteCode = 'TETHER-SANDBOX-CLINIC';

const Set<String> _purposes = {
  'core', 'reminders', 'records_import', 'share_care_team', //
  'share_caregiver', 'research', 'screen_time',
};
const Set<String> _sharePurposes = {'share_care_team', 'share_caregiver'};

final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
final RegExp _appKey = RegExp(r'^[0-9a-f]{32}$');

/// One API request inside a sandbox transaction.
class SandboxCall {
  SandboxCall({
    required this.state,
    required this.userId,
    required this.body,
    required this.query,
    required this.params,
    required this.idempotencyKey,
    required this.now,
    required this.recentAuth,
    this.offsetOf = deviceZoneOffset,
  });

  final Json state;
  final String userId;
  final Object? body;
  final Map<String, String> query;
  final Map<String, String> params;
  final String? idempotencyKey;
  final DateTime now;

  /// Whether the sign-in is recent enough for export and deletion.
  final bool recentAuth;
  final ZoneOffset offsetOf;

  String get nowText => now.toUtc().toIso8601String();

  /// The account's data, created on first use.
  Json get data {
    final all = state['data']! as Json;
    return (all[userId] ??= newAccountData(userId, nowText)) as Json;
  }

  List<Object?> list(String key) =>
      (data[key] ??= <Object?>[]) as List<Object?>;

  String newId() => SandboxStore.nextId(state, userId);
}

/// What a sandbox route answers: a status and a JSON body (null for none).
class SandboxAnswer {
  const SandboxAnswer(this.status, [this.json]);

  final int status;
  final Object? json;
}

/// The data of a new sandbox account.
Json newAccountData(String userId, String now) => <String, Object?>{
      'profile': <String, Object?>{
        'id': userId,
        'displayName': null,
        'locale': 'en',
        'timeZone': 'UTC',
        'onboardingCompleted': false,
        'avatarPath': null,
        'avatarUrl': null,
        'avatarUrlExpiresAt': null,
        'createdAt': now,
        'updatedAt': now,
      },
      'baseline': null,
      'quitPlan': null,
      'enrolments': <Object?>[],
      'consents': <Object?>[],
      'submissions': <String, Object?>{},
      'entries': <Object?>[],
      'observations': <Object?>[],
      'lessons': <Object?>[],
      'notifications': null,
      'sync': <String, Object?>{'seq': 0, 'areas': <String, Object?>{}},
      'care': <String, Object?>{},
      'records': <String, Object?>{},
    };

// ---------------------------------------------------------------------------
// Profile, baseline, quit plan, catalogue, app config.

SandboxAnswer getProfile(SandboxCall c) =>
    SandboxAnswer(200, c.data['profile']);

SandboxAnswer patchProfile(SandboxCall c) {
  final body = validated(
      c.body,
      {
        'displayName': const StrRule(nullable: true, max: 80),
        'locale': const EnumRule({'en', 'es'}),
        'timeZone': const StrRule(min: 1, max: 64),
        'onboardingCompleted': const BoolRule(),
        'avatarPath': const StrRule(nullable: true, max: 512),
      },
      c.now);
  if (body.isEmpty) throw const SandboxProblem(400, 'bad_request');
  final profile = c.data['profile']! as Json
    ..addAll(body)
    ..['updatedAt'] = c.nowText;
  return SandboxAnswer(200, profile);
}

const _baselineRules = {
  'ageRange': EnumRule(
      {'18_24', '25_34', '35_44', '45_54', '55_64', '65_74', '75_plus'},
      nullable: true),
  'sleepBand': EnumRule({'lt5', '5_6', '7_8', '9plus'}, nullable: true),
  'stressBand': EnumRule({'low', 'some', 'high'}, nullable: true),
};

Json _baselineOf(Object? stored) {
  final b = (stored as Json?) ?? const <String, Object?>{};
  return {
    'ageRange': b['ageRange'],
    'sleepBand': b['sleepBand'],
    'stressBand': b['stressBand'],
  };
}

SandboxAnswer getBaseline(SandboxCall c) =>
    SandboxAnswer(200, _baselineOf(c.data['baseline']));

SandboxAnswer putBaseline(SandboxCall c) {
  final body =
      validated(c.body, _baselineRules, c.now, code: 'invalid_request');
  c.data['baseline'] = _baselineOf(body);
  return SandboxAnswer(200, c.data['baseline']);
}

Json _quitPlanBody(SandboxCall c) {
  final body = c.body;
  if (body is! Map) throw const SandboxProblem(400, 'bad_request');
  try {
    final checked = checkObject(
        body,
        {
          'dailyCigaretteUse': const EnumRule({
            'notEveryDay', 'tenOrFewer', 'elevenToTwenty', //
            'twentyOneToThirty', 'thirtyOneOrMore',
          }, required: true, nullable: true),
          'smokingTriggers': const SetRule({
            'stress', 'afterMeals', 'driving', 'coffee', 'socialSettings', //
            'workBreaks', 'alcohol', 'boredom', 'morning', 'beforeBed',
            'scrolling',
          }, required: true, max: 11),
          'customSmokingTrigger':
              const StrRule(required: true, nullable: true, min: 1, max: 120),
          'readinessPath':
              const EnumRule({'prepare', 'explore', 'connect'}, required: true),
          'quitPlanPath': const EnumRule(
              {'setQuitDate', 'quitToday', 'reduceGradually', 'exploreFirst'},
              required: true),
          'quitDate':
              const StrRule(required: true, pattern: null, min: 10, max: 10),
          'quitDayCheckIn': const BoolRule(required: true),
          'quitReasons': const SetRule({
            'family', 'breatheEasier', 'improveHealth', 'saveMoney', //
            'control', 'future', 'custom',
          }, required: true, max: 7),
          'customQuitReason':
              const StrRule(required: true, nullable: true, min: 1, max: 160),
          'topQuitReason': const EnumRule({
            'family', 'breatheEasier', 'improveHealth', 'saveMoney', //
            'control', 'future', 'custom',
          }, required: true, nullable: true),
          'supportPeople': const _AnyListRule(max: 10),
          'preparationTasks': const SetRule(
              {'removeSupplies', 'smokeFreeSpaces', 'stockAlternatives'},
              required: true, max: 3),
          'treatmentSupport': const BoolRule(required: true),
          'careTeamReminder': const BoolRule(required: true),
        },
        c.now);
    DateTime.parse(checked['quitDate']! as String);
    if (checked['quitPlanPath'] == 'exploreFirst' &&
        checked['readinessPath'] != 'explore') {
      throw const FormatException();
    }
    return checked;
  } on FormatException {
    throw const SandboxProblem(400, 'bad_request');
  }
}

class _AnyListRule extends FieldRule {
  const _AnyListRule({this.max = 10}) : super(required: true);
  final int max;

  @override
  Object? check(Object? value, DateTime now) {
    if (value is! List || value.length > max) throw const FormatException();
    return value;
  }
}

SandboxAnswer getQuitPlan(SandboxCall c) {
  final plan = c.data['quitPlan'];
  if (plan == null) throw const SandboxProblem(404, 'not_found');
  return SandboxAnswer(200, plan);
}

SandboxAnswer putQuitPlan(SandboxCall c) {
  final body = _quitPlanBody(c);
  final existing = c.data['quitPlan'] as Json?;
  c.data['quitPlan'] = {
    ...body,
    'userId': c.userId,
    'createdAt': existing?['createdAt'] ?? c.nowText,
    'updatedAt': c.nowText,
  };
  return SandboxAnswer(200, c.data['quitPlan']);
}

SandboxAnswer importGuestQuitPlan(SandboxCall c) {
  final body = _quitPlanBody(c);
  if (c.data['quitPlan'] != null) throw const SandboxProblem(409, 'conflict');
  c.data['quitPlan'] = {
    ...body,
    'userId': c.userId,
    'createdAt': c.nowText,
    'updatedAt': c.nowText,
  };
  return SandboxAnswer(201, c.data['quitPlan']);
}

SandboxAnswer getCatalogue(SandboxCall c) => SandboxAnswer(200, {
      'programmes': [
        for (final code in sandboxProgrammes)
          {
            'code': code,
            'slug': _catalogue[code]!.$1,
            'name': _catalogue[code]!.$2,
            'area': _catalogue[code]!.$3,
            'archetype': 'programme',
            'receivesResources': <String>[],
          },
      ],
    });

SandboxAnswer getAppConfig(SandboxCall c) => const SandboxAnswer(200, {
      'minimumVersion': {'ios': '1.0.0', 'android': '1.0.0'},
    });

// ---------------------------------------------------------------------------
// Account export and deletion.

SandboxAnswer exportAccount(SandboxCall c) {
  if (!c.recentAuth) throw const SandboxProblem(401, 'unauthenticated');
  final d = c.data;
  return SandboxAnswer(200, {
    'schemaVersion': '1.0',
    'generatedAt': c.nowText,
    'profile': d['profile'],
    'quitPlan': d['quitPlan'],
    'programData': <Object?>[],
    // Every other row of the account, so the export holds all of it.
    'sandbox': {
      for (final key in d.keys)
        if (!const {'profile', 'quitPlan', 'submissions'}.contains(key))
          key: d[key],
    },
  });
}

/// The receipt's `deleted` key set, as the API's.
const List<String> deletionReceiptKeys = [
  'profiles', 'quitPlans', 'avatarObjects', 'programData', //
];

/// Deletes the account's data and returns the receipt. The caller removes
/// the identity and the session.
SandboxAnswer deleteAccountData(SandboxCall c) {
  final body = validated(
      c.body,
      {
        'confirmation': const StrRule(required: true),
      },
      c.now);
  if (body['confirmation'] != 'DELETE') {
    throw const SandboxProblem(400, 'bad_request');
  }
  if (!c.recentAuth) throw const SandboxProblem(401, 'unauthenticated');
  final all = c.state['data']! as Json;
  final had = all.remove(c.userId) as Json?;
  return SandboxAnswer(200, {
    'requestId': c.newId(),
    'completedAt': c.nowText,
    'deleted': {
      'profiles': had == null ? 0 : 1,
      'quitPlans': had?['quitPlan'] == null ? 0 : 1,
      'avatarObjects': 0,
      'programData': 0,
    },
    'authIdentityDeleted': true,
    'authIdentityStatus': 'deleted',
  });
}

// ---------------------------------------------------------------------------
// Enrolments and consents.

List<Json> _enrolments(SandboxCall c) =>
    [for (final e in c.list('enrolments')) e! as Json];

List<Json> _consents(SandboxCall c) =>
    [for (final x in c.list('consents')) x! as Json];

Json _ownEnrolment(SandboxCall c, String id) {
  for (final e in _enrolments(c)) {
    if (e['id'] == id) return e;
  }
  throw const SandboxProblem(404, 'enrolment_not_found');
}

Json? _liveCore(SandboxCall c, String enrolmentId) {
  for (final x in _consents(c)) {
    if (x['enrolmentId'] == enrolmentId &&
        x['purpose'] == 'core' &&
        x['revokedAt'] == null) {
      return x;
    }
  }
  return null;
}

Json _consentView(Json x, {bool granted = false}) => {
      'id': x['id'],
      'enrolmentId': x['enrolmentId'],
      'purpose': x['purpose'],
      'recipientRef': x['recipientRef'],
      'consentVersion': x['consentVersion'],
      'locale': x['locale'],
      'consentText': x['consentText'],
      'grantedAt': x['grantedAt'],
      'revokedAt': x['revokedAt'],
      if (granted) 'supersededId': x['supersededId'],
    };

Json enrolmentView(SandboxCall c, Json e) {
  final live = [
    for (final x in _consents(c))
      if (x['enrolmentId'] == e['id'] && x['revokedAt'] == null)
        _consentView(x),
  ];
  final core = _liveCore(c, e['id']! as String);
  final current = core == null ? null : sandboxConsentVersion;
  return {
    ...e,
    'consents': live,
    'currentCoreConsentVersion': current,
    'reconsentRequired': e['status'] != 'left' &&
        core != null &&
        core['consentVersion'] != sandboxConsentVersion,
  };
}

int _focusCount(SandboxCall c, {String? except}) => _enrolments(c)
    .where((e) => e['status'] == 'focus' && e['id'] != except)
    .length;

SandboxAnswer listEnrolments(SandboxCall c) => SandboxAnswer(200, {
      'currentCoreConsentVersions': {
        'en': sandboxConsentVersion,
        'es': sandboxConsentVersion,
      },
      'enrolments': [for (final e in _enrolments(c)) enrolmentView(c, e)],
    });

const _modeRule = EnumRule({'quit', 'reduce'}, nullable: true);

SandboxAnswer createEnrolment(SandboxCall c) {
  final body = validated(
      c.body,
      {
        'programmeCode':
            StrRule(required: true, pattern: RegExp(r'^[a-z]{2}$')),
        'status':
            const EnumRule({'focus', 'learn_only', 'paused'}, required: true),
        'mode': _modeRule,
      },
      c.now);
  final code = body['programmeCode']! as String;
  if (body['mode'] != null && code != 'bf' && code != 'sf') {
    throw const SandboxProblem(400, 'mode_not_allowed');
  }
  if (!sandboxProgrammes.contains(code)) {
    throw const SandboxProblem(404, 'programme_not_found');
  }
  if (_enrolments(c).any((e) => e['programmeCode'] == code)) {
    throw const SandboxProblem(409, 'already_enrolled');
  }
  if (body['status'] == 'focus' && _focusCount(c) >= 2) {
    throw const SandboxProblem(409, 'focus_cap_reached');
  }
  final enrolment = <String, Object?>{
    'id': c.newId(),
    'programmeCode': code,
    'status': body['status'],
    'mode': body['mode'],
    'joinedAt': c.nowText,
    'leftAt': null,
    'createdAt': c.nowText,
    'updatedAt': c.nowText,
  };
  c.list('enrolments').add(enrolment);
  return SandboxAnswer(201, enrolmentView(c, enrolment));
}

String _idParam(SandboxCall c, {String code = 'bad_request'}) {
  final id = c.params['id'] ?? '';
  if (!_uuid.hasMatch(id)) throw SandboxProblem(400, code);
  return id.toLowerCase();
}

SandboxAnswer updateEnrolment(SandboxCall c) {
  final id = _idParam(c);
  final body = validated(
      c.body,
      {
        'status': const EnumRule({'focus', 'learn_only', 'paused', 'left'}),
        'mode': _modeRule,
      },
      c.now);
  if (body.isEmpty) throw const SandboxProblem(400, 'bad_request');
  final e = _ownEnrolment(c, id);
  if (body.containsKey('mode') &&
      body['mode'] != null &&
      e['programmeCode'] != 'bf' &&
      e['programmeCode'] != 'sf') {
    throw const SandboxProblem(400, 'mode_not_allowed');
  }
  if (body['status'] == 'focus' &&
      e['status'] != 'focus' &&
      _focusCount(c, except: id) >= 2) {
    throw const SandboxProblem(409, 'focus_cap_reached');
  }
  if (body.containsKey('status')) {
    final status = body['status'];
    e['leftAt'] = status == 'left' ? (e['leftAt'] ?? c.nowText) : null;
    if (status == 'left' && e['status'] != 'left') {
      // Leaving switches off every optional consent; core stays live but
      // grants nothing while the enrolment is left.
      for (final x in _consents(c)) {
        if (x['enrolmentId'] == id &&
            x['purpose'] != 'core' &&
            x['revokedAt'] == null) {
          x['revokedAt'] = c.nowText;
        }
      }
    }
    e['status'] = status;
  }
  if (body.containsKey('mode')) e['mode'] = body['mode'];
  e['updatedAt'] = c.nowText;
  return SandboxAnswer(200, enrolmentView(c, e));
}

SandboxAnswer deleteEnrolment(SandboxCall c) {
  final id = _idParam(c);
  final body = c.body;
  if (body is! Map || body['confirmation'] != 'DELETE') {
    throw const SandboxProblem(400, 'confirmation_required');
  }
  if (!c.recentAuth) {
    throw const SandboxProblem(401, 'recent_authentication_required');
  }
  final e = _ownEnrolment(c, id);
  final code = e['programmeCode'];
  c.list('enrolments').remove(e);
  c.list('consents').removeWhere((x) => (x! as Json)['enrolmentId'] == id);
  for (final key in ['entries', 'observations', 'lessons']) {
    c.list(key).removeWhere((r) => (r! as Json)['programme'] == code);
  }
  ((c.data['sync']! as Json)['areas']! as Json).remove(code);
  return const SandboxAnswer(204);
}

SandboxAnswer swapFocus(SandboxCall c) {
  final body = validated(
      c.body,
      {
        'demoteId': StrRule(required: true, pattern: _uuid),
        'promoteId': StrRule(required: true, pattern: _uuid),
      },
      c.now);
  final demote = _ownEnrolment(c, (body['demoteId']! as String).toLowerCase());
  final promote =
      _ownEnrolment(c, (body['promoteId']! as String).toLowerCase());
  if (demote == promote ||
      demote['status'] != 'focus' ||
      promote['status'] == 'focus' ||
      promote['status'] == 'left') {
    throw const SandboxProblem(409, 'focus_swap_invalid');
  }
  demote
    ..['status'] = 'paused'
    ..['updatedAt'] = c.nowText;
  promote
    ..['status'] = 'focus'
    ..['updatedAt'] = c.nowText;
  return SandboxAnswer(200, {
    'demoted': enrolmentView(c, demote),
    'promoted': enrolmentView(c, promote),
  });
}

SandboxAnswer grantConsent(SandboxCall c) {
  final body = validated(
      c.body,
      {
        'enrolmentId': StrRule(required: true, pattern: _uuid),
        'purpose': const EnumRule(_purposes, required: true),
        'recipientRef': StrRule(pattern: _uuid),
        'consentVersion': StrRule(
            required: true,
            pattern: RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$')),
        'locale': const EnumRule({'en', 'es'}, required: true),
      },
      c.now);
  final purpose = body['purpose']! as String;
  final share = _sharePurposes.contains(purpose);
  if (share != body.containsKey('recipientRef')) {
    throw const SandboxProblem(400, 'bad_request');
  }
  final e = _ownEnrolment(c, (body['enrolmentId']! as String).toLowerCase());
  if (e['status'] == 'left') throw const SandboxProblem(409, 'enrolment_left');
  if (body['consentVersion'] != sandboxConsentVersion) {
    throw const SandboxProblem(409, 'consent_document_unavailable');
  }
  final recipient = (body['recipientRef'] as String?)?.toLowerCase();
  final core = _liveCore(c, e['id']! as String);
  String? superseded;
  if (purpose == 'core') {
    if (core != null) {
      if (core['consentVersion'] == body['consentVersion'] &&
          core['locale'] == body['locale']) {
        throw const SandboxProblem(409, 'consent_already_granted');
      }
      core['revokedAt'] = c.nowText;
      superseded = core['id'] as String?;
    }
  } else {
    if (core == null) throw const SandboxProblem(409, 'core_consent_required');
    final duplicate = _consents(c).any((x) =>
        x['enrolmentId'] == e['id'] &&
        x['purpose'] == purpose &&
        x['recipientRef'] == recipient &&
        x['revokedAt'] == null);
    if (duplicate) throw const SandboxProblem(409, 'consent_already_granted');
    if (share && !_isLiveRecipient(c, purpose, recipient!)) {
      throw const SandboxProblem(409, 'consent_recipient_invalid');
    }
  }
  final consent = <String, Object?>{
    'id': c.newId(),
    'enrolmentId': e['id'],
    'purpose': purpose,
    'recipientRef': recipient,
    'consentVersion': body['consentVersion'],
    'locale': body['locale'],
    'consentText': 'DRAFT · sandbox consent document ($purpose). '
        'Synthetic data only.',
    'grantedAt': c.nowText,
    'revokedAt': null,
    'supersededId': superseded,
  };
  c.list('consents').add(consent);
  return SandboxAnswer(201, _consentView(consent, granted: true));
}

bool _isLiveRecipient(SandboxCall c, String purpose, String id) {
  final care = c.data['care']! as Json;
  final kind = purpose == 'share_care_team' ? 'connections' : 'caregivers';
  final rows = (care[kind] as List<Object?>?) ?? const [];
  return rows.any((r) => (r! as Json)['id'] == id);
}

void _revoke(SandboxCall c, Json consent) {
  if (consent['purpose'] == 'core') {
    for (final x in _consents(c)) {
      if (x['enrolmentId'] == consent['enrolmentId'] &&
          x['revokedAt'] == null) {
        x['revokedAt'] = c.nowText;
      }
    }
  }
  consent['revokedAt'] = c.nowText;
}

SandboxAnswer revokeConsentByPurpose(SandboxCall c) {
  final body = validated(
      c.body,
      {
        'enrolmentId': StrRule(required: true, pattern: _uuid),
        'purpose': const EnumRule(_purposes, required: true),
        'recipientRef': StrRule(pattern: _uuid),
        'revoked': const BoolRule(required: true),
      },
      c.now);
  if (body['revoked'] != true) throw const SandboxProblem(400, 'bad_request');
  final purpose = body['purpose']! as String;
  if (body.containsKey('recipientRef') && !_sharePurposes.contains(purpose)) {
    throw const SandboxProblem(400, 'bad_request');
  }
  final e = _ownEnrolment(c, (body['enrolmentId']! as String).toLowerCase());
  final recipient = (body['recipientRef'] as String?)?.toLowerCase();
  final live = [
    for (final x in _consents(c))
      if (x['enrolmentId'] == e['id'] &&
          x['purpose'] == purpose &&
          x['revokedAt'] == null &&
          (recipient == null || x['recipientRef'] == recipient))
        x,
  ];
  if (live.isEmpty) throw const SandboxProblem(404, 'consent_not_found');
  if (live.length > 1) {
    throw const SandboxProblem(409, 'consent_recipient_required');
  }
  _revoke(c, live.single);
  return SandboxAnswer(200, _consentView(live.single));
}

SandboxAnswer revokeConsentById(SandboxCall c) {
  final id = _idParam(c);
  final body = validated(
      c.body,
      {
        'revoked': const BoolRule(required: true),
      },
      c.now);
  if (body['revoked'] != true) throw const SandboxProblem(400, 'bad_request');
  final consent = _consents(c).where((x) => x['id'] == id).firstOrNull;
  if (consent == null) throw const SandboxProblem(404, 'consent_not_found');
  if (consent['revokedAt'] != null) {
    throw const SandboxProblem(409, 'consent_already_revoked');
  }
  _revoke(c, consent);
  return SandboxAnswer(200, _consentView(consent));
}

// ---------------------------------------------------------------------------
// Programme events.

/// One event route: its body rules, spec ranges (422 value_out_of_range),
/// measurement fields (0–10000, else 422 invalid_record), and what it
/// stores.
class _EventRoute {
  const _EventRoute(
    this.fields,
    this.build, {
    this.atLeastOne = const [],
    this.ranges = const {},
    this.measurements = const [],
  });

  final Map<String, FieldRule> fields;
  final List<String> atLeastOne;
  final Map<String, (num, num)> ranges;
  final List<String> measurements;

  /// (observations as metric → value, entry kind and payload or null, time)
  final (Map<String, num>, String?, Json, String?) Function(Json body) build;
}

const _occurred = TimeRule();
const _measurement = NumRule();

String? _labTime(Object? date) => date == null ? null : '${date}T00:00:00.000Z';

Json _present(Map<String, Object?> values) => {
      for (final e in values.entries)
        if (e.value != null) e.key: e.value,
    };

final Map<String, _EventRoute> _eventRoutes = {
  'hw/readings': _EventRoute(
    {
      'systolic': const IntRule(required: true),
      'diastolic': const IntRule(required: true),
      // Bounded as a measurement: outside 0–10000 is 422 invalid_record.
      'pulse': const IntRule(),
      'measuredAt': _occurred,
    },
    (b) => (
      {
        'bp_systolic': b['systolic']! as num,
        'bp_diastolic': b['diastolic']! as num,
        if (b['pulse'] != null) 'heart_rate': b['pulse']! as num,
      },
      null,
      const {},
      b['measuredAt'] as String?,
    ),
    ranges: {'systolic': (70, 250), 'diastolic': (40, 150)},
  ),
  'hw/lipids': _EventRoute(
    {
      'total': _measurement,
      'ldl': _measurement,
      'hdl': _measurement,
      'triglycerides': _measurement,
      'labDate': const DateRule(required: true),
    },
    (b) => (
      {
        if (b['total'] != null) 'chol_total': b['total']! as num,
        if (b['ldl'] != null) 'chol_ldl': b['ldl']! as num,
        if (b['hdl'] != null) 'chol_hdl': b['hdl']! as num,
        if (b['triglycerides'] != null)
          'triglycerides': b['triglycerides']! as num,
      },
      null,
      const {},
      _labTime(b['labDate']),
    ),
    atLeastOne: ['total', 'ldl', 'hdl', 'triglycerides'],
    measurements: ['total', 'ldl', 'hdl', 'triglycerides'],
  ),
  'st/readings': _EventRoute(
    {
      'reading': const NumRule(required: true),
      'when': const EnumRule(
          {'fasting', 'before_meal', '2_h_after_meal', 'bedtime', 'other'}),
      'feelings':
          const SetRule({'fine', 'shaky', 'sweaty', 'tired', 'thirsty'}),
      'note': const StrRule(min: 1, max: 500, trim: true),
      'measuredAt': _occurred,
    },
    (b) => (
      {'glucose': b['reading']! as num},
      null,
      _present(
          {'timing': b['when'], 'feelings': b['feelings'], 'note': b['note']}),
      b['measuredAt'] as String?,
    ),
    ranges: {'reading': (20, 600)},
  ),
  'st/a1c': _EventRoute(
    {
      'a1c': const NumRule(required: true),
      'labDate': const DateRule(required: true),
    },
    (b) => ({'a1c': b['a1c']! as num}, null, const {}, _labTime(b['labDate'])),
    measurements: ['a1c'],
  ),
  're/labs': _EventRoute(
    {
      'egfr': _measurement,
      'urineAcr': _measurement,
      'alt': _measurement,
      'labDate': const DateRule(required: true),
    },
    (b) => (
      {
        if (b['egfr'] != null) 'egfr': b['egfr']! as num,
        if (b['urineAcr'] != null) 'urine_acr': b['urineAcr']! as num,
        if (b['alt'] != null) 'alt': b['alt']! as num,
      },
      null,
      const {},
      _labTime(b['labDate']),
    ),
    atLeastOne: ['egfr', 'urineAcr', 'alt'],
    measurements: ['egfr', 'urineAcr', 'alt'],
  ),
  'ca/zone-checks': _EventRoute(
    {
      'zone': const EnumRule({'green', 'yellow', 'red'}, required: true),
      'symptoms': const SetRule({
        'coughing', 'wheezing', 'short_of_breath', 'chest_tightness', //
        'woke_at_night', 'can_t_speak_in_full_sentences',
      }),
      'peakFlow': const NumRule(),
      'checkedAt': _occurred,
    },
    (b) => (
      {if (b['peakFlow'] != null) 'peak_flow': b['peakFlow']! as num},
      'ca.zone_check',
      _present({'zone': b['zone'], 'symptoms': b['symptoms']}),
      b['checkedAt'] as String?,
    ),
    ranges: {'peakFlow': (50, 900)},
  ),
  'ca/symptoms': _EventRoute(
    {
      'symptoms': const SetRule({
        'coughing', 'wheezing', 'short_of_breath', 'chest_tightness', //
        'woke_at_night',
      }, required: true, min: 1),
      'severity': const EnumRule({'mild', 'moderate', 'severe'}),
      'triggers': const SetRule(
          {'cold_air', 'smoke', 'pollen', 'exercise', 'not_sure'}),
      'note': const StrRule(min: 1, max: 500, trim: true),
      'occurredAt': _occurred,
    },
    (b) => (
      const {},
      'ca.symptom',
      _present({
        'symptoms': b['symptoms'],
        'severity': b['severity'],
        'triggers': b['triggers'],
        'note': b['note'],
      }),
      b['occurredAt'] as String?,
    ),
  ),
  'ea/moods': _EventRoute(
    {
      'mood': const EnumRule({'very_low', 'low', 'okay', 'good', 'great'},
          required: true),
      'topics': const SetRule({
        'work', 'money', 'family', 'health', 'lonely', 'sleep', //
        'thoughts_of_harming_myself', 'not_sure',
      }),
      'occurredAt': _occurred,
    },
    (b) => (
      const {},
      'ea.mood',
      _present({'mood': b['mood'], 'topics': b['topics']}),
      b['occurredAt'] as String?,
    ),
  ),
  'ea/check-backs': _EventRoute(
    {
      'change': const EnumRule({'worse', 'same', 'better'}, required: true),
      'reachedOut': const EnumRule(
          {'yes_i_have_an_appointment', 'not_yet', 'i_don_t_want_to'}),
      'occurredAt': _occurred,
    },
    (b) => (
      const {},
      'ea.check_back',
      _present({'change': b['change'], 'reached_out': b['reachedOut']}),
      b['occurredAt'] as String?,
    ),
  ),
  'sd/sessions': _EventRoute(
    {
      'settings': const SetRule({'audio_on', 'large_text', 'captions'}),
      'occurredAt': _occurred,
    },
    (b) => (
      const {},
      'sd.session',
      _present({'settings': b['settings']}),
      b['occurredAt'] as String?,
    ),
  ),
  'sd/falls': _EventRoute(
    {'occurredAt': _occurred},
    (b) => (const {}, 'sd.fall', const {}, b['occurredAt'] as String?),
  ),
  'sf/pauses': _EventRoute(
    {
      'reason': const EnumRule({
        'message_someone', 'bored', 'avoiding_something', 'can_t_sleep', //
      }, required: true),
      'occurredAt': _occurred,
    },
    (b) => (
      const {},
      'sf.pause',
      {'reason': b['reason']},
      b['occurredAt'] as String?,
    ),
  ),
  'ck/done': _EventRoute(
    {
      'item': StrRule(required: true, pattern: RegExp(r'^[a-z0-9_]{1,40}$')),
      'doneOn': const DateRule(required: true),
      'place': const StrRule(min: 1, max: 500, trim: true),
      'occurredAt': _occurred,
    },
    (b) => (
      const {},
      'ck.done',
      _present(
          {'item': b['item'], 'done_on': b['doneOn'], 'place': b['place']}),
      b['occurredAt'] as String?,
    ),
  ),
  'be/diary': _EventRoute(
    {
      'fatigue': const IntRule(required: true, min: 0, max: 10),
      'symptoms': const SetRule(
          {'nausea', 'pain', 'mouth_sores', 'numbness', 'low_mood'}),
      'occurredAt': _occurred,
    },
    (b) => (
      const {},
      'be.diary',
      _present({'fatigue': b['fatigue'], 'symptoms': b['symptoms']}),
      b['occurredAt'] as String?,
    ),
  ),
  'be/survivorship': _EventRoute(
    {
      'feeling': const EnumRule({'hard', 'mixed', 'good'}, required: true),
      'occurredAt': _occurred,
    },
    (b) => (
      const {},
      'be.survivorship',
      {'feeling': b['feeling']},
      b['occurredAt'] as String?,
    ),
  ),
};

/// Every event route as `code/kind`.
Iterable<String> get sandboxEventRoutes => _eventRoutes.keys;

/// The submission id of an Idempotency-Key (checked before the body).
String _submissionId(String? key) {
  if (key == null) throw const SandboxProblem(400, 'idempotency_key_required');
  if (_appKey.hasMatch(key)) {
    return '${key.substring(0, 8)}-${key.substring(8, 12)}-'
        '${key.substring(12, 16)}-${key.substring(16, 20)}-${key.substring(20)}';
  }
  if (_uuid.hasMatch(key)) return key.toLowerCase();
  throw const SandboxProblem(400, 'idempotency_key_invalid');
}

const Set<String> _timeFields = {
  'occurredAt', 'measuredAt', 'checkedAt', 'labDate', 'openedAt', //
};

/// The content of a submission without its times (times are not compared).
String _fingerprint(String route, Json body) => canonicalJson({
      'route': route,
      for (final e in body.entries)
        if (!_timeFields.contains(e.key)) e.key: e.value,
    });

/// A replay (200) when [submissionId] was stored with the same content, a
/// conflict (409) with other content, null when new.
SandboxAnswer? _replay(
  SandboxCall c,
  String submissionId,
  String fingerprint, [
  Json extra = const {},
]) {
  final stored = (c.data['submissions']! as Json)[submissionId] as Json?;
  if (stored == null) return null;
  if (stored['fingerprint'] != fingerprint) {
    throw const SandboxProblem(409, 'idempotency_key_conflict');
  }
  return SandboxAnswer(200, {
    'submissionId': submissionId,
    'replayed': true,
    ...((stored['extra'] as Json?) ?? extra),
  });
}

void _remember(SandboxCall c, String id, String fingerprint, [Json? extra]) {
  (c.data['submissions']! as Json)[id] = {
    'fingerprint': fingerprint,
    if (extra != null) 'extra': extra,
  };
}

/// The caller's enrolment in [code] that may receive records, or the
/// refusal: none → 404, left → 409, no live core → 409.
Json _writableEnrolment(SandboxCall c, String code) {
  final e = _enrolments(c).where((e) => e['programmeCode'] == code).firstOrNull;
  if (e == null) throw const SandboxProblem(404, 'enrolment_not_found');
  if (e['status'] == 'left') throw const SandboxProblem(409, 'enrolment_left');
  if (_liveCore(c, e['id']! as String) == null) {
    throw const SandboxProblem(409, 'core_consent_required');
  }
  return e;
}

Json _eventBody(SandboxCall c, Map<String, FieldRule> fields) =>
    validated(c.body, fields, c.now, code: 'invalid_request');

/// The handler of the event route `code/kind`.
SandboxAnswer Function(SandboxCall) eventHandler(String codeKind) =>
    (c) => _submitEvent(c, codeKind);

SandboxAnswer _submitEvent(SandboxCall c, String codeKind) {
  final [code, kind] = codeKind.split('/');
  final route = _eventRoutes[codeKind];
  if (route == null) throw const SandboxProblem(404, 'not_found');
  final submissionId = _submissionId(c.idempotencyKey);
  final body = _eventBody(c, route.fields);
  if (route.atLeastOne.isNotEmpty &&
      !route.atLeastOne.any((f) => body[f] != null)) {
    throw const SandboxProblem(400, 'invalid_request');
  }
  for (final MapEntry(key: name, value: (min, max)) in route.ranges.entries) {
    final value = body[name];
    if (value is num && (value < min || value > max)) {
      throw const SandboxProblem(422, 'value_out_of_range');
    }
  }
  _writableEnrolment(c, code);
  final (observations, entryKind, payload, time) = route.build(body);
  if (observations.values.any((v) => v < 0 || v > 10000)) {
    throw const SandboxProblem(422, 'invalid_record');
  }
  final fingerprint = _fingerprint('$code/$kind', body);
  final replay = _replay(c, submissionId, fingerprint);
  if (replay != null) return replay;
  final at = time ?? c.nowText;
  if (entryKind != null) {
    c.list('entries').add({
      'programme': code,
      'kind': entryKind,
      'at': at,
      'payload': payload,
      'submissionId': submissionId,
    });
  }
  for (final MapEntry(key: metric, value: value) in observations.entries) {
    c.list('observations').add({
      'programme': code,
      'metric': metric,
      'value': value,
      'unit': _units[metric] ?? '',
      'at': at,
      'attributes': entryKind == null ? payload : const <String, Object?>{},
      'submissionId': submissionId,
    });
  }
  _remember(c, submissionId, fingerprint);
  return SandboxAnswer(201, {'submissionId': submissionId});
}

const Map<String, String> _units = {
  'bp_systolic': 'mm[Hg]',
  'bp_diastolic': 'mm[Hg]',
  'heart_rate': '/min',
  'chol_total': 'mg/dL',
  'chol_ldl': 'mg/dL',
  'chol_hdl': 'mg/dL',
  'triglycerides': 'mg/dL',
  'glucose': 'mg/dL',
  'a1c': '%',
  'egfr': 'mL/min/{1.73_m2}',
  'urine_acr': 'mg/g',
  'alt': 'U/L',
  'peak_flow': 'L/min',
};

// ---------------------------------------------------------------------------
// Check-ins, rescues, lessons.

SandboxAnswer submitCheckIn(SandboxCall c) {
  final submissionId = _submissionId(c.idempotencyKey);
  final body = _eventBody(c, {
    'feel': const EnumRule({'low', 'not_great', 'okay', 'good', 'great'}),
    'stress': const EnumRule({'low', 'some', 'high'}),
    'answers': const ObjRule({
      'bf': EnumRule({'no', 'a_puff', 'one_or_more'}),
      'sf': EnumRule({'better', 'same', 'drained'}),
    }),
    'occurredAt': _occurred,
  });
  final answers = (body['answers'] as Json?) ?? const <String, Object?>{};
  if (body['feel'] == null && body['stress'] == null && answers.isEmpty) {
    throw const SandboxProblem(400, 'invalid_request');
  }
  final fingerprint = _fingerprint('check-ins', body);
  final stored = (c.data['submissions']! as Json)[submissionId];
  if (stored != null) return _replay(c, submissionId, fingerprint)!;
  final targets = [
    for (final e in _enrolments(c))
      if (e['status'] == 'focus' && _liveCore(c, e['id']! as String) != null)
        e['programmeCode']! as String,
  ];
  if (targets.isEmpty) throw const SandboxProblem(409, 'no_focus_programme');
  if (answers.keys.any((code) => !targets.contains(code))) {
    throw const SandboxProblem(422, 'invalid_record');
  }
  final shared = body['feel'] != null || body['stress'] != null;
  final rows = [
    for (final code in targets)
      if (shared || answers.containsKey(code)) code,
  ]..sort();
  final at = (body['occurredAt'] as String?) ?? c.nowText;
  for (final code in rows) {
    c.list('entries').add({
      'programme': code,
      'kind': 'check_in',
      'at': at,
      'payload': _present({
        'feel': body['feel'],
        'stress': body['stress'],
        'answer': answers[code],
      }),
      'submissionId': submissionId,
    });
  }
  _remember(c, submissionId, fingerprint, {'entries': rows});
  return SandboxAnswer(201, {'submissionId': submissionId, 'entries': rows});
}

SandboxAnswer submitRescue(SandboxCall c) {
  final submissionId = _submissionId(c.idempotencyKey);
  final body = _eventBody(c, {
    'programme': const EnumRule({'bf'}),
    'tool': StrRule(required: true, pattern: RegExp(r'^[a-z0-9_]{1,40}$')),
    'openedAt': _occurred,
    'intensityBefore': const IntRule(min: 0, max: 10),
    'intensityAfter': const IntRule(min: 0, max: 10),
    'helped': const EnumRule({'yes', 'a_little', 'no'}),
    'escalated': const BoolRule(),
  });
  final bf = body['programme'] == 'bf';
  if (bf) _writableEnrolment(c, 'bf');
  final fingerprint = _fingerprint('rescues', body);
  final replay = _replay(c, submissionId, fingerprint);
  if (replay != null) return replay;
  c.list('entries').add({
    'programme': bf ? 'bf' : null,
    'kind': 'rescue',
    'at': (body['openedAt'] as String?) ?? c.nowText,
    'payload': {
      'tool': body['tool'],
      'openedAt': (body['openedAt'] as String?) ?? c.nowText,
      'intensityBefore': body['intensityBefore'],
      'intensityAfter': body['intensityAfter'],
      'helped': body['helped'],
      'escalated': body['escalated'] ?? false,
    },
    'submissionId': submissionId,
  });
  _remember(c, submissionId, fingerprint);
  return SandboxAnswer(201, {'submissionId': submissionId});
}

SandboxAnswer submitLesson(SandboxCall c) {
  final submissionId = _submissionId(c.idempotencyKey);
  final body = _eventBody(c, {
    'programme': StrRule(required: true, pattern: RegExp(r'^[a-z]{2}$')),
    'lessonId': StrRule(
        required: true, pattern: RegExp(r'^[a-z0-9][a-z0-9_.-]{0,79}$')),
  });
  final programme = body['programme']! as String;
  final lessonId = body['lessonId']! as String;
  if (!lessonId.startsWith('$programme.')) {
    throw const SandboxProblem(400, 'invalid_request');
  }
  _writableEnrolment(c, programme);
  final fingerprint = _fingerprint('lessons', body);
  final replay = _replay(c, submissionId, fingerprint);
  if (replay != null) return replay;
  final done = c.list('lessons').any((l) =>
      (l! as Json)['programme'] == programme &&
      (l as Json)['lessonId'] == lessonId);
  _remember(c, submissionId, fingerprint);
  if (done) {
    // The lesson is the identity: a completed lesson is not stored twice.
    return SandboxAnswer(200, {'submissionId': submissionId, 'replayed': true});
  }
  c.list('lessons').add({
    'programme': programme,
    'lessonId': lessonId,
    'completedAt': c.nowText,
    'submissionId': submissionId,
  });
  return SandboxAnswer(201, {'submissionId': submissionId});
}

// ---------------------------------------------------------------------------
// Today and summary.

DateTime _at(Object? text) => DateTime.parse(text! as String).toUtc();

List<Json> _rows(SandboxCall c, String key, String? programme) => [
      for (final r in c.list(key))
        if ((r! as Json)['programme'] == programme) r as Json,
    ]..sort((a, b) => _at(a['at'] ?? a['completedAt'])
        .compareTo(_at(b['at'] ?? b['completedAt'])));

Json? _last(List<Json> rows, bool Function(Json) where) {
  for (final r in rows.reversed) {
    if (where(r)) return r;
  }
  return null;
}

List<Json> _lapses(SandboxCall c, String code) {
  final areas = (c.data['sync']! as Json)['areas']! as Json;
  final area = areas[code] as Json?;
  return [
    for (final l in (area?['lapses'] as List<Object?>?) ?? const []) l! as Json,
  ];
}

Json? _lastValue(List<Json> observations, String metric) {
  final row = _last(observations, (o) => o['metric'] == metric);
  return row == null ? null : {'value': row['value'], 'at': row['at']};
}

Json? _helpfulRescue(List<Json> entries) {
  final row = _last(
      entries,
      (e) =>
          e['kind'] == 'rescue' &&
          const {'yes', 'a_little'}
              .contains((e['payload']! as Json)['helped']));
  return row == null
      ? null
      : {'tool': (row['payload']! as Json)['tool'], 'at': row['at']};
}

SandboxAnswer getToday(SandboxCall c) {
  final profile = c.data['profile']! as Json;
  final window = dayWindow(profile['timeZone'], c.now, offsetOf: c.offsetOf);
  bool inToday(Json r) =>
      !_at(r['at']).isBefore(window.todayStart) &&
      _at(r['at']).isBefore(window.tomorrowStart);
  bool inLast7(Json r) =>
      !_at(r['at']).isBefore(window.last7Start) &&
      _at(r['at']).isBefore(window.tomorrowStart);
  final allEntries = [for (final e in c.list('entries')) e! as Json];
  final reminders = {
    for (final r in (_preferences(c)['programmeReminders']! as List<Object?>))
      (r! as Json)['programme']: (r as Json)['remindAt'],
  };
  final blocks = <Object?>[];
  for (final e in _enrolments(c)) {
    if (e['status'] == 'left') continue;
    final code = e['programmeCode']! as String;
    final entries = _rows(c, 'entries', code);
    final observations = _rows(c, 'observations', code);
    final lapses = _lapses(c, code);
    final block = <String, Object?>{
      'code': code,
      'status': e['status'],
      'mode': e['mode'],
      'reminderAt': reminders[code],
      'lessonsCompleted': c
          .list('lessons')
          .where((l) => (l! as Json)['programme'] == code)
          .length,
    };
    switch (code) {
      case 'hw':
        final s = _last(observations, (o) => o['metric'] == 'bp_systolic');
        Object? valueAt(String metric) => s == null
            ? null
            : _last(
                observations,
                (o) =>
                    o['metric'] == metric &&
                    o['submissionId'] == s['submissionId'])?['value'];
        block['lastBp'] = s == null
            ? null
            : {
                'systolic': s['value'],
                'diastolic': valueAt('bp_diastolic'),
                'pulse': valueAt('heart_rate'),
                'at': s['at'],
              };
      case 'st':
        block['lastGlucose'] = _lastValue(observations, 'glucose');
        block['lastA1c'] = _lastValue(observations, 'a1c');
      case 're':
        block['lastLabs'] = {
          'egfr': _lastValue(observations, 'egfr'),
          'urineAcr': _lastValue(observations, 'urine_acr'),
          'alt': _lastValue(observations, 'alt'),
        };
      case 'ca':
        final z = _last(entries, (r) => r['kind'] == 'ca.zone_check');
        block['lastZoneCheck'] = z == null
            ? null
            : {'zone': (z['payload']! as Json)['zone'], 'at': z['at']};
      case 'ea':
        final m = _last(entries, (r) => r['kind'] == 'ea.mood');
        block['lastMood'] = m == null
            ? null
            : {'mood': (m['payload']! as Json)['mood'], 'at': m['at']};
      case 'sd':
        block['sessionsLast7Days'] = entries
            .where((r) => r['kind'] == 'sd.session' && inLast7(r))
            .length;
        block['lastFallAt'] =
            _last(entries, (r) => r['kind'] == 'sd.fall')?['at'];
      case 'sf':
        block['pausesToday'] =
            entries.where((r) => r['kind'] == 'sf.pause' && inToday(r)).length;
        block['lapsesLast7Days'] = lapses.where(inLast7).length;
      case 'ck':
        final d = _last(entries, (r) => r['kind'] == 'ck.done');
        block['lastDone'] = d == null
            ? null
            : {
                'item': (d['payload']! as Json)['item'],
                'doneOn': (d['payload']! as Json)['done_on'],
                'at': d['at'],
              };
      case 'be':
        final d = _last(entries, (r) => r['kind'] == 'be.diary');
        block['lastDiary'] = d == null
            ? null
            : {'fatigue': (d['payload']! as Json)['fatigue'], 'at': d['at']};
      case 'bf':
        block['lapsesLast7Days'] = lapses.where(inLast7).length;
        block['lastLapseAt'] = lapses.isEmpty
            ? null
            : (lapses.map((l) => _at(l['at'])).toList()..sort())
                .last
                .toIso8601String();
        block['lastHelpfulRescue'] = _helpfulRescue(entries);
    }
    blocks.add(block);
  }
  return SandboxAnswer(200, {
    'date': window.date,
    'checkin': {
      'doneToday': allEntries.any((r) => r['kind'] == 'check_in' && inToday(r)),
    },
    'account': {'lastHelpfulRescue': _helpfulRescue(_rows(c, 'entries', null))},
    'programmes': blocks,
  });
}

/// `programme` and exactly one of `days` / `range`, as the API parses them.
(String, int) parseSummaryQuery(Map<String, String> query) {
  const days = {'7': 7, '30': 30, '90': 90};
  const ranges = {'7d': 7, '30d': 30, '90d': 90};
  final keys = query.keys.toSet();
  final programme = query['programme'];
  if (programme == null ||
      !RegExp(r'^[a-z]{2}$').hasMatch(programme) ||
      keys.difference({'programme', 'days', 'range'}).isNotEmpty ||
      keys.contains('days') == keys.contains('range')) {
    throw const SandboxProblem(400, 'invalid_request');
  }
  final value =
      keys.contains('days') ? days[query['days']] : ranges[query['range']];
  if (value == null) throw const SandboxProblem(400, 'invalid_request');
  return (programme, value);
}

SandboxAnswer getSummary(SandboxCall c) {
  final (code, days) = parseSummaryQuery(c.query);
  final e = _enrolments(c).where((e) => e['programmeCode'] == code).firstOrNull;
  if (e == null) throw const SandboxProblem(404, 'enrolment_not_found');
  final since = c.now.toUtc().subtract(Duration(days: days));
  bool recent(Json r) => !_at(r['at'] ?? r['completedAt']).isBefore(since);
  final entries = _rows(c, 'entries', code);
  return SandboxAnswer(200, {
    'programme': code,
    'days': days,
    'since': since.toIso8601String(),
    'status': e['status'],
    'observations': [
      for (final o in _rows(c, 'observations', code))
        if (recent(o))
          {
            'metric': o['metric'],
            'value': o['value'],
            'unit': o['unit'],
            'at': o['at'],
            'attributes': o['attributes'],
          },
    ],
    'entries': [
      for (final r in entries)
        if (r['kind'] != 'rescue' && recent(r))
          {'kind': r['kind'], 'at': r['at'], 'payload': r['payload']},
    ],
    'lessons': [
      for (final l in _rows(c, 'lessons', code))
        if (recent(l))
          {'lessonId': l['lessonId'], 'completedAt': l['completedAt']},
    ],
    if (code == 'bf' || code == 'sf')
      'lapses': [
        for (final l in _lapses(c, code))
          if (!_at(l['at']).isBefore(since)) {'at': l['at']},
      ],
    if (code == 'bf')
      'rescues': [
        for (final r in entries)
          if (r['kind'] == 'rescue' && recent(r)) r['payload'],
      ],
  });
}

// ---------------------------------------------------------------------------
// Notification preferences.

Json _preferences(SandboxCall c) =>
    (c.data['notifications'] as Json?) ??
    {
      'remindersEnabled': false,
      'sensitiveDetails': false,
      'quietHoursEnabled': false,
      'persisted': false,
      'programmeReminders': <Object?>[],
    };

SandboxAnswer getPreferences(SandboxCall c) =>
    SandboxAnswer(200, _preferences(c));

SandboxAnswer patchPreferences(SandboxCall c) {
  final body = _eventBody(c, {
    'remindersEnabled': const BoolRule(),
    'sensitiveDetails': const BoolRule(),
    'quietHoursEnabled': const BoolRule(),
    'programmeReminders': const _RemindersRule(),
  });
  final prefs = Map<String, Object?>.of(_preferences(c))
    ..addAll(body)
    ..['persisted'] = true;
  c.data['notifications'] = prefs;
  return SandboxAnswer(200, prefs);
}

class _RemindersRule extends FieldRule {
  const _RemindersRule();

  @override
  Object? check(Object? value, DateTime now) {
    if (value is! List || value.length > 11) throw const FormatException();
    final seen = <String>{};
    return [
      for (final r in value)
        () {
          final checked = checkObject(
              r,
              {
                'programme':
                    StrRule(required: true, pattern: RegExp(r'^[a-z]{2}$')),
                'remindAt': StrRule(
                    required: true,
                    pattern: RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$')),
              },
              now);
          if (!seen.add(checked['programme']! as String)) {
            throw const FormatException();
          }
          return checked;
        }(),
    ];
  }
}

// ---------------------------------------------------------------------------
// Care team and records. Bodies are stored as sent (JSON objects); nothing
// is delivered anywhere.

Json _care(SandboxCall c) => c.data['care']! as Json;
Json _records(SandboxCall c) => c.data['records']! as Json;

Json _objectBody(SandboxCall c) {
  final body = c.body;
  if (body is! Map) throw const SandboxProblem(400, 'bad_request');
  return {for (final e in body.entries) '${e.key}': e.value};
}

SandboxAnswer Function(SandboxCall) storeCare(String kind,
        {bool keyed = false}) =>
    (c) {
      final body = _objectBody(c);
      String? submissionId;
      if (keyed) submissionId = _submissionId(c.idempotencyKey);
      final rows = (_care(c)[kind] ??= <Object?>[]) as List<Object?>;
      if (submissionId != null) {
        final fingerprint = _fingerprint('care/$kind', body);
        final replay = _replay(c, submissionId, fingerprint);
        if (replay != null) return replay;
        _remember(c, submissionId, fingerprint);
      }
      final row = {
        'id': c.newId(),
        'createdAt': c.nowText,
        'body': body,
        'delivery': 'none (sandbox)',
      };
      rows.add(row);
      return SandboxAnswer(
          201, {'id': row['id'], 'createdAt': row['createdAt']});
    };

SandboxAnswer redeemConnection(SandboxCall c) {
  final body = _objectBody(c);
  final code =
      body.values.whereType<String>().map((v) => v.trim().toUpperCase());
  if (!code.contains(sandboxInviteCode)) {
    // A bad code is the generic refusal, as on the server.
    throw const SandboxProblem(400, 'bad_request');
  }
  final rows = (_care(c)['connections'] ??= <Object?>[]) as List<Object?>;
  final existing =
      rows.cast<Json>().where((r) => r['clinicName'] == 'Sandbox Clinic');
  if (existing.isNotEmpty) return SandboxAnswer(200, existing.first);
  final row = {
    'id': c.newId(),
    'clinicName': 'Sandbox Clinic',
    'connectedAt': c.nowText,
  };
  rows.add(row);
  return SandboxAnswer(201, row);
}

SandboxAnswer Function(SandboxCall) listCare(String kind) =>
    (c) => SandboxAnswer(200, {kind: _care(c)[kind] ?? <Object?>[]});

SandboxAnswer addManualRecord(SandboxCall c) {
  final submissionId = _submissionId(c.idempotencyKey);
  final body = _objectBody(c);
  final fingerprint = _fingerprint('records/manual', body);
  final replay = _replay(c, submissionId, fingerprint);
  if (replay != null) return replay;
  _remember(c, submissionId, fingerprint);
  final rows = (_records(c)['manual'] ??= <Object?>[]) as List<Object?>;
  final row = {'id': c.newId(), 'createdAt': c.nowText, 'item': body};
  rows.add(row);
  return SandboxAnswer(201, {'submissionId': submissionId, 'id': row['id']});
}

SandboxAnswer listItems(SandboxCall c) =>
    SandboxAnswer(200, {'items': _records(c)['items'] ?? <Object?>[]});

SandboxAnswer listSources(SandboxCall c) =>
    SandboxAnswer(200, {'sources': _records(c)['sources'] ?? <Object?>[]});

SandboxAnswer Function(SandboxCall) storeRecords(String kind) => (c) {
      final body = _objectBody(c);
      final rows = (_records(c)[kind] ??= <Object?>[]) as List<Object?>;
      rows.add({'id': c.newId(), 'createdAt': c.nowText, 'body': body});
      return const SandboxAnswer(200, {'stored': true});
    };

Json _source(SandboxCall c) {
  final id = (c.params['id'] ?? '').toLowerCase();
  final rows = (_records(c)['sources'] as List<Object?>?) ?? const [];
  for (final r in rows) {
    if ((r! as Json)['id'] == id) return r as Json;
  }
  throw const SandboxProblem(404, 'not_found');
}

SandboxAnswer syncSource(SandboxCall c) {
  final source = _source(c);
  source['syncedAt'] = c.nowText;
  final items = [
    for (final i in (_records(c)['items'] as List<Object?>?) ?? const [])
      if ((i! as Json)['sourceId'] == source['id']) i,
  ];
  return SandboxAnswer(200, {'sourceId': source['id'], 'items': items});
}

SandboxAnswer disconnectSource(SandboxCall c) {
  final source = _source(c);
  (_records(c)['sources']! as List<Object?>).remove(source);
  ((_records(c)['items'] as List<Object?>?) ?? <Object?>[])
      .removeWhere((i) => (i! as Json)['sourceId'] == source['id']);
  return const SandboxAnswer(204);
}
