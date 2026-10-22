// GENERATED from spec/screens/records_review.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Review imported data  ·  route `/records/review`  ·  flow `records`  ·  kind `screen`
/// Default state · phase resources
/// Validation pipeline: FHIR R4 schema → code mapping (LOINC, SNOMED CT, CVX, RxNorm) → unit normalisation (UCUM) → plausibility ranges → duplicate detection (code + date + value) → conflict with manual entries → member review.
///
/// Actions (generated from spec/screens/records_review.json):
///   • Close → close
///   • Review → push → records_conflict
///   • Add selected items to my programs → decide rec.review: Anything selected? → Chosen: POST /v1/records/fhir/accept then toast “Added to your programs” then popto → records_hub | Nothing chosen: toast “Select the items you want to add.”
///   • Review conflicts first → push → records_conflict
/// API: —
class RecordsReviewScreen extends StatelessWidget {
  const RecordsReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Review', left: THeaderLeft.close, pill: 'Not added yet'),
      children: [
        TTitle('Review before adding'),
        TBody('Nothing reaches your programs until you confirm.', tone: TTextTone.muted),
        TBanner(kind: TBannerKind.offline, text: '2 items need your review.', actionLabel: 'Review', onAction: () => TNav.push(context, Routes.recordsConflict), actionKey: const ValueKey('a:body[2]')),
        TCard(tag: 'hw', children: [TChecklist(fieldKey: 'records_review.keep_hw', items: [TCheckItem('12 blood pressure readings', sub: 'Jun – Oct 2026'), TCheckItem('Lipid panel', sub: 'LDL 138 · Sep 30')])]),
        TCard(tag: 'st', children: [TChecklist(fieldKey: 'records_review.keep_st', items: [TCheckItem('A1C 7.6%', sub: 'Oct 1 · differs from your entry (7.4%)')])]),
        TCard(tag: 'ck', children: [TChecklist(fieldKey: 'records_review.keep_ck', items: [TCheckItem('Flu vaccine', sub: 'Oct 12, 2025'), TCheckItem('Tdap', sub: '2019')])]),
        TCard(tag: 'bf', children: [TChecklist(fieldKey: 'records_review.keep_bf', items: [TCheckItem('Smoking status: every day smoker', sub: 'Aug 2026 · sets your baseline')])]),
        TCard(tag: 're', children: [TChecklist(fieldKey: 'records_review.keep_re', items: [TCheckItem('eGFR 58', sub: 'Oct 3')])]),
        TEyebrow('Checked automatically'),
        TKeyValue(rows: [('Units converted', '2 glucose results · mmol/L → mg/dL'), ('Duplicates skipped', '3 readings you already entered'), ('Held as likely typo', '1 · BP 1290/80'), ('Future dates rejected', '0')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Add selected items to my programs', onPressed: () => TNav.branch(context, 'Anything selected?', <String, VoidCallback>{'Chosen': () => TNav.submit(context, 'POST /v1/records/fhir/accept', screenId: 'records_review', then: () => TNav.toast(context, 'Added to your programs', then: () => TNav.popTo(context, Routes.recordsHub))), 'Nothing chosen': () => TNav.toast(context, 'Select the items you want to add.')}, decide: 'rec.review'), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Review conflicts first', onTap: () => TNav.push(context, Routes.recordsConflict)),
      ],
    );
  }
}
