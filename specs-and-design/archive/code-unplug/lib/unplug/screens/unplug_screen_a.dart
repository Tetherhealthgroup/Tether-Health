import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/platform_ceiling.dart';
import '../widgets/unplug_kit.dart';
import '../widgets/unplug_scope.dart';

/// Screen A — what the module can actually see, per addendum §1.
///
/// This is the first screen in the module on purpose. A clinician who believes
/// they are looking at per-app iOS data will make decisions on numbers that do
/// not exist, so the ceiling is stated before anything is switched on.
class UnplugScreenA extends StatelessWidget {
  const UnplugScreenA({required this.nav, super.key});

  final UnplugNavigation nav;

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final platform = state.platform;

    return UnplugPage(
      nav: nav,
      children: [
        UnplugSection(
          title: 'This device',
          child: UnplugChoices<TrackedPlatform>(
            values: TrackedPlatform.values,
            selected: platform,
            labelOf: (value) => value.label,
            onSelected: state.selectPlatform,
          ),
        ),
        UnplugNote(
          text: platform == TrackedPlatform.ios
              ? 'On iOS the app identities are opaque, device-local tokens. '
                  'They can be shielded, and they can be drawn using Apple’s '
                  'own label view. They cannot be named, and they cannot leave '
                  'the device.'
              : 'On Android the usage API returns real package names and real '
                  'durations. Everything below is available, but the dashboard '
                  'is still designed to the iOS floor so the two platforms tell '
                  'a care team one story.',
        ),
        UnplugSection(
          title: 'Signal by signal',
          child: Column(
            children: [
              for (final signal in platformSignals)
                _SignalRow(signal: signal, platform: platform),
            ],
          ),
        ),
        const UnplugNote(
          tone: NoteTone.warning,
          text: 'The care team is told this in writing during Phase 1. The '
              'platform is labelled on every patient record, so nobody has to '
              'remember which ceiling a number came from.',
        ),
      ],
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({required this.signal, required this.platform});

  final PlatformSignal signal;
  final TrackedPlatform platform;

  @override
  Widget build(BuildContext context) {
    final availability = signal.availabilityOn(platform);
    final (background, foreground) = switch (availability) {
      SignalAvailability.full => (AppColors.mint, AppColors.deepTeal),
      SignalAvailability.aggregate => (
          AppColors.mintStrong,
          AppColors.deepTeal
        ),
      SignalAvailability.approximate => (
          const Color(0xFFFFF3D6),
          const Color(0xFF7A5A15),
        ),
      SignalAvailability.unavailable => (
          AppColors.coralLight,
          const Color(0xFF8C3A26),
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: UnplugCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    signal.name,
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                UnplugPill(
                  label: availability.label,
                  background: background,
                  foreground: foreground,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Wanted: ${signal.wanted}',
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              signal.noteFor(platform),
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
