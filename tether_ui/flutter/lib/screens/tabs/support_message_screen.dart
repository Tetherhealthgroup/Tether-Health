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
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TBoundValues(keys: const ['support.message_title'], place: TExamplePlace.inline, builder: (context, v) => TTitle(v.text('support.message_title', s.supportMessageBodyN0Text))),
        TBoundValues(keys: const ['support.help_phrase_quoted'], builder: (context, v) => TCard(variant: TCardVariant.mint, eyebrow: s.supportMessageBodyN1Eyebrow, title: v.text('support.help_phrase_quoted', s.supportMessageBodyN1Title), text: s.supportMessageBodyN1Text)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.supportMessageFooterN0Label, onPressed: () => TNav.sms(context, 'Jordan'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.supportMessageFooterN1Label, onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
