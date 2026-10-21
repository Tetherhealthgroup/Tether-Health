// The production TDevice: answers the device and OS questions that decide
// branches in the tether_ui screens.
//
// Each question has one entry naming the ticket that wires it. Only the
// platform question is answered today; every other one gives no answer and
// reports `device_not_configured`, so the branch fails closed.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tether_ui/ui/ui.dart';

/// Code reported for a question nobody answers yet. The same code as the
/// kit's inert default, so reports read the same.
const String deviceNotConfiguredCode = TInertDevice.code;

/// Who answers each question, by ticket. Every [TAsk] has an entry.
const Map<TAsk, String> deviceAskOwners = {
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
  // Reference surfaces are preview only; the app never answers them.
  TAsk.reference: 'never answered',
};

/// The production [TDevice].
///
/// It never throws and never gives an answer outside the question's answer
/// set. [onCode] receives only [deviceNotConfiguredCode], never the branch or
/// anything the member entered.
class AppDevice implements TDevice {
  AppDevice({this.onCode, TargetPlatform Function()? platform})
      : _platform = platform ?? (() => defaultTargetPlatform);

  final void Function(String code)? onCode;
  final TargetPlatform Function() _platform;

  @override
  Future<TAnswer?> ask(BuildContext context, TBranchRef branch) async {
    final ask = branch.ask;
    final answer = switch (ask) {
      TAsk.platform => _platformAnswer(),
      TAsk.reference => null,
      _ => _notConfigured(),
    };
    return answer != null && ask.answers.contains(answer) ? answer : null;
  }

  TAnswer? _platformAnswer() {
    try {
      return switch (_platform()) {
        TargetPlatform.iOS => TAnswer.ios,
        TargetPlatform.android => TAnswer.android,
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  TAnswer? _notConfigured() {
    try {
      onCode?.call(deviceNotConfiguredCode);
    } catch (_) {
      // Reporting never changes the answer.
    }
    return null;
  }
}
