/// One remedy, in full.
///
/// Ordering on this screen is deliberate and is the safety property worth
/// protecting: the stop rule is drawn **above** the steps, not below them.
/// A person who scrolls far enough to start a practice has already passed the
/// warning, and a warning nobody reaches is decoration. The boundary — what
/// this does not do — sits at the bottom, because it informs rather than
/// protects.
library;

import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../theme/tether_tokens.dart';
import '../../widgets/blocks/tether_card.dart';
import '../../widgets/blocks/tether_timer.dart';
import '../../widgets/tether_page.dart';
import 'shell_routes.dart';

class RemedyScreen extends StatelessWidget {
  const RemedyScreen({required this.remedy, super.key});

  final Remedy remedy;

  @override
  Widget build(BuildContext context) {
    return TetherPage(
      title: remedy.title,
      badge: remedy.isTimed ? _length(remedy.duration!) : null,
      leading: LeadingControl.back,
      headline: remedy.title,
      sub: remedy.summary.isEmpty ? null : remedy.summary,
      body: [
        // Above the steps, on purpose. See the library docstring.
        if (remedy.hasStopRule) _StopCard(text: remedy.stopIf),

        if (remedy.isTimed)
          // The shared block widget rather than a private countdown, so the
          // fix that stops a covered timer from ticking (a pushed route leaves
          // `ModalRoute.isCurrent` false) applies here too instead of having to
          // be remembered twice.
          TetherTimer(
            block: TimerBlock(
              seconds: remedy.duration!.inSeconds,
              label: remedy.title.toUpperCase(),
              quote: null,
            ),
          ),

        if (remedy.steps.isNotEmpty) _StepsCard(steps: remedy.steps),

        if (remedy.boundary.isNotEmpty) _BoundaryCard(text: remedy.boundary),
      ],
      actions: [
        TetherActionButton(
          label: 'Done',
          onPressed: () => Navigator.of(context).pop(),
        ),
        TetherActionButton(
          label: 'Get help now',
          kind: 'ghost',
          onPressed: () =>
              Navigator.of(context).pushNamed(ShellRoutes.crisis),
        ),
      ],
      footer: 'Not recorded. Not shared. Not a treatment.',
    );
  }
}

String _length(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes < 1) return '${duration.inSeconds}s';
  return '$minutes min';
}

/// When to stop and involve a person.
///
/// Coral, which this design reserves for the things a person must not scroll
/// past. Only drawn when the remedy has a rule — see [Remedy.stopIf] for why
/// an invented warning would be worse than none.
class _StopCard extends StatelessWidget {
  const _StopCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TetherSpace.blockGap),
      child: TetherCardShell(
        tone: CardTone.coral,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stop if', style: TetherText.eyebrow),
            const SizedBox(height: 4),
            Text(text, style: TetherText.cardBody),
          ],
        ),
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TetherSpace.blockGap),
      child: TetherCardShell(
        tone: CardTone.plain,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == steps.length - 1 ? 0 : 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text('${i + 1}', style: TetherText.rowKey),
                    ),
                    Expanded(
                      child: Text(steps[i], style: TetherText.cardBody),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BoundaryCard extends StatelessWidget {
  const _BoundaryCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return TetherCardShell(
      tone: CardTone.mintPale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What this does not do', style: TetherText.eyebrow),
          const SizedBox(height: 4),
          Text(text, style: TetherText.cardBody),
        ],
      ),
    );
  }
}
