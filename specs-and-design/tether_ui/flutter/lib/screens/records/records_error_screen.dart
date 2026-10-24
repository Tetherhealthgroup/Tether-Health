// GENERATED from spec/screens/records_error.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Connection problem  ·  route `/records/error`  ·  flow `records`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/records_error.json):
///   • Back → back
///   • Try again → back
///   • Choose another source → replace → records_add
///   • Enter manually instead → replace → records_manual
/// API: —
class RecordsErrorScreen extends StatelessWidget {
  const RecordsErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsErrorHeaderTitle),
      children: [
        TIllustration(glyph: '!', tone: TTone.error),
        TTitle(s.recordsErrorBodyN1Text, size: TTitleSize.l, center: true),
        TBody(s.recordsErrorBodyN2Text, tone: TTextTone.muted, center: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsErrorFooterN0Label, onPressed: () => TNav.back(context), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.recordsErrorFooterN1Label, onPressed: () => TNav.replace(context, Routes.recordsAdd), variant: TButtonVariant.secondary),
        TLink(key: const ValueKey('a:footer[2]'), label: s.recordsErrorFooterN2Label, onTap: () => TNav.replace(context, Routes.recordsManual)),
      ],
    );
  }
}
