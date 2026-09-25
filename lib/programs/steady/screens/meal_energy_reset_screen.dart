import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../steady_safety.dart';

/// The Steady rescue flow: a gentle energy reset after a difficult reading.
///
/// HARD RULES: no calorie counting, no food-calorie inputs, no
/// compensation language ("burn it off", "make up for it"). A high reading
/// is information, not a failure.
class MealEnergyResetScreen extends StatelessWidget {
  const MealEnergyResetScreen({
    required this.onDone,
    this.onClose,
    super.key,
  });

  final VoidCallback onDone;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Energy reset'),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.deepTeal,
        leading: onClose == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onClose,
                tooltip: 'Back',
              ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Card(
              color: AppColors.mint,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A high reading is information, not a failure.',
                      style: TextStyle(
                        color: AppColors.deepTeal,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This reset is a gentle pause — no counting, no making up for anything.',
                      style: TextStyle(color: AppColors.tealSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Take it one step at a time',
              style: TextStyle(
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < SteadySafety.resetSteps.length; i++)
              Card(
                color: AppColors.paper,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.deepTeal,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          SteadySafety.resetSteps[i],
                          style: const TextStyle(
                            color: AppColors.tealSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'No calories are counted here, and nothing needs to be "burned off".',
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Finish energy reset',
              button: true,
              excludeSemantics: true,
              child: FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
