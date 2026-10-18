// GENERATED from spec/screens/support_message.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Preview message  ·  route `/support/message`  ·  flow `tabs`  ·  kind `sheet`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/support_message.json):
///   • Open Messages → sms Jordan
///   • Cancel → close
/// API: —
class SupportMessageScreen extends StatelessWidget {
  const SupportMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TSheet(
      children: [
        TTitle('Send to Jordan?'),
        TCard(variant: TCardVariant.mint, eyebrow: 'Preview', title: '“Can you stay with me for the next 10 minutes?”', text: 'Sent from your phone’s Messages app. Tether never sends on its own.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Open Messages', onPressed: () => TNav.sms(context, 'Jordan'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Cancel', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
