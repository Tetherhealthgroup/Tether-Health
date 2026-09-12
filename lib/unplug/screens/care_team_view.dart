import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/delivery_track.dart';
import '../models/observe_week.dart';
import '../models/platform_ceiling.dart';
import '../models/unplug_module_state.dart';
import '../widgets/unplug_kit.dart';
import '../widgets/unplug_scope.dart';

/// The read-only care-team view — the Phase 1 deliverable in addendum §5.
///
/// Two rules shape this screen and neither is negotiable:
///
/// 1. It is designed to the iOS floor (§1). There is no per-app breakdown here
///    even when the patient is on Android, because a clinician who learns to
///    expect one will make decisions about an iPhone patient on numbers that do
///    not exist. Android's extra detail is offered as an explicitly labelled
///    supplement, never as the record.
/// 2. The platform is labelled on the record itself, not in a footnote.
///
/// It is also genuinely read-only. There is no control on this screen that
/// changes anything on the patient's device: a clinician changes a tier by
/// agreeing it, and the change is made where the role matrix says it may be.
class CareTeamView extends StatelessWidget {
  const CareTeamView({super.key});

  static Route<void> route(UnplugModuleState state) => MaterialPageRoute<void>(
        builder: (context) => UnplugScope(state: state, child: const CareTeamView()),
      );

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final track = state.track;
    const week = sampleObserveWeek;
    final live = state.liveUsage;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.deepTeal,
        foregroundColor: Colors.white,
        title: const Text(
          'Care-team view',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Center(
              child: UnplugPill(
                label: 'READ ONLY',
                background: Color(0x33D5EF75),
                foreground: AppColors.lime,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          UnplugCard(
            color: AppColors.mint,
            borderColor: AppColors.mintStrong,
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, color: AppColors.deepTeal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This device · ${state.platform.label}',
                        style: const TextStyle(
                          color: AppColors.deepTeal,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${track.label} track · '
                        '${state.template?.name ?? 'no template'}',
                        style: const TextStyle(
                          color: AppColors.tealSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!state.isLive)
            const UnplugNote(
              tone: NoteTone.warning,
              text: 'Simulated. This build has no screen-time layer attached, so '
                  'every figure below is illustrative. A real record would carry '
                  'the same warning rather than look identical.',
            ),
          UnplugSection(
            title: 'Derived metrics',
            trailing: const UnplugPill(label: 'Designed to the iOS floor'),
            child: UnplugCard(
              child: Column(
                children: [
                  UnplugFact(
                    label: 'Time on selected',
                    value: live == null
                        ? '${formatMinutes(week.totalMinutes)} (sample)'
                        : formatMinutes(
                            live.dailyMinutes.fold(0, (a, b) => a + b),
                          ),
                    emphasis: true,
                  ),
                  UnplugFact(
                    label: 'Opens',
                    value: live == null
                        ? '${week.opens} (sample)'
                        : '${live.opens}'
                            '${live.opensAreApproximate ? ' · approximate' : ''}',
                  ),
                  UnplugFact(
                    label: 'Intercepts fired',
                    value: '${state.interceptsShown}',
                  ),
                  UnplugFact(
                    label: 'Closed rather than pushed through',
                    value: '${state.interceptsDismissed}',
                  ),
                  UnplugFact(
                    label: 'Overrides used',
                    value: '${state.overridesUsed} of '
                        '${state.overrideAllowance}',
                  ),
                  UnplugFact(label: 'Current tier', value: 'Tier ${state.tier}'),
                ],
              ),
            ),
          ),
          if (state.platform == TrackedPlatform.ios || live?.perApp.isEmpty == true)
            const UnplugNote(
              text: 'No per-app breakdown appears here, for either platform. On '
                  'iOS one cannot exist; showing one for Android patients only '
                  'would train a clinician to look for a number that is absent '
                  'from half their caseload.',
            ),
          UnplugSection(
            title: 'Journal and mood tags',
            child: _ConsentGated(track: track),
          ),
          UnplugSection(
            title: 'Escalation route',
            child: UnplugCard(
              color: state.escalationOpened
                  ? AppColors.coralLight
                  : AppColors.paper,
              borderColor:
                  state.escalationOpened ? AppColors.coral : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.escalationOpened
                        ? 'An escalation is open on this record.'
                        : 'No escalation is open.',
                    style: TextStyle(
                      color: state.escalationOpened
                          ? const Color(0xFF8C3A26)
                          : AppColors.deepTeal,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    distressRouteFor(track),
                    style: TextStyle(
                      color: state.escalationOpened
                          ? const Color(0xFF8C3A26)
                          : AppColors.tealSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          UnplugSection(
            title: 'What this view cannot tell you',
            child: UnplugCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final signal in platformSignals.where(
                    (signal) =>
                        signal.ios != SignalAvailability.full ||
                        signal.android != SignalAvailability.full,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.block_flipped,
                            size: 16,
                            color: AppColors.mutedTeal,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              '${signal.name}: '
                              '${signal.availabilityOn(TrackedPlatform.ios).label.toLowerCase()} '
                              'on iOS, '
                              '${signal.availabilityOn(TrackedPlatform.android).label.toLowerCase()} '
                              'on Android.',
                              style: const TextStyle(
                                color: AppColors.tealSecondary,
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The journal, shown according to the role matrix rather than to seniority.
class _ConsentGated extends StatelessWidget {
  const _ConsentGated({required this.track});

  final DeliveryTrack track;

  @override
  Widget build(BuildContext context) {
    final grant = trackCapabilities
        .firstWhere((capability) => capability.name == 'View journal and mood tags')
        .grantFor(track);

    if (grant.kind == GrantKind.blocked) {
      return UnplugCard(
        child: Row(
          children: [
            const Icon(Icons.lock_outline_rounded, color: AppColors.mutedTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Not available on the ${track.label.toLowerCase()} track. A '
                'coach never reads free text; the tags that drive escalation are '
                'evaluated by policy instead.',
                style: const TextStyle(
                  color: AppColors.tealSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return UnplugCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnplugPill(label: grant.label),
          const SizedBox(height: 10),
          const Text(
            'Nothing is shown here until the patient has consented to sharing '
            'it, and the consent is per programme rather than once at signup.',
            style: TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
