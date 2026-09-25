import 'package:flutter/material.dart';

import '../../program.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/program_home_shell.dart';
import '../heartwise_controller.dart';
import '../heartwise_safety.dart';
import '../models/bp_reading.dart';
import '../widgets/emergency_card.dart';

/// Heartwise program hub: today's focus, the permanent emergency card,
/// and navigation to blood-pressure logging and the cholesterol panel.
class HeartwiseHomeScreen extends StatelessWidget {
  const HeartwiseHomeScreen({
    required this.controller,
    required this.onLogBp,
    required this.onOpenCholesterol,
    this.launchEmergency,
    super.key,
  });

  final HeartwiseController controller;
  final VoidCallback onLogBp;
  final VoidCallback onOpenCholesterol;

  /// Injected for tests; defaults to opening a `tel:` link.
  final Future<void> Function(Uri uri)? launchEmergency;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final spec = programSpecs[ProgramId.heartwise]!;
        return ProgramHomeShell(
          spec: spec,
          title: spec.name,
          isLoading: controller.isLoading,
          errorMessage: controller.errorMessage,
          onRetry: controller.retry,
          children: [
            EmergencyCard(launchEmergency: launchEmergency),
            const SizedBox(height: 12),
            _TodaysFocusCard(controller: controller),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Log blood pressure',
                    button: true,
                    excludeSemantics: true,
                    child: FilledButton(
                      onPressed: onLogBp,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.deepTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Log blood pressure'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    label: 'Open cholesterol panel',
                    button: true,
                    excludeSemantics: true,
                    child: FilledButton(
                      onPressed: onOpenCholesterol,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.paper,
                        foregroundColor: AppColors.deepTeal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cholesterol panel'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _WhenToCallDoctorCard(),
            const SizedBox(height: 12),
            const _TargetsNoteCard(),
          ],
        );
      },
    );
  }
}

class _TodaysFocusCard extends StatelessWidget {
  const _TodaysFocusCard({required this.controller});

  final HeartwiseController controller;

  @override
  Widget build(BuildContext context) {
    final latest = controller.latestBpReading;
    return Card(
      color: AppColors.paper,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's focus",
              style: TextStyle(
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (latest == null)
              const Text(
                'No readings yet. Log your blood pressure whenever you take it — there is no schedule to keep up with.',
                style: TextStyle(color: AppColors.tealSecondary),
              )
            else
              Semantics(
                label: 'Latest reading ${_describe(latest)}',
                excludeSemantics: true,
                child: Text(
                  'Latest: ${_describe(latest)}',
                  style: const TextStyle(color: AppColors.tealSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Readings are shown as data only — never graded.
  static String _describe(BpReading reading) {
    final systolic = reading.systolic?.toString() ?? '—';
    final diastolic = reading.diastolic?.toString() ?? '—';
    return '$systolic/$diastolic';
  }
}

class _WhenToCallDoctorCard extends StatelessWidget {
  const _WhenToCallDoctorCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.paper,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              HeartwiseSafety.whenToCallDoctorTitle,
              style: TextStyle(
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in HeartwiseSafety.whenToCallDoctorItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '•  ',
                      style: TextStyle(color: AppColors.tealSecondary),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(color: AppColors.tealSecondary),
                      ),
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

class _TargetsNoteCard extends StatelessWidget {
  const _TargetsNoteCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: AppColors.mint,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.tealSecondary,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                HeartwiseSafety.targetsNote,
                style: TextStyle(color: AppColors.tealSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
