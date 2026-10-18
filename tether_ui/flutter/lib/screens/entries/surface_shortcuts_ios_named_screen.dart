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
    return TScreen(
      header: THeader(title: 'Siri & Shortcuts', left: THeaderLeft.close, pill: 'Reference'),
      children: [
        TBody('With Show sensitive details on (Account → Notifications), shortcuts use program names.', tone: TTextTone.muted),
        TListGroup(title: 'Tether Health · App Shortcuts', rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'Rescue', sub: '“Rescue in Tether” · opens Rescue', lead: TLead.icon('✚'), onTap: () => TNav.sheet(context, Routes.rescuePick)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'ClearAir red-zone plan', sub: '“Show my ClearAir plan in Tether”', lead: TLead.program('ca'), onTap: () => TNav.push(context, Routes.caRed))]),
      ],
    );
  }
}
