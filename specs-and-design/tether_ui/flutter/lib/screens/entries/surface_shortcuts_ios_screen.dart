// GENERATED from spec/screens/surface_shortcuts_ios.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Siri & App Shortcuts (iPhone)  ·  route `/surface/shortcuts/ios`  ·  flow `entries`  ·  kind `screen`
/// Default state · phase rescue
/// Copy needs clinical/legal review. App Intents exposed as App Shortcuts. The My plan intent is offered only while enrolled in ClearAir and opens the ClearAir red-zone plan.
///
/// Actions (generated from spec/screens/surface_shortcuts_ios.json):
///   • Close → close
///   • Rescue → sheet → rescue_pick
///   • My plan → push → ca_red
/// API: —
class SurfaceShortcutsIosScreen extends StatelessWidget {
  const SurfaceShortcutsIosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.surfaceShortcutsIosHeaderTitle, left: THeaderLeft.close),
      children: [
        TListGroup(title: s.surfaceShortcutsIosBodyN0Title, rows: [TListRow(key: const ValueKey('a:body[0].rows[0]'), label: s.surfaceShortcutsIosBodyN0RowsN0Label, sub: s.surfaceShortcutsIosBodyN0RowsN0Sub, lead: TLead.icon('✚'), onTap: () => TNav.sheet(context, Routes.rescuePick)), TListRow(key: const ValueKey('a:body[0].rows[1]'), label: s.surfaceShortcutsIosBodyN0RowsN1Label, sub: s.surfaceShortcutsIosBodyN0RowsN1Sub, lead: TLead.icon('▤'), onTap: () => TNav.push(context, Routes.caRed))]),
        TCard(variant: TCardVariant.mint, text: s.surfaceShortcutsIosBodyN1Text),
      ],
    );
  }
}
