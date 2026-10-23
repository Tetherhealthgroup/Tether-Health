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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.caRedHeaderTitle, left: THeaderLeft.close),
      children: [
        TBanner(kind: TBannerKind.urgent, text: s.caRedBodyN0Text),
        TButton(key: const ValueKey('a:body[1]'), label: s.caRedBodyN1Label, onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger),
        TCard(eyebrow: s.caRedBodyN2Eyebrow, children: [TChecklist(items: [TCheckItem(s.caRedBodyN2ChildrenN0ItemsN0Label, value: 'Reliever inhaler now, as written'), TCheckItem(s.caRedBodyN2ChildrenN0ItemsN1Label, value: 'Call your clinician or 911'), TCheckItem(s.caRedBodyN2ChildrenN0ItemsN2Label, value: 'Don’t drive yourself')])]),
        TBoundValues(keys: const ['ca.emergency_contact_action'], builder: (context, v) => TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: v.text('ca.emergency_contact_action', s.caRedBodyN3RowsN0Label), sub: s.caRedBodyN3RowsN0Sub, lead: TLead.avatar('M'), onTap: () => TNav.sheet(context, Routes.supportMessage))])),
        TBody(s.caRedBodyN4Text, tone: TTextTone.small),
      ],
    );
  }
}
