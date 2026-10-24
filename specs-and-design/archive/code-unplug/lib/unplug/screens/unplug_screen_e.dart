import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/observe_week.dart';
import '../models/platform_ceiling.dart';
import '../widgets/unplug_kit.dart';
import '../widgets/unplug_scope.dart';

/// Screen E — the Observe Week baseline report.
///
/// The report is designed to the iOS floor: an aggregate total, opens and a
/// time-of-day shape. Android's per-app split is shown underneath, labelled as
/// platform-specific detail, so a care team reading two patients' reports is
/// never quietly comparing two different things (addendum §1).
///
/// Every number here is sample data. See `models/observe_week.dart`.
class UnplugScreenE extends StatelessWidget {
  const UnplugScreenE({required this.nav, super.key});

  final UnplugNavigation nav;

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final platform = state.platform;
    const week = sampleObserveWeek;

    return UnplugPage(
      nav: nav,
      children: [
        const UnplugNote(
          tone: NoteTone.warning,
          text: 'Sample data. Nothing on this screen was measured from this '
              'device — the native implementation does not exist yet. The '
              'numbers are here so the report can be reviewed before real data '
              'is collected.',
        ),
        UnplugSection(
          title: 'The week',
          trailing: UnplugPill(label: 'Recorded on ${platform.label}'),
          child: UnplugCard(
            child: Column(
              children: [
                Row(
                  children: [
                    _Headline(
                      value: formatMinutes(week.totalMinutes),
                      label: 'On your selected apps',
                    ),
                    _Headline(
                      value: formatMinutes(week.averageMinutes),
                      label: 'Average day',
                    ),
                  ],
                ),
                const Divider(height: 26),
                Row(
                  children: [
                    _Headline(
                      value: '${week.opens}',
                      label: platform == TrackedPlatform.ios
                          ? 'Intercepts fired (opens approximated)'
                          : 'Opens',
                    ),
                    _Headline(
                      value: formatMinutes(week.peakMinutes),
                      label: 'Heaviest day',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (platform == TrackedPlatform.ios)
          const UnplugNote(
            text: 'iOS has no launch counter available to this app. The number '
                'above counts shield events, which is close while every open '
                'is intercepted and drifts once a shield is lifted. It is '
                'labelled as approximate everywhere it appears, including the '
                'care-team view.',
          ),
        UnplugSection(
          title: 'By day',
          child: UnplugCard(
            child: Column(
              children: [
                for (var index = 0; index < week.dailyMinutes.length; index++)
                  UnplugBar(
                    label: weekdayLabels[index % weekdayLabels.length],
                    value: formatMinutes(week.dailyMinutes[index]),
                    fraction: week.peakMinutes == 0
                        ? 0
                        : week.dailyMinutes[index] / week.peakMinutes,
                  ),
              ],
            ),
          ),
        ),
        UnplugSection(
          title: 'By time of day',
          child: UnplugCard(
            child: Column(
              children: [
                for (final part in week.dayparts)
                  UnplugBar(
                    label: part.label,
                    value: formatMinutes(part.minutes),
                    fraction: week.peakDaypartMinutes == 0
                        ? 0
                        : part.minutes / week.peakDaypartMinutes,
                  ),
              ],
            ),
          ),
        ),
        UnplugSection(
          title: 'By app',
          trailing: UnplugPill(
            label: platform == TrackedPlatform.android
                ? 'Android detail'
                : 'Not available on iOS',
            background: platform == TrackedPlatform.android
                ? AppColors.mint
                : AppColors.coralLight,
            foreground: platform == TrackedPlatform.android
                ? AppColors.deepTeal
                : const Color(0xFF8C3A26),
          ),
          child: platform == TrackedPlatform.android
              ? const _AndroidSplit(week: week)
              : const _IosGroups(),
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AndroidSplit extends StatelessWidget {
  const _AndroidSplit({required this.week});

  final ObserveWeek week;

  @override
  Widget build(BuildContext context) {
    final peak = week.perApp.isEmpty
        ? 0
        : week.perApp.map((app) => app.minutes).reduce((a, b) => a > b ? a : b);

    return UnplugCard(
      child: Column(
        children: [
          for (final app in week.perApp)
            UnplugBar(
              label: app.packageLabel,
              value: '${formatMinutes(app.minutes)} · ${app.opens} opens',
              fraction: peak == 0 ? 0 : app.minutes / peak,
            ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Android returns real package names and real durations. The '
              'dashboard treats this as extra detail, never as the baseline, '
              'so an iOS patient is not shown as having less information.',
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IosGroups extends StatelessWidget {
  const _IosGroups();

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final groups = state.groups.where((group) => group.shielded).toList();

    return UnplugCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'iOS cannot tell this app which apps these were.',
            style: TextStyle(
              color: AppColors.deepTeal,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The tokens are opaque, and the extension that computes usage '
            'detail has no network access by design. What the report can show '
            'is the aggregate above, plus the groups labelled on screen B.',
            style: TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          if (groups.isEmpty)
            const Text(
              'No groups are shielded yet.',
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final group in groups)
                  UnplugPill(
                    label: '${group.label} · ${group.appCount} apps',
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
