// GENERATED from spec/screens/records_hub_empty.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Health records · empty  ·  route `/records?state=empty`  ·  flow `records`  ·  kind `screen`
/// State: empty of records_hub · phase resources
/// 
///
/// Actions (generated from spec/screens/records_hub_empty.json):
///   • Back → back
///   • Connect a health system → push → records_add
///   • Enter a value manually → push → records_manual
/// API: —
class RecordsHubEmptyScreen extends StatelessWidget {
  const RecordsHubEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsHubEmptyHeaderTitle),
      children: [
        TIllustration(glyph: '+'),
        TTitle(s.recordsHubEmptyBodyN1Text, size: TTitleSize.l, center: true),
        TBody(s.recordsHubEmptyBodyN2Text, tone: TTextTone.muted, center: true),
        TKeyValue(rows: [('Epic MyChart', s.recordsHubEmptyBodyN3RowsN0N1), ('Medicare', s.recordsHubEmptyBodyN3RowsN1N1), (s.recordsHubEmptyBodyN3RowsN2N0, s.recordsHubEmptyBodyN3RowsN2N1)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsHubEmptyFooterN0Label, onPressed: () => TNav.push(context, Routes.recordsAdd), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.recordsHubEmptyFooterN1Label, onPressed: () => TNav.push(context, Routes.recordsManual), variant: TButtonVariant.secondary),
      ],
    );
  }
}
