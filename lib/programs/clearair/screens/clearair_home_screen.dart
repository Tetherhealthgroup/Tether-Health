import 'package:flutter/material.dart';

import '../../program.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/program_home_shell.dart';
import '../clearair_controller.dart';
import '../clearair_safety.dart';
import '../models/action_plan.dart';
import '../models/symptom_log.dart';

/// ClearAir program hub: the action-plan zone banner (always visible),
/// the daily zone check, and the always-reachable red-zone route.
class ClearAirHomeScreen extends StatelessWidget {
  const ClearAirHomeScreen({
    required this.controller,
    required this.onZoneCheck,
    required this.onOpenRedZone,
    super.key,
  });

  final ClearAirController controller;
  final VoidCallback onZoneCheck;
  final VoidCallback onOpenRedZone;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final spec = programSpecs[ProgramId.clearAir]!;
        return ProgramHomeShell(
          spec: spec,
          title: spec.name,
          isLoading: controller.isLoading,
          errorMessage: controller.errorMessage,
          onRetry: controller.retry,
          children: [
            _ZoneBanner(controller: controller),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Daily zone check',
                    button: true,
                    excludeSemantics: true,
                    child: FilledButton(
                      onPressed: onZoneCheck,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.deepTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Daily zone check'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    label: ClearAirSafety.redZoneButtonLabel,
                    button: true,
                    excludeSemantics: true,
                    child: FilledButton(
                      onPressed: onOpenRedZone,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB3261E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(ClearAirSafety.redZoneButtonLabel),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PlanCard(
              controller: controller,
              onRecordPlan: () => _recordActionPlan(context, controller),
            ),
            const SizedBox(height: 12),
            _SymptomHistoryCard(controller: controller),
          ],
        );
      },
    );
  }

  /// Records the clinician's action plan. The zone and the clinician /
  /// care-team source are both required — the app never decides zones.
  static Future<void> _recordActionPlan(
    BuildContext context,
    ClearAirController controller,
  ) =>
      showDialog<void>(
        context: context,
        builder: (_) => _ActionPlanDialog(controller: controller),
      );
}

class _ActionPlanDialog extends StatefulWidget {
  const _ActionPlanDialog({required this.controller});

  final ClearAirController controller;

  @override
  State<_ActionPlanDialog> createState() => _ActionPlanDialogState();
}

class _ActionPlanDialogState extends State<_ActionPlanDialog> {
  final _byController = TextEditingController();
  ActionPlanZone _zone = ActionPlanZone.green;
  String? _error;

  @override
  void dispose() {
    _byController.dispose();
    super.dispose();
  }

  void _save() {
    if (!widget.controller.recordClinicianPlan(
      zone: _zone,
      recordedBy: _byController.text,
    )) {
      setState(() => _error = widget.controller.errorMessage);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record action plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record the zones exactly as your clinician wrote them in your action plan.',
              style: TextStyle(color: AppColors.tealSecondary),
            ),
            const SizedBox(height: 8),
            RadioGroup<ActionPlanZone>(
              groupValue: _zone,
              onChanged: (value) {
                if (value != null) setState(() => _zone = value);
              },
              child: Column(
                children: [
                  for (final option in ActionPlanZone.values)
                    RadioListTile<ActionPlanZone>(
                      title: Text('${option.label} zone'),
                      value: option,
                      activeColor: AppColors.deepTeal,
                    ),
                ],
              ),
            ),
            TextField(
              controller: _byController,
              decoration: const InputDecoration(
                labelText: 'Recorded by (clinician or care team)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// The action-plan zone banner. Always visible at the top of the home
/// screen; the zone is always named in text, never shown by color alone.
class _ZoneBanner extends StatelessWidget {
  const _ZoneBanner({required this.controller});

  final ClearAirController controller;

  @override
  Widget build(BuildContext context) {
    final zone = controller.currentZone;
    final Color background;
    final Color border;
    final String text;
    if (zone == null) {
      background = AppColors.paper;
      border = AppColors.border;
      text =
          'No action plan recorded yet. Your clinician provides your green, yellow, and red zones.';
    } else {
      switch (zone) {
        case ActionPlanZone.green:
          background = const Color(0xFFDFF2E7);
          border = const Color(0xFF9FD3B4);
          text = 'Your action plan zone: Green';
        case ActionPlanZone.yellow:
          background = const Color(0xFFFFF3D6);
          border = const Color(0xFFE8C95C);
          text = 'Your action plan zone: Yellow';
        case ActionPlanZone.red:
          background = const Color(0xFFFDE7E3);
          border = const Color(0xFFF1998A);
          text = 'Your action plan zone: Red — open your red-zone plan now.';
      }
    }
    return Semantics(
      label: 'Action plan zone. $text',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              zone == ActionPlanZone.red
                  ? Icons.warning_amber_rounded
                  : Icons.favorite_rounded,
              color: AppColors.deepTeal,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.controller,
    required this.onRecordPlan,
  });

  final ClearAirController controller;
  final VoidCallback onRecordPlan;

  @override
  Widget build(BuildContext context) {
    final plan = controller.clinicianPlan;
    return Card(
      color: AppColors.paper,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Action plan',
              style: TextStyle(
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (plan == null)
              const Text(
                'No plan recorded yet. Your action-plan zones come from your clinician — the app does not decide them.',
                style: TextStyle(color: AppColors.tealSecondary),
              )
            else
              Text(
                'Baseline zone: ${plan.zone.label}\nRecorded by ${plan.recordedBy}',
                style: const TextStyle(color: AppColors.tealSecondary),
              ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Record action plan',
              button: true,
              excludeSemantics: true,
              child: FilledButton(
                onPressed: onRecordPlan,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                    plan == null ? 'Record action plan' : 'Update action plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymptomHistoryCard extends StatelessWidget {
  const _SymptomHistoryCard({required this.controller});

  final ClearAirController controller;

  @override
  Widget build(BuildContext context) {
    final logs = controller.symptomLogs;
    return Card(
      color: AppColors.paper,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent check-ins',
              style: TextStyle(
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (logs.isEmpty)
              const Text(
                'No check-ins yet. Your daily zone check takes under a minute.',
                style: TextStyle(color: AppColors.tealSecondary),
              )
            else
              for (final log in logs.reversed.take(5)) _logRow(log),
          ],
        ),
      ),
    );
  }

  Widget _logRow(SymptomLog log) {
    final symptoms =
        log.symptoms.isEmpty ? 'No symptoms' : log.symptoms.join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              log.zone.label,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              symptoms,
              style: const TextStyle(color: AppColors.tealSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
