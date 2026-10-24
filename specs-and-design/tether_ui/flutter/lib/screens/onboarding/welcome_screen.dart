// GENERATED from spec/screens/welcome.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Welcome  ·  route `/welcome`  ·  flow `onboarding`  ·  kind `screen`
/// Default state · phase welcome
/// Language is chosen once for the whole account. No data is collected on this screen.
///
/// Actions (generated from spec/screens/welcome.json):
///   • Get started → push → ob_programs
///   • I already have an account → sheet → auth_signin
///   • Terms and Privacy Notice → external https://www.tetherhealthgroup.com/privacy/
/// API: —
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: '', left: THeaderLeft.logo),
      children: [
        TSegmented(fieldKey: 'welcome.value', options: ['en', 'es'], labels: ['English', 'Español'], selected: 'en'),
        TIllustration(glyph: '✿'),
        TEyebrow(s.welcomeBodyN2Text),
        TTitle(s.welcomeBodyN3Text, size: TTitleSize.xl),
        TBody(s.welcomeBodyN4Text),
        TKeyValue(rows: [(s.welcomeBodyN5RowsN0N0, s.welcomeBodyN5RowsN0N1), (s.welcomeBodyN5RowsN1N0, s.welcomeBodyN5RowsN1N1), (s.welcomeBodyN5RowsN2N0, s.welcomeBodyN5RowsN2N1)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.welcomeFooterN0Label, onPressed: () => TNav.push(context, Routes.obPrograms), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.welcomeFooterN1Label, onTap: () => TNav.sheet(context, Routes.authSignin)),
        TLink(key: const ValueKey('a:footer[2]'), label: s.welcomeFooterN2Label, onTap: () => TNav.external(context, 'https://www.tetherhealthgroup.com/privacy/')),
      ],
    );
  }
}
