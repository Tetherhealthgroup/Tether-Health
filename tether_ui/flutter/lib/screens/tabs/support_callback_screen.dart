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
    return TSheet(
      children: [
        TTitle('Request a counselor call-back?'),
        TBody('Review exactly what will be sent before you agree.', tone: TTextTone.muted),
        TKeyValue(rows: [('Sent to', 'California Smokers’ Helpline'), ('Shared', 'First name, phone, preferred time'), ('Not shared', 'Your plan, check-ins, health details'), ('Consent expires', '30 days')]),
        TField(fieldKey: 'support_callback.best_time_to_call', label: 'Best time to call', placeholder: 'Weekdays after 5 PM', kind: TFieldKind.select),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Send referral', onPressed: () => TNav.submit(context, 'POST /v1/care/referrals', then: () => TNav.toast(context, 'Request sent. Expect a call within 2 business days.', then: () => TNav.close(context))), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Cancel', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
