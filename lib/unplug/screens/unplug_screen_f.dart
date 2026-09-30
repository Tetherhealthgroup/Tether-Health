import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/delivery_track.dart';
import '../models/program_template.dart';
import '../models/unplug_module_state.dart';
import '../widgets/unplug_kit.dart';
import '../widgets/unplug_scope.dart';

/// Screen F — the tier ladder and what it costs to loosen a limit.
///
/// Addendum §4: tightening is immediate and free. Loosening always costs
/// something — a named reviewer on the clinician and coach tracks, or a 24-hour
/// cool-off when the person is self-guided. The template, where one is applied,
/// sets the ceiling this screen cannot exceed.
class UnplugScreenF extends StatefulWidget {
  const UnplugScreenF({required this.nav, super.key});

  final UnplugNavigation nav;

  @override
  State<UnplugScreenF> createState() => _UnplugScreenFState();
}

class _UnplugScreenFState extends State<UnplugScreenF> {
  int? _candidate;

  int _resolvedCandidate(UnplugModuleState state) =>
      (_candidate ?? state.tier).clamp(state.tierFloor, state.tierCeiling);

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final candidate = _resolvedCandidate(state);
    final request = state.limitRequest;
    final divisions = state.tierCeiling - state.tierFloor;

    return UnplugPage(
      nav: widget.nav,
      children: [
        UnplugSection(
          title: 'Tier',
          trailing: UnplugPill(
            label: state.template == null
                ? 'No template · tiers 0–$maxTier'
                : '${state.template!.name} · ${state.template!.tierRange}',
          ),
          child: UnplugCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Tier $candidate',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (candidate != state.tier)
                      Text(
                        'currently tier ${state.tier}',
                        style: const TextStyle(
                          color: AppColors.mutedTeal,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tierDescriptions[candidate.clamp(
                    0,
                    tierDescriptions.length - 1,
                  )],
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: candidate.toDouble(),
                  min: state.tierFloor.toDouble(),
                  max: state.tierCeiling.toDouble(),
                  divisions: divisions == 0 ? null : divisions,
                  label: 'Tier $candidate',
                  onChanged: state.selfMayMoveTier
                      ? (value) => setState(() => _candidate = value.round())
                      : null,
                ),
                if (!state.selfMayMoveTier)
                  const Text(
                    'This template gives the guardian every limit. Nothing on '
                    'this screen is editable by the person using the app.',
                    style: TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: !state.selfMayMoveTier || candidate == state.tier
                        ? null
                        : () {
                            state.requestTier(candidate);
                            setState(() => _candidate = null);
                          },
                    child: Text(
                      candidate < state.tier
                          ? 'Request a lower tier'
                          : 'Apply tier $candidate',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (candidate < state.tier)
          UnplugNote(
            text: switch (state.track) {
              DeliveryTrack.selfGuided =>
                'Lowering the tier is a loosening, so it waits out a 24-hour '
                    'cool-off. Raising it applies the moment you press apply.',
              DeliveryTrack.clinician =>
                'Lowering the tier is a loosening, so the clinician holding '
                    'this program approves it first.',
              DeliveryTrack.coach =>
                'Lowering the tier is a loosening, so the coach holding this '
                    'program approves it first.',
            },
          ),
        if (request != null) _PendingRequest(request: request, state: state),
        UnplugSection(
          title: 'Overrides',
          trailing: Text(
            '${state.overridesLeft} of ${state.overrideAllowance} left',
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: UnplugCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How many times the intercept may be opened anyway before '
                  'the window closes for good.',
                  style: TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: state.overrideAllowance.toDouble(),
                        max: 6,
                        divisions: 6,
                        label: '${state.overrideAllowance}',
                        onChanged: (value) =>
                            state.setOverrideAllowance(value.round()),
                      ),
                    ),
                    TextButton(
                      onPressed: state.overridesUsed == 0
                          ? null
                          : state.resetOverrides,
                      child: const Text('Reset window'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        UnplugSection(
          title: 'The ladder',
          child: Column(
            children: [
              for (var tier = 0; tier < tierDescriptions.length; tier++)
                _TierRow(
                  tier: tier,
                  description: tierDescriptions[tier],
                  current: tier == state.tier,
                  reachable:
                      tier >= state.tierFloor && tier <= state.tierCeiling,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingRequest extends StatelessWidget {
  const _PendingRequest({required this.request, required this.state});

  final LimitIncreaseRequest request;
  final UnplugModuleState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final clearsAt = request.clearsAt;
    final cleared = request.isClearedAt(now);
    final remaining = clearsAt?.difference(now);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: UnplugCard(
        color: AppColors.mint,
        borderColor: AppColors.mintStrong,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waiting to move to tier ${request.requestedTier}',
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              clearsAt == null
                  ? 'Sent to ${request.reviewer}. Nothing changes until they '
                      'approve it.'
                  : cleared
                      ? 'The cool-off has passed. Apply it whenever you are '
                          'ready.'
                      : 'The cool-off clears at '
                          '${_formatClock(clearsAt)}, in '
                          '${_formatRemaining(remaining!)}.',
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: clearsAt != null && !cleared
                        ? null
                        : state.settleLimitRequest,
                    child: Text(
                      clearsAt == null ? 'Record approval' : 'Apply now',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.withdrawLimitRequest,
                    child: const Text('Withdraw'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatClock(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _formatRemaining(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.tier,
    required this.description,
    required this.current,
    required this.reachable,
  });

  final int tier;
  final String description;
  final bool current;
  final bool reachable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: UnplugCard(
        padding: const EdgeInsets.all(13),
        color: current ? AppColors.mint : AppColors.paper,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: reachable ? AppColors.deepTeal : AppColors.border,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$tier',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  color:
                      reachable ? AppColors.tealSecondary : AppColors.mutedTeal,
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (!reachable)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.mutedTeal,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
