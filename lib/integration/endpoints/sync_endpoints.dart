// Plans, profile answers and lapses: saved to the sync document of the
// account (or the guest's, which stays on the phone), then synced. A plan
// save creates the programme's enrolment when it is missing (in focus, or
// learn only when focus is full).
import 'package:tether_ui/ui/ui.dart';

import '../../api/tether_api.dart';
import '../../data/sync_codec.dart';
import '../../sync/sync_client.dart';
import '../../sync/sync_engine.dart';
import '../../sync/sync_models.dart';
import '../registry.dart';
import 'common.dart';

/// The programme of a lapse screen.
const Map<String, String> lapseAreas = {'bf_slip': 'bf', 'sf_slip': 'sf'};

/// Handlers of the sync endpoints.
Map<String, EndpointHandler> syncHandlers(HandlerKit kit) {
  Future<TResult> afterSave() async {
    if (!kit.services.signedIn) return const TResult.ok();
    final status = await kit.services.sync.sync();
    await kit.data.refresh();
    return switch (status) {
      // Stored on the phone and sent on the next sync.
      SyncRunStatus.offline => const TResult.queued(),
      SyncRunStatus.ok || SyncRunStatus.guest => const TResult.ok(),
      // Kept on the phone; sent once the programme has a live consent.
      SyncRunStatus.consentRequired => const TResult.queued(),
      SyncRunStatus.authFailed => const TResult.failed('unauthenticated'),
      SyncRunStatus.failed => const TResult.failed('sync_failed'),
    };
  }

  Future<String?> ensureEnrolment(String area) async {
    if (!kit.services.signedIn) return null;
    final list = await kit.api.enrolments.list();
    final enrolments = list.valueOrNull?.enrolments;
    if (enrolments == null) {
      return list.errorOrNull?.wire ?? 'enrolments_unavailable';
    }
    if (enrolments.any((e) => e.programmeCode == area)) return null;
    final focus =
        enrolments.where((e) => e.status == EnrolmentStatus.focus).length;
    final created = await kit.api.enrolments.create(
      programmeCode: area,
      status: focus >= 2 ? EnrolmentStatus.learnOnly : EnrolmentStatus.focus,
    );
    return created.isSuccess ? null : created.errorOrNull!.wire;
  }

  EndpointHandler plan(String endpoint) => (call) => guarded(() async {
        final area = syncEndpointAreas[endpoint]!;
        final screen = syncScreenOf[call.screenId]?.$2 ??
            syncScreenIdOf(endpoint) ??
            'plan';
        final refused = await ensureEnrolment(area);
        if (refused != null) return TResult.failed(refused);
        await kit.services.openSync();
        // A consent-class screen sends only what changed: keep the rest.
        final stored = kit.services.sync.answersOf(area, screen);
        final values = {
          if (stored != null) ...decodeScreen(call.screenId, stored),
          ...screenValues(call.screenId, call.payload),
        };
        await kit.services.sync
            .saveAnswers(area, screen, encodeScreen(call.screenId, values));
        return afterSave();
      });

  return {
    for (final endpoint in syncEndpointAreas.keys) endpoint: plan(endpoint),
    syncLapseEndpoint: (call) => guarded(() async {
          final area = lapseAreas[call.screenId];
          if (area == null) {
            return const TResult.failed(HandlerCodes.programUnknown);
          }
          final s = Snapshot(call);
          final severity = s.one(area == 'bf' ? 'what_happened' : 'value');
          final context =
              s.list(area == 'bf' ? 'what_was_going_on_optional' : 'value');
          await kit.services.openSync();
          await kit.services.sync.appendLapse(
            area,
            Lapse(
              at: DateTime.now().toUtc(),
              severity: area == 'bf' && severity != null ? slug(severity) : '',
              context: [for (final c in context) slug(c)],
            ),
          );
          return afterSave();
        }),
  };
}
