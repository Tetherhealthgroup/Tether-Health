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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.ckItemHeaderTitle),
      children: [
        TTitle(s.ckItemBodyN0Text),
        TBody(s.ckItemBodyN1Text, tone: TTextTone.muted),
        TKeyValue(rows: [(s.ckItemBodyN2RowsN0N0, s.ckItemBodyN2RowsN0N1), (s.ckItemBodyN2RowsN1N0, s.ckItemBodyN2RowsN1N1), (s.ckItemBodyN2RowsN2N0, s.ckItemBodyN2RowsN2N1)]),
        TCard(variant: TCardVariant.mint, title: s.ckItemBodyN3Title, text: s.ckItemBodyN3Text),
        TBody(s.ckItemBodyN4Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.ckItemFooterN0Label, onPressed: () => TNav.push(context, Routes.supportMessageCare), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.ckItemFooterN1Label, onPressed: () => TNav.push(context, Routes.ckDone), variant: TButtonVariant.secondary),
      ],
    );
  }
}
