// GENERATED from spec/screens/support_callback.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Request call-back  ·  route `/support/callback`  ·  flow `tabs`  ·  kind `sheet`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/support_callback.json):
///   • Send referral → POST /v1/care/referrals then toast “Request sent. Expect a call within 2 business days.” then close
///   • Cancel → close
/// API: —
class SupportCallbackScreen extends StatelessWidget {
  const SupportCallbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TTitle(s.supportCallbackBodyN0Text),
        TBody(s.supportCallbackBodyN1Text, tone: TTextTone.muted),
        TKeyValue(rows: [(s.supportCallbackBodyN2RowsN0N0, s.supportCallbackBodyN2RowsN0N1), (s.supportCallbackBodyN2RowsN1N0, s.supportCallbackBodyN2RowsN1N1), (s.supportCallbackBodyN2RowsN2N0, s.supportCallbackBodyN2RowsN2N1), (s.supportCallbackBodyN2RowsN3N0, s.supportCallbackBodyN2RowsN3N1)]),
        TField(fieldKey: 'support_callback.best_time_to_call', label: s.supportCallbackBodyN3Label, placeholder: s.supportCallbackBodyN3Placeholder, kind: TFieldKind.select),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.supportCallbackFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/care/referrals', screenId: 'support_callback', then: () => TNav.toast(context, s.supportCallbackFooterN0ActionThenValue, then: () => TNav.close(context))), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.supportCallbackFooterN1Label, onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
