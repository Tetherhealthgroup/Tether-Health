// Device calls: Unplug (ScrollFree) and the Ease safety plan.
//
// - Unplug: in sandbox mode a deterministic simulated answer (nothing is
//   shielded); in http mode the native implementation, which this build
//   does not have yet, so the call fails closed.
// - The Ease safety plan stays on the phone, encrypted, in both modes. It
//   is never sent anywhere, and it is deleted with the account.
import 'dart:convert';

import 'package:tether_ui/ui/ui.dart';

import '../../data/app_services.dart';
import '../../data/sync_codec.dart';
import '../registry.dart';
import 'common.dart';

/// The Unplug calls.
const List<String> unplugEndpoints = [
  'CALL device:unplug/endSession',
  'CALL device:unplug/liftShield+purgeLocalData',
  'CALL device:unplug/setThresholds+applyShield',
  'CALL device:unplug/startSession',
];

/// Moves a guest's safety plan to [accountId] (unless the account has one)
/// and deletes the guest's copy. Called when the member merges.
Future<void> adoptGuestSafetyPlan(
    AppServices services, String accountId) async {
  final guest = await services.local.read(safetyPlanScope(null));
  if (guest == null) return;
  final mine = await services.local.read(safetyPlanScope(accountId));
  if (mine == null) {
    await services.local.write(safetyPlanScope(accountId), guest);
  }
  await services.local.delete(safetyPlanScope(null));
}

/// Handlers of the device endpoints.
Map<String, EndpointHandler> deviceHandlers(HandlerKit kit) => {
      for (final endpoint in unplugEndpoints)
        endpoint: (call) async => kit.sandbox
            ? const TResult.ok()
            : const TResult.failed(HandlerCodes.deviceUnavailable),
      'PUT device:encrypted/ea/safety-plan': (call) async {
        final values = screenValues(call.screenId, call.payload);
        await kit.services.local
            .write(safetyPlanScope(kit.services.accountId), jsonEncode(values));
        return const TResult.ok();
      },
    };
