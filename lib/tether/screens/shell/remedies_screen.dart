/// Things that help right now.
///
/// A seventh shell surface, and the only one that is not in `shell.json`. The
/// bundle's six are numbered SH1..SH6 and `test/tether_bundle_test.dart` holds
/// that file byte-identical to the shipped design, so a new screen cannot be
/// added by editing it. This one is therefore owned by the app rather than by
/// the bundle, and [ShellRoutes] says so where it is declared.
///
/// It still obeys the shell's rule that a shell screen is "built once and is
/// identical in every area". Here that is not just consistency — it is the
/// clinical constraint. A remedy list that varied by program would sooner or
/// later carry advice about fluid, diet or exertion, and the app does not know
/// whether the person reading it is on dialysis or has unstable angina. See
/// [Remedy] and `design/remedies-clinical-review.md`.
library;

import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../state/tether_scope.dart';
import '../../theme/tether_tokens.dart';
import '../../widgets/blocks/tether_card.dart';
import '../../widgets/tether_page.dart';
import 'shell_routes.dart';

/// The remedy library.
///
/// Takes no arguments and reads nothing about the person. Two people in
/// different programs, on different days, see the same list in the same order.
class RemediesScreen extends StatelessWidget {
  const RemediesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final remedies = TetherScope.of(context).bundle.remedies;

    return TetherPage(
      title: 'Things that help',
      badge: 'Any program',
      leading: LeadingControl.back,
      headline: 'Small things, for right now.',
      sub: 'None of these treat an illness. They are for getting through the '
          'next few minutes, or the next night.',
      body: [
        for (final remedy in remedies)
          _RemedyCard(
            remedy: remedy,
            // By name, so a tap here and a deep link from a notification run
            // the same code. Pushing the object directly was how the two came
            // apart: the route carried a correct `Remedy` and a path nobody
            // had registered, so only the tap worked.
            onTap: () =>
                Navigator.of(context).pushNamed(ShellRoutes.remedy(remedy.id)),
          ),

        // Said once, at the bottom, and again on every remedy. The repetition
        // is deliberate: somebody who taps straight through from a program
        // never reads this page.
        const _NotATreatmentNote(),
      ],
      actions: [
        TetherActionButton(
          label: 'Get help now',
          kind: 'ghost',
          onPressed: () => Navigator.of(context).pushNamed(ShellRoutes.crisis),
        ),
      ],
      footer: 'Nothing here is recorded, and nothing here is shared.',
    );
  }
}

/// One remedy, as a row in the library.
///
/// Shows the length when there is one, because "five minutes" is most of the
/// decision a person is making when they are already struggling.
class _RemedyCard extends StatelessWidget {
  const _RemedyCard({required this.remedy, required this.onTap});

  final Remedy remedy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TetherSpace.blockGap),
      child: TetherCardShell(
        tone: CardTone.plain,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (remedy.helpsWith.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  remedy.helpsWith.join(' · '),
                  style: TetherText.eyebrow,
                ),
              ),
            Text(remedy.title, style: TetherText.cardTitle),
            if (remedy.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(remedy.summary, style: TetherText.cardBody),
              ),
            if (remedy.isTimed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _length(remedy.duration!),
                  style: TetherText.mini,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A duration as somebody would say it.
///
/// Whole minutes only. "2 minutes 30 seconds" reads like a cooking timer, and
/// every remedy here is a round number anyway — if one ever is not, rounding
/// down understates the commitment, which is the safe direction to be wrong in.
String _length(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes < 1) return '${duration.inSeconds} seconds';
  return minutes == 1 ? 'About a minute' : 'About $minutes minutes';
}

class _NotATreatmentNote extends StatelessWidget {
  const _NotATreatmentNote();

  @override
  Widget build(BuildContext context) {
    return const TetherCardShell(
      tone: CardTone.coral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('These are not treatment', style: TetherText.cardTitle),
          SizedBox(height: 4),
          Text(
            'They do not replace medication, a clinician, or a plan. If '
            'something here is the only thing keeping a day together, that is '
            'worth telling somebody.',
            style: TetherText.cardBody,
          ),
        ],
      ),
    );
  }
}
