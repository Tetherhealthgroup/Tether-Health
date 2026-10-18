// GENERATED from spec/screens/surface_widget_android.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Home-screen widget (Android)  ·  route `/surface/widget/android`  ·  flow `entries`  ·  kind `fullscreen`
/// Default state · phase rescue
/// Copy needs clinical/legal review.
///
/// Actions (generated from spec/screens/surface_widget_android.json):
///   • Close → close
///   • Rescue → sheet → rescue_pick
/// API: —
class SurfaceWidgetAndroidScreen extends StatelessWidget {
  const SurfaceWidgetAndroidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Android widget', left: THeaderLeft.close, pill: 'Reference'),
      background: TBackground.dark,
      children: [
        TEyebrow('Home screen · 2×1 widget'),
        TCard(key: const ValueKey('a:body[1]'), variant: TCardVariant.coral, title: 'Rescue', text: 'Help for the next few minutes', onTap: () => TNav.sheet(context, Routes.rescuePick)),
        TKeyValue(rows: [('Label', 'Rescue (generic)'), ('Shows', 'No health data, no program names'), ('Tap', 'Opens Rescue, even when signed out'), ('Built with', 'RemoteViews, no extra library')]),
      ],
    );
  }
}
