import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/delivery_track.dart';
import '../models/unplug_module_state.dart';
import '../widgets/unplug_kit.dart';
import '../widgets/unplug_scope.dart';

/// Screen H — Urge SOS, and the point where the app stops being enough.
///
/// The coping tools are the easy half. The half that matters is addendum §4.1:
/// a distress signal must never terminate at a non-clinical coach. Two distress
/// tags in a row open the route defined for the delivery track, and that route
/// is program configuration owned by clinical leadership, not a decision this
/// screen makes.
class UnplugScreenH extends StatelessWidget {
  const UnplugScreenH({required this.nav, this.onOpenEffortGate, super.key});

  final UnplugNavigation nav;

  /// Opens screen D, where the breath lives.
  final VoidCallback? onOpenEffortGate;

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);

    return UnplugPage(
      nav: nav,
      children: [
        UnplugSection(
          title: 'Right now',
          child: Column(
            children: [
              _ActionCard(
                icon: Icons.air_rounded,
                title: 'Take a breath',
                body: 'The same gate the intercept uses. Nothing to decide, '
                    'just time to pass.',
                onTap: onOpenEffortGate,
              ),
              _ActionCard(
                icon: Icons.timer_outlined,
                title: 'Put it behind a timer',
                body: 'Start a short focus session instead of deciding now.',
                onTap: () => state.startSession(
                  duration: const Duration(minutes: 15),
                  scope: SessionScope.selectedApps,
                  strict: false,
                ),
              ),
              const _ActionCard(
                icon: Icons.edit_note_rounded,
                title: 'Write it down',
                body: 'Available on tracks where the journal is switched on. '
                    'A coach never reads it.',
              ),
            ],
          ),
        ),
        UnplugSection(
          title: 'What is this about?',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in urgeTags)
                ActionChip(
                  label: Text(tag.label),
                  backgroundColor:
                      tag.distress ? AppColors.coralLight : AppColors.paper,
                  side: const BorderSide(color: AppColors.border),
                  labelStyle: TextStyle(
                    color: tag.distress
                        ? const Color(0xFF8C3A26)
                        : AppColors.deepTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  onPressed: () => state.tagUrge(tag),
                ),
            ],
          ),
        ),
        if (state.recentTags.isNotEmpty)
          UnplugSection(
            title: 'Recent tags',
            trailing: TextButton(
              onPressed: state.clearUrgeTags,
              child: const Text('Clear'),
            ),
            child: UnplugCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in state.recentTags)
                    UnplugPill(
                      label: tag.label,
                      background: tag.distress
                          ? AppColors.coralLight
                          : AppColors.mint,
                      foreground: tag.distress
                          ? const Color(0xFF8C3A26)
                          : AppColors.deepTeal,
                    ),
                ],
              ),
            ),
          ),
        if (state.escalationOpened) _EscalationCard(track: state.track),
        if (!state.escalationOpened)
          UnplugNote(
            text: '$distressEscalationThreshold distress tags in a row open '
                'the escalation route for this program. Tag “Anxious”, '
                '“Lonely” or “Low” twice to see where it goes on the '
                '${state.track.label.toLowerCase()} track.',
          ),
        if (state.track == DeliveryTrack.selfGuided)
          const UnplugNote(
            tone: NoteTone.warning,
            text: 'On the self-guided track this app is not treatment, and it '
                'says so at enrollment rather than here, where it would be too '
                'late to matter.',
          ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: AppColors.deepTeal),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: onTap == null
                              ? AppColors.mutedTeal
                              : AppColors.deepTeal,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: const TextStyle(
                          color: AppColors.tealSecondary,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EscalationCard extends StatelessWidget {
  const _EscalationCard({required this.track});

  final DeliveryTrack track;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: UnplugCard(
        color: AppColors.coralLight,
        borderColor: AppColors.coral,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  color: Color(0xFF8C3A26),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is going to a person — ${track.label.toLowerCase()} '
                    'track',
                    style: const TextStyle(
                      color: Color(0xFF8C3A26),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              distressRouteFor(track),
              style: const TextStyle(
                color: Color(0xFF8C3A26),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The route above is program configuration owned by Tether’s '
              'clinical leadership. It is not logic this screen decides, and '
              'it cannot be configured to stop at a coach.',
              style: TextStyle(
                color: Color(0xFF8C3A26),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
