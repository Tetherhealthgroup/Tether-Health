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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsReviewHeaderTitle, left: THeaderLeft.close, pill: s.recordsReviewHeaderPill),
      children: [
        TTitle(s.recordsReviewBodyN0Text),
        TBody(s.recordsReviewBodyN1Text, tone: TTextTone.muted),
        TBoundValues(keys: const ['records.review_banner'], builder: (context, v) => TBanner(kind: TBannerKind.offline, text: v.text('records.review_banner', s.recordsReviewBodyN2Text), actionLabel: s.recordsReviewBodyN2ActionLabel, onAction: () => TNav.push(context, Routes.recordsConflict), actionKey: const ValueKey('a:body[2]'))),
        TCard(tag: 'hw', children: [TChecklist(fieldKey: 'records_review.keep_hw', items: [TCheckItem(s.recordsReviewBodyN3ChildrenN0ItemsN0Label, value: '12 blood pressure readings', sub: s.recordsReviewBodyN3ChildrenN0ItemsN0Sub), TCheckItem(s.recordsReviewBodyN3ChildrenN0ItemsN1Label, value: 'Lipid panel', sub: s.recordsReviewBodyN3ChildrenN0ItemsN1Sub)])]),
        TCard(tag: 'st', children: [TChecklist(fieldKey: 'records_review.keep_st', items: [TCheckItem(s.recordsReviewBodyN4ChildrenN0ItemsN0Label, value: 'A1C 7.6%', sub: s.recordsReviewBodyN4ChildrenN0ItemsN0Sub)])]),
        TCard(tag: 'ck', children: [TChecklist(fieldKey: 'records_review.keep_ck', items: [TCheckItem(s.recordsReviewBodyN5ChildrenN0ItemsN0Label, value: 'Flu vaccine', sub: s.recordsReviewBodyN5ChildrenN0ItemsN0Sub), TCheckItem(s.recordsReviewBodyN5ChildrenN0ItemsN1Label, value: 'Tdap', sub: '2019')])]),
        TCard(tag: 'bf', children: [TChecklist(fieldKey: 'records_review.keep_bf', items: [TCheckItem(s.recordsReviewBodyN6ChildrenN0ItemsN0Label, value: 'Smoking status: every day smoker', sub: s.recordsReviewBodyN6ChildrenN0ItemsN0Sub)])]),
        TCard(tag: 're', children: [TChecklist(fieldKey: 'records_review.keep_re', items: [TCheckItem(s.recordsReviewBodyN7ChildrenN0ItemsN0Label, value: 'eGFR 58', sub: s.recordsReviewBodyN7ChildrenN0ItemsN0Sub)])]),
        TEyebrow(s.recordsReviewBodyN8Text),
        TBoundValues(keys: const ['records.review.units_converted', 'records.review.duplicates_skipped', 'records.review.held_as_typo', 'records.review.future_dates_rejected'], builder: (context, v) => TKeyValue(rows: [(s.recordsReviewBodyN9RowsN0N0, v.text('records.review.units_converted', s.recordsReviewBodyN9RowsN0N1)), (s.recordsReviewBodyN9RowsN1N0, v.text('records.review.duplicates_skipped', s.recordsReviewBodyN9RowsN1N1)), (s.recordsReviewBodyN9RowsN2N0, v.text('records.review.held_as_typo', s.recordsReviewBodyN9RowsN2N1)), (s.recordsReviewBodyN9RowsN3N0, v.text('records.review.future_dates_rejected', '0'))])),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsReviewFooterN0Label, onPressed: () => TNav.branch(context, 'Anything selected?', <String, VoidCallback>{'Chosen': () => TNav.submit(context, 'POST /v1/records/fhir/accept', screenId: 'records_review', then: () => TNav.toast(context, s.recordsReviewFooterN0ActionCasesN0ActionThenValue, then: () => TNav.popTo(context, Routes.recordsHub))), 'Nothing chosen': () => TNav.toast(context, s.recordsReviewFooterN0ActionCasesN1ActionValue)}, decide: 'rec.review'), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.recordsReviewFooterN1Label, onTap: () => TNav.push(context, Routes.recordsConflict)),
      ],
    );
  }
}
