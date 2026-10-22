// GENERATED from spec/screens/surface_shortcuts_ios_named.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Siri & App Shortcuts (sensitive details on)  ·  route `/surface/shortcuts/ios?state=named`  ·  flow `entries`  ·  kind `screen`
/// State: Show sensitive details on of surface_shortcuts_ios · phase rescue
/// Copy needs clinical/legal review.
///
/// Actions (generated from spec/screens/surface_shortcuts_ios_named.json):
///   • Close → close
///   • Rescue → sheet → rescue_pick
///   • ClearAir red-zone plan → push → ca_red
/// API: —
class SurfaceShortcutsIosNamedScreen extends StatelessWidget {
  const SurfaceShortcutsIosNamedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.surfaceShortcutsIosNamedHeaderTitle, left: THeaderLeft.close),
      children: [
        TListGroup(title: s.surfaceShortcutsIosNamedBodyN0Title, rows: [TListRow(key: const ValueKey('a:body[0].rows[0]'), label: s.surfaceShortcutsIosNamedBodyN0RowsN0Label, sub: s.surfaceShortcutsIosNamedBodyN0RowsN0Sub, lead: TLead.icon('✚'), onTap: () => TNav.sheet(context, Routes.rescuePick)), TListRow(key: const ValueKey('a:body[0].rows[1]'), label: s.surfaceShortcutsIosNamedBodyN0RowsN1Label, sub: s.surfaceShortcutsIosNamedBodyN0RowsN1Sub, lead: TLead.program('ca'), onTap: () => TNav.push(context, Routes.caRed))]),
      ],
    );
  }
}
