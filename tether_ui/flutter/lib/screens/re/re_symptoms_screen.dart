// GENERATED from spec/screens/re_symptoms.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Symptom check  ·  route `/p/re/symptoms`  ·  flow `re`  ·  kind `screen`
/// Default state · program re · phase rescue
/// 
///
/// Actions (generated from spec/screens/re_symptoms.json):
///   • Close → close
///   • Contact my care team → push → support_message_care
///   • Vomiting blood or confused? Call 911 → call 911
/// API: —
class ReSymptomsScreen extends StatelessWidget {
  const ReSymptomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Check symptoms', left: THeaderLeft.close),
      children: [
        TTitle('Do you have any of these?'),
        TChips(fieldKey: 're_symptoms.value', options: ['Very little urine', 'Swelling in legs or face', 'Yellow skin or eyes', 'Confusion', 'Vomiting blood', 'None'], selected: ['Yellow skin or eyes']),
        TBanner(kind: TBannerKind.urgent, text: 'Yellow skin or eyes needs a clinician today.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Contact my care team', onPressed: () => TNav.push(context, Routes.supportMessageCare), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Vomiting blood or confused? Call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger),
      ],
    );
  }
}
