// GENERATED from spec/screens/rescue_pick.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Rescue  ·  route `/rescue`  ·  flow `rescue`  ·  kind `sheet`
/// Default state · phase rescue
/// With one Quit program, the app skips this screen and opens the last helpful tool.
///
/// Actions (generated from spec/screens/rescue_pick.json):
///   • A cigarette → replace → rescue_active
///   • Urge to scroll → replace → sf_pause
///   • Stress → replace → rescue_active
///   • Not sure → replace → rescue_active
///   • Start → replace → rescue_active
///   • Talk to a person → tab → support
///   • Emergency → push → crisis
/// API: —
class RescuePickScreen extends StatelessWidget {
  const RescuePickScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TEyebrow(s.rescuePickBodyN0Text),
        TTitle(s.rescuePickBodyN1Text),
        TBody(s.rescuePickBodyN2Text, tone: TTextTone.muted),
        TTileGrid(tiles: [TTile(key: const ValueKey('a:body[3].items[0]'), label: s.rescuePickBodyN3ItemsN0Label, value: 'A cigarette', sub: 'BreatheFree', program: 'bf', onTap: () => TNav.replace(context, Routes.rescueActive)), TTile(key: const ValueKey('a:body[3].items[1]'), label: s.rescuePickBodyN3ItemsN1Label, value: 'Urge to scroll', sub: 'ScrollFree', program: 'sf', onTap: () => TNav.replace(context, Routes.sfPause)), TTile(key: const ValueKey('a:body[3].items[2]'), label: s.rescuePickBodyN3ItemsN2Label, value: 'Stress', sub: s.rescuePickBodyN3ItemsN2Sub, glyph: '~', onTap: () => TNav.replace(context, Routes.rescueActive)), TTile(key: const ValueKey('a:body[3].items[3]'), label: s.rescuePickBodyN3ItemsN3Label, value: 'Not sure', sub: s.rescuePickBodyN3ItemsN3Sub, glyph: '?', onTap: () => TNav.replace(context, Routes.rescueActive))]),
        TCard(variant: TCardVariant.dark, eyebrow: s.rescuePickBodyN4Eyebrow, title: s.rescuePickBodyN4Title, cta: TButton(key: const ValueKey('a:body[4].cta[0]'), label: s.rescuePickBodyN4CtaN0Label, onPressed: () => TNav.replace(context, Routes.rescueActive), variant: TButtonVariant.lime, small: true)),
        TButtonRow(children: [TButton(key: const ValueKey('a:body[5].items[0]'), label: s.rescuePickBodyN5ItemsN0Label, onPressed: () => TNav.tab(context, Routes.support), variant: TButtonVariant.secondary, small: true), TButton(key: const ValueKey('a:body[5].items[1]'), label: s.rescuePickBodyN5ItemsN1Label, onPressed: () => TNav.push(context, Routes.crisis), variant: TButtonVariant.danger, small: true)]),
      ],
      footer: [
        
      ],
    );
  }
}
