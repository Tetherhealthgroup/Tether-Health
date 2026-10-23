// The endpoint handlers of the tether_ui screens and the production TData,
// built from the app's backend.
//
// No handler is wired yet: every registered endpoint still fails with
// `not_implemented`, and no bound value is filled.
import '../../app/composition.dart' show HandlerContext;
import '../../backend/backend.dart';
import '../data_adapter.dart';
import '../registry.dart';

/// The handler of each endpoint, by its spec string.
Map<String, EndpointHandler> buildHandlers(HandlerContext context) =>
    const <String, EndpointHandler>{};

/// The production TData for [backend].
AppData buildAppData(Backend backend) => AppData();
