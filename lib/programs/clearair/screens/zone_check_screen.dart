import 'package:flutter/material.dart';

import '../../program.dart';
import '../../../theme/app_colors.dart';
import '../clearair_controller.dart';
import '../clearair_safety.dart';
import '../models/action_plan.dart';

/// Daily zone check-in: symptoms, optional peak flow, and the zone from
/// the user's own action plan. The screen shows the plan's guidance for
/// the chosen zone — the app does not determine zones clinically.
class ZoneCheckScreen extends StatefulWidget {
  const ZoneCheckScreen({
    required this.controller,
    required this.onCompleted,
    this.onClose,
    super.key,
  });

  final ClearAirController controller;
  final ValueChanged<ProgramCheckInResult> onCompleted;
  final VoidCallback? onClose;

  @override
  State<ZoneCheckScreen> createState() => _ZoneCheckScreenState();
}

class _ZoneCheckScreenState extends State<ZoneCheckScreen> {
  final Set<String> _symptoms = <String>{};
  final _peakFlowController = TextEditingController();
  ActionPlanZone _zone = ActionPlanZone.green;
  String? _error;

  @override
  void dispose() {
    _peakFlowController.dispose();
    super.dispose();
  }

  void _save() {
    final raw = _peakFlowController.text.trim();
    final peakFlow = raw.isEmpty ? null : int.tryParse(raw);
    if (raw.isNotEmpty && peakFlow == null) {
      setState(() => _error = 'Peak flow must be a whole number.');
      return;
    }
    final result = widget.controller.completeZoneCheckIn(
      symptoms: _symptoms.toList(),
      zone: _zone,
      peakFlow: peakFlow,
    );
    widget.onCompleted(result);
  }

  @override
  Widget build(BuildContext context) {
    final hasPlan = widget.controller.clinicianPlan != null;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Daily zone check'),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.deepTeal,
        leading: widget.onClose == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: widget.onClose,
                tooltip: 'Back',
              ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (!hasPlan)
              const Card(
                color: AppColors.paper,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Your clinician has not recorded an action plan yet. The zones below come from your plan once it is recorded.',
                    style: TextStyle(color: AppColors.tealSecondary),
                  ),
                ),
              ),
            if (!hasPlan) const SizedBox(height: 12),
            const Text(
              'Any symptoms today?',
              style: TextStyle(
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose any that fit. This is your own report — it is information, not a grade.',
              style: TextStyle(color: AppColors.mutedTeal, fontSize: 12),
            ),
            for (final symptom in ClearAirSafety.symptomOptions)
              CheckboxListTile(
                title: Text(symptom),
                value: _symptoms.contains(symptom),
                activeColor: AppColors.deepTeal,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _symptoms.add(symptom);
                    } else {
                      _symptoms.remove(symptom);
                    }
                  });
                },
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _peakFlowController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Peak flow (optional)',
                hintText: 'Leave blank if you do not have a meter',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Which zone does your action plan put you in today?',
              style: TextStyle(
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Follow your plan to decide — the app does not determine this for you.',
              style: TextStyle(color: AppColors.mutedTeal, fontSize: 12),
            ),
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
            const SizedBox(height: 8),
            Card(
              color: AppColors.mint,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  ClearAirSafety.guidanceFor(_zone),
                  style: const TextStyle(color: AppColors.tealSecondary),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                label: 'Error. $_error',
                excludeSemantics: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Semantics(
              label: 'Save zone check-in',
              button: true,
              excludeSemantics: true,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save check-in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
