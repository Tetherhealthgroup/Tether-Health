// GENERATED from spec/screens/surface_widget_ios.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Home-screen widget (iPhone)  ·  route `/surface/widget/ios`  ·  flow `entries`  ·  kind `fullscreen`
/// Default state · phase rescue
/// Copy needs clinical/legal review. WidgetKit extension, static content. The coral card stands for the widget; tapping it opens Rescue.
///
/// Actions (generated from spec/screens/surface_widget_ios.json):
///   • Close → close
///   • Rescue → sheet → rescue_pick
/// API: —
class SurfaceWidgetIosScreen extends StatelessWidget {
  const SurfaceWidgetIosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'iPhone widget', left: THeaderLeft.close),
      background: TBackground.dark,
      children: [
        TCard(key: const ValueKey('a:body[0]'), variant: TCardVariant.coral, title: 'Rescue', text: 'Help for the next few minutes', onTap: () => TNav.sheet(context, Routes.rescuePick)),
      ],
    );
  }
}
