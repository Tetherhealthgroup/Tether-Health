import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/profile_avatar.dart';
import 'resource_screen_widgets.dart';

class ProgressDashboardScreen extends StatelessWidget {
  const ProgressDashboardScreen({
    required this.isSpanish,
    required this.onBack,
    required this.onOpenSettings,
    this.profileIdentity = const ProfileIdentity(),
    required this.onOpenHome,
    required this.onOpenPlan,
    required this.onOpenLearn,
    required this.onOpenSupport,
    super.key,
  });

  final bool isSpanish;
  final VoidCallback onBack;
  final VoidCallback onOpenSettings;
  final ProfileIdentity profileIdentity;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenLearn;
  final VoidCallback onOpenSupport;

  String t(String english, String spanish) =>
      localized(isSpanish, english, spanish);

  void _showInfo(BuildContext context, String title, String body) {
    showResourceInformation(
      context,
      title: title,
      body: body,
      closeLabel: t('Done', 'Listo'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('functional-progress-dashboard-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ResourcePageHeader(
              title: t('Progress', 'Progreso'),
              subtitle: t(
                'Patterns, practice and progress—without punishment.',
                'Patrones, práctica y progreso, sin castigos.',
              ),
              onBack: onBack,
              backSemanticLabel: t('Go back', 'Volver'),
              actions: [
                IconButton(
                  key: const ValueKey('progress-open-settings'),
                  tooltip: t(
                    'Settings and privacy',
                    'Configuración y privacidad',
                  ),
                  onPressed: onOpenSettings,
                  icon: ProfileAvatar(identity: profileIdentity),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('progress-dashboard-scroll'),
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _EmptyProgressCard(),
                    const SizedBox(height: 12),
                    ResourceCard(
                      key: const ValueKey('progress-health-timeline'),
                      onTap: () => _showInfo(
                        context,
                        t(
                          'Health benefits build over time',
                          'Los beneficios para la salud crecen con el tiempo',
                        ),
                        t(
                          'This is a clinically reviewed general timeline, not a personal test result or prediction.',
                          'Esta es una cronología general revisada clínicamente, no un resultado o predicción personal.',
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.health_and_safety_outlined,
                            color: AppColors.coral,
                            size: 34,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t(
                                    'Health benefits build over time',
                                    'Los beneficios crecen con el tiempo',
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.deepTeal,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  t(
                                    'View a clinically reviewed general timeline—not a personal test result.',
                                    'Consulta una cronología general, no un resultado personal.',
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.mutedTeal,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ResourceBottomNavigation(
        selectedIndex: 2,
        isSpanish: isSpanish,
        onHome: onOpenHome,
        onPlan: onOpenPlan,
        onProgress: () {},
        onLearn: onOpenLearn,
        onSupport: onOpenSupport,
      ),
    );
  }
}

/// Draft wording for the empty Progress screen, awaiting clinical and legal
/// review. No reviewed Spanish exists yet, so both languages show the English
/// text until a reviewed translation is added.
const emptyProgressTitle = 'Nothing to show yet';
const emptyProgressBody =
    'Progress here comes only from what you record. No numbers or charts are '
    'shown until there is something of yours to report.';

/// Progress shows only the member's own records. The app does not keep a
/// history of check-ins, slips or coping practice for this screen yet, so it
/// says so instead of showing sample figures.
class _EmptyProgressCard extends StatelessWidget {
  const _EmptyProgressCard();

  @override
  Widget build(BuildContext context) {
    return const ResourceCard(
      key: ValueKey('progress-empty-state'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_rounded, color: AppColors.deepTeal),
          SizedBox(height: 8),
          Text(
            emptyProgressTitle,
            style: TextStyle(
              color: AppColors.deepTeal,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            emptyProgressBody,
            style: TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
