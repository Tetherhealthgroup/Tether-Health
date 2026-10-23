// The account, profile, baseline, quit plan, catalogue and app config routes.
import 'package:flutter/foundation.dart';

import '../backend/backend.dart';
import '../profile/user_profile.dart';
import '../quit_plan/quit_plan.dart';
import 'api_result.dart';

/// `DELETE /v1/account/data`: what was deleted.
@immutable
class DeletionReceipt {
  const DeletionReceipt({
    required this.requestId,
    required this.completedAt,
    required this.deleted,
  });

  factory DeletionReceipt.fromJson(Map<String, Object?> json) =>
      DeletionReceipt(
        requestId: field<String>(json, 'requestId'),
        completedAt: DateTime.parse(field<String>(json, 'completedAt')),
        deleted: Map<String, int>.unmodifiable({
          for (final MapEntry(:key, :value)
              in jsonObject(json['deleted']).entries)
            key: value is num ? value.toInt() : throw const ApiShapeException(),
        }),
      );

  final String requestId;
  final DateTime completedAt;

  /// Deleted row counts by kind (the receipt's key set).
  final Map<String, int> deleted;

  Map<String, Object?> toJson() => {
        'requestId': requestId,
        'completedAt': completedAt.toUtc().toIso8601String(),
        'deleted': deleted,
      };
}

/// A programme of the catalogue.
@immutable
class CatalogueProgramme {
  const CatalogueProgramme({
    required this.code,
    required this.slug,
    required this.name,
    required this.area,
    required this.archetype,
  });

  factory CatalogueProgramme.fromJson(Map<String, Object?> json) =>
      CatalogueProgramme(
        code: field<String>(json, 'code'),
        slug: field<String>(json, 'slug'),
        name: field<String>(json, 'name'),
        area: field<String>(json, 'area'),
        archetype: field<String>(json, 'archetype'),
      );

  final String code;
  final String slug;
  final String name;
  final String area;
  final String archetype;
}

/// The baseline answers (age, sleep and stress bands); null means unset.
@immutable
class Baseline {
  const Baseline({this.ageRange, this.sleepBand, this.stressBand});

  factory Baseline.fromJson(Map<String, Object?> json) => Baseline(
        ageRange: field<String?>(json, 'ageRange'),
        sleepBand: field<String?>(json, 'sleepBand'),
        stressBand: field<String?>(json, 'stressBand'),
      );

  final String? ageRange;
  final String? sleepBand;
  final String? stressBand;

  Map<String, Object?> toJson() => {
        'ageRange': ageRange,
        'sleepBand': sleepBand,
        'stressBand': stressBand,
      };
}

/// `GET /v1/app/config`.
@immutable
class RemoteAppConfig {
  const RemoteAppConfig({
    required this.minimumIosVersion,
    required this.minimumAndroidVersion,
  });

  factory RemoteAppConfig.fromJson(Map<String, Object?> json) {
    final minimum = jsonObject(json['minimumVersion']);
    return RemoteAppConfig(
      minimumIosVersion: field<String>(minimum, 'ios'),
      minimumAndroidVersion: field<String>(minimum, 'android'),
    );
  }

  final String minimumIosVersion;
  final String minimumAndroidVersion;
}

/// The account-level routes.
class AccountApi {
  const AccountApi(this._transport);

  final BackendTransport _transport;

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

  /// `POST /v1/account/export`: every app-owned row of the member, as JSON.
  /// Needs a recent sign-in.
  Future<ApiResult<Map<String, Object?>>> export() => _send(
        BackendMethod.post,
        '/v1/account/export',
        (_, json) => jsonObject(json),
      );

  /// `DELETE /v1/account/data`: deletes the account and its data. Needs a
  /// recent sign-in. Safe to retry.
  Future<ApiResult<DeletionReceipt>> deleteData() => _send(
        BackendMethod.delete,
        '/v1/account/data',
        (_, json) => DeletionReceipt.fromJson(jsonObject(json)),
        body: const {'confirmation': 'DELETE'},
      );

  /// `GET /v1/profile`.
  Future<ApiResult<UserProfile>> profile() => _send(
        BackendMethod.get,
        '/v1/profile',
        (_, json) => UserProfile.fromJson(jsonObject(json)),
      );

  /// `PATCH /v1/profile`: changes only what is given.
  Future<ApiResult<UserProfile>> updateProfile({
    String? displayName,
    bool clearDisplayName = false,
    String? locale,
    String? timeZone,
    bool? onboardingCompleted,
  }) {
    final body = <String, Object?>{
      if (displayName != null) 'displayName': displayName,
      if (displayName == null && clearDisplayName) 'displayName': null,
      if (locale != null) 'locale': locale,
      if (timeZone != null) 'timeZone': timeZone,
      if (onboardingCompleted != null)
        'onboardingCompleted': onboardingCompleted,
    };
    if (body.isEmpty) throw ArgumentError('a profile update needs a field');
    return _send(
      BackendMethod.patch,
      '/v1/profile',
      (_, json) => UserProfile.fromJson(jsonObject(json)),
      body: body,
    );
  }

  /// `GET /v1/profile/baseline`.
  Future<ApiResult<Baseline>> baseline() => _send(
        BackendMethod.get,
        '/v1/profile/baseline',
        (_, json) => Baseline.fromJson(jsonObject(json)),
      );

  /// `PUT /v1/profile/baseline`: an unset band stores null.
  Future<ApiResult<Baseline>> putBaseline(Baseline baseline) => _send(
        BackendMethod.put,
        '/v1/profile/baseline',
        (_, json) => Baseline.fromJson(jsonObject(json)),
        body: baseline.toJson(),
      );

  /// `GET /v1/quit-plan`.
  Future<ApiResult<QuitPlan>> quitPlan() => _send(
        BackendMethod.get,
        '/v1/quit-plan',
        (_, json) => QuitPlan.fromJson(jsonObject(json)),
      );

  /// `PUT /v1/quit-plan`.
  Future<ApiResult<QuitPlan>> putQuitPlan(QuitPlan plan) => _send(
        BackendMethod.put,
        '/v1/quit-plan',
        (_, json) => QuitPlan.fromJson(jsonObject(json)),
        body: plan.toRequestJson(),
      );

  /// `POST /v1/quit-plan/guest-import`: uploads a guest's plan after the
  /// member agreed to merge it. 409 when the account already has a plan.
  Future<ApiResult<QuitPlan>> importGuestQuitPlan(QuitPlan plan) => _send(
        BackendMethod.post,
        '/v1/quit-plan/guest-import',
        (_, json) => QuitPlan.fromJson(jsonObject(json)),
        body: plan.toRequestJson(),
      );

  /// `GET /v1/catalogue/programmes`.
  Future<ApiResult<List<CatalogueProgramme>>> programmes() => _send(
        BackendMethod.get,
        '/v1/catalogue/programmes',
        (_, json) => [
          for (final p in jsonObjects(jsonObject(json)['programmes']))
            CatalogueProgramme.fromJson(p),
        ],
      );

  /// `GET /v1/app/config`.
  Future<ApiResult<RemoteAppConfig>> appConfig() => _send(
        BackendMethod.get,
        '/v1/app/config',
        (_, json) => RemoteAppConfig.fromJson(jsonObject(json)),
      );
}
