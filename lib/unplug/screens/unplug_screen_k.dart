import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/delivery_track.dart';
import '../widgets/unplug_kit.dart';
import '../widgets/unplug_scope.dart';
import 'care_team_view.dart';

/// Screen K — who holds which capability, per addendum §4.
///
/// The matrix is rendered a row at a time rather than as a table, because on a
/// phone a three-column table is unreadable and this content is exactly the
/// content nobody should have to squint at.
class UnplugScreenK extends StatelessWidget {
  const UnplugScreenK({required this.nav, super.key});

  final UnplugNavigation nav;

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final track = state.track;

    return UnplugPage(
      nav: nav,
      children: [
        UnplugSection(
          title: 'Delivery track',
          child: UnplugChoices<DeliveryTrack>(
            values: DeliveryTrack.values,
            selected: track,
            labelOf: (value) => value.label,
            onSelected: state.selectTrack,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            track.description,
            style: const TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ),
        if (state.template != null)
          UnplugNote(
            text: 'This track came from the ${state.template!.name} template. '
                'Changing it here leaves the template’s other settings in '
                'place.',
          ),
        UnplugSection(
          title: 'Capabilities',
          child: Column(
            children: [
              for (final capability in trackCapabilities)
                _CapabilityRow(capability: capability, selected: track),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).push(CareTeamView.route(state)),
              icon: const Icon(Icons.monitor_heart_outlined),
              label: const Text('Open the care-team view'),
            ),
          ),
        ),
        UnplugSection(
          title: 'Where distress goes',
          child: UnplugCard(
            color: AppColors.mint,
            borderColor: AppColors.mintStrong,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  distressRouteFor(track),
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A distress signal must never terminate at a non-clinical '
                  'coach. This route is a configurable escalation policy per '
                  'program, owned by Tether’s clinical leadership — not app '
                  'logic, and not a per-coach preference.',
                  style: TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        const UnplugNote(
          text: 'Two open questions the addendum flags: whether Tether already '
              'has a clinical escalation protocol this should point at rather '
              'than reinvent, and whether any program covers substance use, '
              'which brings 42 CFR Part 2 and a different consent '
              'architecture.',
        ),
      ],
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.capability, required this.selected});

  final TrackCapability capability;
  final DeliveryTrack selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: UnplugCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              capability.name,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final track in DeliveryTrack.values)
              _GrantLine(
                track: track,
                grant: capability.grantFor(track),
                highlighted: track == selected,
              ),
            if (capability.note != null) ...[
              const SizedBox(height: 8),
              Text(
                capability.note!,
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GrantLine extends StatelessWidget {
  const _GrantLine({
    required this.track,
    required this.grant,
    required this.highlighted,
  });

  final DeliveryTrack track;
  final CapabilityGrant grant;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (grant.kind) {
      GrantKind.allowed => (AppColors.mint, AppColors.deepTeal),
      GrantKind.conditional => (
          const Color(0xFFFFF3D6),
          const Color(0xFF7A5A15),
        ),
      GrantKind.blocked => (AppColors.coralLight, const Color(0xFF8C3A26)),
      GrantKind.notApplicable => (AppColors.cream, AppColors.mutedTeal),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              track.label,
              style: TextStyle(
                color: highlighted ? AppColors.deepTeal : AppColors.mutedTeal,
                fontSize: 12.5,
                fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: UnplugPill(
                label: grant.label,
                background: background,
                foreground: foreground,
              ),
            ),
          ),
          if (highlighted)
            const Icon(
              Icons.arrow_back_rounded,
              size: 15,
              color: AppColors.deepTeal,
            ),
        ],
      ),
    );
  }
}
