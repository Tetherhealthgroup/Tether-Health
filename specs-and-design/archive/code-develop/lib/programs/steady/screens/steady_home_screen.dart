import 'package:flutter/material.dart';

import '../../program.dart';
import '../../theme/app_colors.dart';
import '../../widgets/program_home_shell.dart';
import '../models/glucose_reading.dart';
import '../steady_controller.dart';
import '../steady_safety.dart';

/// Steady program hub: today's focus, logging streak (information only),
/// the clinician-set target range, and navigation.
class SteadyHomeScreen extends StatelessWidget {
  const SteadyHomeScreen({
    required this.controller,
    required this.onLogReading,
    required this.onOpenReset,
    super.key,
  });

  final SteadyController controller;
  final VoidCallback onLogReading;
  final VoidCallback onOpenReset;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final spec = programSpecs[ProgramId.steady]!;
        return ProgramHomeShell(
          spec: spec,
          title: spec.name,
          isLoading: controller.isLoading,
          errorMessage: controller.errorMessage,
          onRetry: controller.retry,
          children: [
            _TodaysFocusCard(controller: controller),
            const SizedBox(height: 12),
            _StreakCard(controller: controller),
            const SizedBox(height: 12),
            _TargetRangeCard(
              controller: controller,
              onRecordTarget: () => _recordTargetRange(context, controller),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Log a glucose reading',
                    button: true,
                    excludeSemantics: true,
                    child: FilledButton(
                      onPressed: onLogReading,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.deepTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Log a reading'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    label: 'Open energy reset',
                    button: true,
                    excludeSemantics: true,
                    child: FilledButton(
                      onPressed: onOpenReset,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.paper,
                        foregroundColor: AppColors.deepTeal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Energy reset'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Records the clinician-provided target range. The app never invents
  /// one — the dialog requires the clinician / care team source.
  static Future<void> _recordTargetRange(
    BuildContext context,
    SteadyController controller,
  ) async {
    final minController = TextEditingController();
    final maxController = TextEditingController();
    final byController = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Record target range'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your clinician sets this range. The app never invents one.',
                  style: TextStyle(color: AppColors.tealSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('steady-target-min'),
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Lower value (mg/dL)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('steady-target-max'),
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Upper value (mg/dL)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('steady-target-by'),
                  controller: byController,
                  decoration: const InputDecoration(
                    labelText: 'Set by (clinician or care team)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final min = int.tryParse(minController.text.trim());
                final max = int.tryParse(maxController.text.trim());
                if (min == null || max == null) {
                  setState(
                    () => error = 'Enter whole numbers for both values.',
                  );
                  return;
                }
                if (!controller.setTargetRange(
                  minMgDl: min,
                  maxMgDl: max,
                  setBy: byController.text,
                )) {
                  setState(() => error = controller.errorMessage);
                  return;
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    minController.dispose();
    maxController.dispose();
    byController.dispose();
  }
}

class _TodaysFocusCard extends StatelessWidget {
  const _TodaysFocusCard({required this.controller});

  final SteadyController controller;

  @override
  Widget build(BuildContext context) {
    final latest = controller.latestReading;
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
                'No readings yet. Log a reading whenever you check — there is no schedule to keep up with.',
                style: TextStyle(color: AppColors.tealSecondary),
              )
            else
              Text(
                'Latest: ${_describe(latest)}',
                style: const TextStyle(color: AppColors.tealSecondary),
              ),
            const SizedBox(height: 8),
            const Text(
              SteadySafety.readingsAreDataNote,
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Values are shown as data only — never graded.
  static String _describe(GlucoseReading reading) {
    final value =
        reading.valueMgDl == null ? '—' : '${reading.valueMgDl} mg/dL';
    return '$value · ${reading.context.label}';
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.controller});

  final SteadyController controller;

  @override
  Widget build(BuildContext context) {
    final streak = controller.loggingStreakDays;
    return Card(
      color: AppColors.paper,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.tealSecondary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: 'Logging streak, $streak days',
                    excludeSemantics: true,
                    child: Text(
                      'Logging streak: $streak ${streak == 1 ? 'day' : 'days'}',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Logging is information — there are no grades here.',
                    style: TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 12,
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

class _TargetRangeCard extends StatelessWidget {
  const _TargetRangeCard({
    required this.controller,
    required this.onRecordTarget,
  });

  final SteadyController controller;
  final VoidCallback onRecordTarget;

  @override
  Widget build(BuildContext context) {
    final target = controller.targetRange;
    return Card(
      color: AppColors.mint,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target range',
              style: TextStyle(
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (target == null) ...[
              const Text(
                'No target range recorded yet. Your clinician sets this — the app never invents one.',
                style: TextStyle(color: AppColors.tealSecondary),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Record target range',
                button: true,
                excludeSemantics: true,
                child: FilledButton(
                  onPressed: onRecordTarget,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Record target range'),
                ),
              ),
            ] else ...[
              Semantics(
                label:
                    'Target range ${target.minMgDl} to ${target.maxMgDl} milligrams per deciliter, set by ${target.setBy}',
                excludeSemantics: true,
                child: Text(
                  '${target.minMgDl}–${target.maxMgDl} mg/dL',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set by ${target.setBy}',
                style: const TextStyle(color: AppColors.tealSecondary),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              SteadySafety.clinicianTargetsNote,
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
