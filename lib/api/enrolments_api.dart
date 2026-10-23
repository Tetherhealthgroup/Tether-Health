// Enrolments and programme consents (`/v1/enrolments*`).
import 'package:flutter/foundation.dart';

import '../backend/backend.dart';
import 'api_result.dart';

/// An enrolment's state.
enum EnrolmentStatus {
  focus('focus'),
  learnOnly('learn_only'),
  paused('paused'),
  left('left');

  const EnrolmentStatus(this.wire);
  final String wire;

  static EnrolmentStatus fromWire(Object? wire) => values.firstWhere(
        (s) => s.wire == wire,
        orElse: () => throw const ApiShapeException(),
      );
}

/// BreatheFree and ScrollFree only.
enum EnrolmentMode {
  quit('quit'),
  reduce('reduce');

  const EnrolmentMode(this.wire);
  final String wire;

  static EnrolmentMode? fromWire(Object? wire) => wire == null
      ? null
      : values.firstWhere(
          (m) => m.wire == wire,
          orElse: () => throw const ApiShapeException(),
        );
}

/// What a programme consent covers.
enum ConsentPurpose {
  core('core'),
  reminders('reminders'),
  recordsImport('records_import'),
  shareCareTeam('share_care_team'),
  shareCaregiver('share_caregiver'),
  research('research'),
  screenTime('screen_time');

  const ConsentPurpose(this.wire);
  final String wire;

  static ConsentPurpose fromWire(Object? wire) => values.firstWhere(
        (p) => p.wire == wire,
        orElse: () => throw const ApiShapeException(),
      );
}

/// The language of a consent document.
enum ConsentLocale {
  en('en'),
  es('es');

  const ConsentLocale(this.wire);
  final String wire;
}

/// A live (or, right after a revoke, revoked) programme consent.
@immutable
class ProgrammeConsent {
  const ProgrammeConsent({
    required this.id,
    required this.enrolmentId,
    required this.purpose,
    required this.recipientRef,
    required this.consentVersion,
    required this.locale,
    required this.grantedAt,
    required this.revokedAt,
    this.supersededId,
  });

  factory ProgrammeConsent.fromJson(Map<String, Object?> json) =>
      ProgrammeConsent(
        id: field<String>(json, 'id'),
        enrolmentId: field<String>(json, 'enrolmentId'),
        purpose: ConsentPurpose.fromWire(json['purpose']),
        recipientRef: field<String?>(json, 'recipientRef'),
        consentVersion: field<String>(json, 'consentVersion'),
        locale: field<String?>(json, 'locale'),
        grantedAt: DateTime.parse(field<String>(json, 'grantedAt')),
        revokedAt: switch (field<String?>(json, 'revokedAt')) {
          null => null,
          final at => DateTime.parse(at),
        },
        supersededId: json['supersededId'] as String?,
      );

  final String id;
  final String enrolmentId;
  final ConsentPurpose purpose;
  final String? recipientRef;
  final String consentVersion;
  final String? locale;
  final DateTime grantedAt;
  final DateTime? revokedAt;

  /// On a grant: the core consent it superseded, if any.
  final String? supersededId;
}

/// One enrolment with its live consents.
@immutable
class Enrolment {
  const Enrolment({
    required this.id,
    required this.programmeCode,
    required this.status,
    required this.mode,
    required this.joinedAt,
    required this.leftAt,
    required this.consents,
    required this.currentCoreConsentVersion,
    required this.reconsentRequired,
  });

  factory Enrolment.fromJson(Map<String, Object?> json) => Enrolment(
        id: field<String>(json, 'id'),
        programmeCode: field<String>(json, 'programmeCode'),
        status: EnrolmentStatus.fromWire(json['status']),
        mode: EnrolmentMode.fromWire(json['mode']),
        joinedAt: DateTime.parse(field<String>(json, 'joinedAt')),
        leftAt: switch (field<String?>(json, 'leftAt')) {
          null => null,
          final at => DateTime.parse(at),
        },
        consents: [
          for (final c in jsonObjects(json['consents'] ?? const <Object?>[]))
            ProgrammeConsent.fromJson(c),
        ],
        currentCoreConsentVersion:
            field<String?>(json, 'currentCoreConsentVersion'),
        reconsentRequired: field<bool>(json, 'reconsentRequired'),
      );

  final String id;
  final String programmeCode;
  final EnrolmentStatus status;
  final EnrolmentMode? mode;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final List<ProgrammeConsent> consents;
  final String? currentCoreConsentVersion;
  final bool reconsentRequired;
}

/// `GET /v1/enrolments`.
@immutable
class EnrolmentList {
  const EnrolmentList({
    required this.enrolments,
    required this.currentCoreConsentVersions,
  });

  factory EnrolmentList.fromJson(Map<String, Object?> json) {
    final versions = jsonObject(json['currentCoreConsentVersions']);
    return EnrolmentList(
      enrolments: [
        for (final e in jsonObjects(json['enrolments'])) Enrolment.fromJson(e),
      ],
      currentCoreConsentVersions: {
        for (final locale in ConsentLocale.values)
          locale: versions[locale.wire] as String?,
      },
    );
  }

  final List<Enrolment> enrolments;

