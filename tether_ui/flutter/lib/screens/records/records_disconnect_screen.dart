// GENERATED from spec/screens/records_disconnect.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Disconnect source  ·  route `/records/source/disconnect`  ·  flow `records`  ·  kind `sheet`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/records_disconnect.json):
///   • Disconnect source → DELETE /v1/records/fhir/sources/:id then toast “Disconnected” then popto → records_hub
///   • Cancel → close
/// API: —
class RecordsDisconnectScreen extends StatelessWidget {
  const RecordsDisconnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TTitle(s.recordsDisconnectBodyN0Text),
        TBody(s.recordsDisconnectBodyN1Text, tone: TTextTone.muted),
        TRadioList(fieldKey: 'records_disconnect.keep', items: [TRadioItem(s.recordsDisconnectBodyN2ItemsN0Label, value: 'Keep imported data', sub: s.recordsDisconnectBodyN2ItemsN0Sub), TRadioItem(s.recordsDisconnectBodyN2ItemsN1Label, value: 'Delete data imported from this source', sub: s.recordsDisconnectBodyN2ItemsN1Sub)], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsDisconnectFooterN0Label, onPressed: () => TNav.submit(context, 'DELETE /v1/records/fhir/sources/:id', screenId: 'records_disconnect', then: () => TNav.toast(context, s.recordsDisconnectFooterN0ActionThenValue, then: () => TNav.popTo(context, Routes.recordsHub))), variant: TButtonVariant.danger),
        TButton(key: const ValueKey('a:footer[1]'), label: s.recordsDisconnectFooterN1Label, onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
