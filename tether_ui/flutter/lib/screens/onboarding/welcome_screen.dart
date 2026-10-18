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
    return TScreen(
      header: THeader(title: '', left: THeaderLeft.logo),
      children: [
        TSegmented(fieldKey: 'welcome.value', options: ['English', 'Español'], selected: 'English'),
        TIllustration(glyph: '✿'),
        TEyebrow('Welcome to Tether Health'),
        TTitle('Care that meets you where you are.', size: TTitleSize.xl),
        TBody('Small steps, practical support and no judgment, for the parts of your health you choose.'),
        TKeyValue(rows: [('Private by design', 'No ads · never sold'), ('Help in one tap', 'Works offline'), ('Your pace', 'Pause anytime')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Get started', onPressed: () => TNav.push(context, Routes.obPrograms), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'I already have an account', onTap: () => TNav.sheet(context, Routes.authSignin)),
        TLink(key: const ValueKey('a:footer[2]'), label: 'Terms and Privacy Notice', onTap: () => TNav.external(context, 'https://www.tetherhealthgroup.com/privacy/')),
      ],
    );
  }
}