  /// The current core consent document version per locale (null: none).
  final Map<ConsentLocale, String?> currentCoreConsentVersions;
}

/// `POST /v1/enrolments/focus-swap`.
@immutable
class FocusSwap {
  const FocusSwap({required this.demoted, required this.promoted});

  final Enrolment demoted;
  final Enrolment promoted;
}

/// The enrolment and consent routes.
class EnrolmentsApi {
  const EnrolmentsApi(this._transport);

  final BackendTransport _transport;

  static const String _base = '/v1/enrolments';

  Future<ApiResult<T>> _send<T>(
    BackendMethod method,
    String path,
    T Function(int status, Object? json) parse, {
    Object? body,
  }) =>
      callBackend(
        _transport,
        BackendRequest(
          service: BackendService.api,
          method: method,
          path: path,
          body: body,
        ),
        parse,
      );

  /// `GET /v1/enrolments`.
  Future<ApiResult<EnrolmentList>> list() => _send(
        BackendMethod.get,
        _base,
        (_, json) => EnrolmentList.fromJson(jsonObject(json)),
      );

  /// `POST /v1/enrolments`: enrols in [programmeCode].
  Future<ApiResult<Enrolment>> create({
    required String programmeCode,
    required EnrolmentStatus status,
    EnrolmentMode? mode,
  }) {
    if (status == EnrolmentStatus.left) {
      throw ArgumentError.value(status, 'status', 'cannot enrol as left');
    }
    return _send(
      BackendMethod.post,
      _base,
      (_, json) => Enrolment.fromJson(jsonObject(json)),
      body: {
        'programmeCode': programmeCode,
        'status': status.wire,
        if (mode != null) 'mode': mode.wire,
      },
    );
  }

  /// `PATCH /v1/enrolments/:id`: changes the status and/or the mode. Pass
  /// [clearMode] to set the mode to null.
  Future<ApiResult<Enrolment>> update(
    String enrolmentId, {
    EnrolmentStatus? status,
    EnrolmentMode? mode,
    bool clearMode = false,
  }) {
    final body = <String, Object?>{
      if (status != null) 'status': status.wire,
      if (mode != null) 'mode': mode.wire,
      if (mode == null && clearMode) 'mode': null,
    };
    if (body.isEmpty) {
      throw ArgumentError('an enrolment update needs a status or a mode');
    }
    return _send(
      BackendMethod.patch,
      '$_base/${Uri.encodeComponent(enrolmentId)}',
      (_, json) => Enrolment.fromJson(jsonObject(json)),
      body: body,
    );
  }

  /// `DELETE /v1/enrolments/:id` ("delete now"): removes the enrolment and
  /// that programme's data. Needs a recent sign-in.
  Future<ApiResult<void>> delete(String enrolmentId) => _send(
        BackendMethod.delete,
        '$_base/${Uri.encodeComponent(enrolmentId)}',
        (_, __) {},
        body: const {'confirmation': 'DELETE'},
      );

  /// `POST /v1/enrolments/focus-swap`.
  Future<ApiResult<FocusSwap>> swapFocus({
    required String demoteId,
    required String promoteId,
  }) =>
      _send(
        BackendMethod.post,
        '$_base/focus-swap',
        (_, json) {
          final map = jsonObject(json);
          return FocusSwap(
            demoted: Enrolment.fromJson(jsonObject(map['demoted'])),
            promoted: Enrolment.fromJson(jsonObject(map['promoted'])),
          );
        },
        body: {'demoteId': demoteId, 'promoteId': promoteId},
      );

  /// `POST /v1/enrolments/consents`: grants a consent for the document
  /// version and locale the member was shown.
  Future<ApiResult<ProgrammeConsent>> grantConsent({
    required String enrolmentId,
    required ConsentPurpose purpose,
    required String consentVersion,
    required ConsentLocale locale,
    String? recipientRef,
  }) =>
      _send(
        BackendMethod.post,
        '$_base/consents',
        (_, json) => ProgrammeConsent.fromJson(jsonObject(json)),
        body: {
          'enrolmentId': enrolmentId,
          'purpose': purpose.wire,
          if (recipientRef != null) 'recipientRef': recipientRef,
          'consentVersion': consentVersion,
          'locale': locale.wire,
        },
      );

  /// `PATCH /v1/enrolments/consents`: revokes the live consent of [purpose]
  /// on the enrolment.
  Future<ApiResult<ProgrammeConsent>> revokeConsent({
    required String enrolmentId,
    required ConsentPurpose purpose,
    String? recipientRef,
  }) =>
      _send(
        BackendMethod.patch,
        '$_base/consents',
        (_, json) => ProgrammeConsent.fromJson(jsonObject(json)),
        body: {
          'enrolmentId': enrolmentId,
          'purpose': purpose.wire,
          if (recipientRef != null) 'recipientRef': recipientRef,
          'revoked': true,
        },
      );

  /// `PATCH /v1/enrolments/consents/:id`: revokes one consent by its id.
  Future<ApiResult<ProgrammeConsent>> revokeConsentById(String consentId) =>
      _send(
        BackendMethod.patch,
        '$_base/consents/${Uri.encodeComponent(consentId)}',
        (_, json) => ProgrammeConsent.fromJson(jsonObject(json)),
        body: {'revoked': true},
      );
}
