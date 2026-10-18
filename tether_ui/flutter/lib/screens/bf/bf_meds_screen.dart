// GENERATED from spec/screens/bf_meds.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Medication center  ·  route `/p/bf/meds`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase resources
/// 
///
/// Actions (generated from spec/screens/bf_meds.json):
///   • Back → back
///   • Taken today → toast “Recorded: taken at 8:07 AM”
///   • Not today → toast “Recorded: not taken”
///   • Nicotine replacement → push → learn_lesson
///   • Prescription options → push → learn_lesson
///   • Side effect or worrying symptom? → push → support_message_care
///   • Add or update recorded plan → push → bf_meds_edit
/// API: —
class BfMedsScreen extends StatelessWidget {
  const BfMedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Medication center'),
      children: [
        TBanner(kind: TBannerKind.info, text: 'Education and tracking, not prescribing. The app never selects a medicine or changes a dose.'),
        TCard(eyebrow: 'Your recorded plan', title: 'Nicotine patch · morning', text: 'Entered by you · follow your clinician’s instructions', children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[1].children[0].items[0]'), label: 'Taken today', onPressed: () => TNav.toast(context, 'Recorded: taken at 8:07 AM'), small: true), TButton(key: const ValueKey('a:body[1].children[0].items[1]'), label: 'Not today', onPressed: () => TNav.toast(context, 'Recorded: not taken'), variant: TButtonVariant.secondary, small: true)])]),
        TListGroup(title: 'Learn', rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Nicotine replacement', sub: 'Patch, gum, lozenge', onTap: () => TNav.push(context, Routes.learnLesson)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Prescription options', sub: 'Varenicline · bupropion SR', onTap: () => TNav.push(context, Routes.learnLesson))]),
        TCard(variant: TCardVariant.warn, title: 'Pregnant, breastfeeding or under 18?', text: 'Talk with a doctor before using quit medicines.'),
        TCard(key: const ValueKey('a:body[4]'), variant: TCardVariant.urgent, title: 'Side effect or worrying symptom?', text: 'Contact your care team or pharmacist. Emergency: 911.', onTap: () => TNav.push(context, Routes.supportMessageCare)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Add or update recorded plan', onPressed: () => TNav.push(context, Routes.bfMedsEdit), variant: TButtonVariant.secondary),
      ],
    );
  }
}
