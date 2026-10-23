// The endpoint handlers of the tether_ui screens and the production TData,
// built from the app's backend.
import 'package:flutter/widgets.dart';

import '../../app/composition.dart' show HandlerContext;
import '../../backend/backend.dart';
import '../../data/app_services.dart';
import '../../data/display_source.dart';
import '../data_adapter.dart';
import '../registry.dart';
import '../settings_data.dart';

/// The handler of each endpoint, by its spec string. Also registers the
/// local cleanup after an account deletion and the work done when the app
/// comes back to the foreground.
Map<String, EndpointHandler> buildHandlers(HandlerContext context) {
  final services = AppServices.of(context.backend);
  context.cleaners.register(services.wipeAccount);
  ForegroundSync.install(services, context.data);
  return const <String, EndpointHandler>{};
}

/// The production TData for [backend].
AppData buildAppData(Backend backend) {
  final services = AppServices.of(backend);
  return AppData(
    accountId: () => services.accountId,
    sources: [
      SettingsSource(services),
      TodaySource(services),
      for (final programme in summaryKeys.keys)
        SummarySource(services, programme),
    ],
  );
}

/// On every return to the foreground: send the outbox, sync the plans and
/// reload the shown values.
class ForegroundSync with WidgetsBindingObserver {
  ForegroundSync._(this._services, this._data);

  final AppServices _services;
  final AppData _data;
  static ForegroundSync? _installed;

  /// Installs one observer (replacing an earlier one).
  static void install(AppServices services, AppData data) {
    final WidgetsBinding binding;
    try {
      binding = WidgetsBinding.instance;
    } on FlutterError {
      return; // No app running (plain unit tests).
    }
    final previous = _installed;
    if (previous != null) binding.removeObserver(previous);
    final next = ForegroundSync._(services, data);
    binding.addObserver(next);
    _installed = next;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) run();
  }

  /// The foreground work; errors are swallowed (nothing is logged).
  Future<void> run() async {
    try {
      await _services.outbox.flush();
      if (_services.signedIn) {
        await _services.openSync();
        await _services.sync.sync();
      }
      await _data.refresh();
    } catch (_) {
      // Retried on the next foreground.
    }
  }
}
