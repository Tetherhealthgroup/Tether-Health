import 'package:flutter/material.dart';

import 'dev/gallery.dart';
import 'router/app_router.dart';
import 'router/routes.dart';
import 'ui/tokens.dart';

/// Start screen. `flutter run --dart-define=START=/welcome` opens the real
/// first-run flow; the default opens the developer gallery of all screens.
const _start = String.fromEnvironment('START', defaultValue: 'gallery');

void main() => runApp(const TetherApp());

class TetherApp extends StatelessWidget {
  const TetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tether Health',
      debugShowCheckedModeBanner: false,
      theme: tetherTheme(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      onGenerateInitialRoutes: (_) => [
        if (_start == 'gallery')
          MaterialPageRoute<void>(builder: (_) => const GalleryScreen())
        else
          AppRouter.onGenerateRoute(RouteSettings(name: AppRouter.screens.containsKey(_start) ? _start : Routes.welcome))!,
      ],
    );
  }
}
