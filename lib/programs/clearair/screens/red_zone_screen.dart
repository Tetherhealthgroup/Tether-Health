import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_colors.dart';
import '../clearair_safety.dart';

/// Red-zone screen. Always reachable from the ClearAir home screen via the
/// red route: "Follow your red-zone plan and seek urgent care now."
class RedZoneScreen extends StatelessWidget {
  const RedZoneScreen({
    this.launchUrgentCare,
    this.urgentCareUri,
    this.onClose,
    super.key,
  });

  /// Injected for tests; defaults to opening a `tel:` link.
  final Future<void> Function(Uri uri)? launchUrgentCare;

  /// TODO(srikanth): configure the urgent-care / clinic number before
  /// release.
  final Uri? urgentCareUri;
  final VoidCallback? onClose;

  static Future<void> _openTelLink(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  Future<void> _contactUrgentCare(BuildContext context) async {
    final launch = launchUrgentCare ?? _openTelLink;
    try {
      await launch(urgentCareUri ?? ClearAirSafety.defaultUrgentCareUri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the phone app. Contact urgent care directly.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Red-zone plan'),
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
            Semantics(
              label: 'Red zone. ${ClearAirSafety.redZoneBody}',
              excludeSemantics: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE7E3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF1998A),
                    width: 1,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFB3261E),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          ClearAirSafety.redZoneHeading,
                          style: TextStyle(
                            color: Color(0xFFB3261E),
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      ClearAirSafety.redZoneBody,
                      style: TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: ClearAirSafety.urgentCareActionLabel,
              button: true,
              excludeSemantics: true,
              child: FilledButton.icon(
                onPressed: () => _contactUrgentCare(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB3261E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.phone_rounded, size: 18),
                label: const Text(ClearAirSafety.urgentCareActionLabel),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You can open this screen any time from the ClearAir home screen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedTeal, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
