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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsImportingHeaderTitle, left: THeaderLeft.close),
      children: [
        TTitle(s.recordsImportingBodyN0Text),
        TBody(s.recordsImportingBodyN1Text, tone: TTextTone.muted),
        TCard(children: [TChecklist(items: [TCheckItem(s.recordsImportingBodyN2ChildrenN0ItemsN0Label, value: 'Conditions', sub: s.recordsImportingBodyN2ChildrenN0ItemsN0Sub, done: true), TCheckItem(s.recordsImportingBodyN2ChildrenN0ItemsN1Label, value: 'Vital signs', sub: s.recordsImportingBodyN2ChildrenN0ItemsN1Sub, done: true), TCheckItem(s.recordsImportingBodyN2ChildrenN0ItemsN2Label, value: 'Lab results', sub: s.recordsImportingBodyN2ChildrenN0ItemsN2Sub, done: true), TCheckItem(s.recordsImportingBodyN2ChildrenN0ItemsN3Label, value: 'Immunizations', sub: s.recordsImportingBodyN2ChildrenN0ItemsN3Sub), TCheckItem(s.recordsImportingBodyN2ChildrenN0ItemsN4Label, value: 'Smoking status', sub: s.recordsImportingBodyN2ChildrenN0ItemsN4Sub)])]),
        TSkeleton(lines: 2),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsImportingFooterN0Label, onPressed: () => TNav.replace(context, Routes.recordsReview), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.recordsImportingFooterN1Label, onTap: () => TNav.popTo(context, Routes.recordsHub)),
      ],
    );
  }
}
