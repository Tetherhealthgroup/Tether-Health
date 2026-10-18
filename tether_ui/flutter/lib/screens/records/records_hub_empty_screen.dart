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
    return TScreen(
      header: THeader(title: 'Health records'),
      children: [
        TIllustration(glyph: '+'),
        TTitle('No health records connected', size: TTitleSize.l, center: true),
        TBody('Bring in readings, labs and vaccinations from your clinic or Medicare, or type them in. Your programs work either way.', tone: TTextTone.muted, center: true),
        TKeyValue(rows: [('Epic MyChart', 'most US hospitals and clinics'), ('Medicare', 'Blue Button 2.0'), ('Other', 'any SMART on FHIR R4 server')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Connect a health system', onPressed: () => TNav.push(context, Routes.recordsAdd), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Enter a value manually', onPressed: () => TNav.push(context, Routes.recordsManual), variant: TButtonVariant.secondary),
      ],
    );
  }
}
