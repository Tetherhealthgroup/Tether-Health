// GENERATED from spec/screens/surface_shortcuts_android.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Launcher shortcuts (Android)  ·  route `/surface/shortcuts/android`  ·  flow `entries`  ·  kind `screen`
/// Default state · phase rescue
/// Copy needs clinical/legal review.
///
/// Actions (generated from spec/screens/surface_shortcuts_android.json):
///   • Close → close
///   • Rescue → sheet → rescue_pick
///   • My plan → push → ca_red
/// API: —
class SurfaceShortcutsAndroidScreen extends StatelessWidget {
  const SurfaceShortcutsAndroidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.surfaceShortcutsAndroidHeaderTitle, left: THeaderLeft.close),
      children: [
        TListGroup(title: 'Tether Health', rows: [TListRow(key: const ValueKey('a:body[0].rows[0]'), label: s.surfaceShortcutsAndroidBodyN0RowsN0Label, lead: TLead.icon('✚'), onTap: () => TNav.sheet(context, Routes.rescuePick)), TListRow(key: const ValueKey('a:body[0].rows[1]'), label: s.surfaceShortcutsAndroidBodyN0RowsN1Label, lead: TLead.icon('▤'), onTap: () => TNav.push(context, Routes.caRed))]),
        TCard(variant: TCardVariant.mint, text: s.surfaceShortcutsAndroidBodyN1Text),
      ],
    );
  }
}
