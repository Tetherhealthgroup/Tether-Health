// GENERATED from spec/screens/ca_red.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Red zone  ·  route `/p/ca/zone/red`  ·  flow `ca`  ·  kind `fullscreen`
/// Default state · program ca · phase rescue
/// 
///
/// Actions (generated from spec/screens/ca_red.json):
///   • Close → close
///   • Call 911 → call 911
///   • Tell Maria → sheet → support_message
/// API: —
class CaRedScreen extends StatelessWidget {
  const CaRedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Red zone · act now', left: THeaderLeft.close),
      children: [
        TBanner(kind: TBannerKind.urgent, text: 'Follow your red-zone plan and seek urgent care now.'),
        TButton(key: const ValueKey('a:body[1]'), label: 'Call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger),
        TCard(eyebrow: 'Your red-zone plan', children: [TChecklist(items: [TCheckItem('Reliever inhaler now, as written'), TCheckItem('Call your clinician or 911'), TCheckItem('Don’t drive yourself')])]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'Tell Maria', sub: 'Emergency contact · preview first', lead: TLead.avatar('M'), onTap: () => TNav.sheet(context, Routes.supportMessage))]),
        TBody('Stays open until you close it.', tone: TTextTone.small),
      ],
    );
  }
}
