// GENERATED from spec/screens/records_importing.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Importing  ·  route `/records/importing`  ·  flow `records`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/records_importing.json):
///   • Close → close
///   • Review imported data → replace → records_review
///   • Cancel import → popto → records_hub
/// API: POST /v1/records/fhir/sources/:id/sync
class RecordsImportingScreen extends StatelessWidget {
  const RecordsImportingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Importing', left: THeaderLeft.close),
      children: [
        TTitle('Importing your records…'),
        TBody('Usually under a minute. You can leave this screen.', tone: TTextTone.muted),
        TCard(children: [TChecklist(items: [TCheckItem('Conditions', sub: '4 found', done: true), TCheckItem('Vital signs', sub: '12 blood pressure readings', done: true), TCheckItem('Lab results', sub: '9 results', done: true), TCheckItem('Immunizations', sub: 'Checking…'), TCheckItem('Smoking status', sub: 'Waiting')])]),
        TSkeleton(lines: 2),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Review imported data', onPressed: () => TNav.replace(context, Routes.recordsReview), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Cancel import', onTap: () => TNav.popTo(context, Routes.recordsHub)),
      ],
    );
  }
}
