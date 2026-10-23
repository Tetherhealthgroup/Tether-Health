// Device calls: Unplug (ScrollFree) and the Ease safety plan.
//
// - Unplug: in sandbox mode a deterministic simulated answer (nothing is
//   shielded); in http mode the native implementation, which this build
//   does not have yet, so the call fails closed.
// - The Ease safety plan stays on the phone, encrypted, in both modes. It
//   is never sent anywhere.
import 'dart:convert';

import 'package:tether_ui/ui/ui.dart';

import '../../data/sync_codec.dart';
import '../../sync/sync_store.dart';
import '../registry.dart';
import 'common.dart';

/// The Unplug calls.
const List<String> unplugEndpoints = [
  'CALL device:unplug/endSession',
  'CALL device:unplug/liftShield+purgeLocalData',
  'CALL device:unplug/setThresholds+applyShield',
  'CALL device:unplug/startSession',
];

/// Where the safety plan is kept (secure storage, per account or guest).
String safetyPlanScope(String? accountId) =>
    'device.ea.safety-plan.${accountId ?? 'guest'}';

/// Handlers of the device endpoints.
Map<String, EndpointHandler> deviceHandlers(
  HandlerKit kit, {
  SyncDocumentStore store = const SecureSyncDocumentStore(),
}) =>
    {
      for (final endpoint in unplugEndpoints)
        endpoint: (call) async => kit.sandbox
            ? const TResult.ok()
            : const TResult.failed(HandlerCodes.deviceUnavailable),
      'PUT device:encrypted/ea/safety-plan': (call) async {
        final values = screenValues(call.screenId, call.payload);
        await store.write(
            safetyPlanScope(kit.services.accountId), jsonEncode(values));
        return const TResult.ok();
      },
    };
