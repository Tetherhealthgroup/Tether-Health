import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_colors.dart';
import '../heartwise_safety.dart';

/// Permanent emergency card for the Heartwise program.
///
/// Always visible on the Heartwise home screen. The call action opens a
/// `tel:` link; the launcher is injectable so widget tests stay hermetic
/// (no url_launcher plugin in tests).
class EmergencyCard extends StatelessWidget {
  const EmergencyCard({this.launchEmergency, super.key});

  /// Opens the emergency `tel:` link. Defaults to [launchUrl]; tests inject
  /// a fake.
  final Future<void> Function(Uri uri)? launchEmergency;

  static Future<void> _openTelLink(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  Future<void> _callEmergency(BuildContext context) async {
    final launch = launchEmergency ?? _openTelLink;
    try {
      await launch(HeartwiseSafety.emergencyUri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the phone app. Dial emergency services directly.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Emergency. ${HeartwiseSafety.emergencyBody}',
      excludeSemantics: true,
      child: Card(
        color: AppColors.coralLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.coral, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.coral,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    HeartwiseSafety.emergencyTitle,
                    style: TextStyle(
                      color: AppColors.deepTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                HeartwiseSafety.emergencyBody,
                style: TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: HeartwiseSafety.emergencyActionLabel,
                button: true,
                excludeSemantics: true,
                child: FilledButton.icon(
                  onPressed: () => _callEmergency(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: const Text(HeartwiseSafety.emergencyActionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
