import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/platform_ceiling.dart';
import '../models/unplug_module_state.dart';
import '../widgets/unplug_kit.dart';
import '../widgets/unplug_scope.dart';

/// Screen I — is tracking actually running?
///
/// The single most common support ticket for a blocker is "it just stopped
/// working", and the reason is almost always OEM battery management killing the
/// Android foreground service, or a permission revoked without telling the app
/// (addendum §2.2 and the §5 risk register). The mitigation is not to prevent
/// it — that is not possible — but to notice it and say so, rather than letting
/// someone believe they are protected when they are not.
class UnplugScreenI extends StatelessWidget {
  const UnplugScreenI({required this.nav, super.key});

  final UnplugNavigation nav;

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final checks = state.applicableChecks;
    final healthy = state.trackingHealthy;
    final failing = checks.where((check) => !check.healthy).toList();

    return UnplugPage(
      nav: nav,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: UnplugCard(
            color: healthy ? AppColors.mint : AppColors.coralLight,
            borderColor: healthy ? AppColors.mintStrong : AppColors.coral,
            child: Row(
              children: [
                Icon(
                  healthy
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  size: 30,
                  color: healthy ? AppColors.deepTeal : const Color(0xFF8C3A26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        healthy
                            ? 'Tracking is running'
                            : 'Tracking has stopped',
                        style: TextStyle(
                          color: healthy
                              ? AppColors.deepTeal
                              : const Color(0xFF8C3A26),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        healthy
                            ? 'All ${checks.length} checks for '
                                '${state.platform.label} pass.'
                            : '${failing.length} of ${checks.length} checks '
                                'failed. Nothing is being measured or '
                                'intercepted until they pass.',
                        style: TextStyle(
                          color: healthy
                              ? AppColors.tealSecondary
                              : const Color(0xFF8C3A26),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        UnplugSection(
          title: '${state.platform.label} checks',
          trailing: TextButton(
            onPressed: healthy ? null : state.restoreTracking,
            child: const Text('Restore all'),
          ),
          child: Column(
            children: [
              for (final check in checks)
                _CheckRow(
                  check: check,
                  onToggle: () => state.toggleCheck(check.name),
                ),
            ],
          ),
        ),
        if (state.platform == TrackedPlatform.android)
          const UnplugNote(
            tone: NoteTone.warning,
            text: 'Xiaomi, Samsung, Oppo and OnePlus each kill a foreground '
                'service differently, so this check has to be validated on a '
                'real device matrix rather than on an emulator.',
          ),
        const UnplugNote(
          text: 'Each check can be flipped here so the warning state can be '
              'reviewed on device. In the shipped module these come from the '
              'platform, not from a switch.',
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check, required this.onToggle});

  final TrackingCheck check;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: UnplugCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  check.healthy
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 20,
                  color: check.healthy ? AppColors.deepTeal : AppColors.coral,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    check.name,
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Switch(value: check.healthy, onChanged: (_) => onToggle()),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              check.detail,
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
            if (!check.healthy) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.coralLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  check.remedy,
                  style: const TextStyle(
                    color: Color(0xFF8C3A26),
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
