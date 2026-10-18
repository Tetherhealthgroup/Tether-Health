// GENERATED from spec/screens/ck_item.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Item detail  ·  route `/p/ck/item/:id`  ·  flow `ck`  ·  kind `screen`
/// Default state · program ck · phase resources
/// 
///
/// Actions (generated from spec/screens/ck_item.json):
///   • Back → back
///   • Message my care team → push → support_message_care
///   • Mark as done → push → ck_done
/// API: —
class CkItemScreen extends StatelessWidget {
  const CkItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Colorectal screening'),
      children: [
        TTitle('Your options'),
        TBody('All are recommended. Talk with your clinician about which fits.', tone: TTextTone.muted),
        TKeyValue(rows: [('Stool test (FIT)', 'at home · yearly'), ('Stool DNA test', 'at home · every 1–3 yrs'), ('Colonoscopy', 'clinic · every 10 yrs')]),
        TCard(variant: TCardVariant.mint, title: 'Cost', text: 'Screening is often covered with no cost-sharing. Check with your insurer.'),
        TBody('Source: USPSTF 2021 · reviewed Aug 2026', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Message my care team', onPressed: () => TNav.push(context, Routes.supportMessageCare), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Mark as done', onPressed: () => TNav.push(context, Routes.ckDone), variant: TButtonVariant.secondary),
      ],
    );
  }
}
