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
    return TSheet(
      children: [
        TTitle('Disconnect Patel Family Medicine?'),
        TBody('Tether stops reading new records and revokes its access token.', tone: TTextTone.muted),
        TRadioList(fieldKey: 'records_disconnect.keep', items: [TRadioItem('Keep imported data', sub: 'Marked “from Patel Family Medicine”'), TRadioItem('Delete data imported from this source', sub: '21 items removed from your programs')], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Disconnect source', onPressed: () => TNav.submit(context, 'DELETE /v1/records/fhir/sources/:id', screenId: 'records_disconnect', then: () => TNav.toast(context, 'Disconnected', then: () => TNav.popTo(context, Routes.recordsHub))), variant: TButtonVariant.danger),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Cancel', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
