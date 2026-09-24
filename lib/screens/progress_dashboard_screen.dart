import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/profile_avatar.dart';
import 'resource_screen_widgets.dart';

enum ProgressRange { sevenDays, thirtyDays, allTime }

class ProgressDashboardScreen extends StatelessWidget {
  const ProgressDashboardScreen({
    required this.isSpanish,
    this.range = ProgressRange.sevenDays,
    this.onRangeChanged,
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
  final ProgressRange range;
  final ValueChanged<ProgressRange>? onRangeChanged;
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
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1, 2);
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
                    _ProgressRangeSelector(
                      initialRange: range,
                      isSpanish: isSpanish,
                      onRangeChanged: onRangeChanged,
                    ),
                    const SizedBox(height: 14),
                    ResourceCard(
                      key: const ValueKey('progress-plan-card'),
                      color: AppColors.deepTeal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('CURRENT QUIT PLAN', 'PLAN ACTUAL PARA DEJARLO'),
                            style: const TextStyle(
                              color: AppColors.mintStrong,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t('7 days active', '7 días activo'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t(
                              '1 day 12 hours since your last reported cigarette',
                              '1 día y 12 horas desde tu último cigarrillo registrado',
                            ),
                            style: const TextStyle(
                              color: AppColors.mintStrong,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Material(
                            color: const Color(0xFF234E48),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              key: const ValueKey('progress-view-slip'),
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showInfo(
                                context,
                                t(
                                  'One slip in this history',
                                  'Un desliz en este historial',
                                ),
                                t(
                                  'Your earlier progress, lessons and coping practice remain. A slip does not erase progress.',
                                  'Tu progreso, lecciones y práctica anteriores se mantienen. Un desliz no borra el progreso.',
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(13),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: AppColors.coral,
                                      foregroundColor: Colors.white,
                                      child: Icon(Icons.remove_rounded),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        t(
                                          'One slip is included in this history\nYour earlier progress remains.',
                                          'Se incluye un desliz en este historial\nTu progreso anterior se mantiene.',
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          height: 1.35,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.lime,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.smoke_free_rounded,
                            label: t('ESTIMATED AVOIDED', 'EVITADOS ESTIMADOS'),
                            value: '61',
                            detail: t(
                              'Baseline minus recorded smoking',
                              'Base menos consumo registrado',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.savings_outlined,
                            label: t('ESTIMATED SAVED', 'AHORRO ESTIMADO'),
                            value: r'$85',
                            detail: t(
                              r'Using $14.00 per pack',
                              r'Usando $14.00 por paquete',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.schedule_rounded,
                            label: t('TIME RECLAIMED', 'TIEMPO RECUPERADO'),
                            value: '5h',
                            detail: t(
                              'Using 5 minutes per cigarette',
                              'Usando 5 minutos por cigarrillo',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.self_improvement_rounded,
                            label: t('COPING PRACTICE', 'PRÁCTICA DE APOYO'),
                            value: '4',
                            detail: t(
                              'Eased after a coping tool',
                              'Mejoraron tras una herramienta',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SectionTitle(
                      t(
                        'Cigarettes reported per day',
                        'Cigarrillos registrados por día',
                      ),
                      trailing: Text(
                        t('Baseline: 10/day', 'Base: 10/día'),
                        style: const TextStyle(
                          color: AppColors.mutedTeal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ResourceCard(
                      key: const ValueKey('progress-chart'),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 130 + ((textScale - 1) * 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [10, 8, 6, 5, 7, 3, 0]
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Semantics(
                                          label: t(
                                            'Day ${entry.key + 1}: ${entry.value} reported cigarettes',
                                            'Día ${entry.key + 1}: ${entry.value} cigarrillos registrados',
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${entry.value}',
                                                style: const TextStyle(
                                                  color: AppColors.mutedTeal,
                                                  fontSize: 10,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Container(
                                                height: 8 + entry.value * 8,
                                                decoration: BoxDecoration(
                                                  color: entry.key == 4
                                                      ? AppColors.coral
                                                      : AppColors.deepTeal,
                                                  borderRadius:
                                                      const BorderRadius
                                                          .vertical(
                                                    top: Radius.circular(6),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t(
                              'Bars show what you reported. Missing check-ins are never counted as zero.',
                              'Las barras muestran lo que registraste. Los registros faltantes nunca cuentan como cero.',
                            ),
                            style: const TextStyle(
                              color: AppColors.mutedTeal,
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResourceCard(
                      key: const ValueKey('progress-coping-card'),
                      color: AppColors.mint,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.deepTeal,
                            foregroundColor: AppColors.lime,
                            child: Icon(Icons.air_rounded),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t(
                                    'MOST HELPFUL COPING TOOL',
                                    'HERRAMIENTA MÁS ÚTIL',
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.tealSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  t('Slow breathing', 'Respiración lenta'),
                                  style: const TextStyle(
                                    color: AppColors.deepTeal,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  t(
                                    'Helpful in 3 of 4 completed rechecks',
                                    'Útil en 3 de 4 reevaluaciones',
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.mutedTeal,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            '−2.3',
                            style: TextStyle(
                              color: AppColors.deepTeal,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });
  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) => ResourceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.deepTeal),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 29,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              detail,
              maxLines: 2,
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 10,
                height: 1.25,
              ),
            ),
          ],
        ),
      );
}

class _ProgressRangeSelector extends StatefulWidget {
  const _ProgressRangeSelector({
    required this.initialRange,
    required this.isSpanish,
    this.onRangeChanged,
  });

  final ProgressRange initialRange;
  final bool isSpanish;
  final ValueChanged<ProgressRange>? onRangeChanged;

  @override
  State<_ProgressRangeSelector> createState() => _ProgressRangeSelectorState();
}

class _ProgressRangeSelectorState extends State<_ProgressRangeSelector> {
  late ProgressRange _range;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
  }

  @override
  void didUpdateWidget(covariant _ProgressRangeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRange != oldWidget.initialRange) {
      _range = widget.initialRange;
    }
  }

  String t(String english, String spanish) =>
      localized(widget.isSpanish, english, spanish);

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ProgressRange>(
      key: const ValueKey('progress-range'),
      segments: [
        ButtonSegment(
          value: ProgressRange.sevenDays,
          label: Text(t('Last 7 days', 'Últimos 7 días')),
        ),
        ButtonSegment(
          value: ProgressRange.thirtyDays,
          label: Text(t('30 days', '30 días')),
        ),
        ButtonSegment(
          value: ProgressRange.allTime,
          label: Text(t('All time', 'Todo')),
        ),
      ],
      selected: {_range},
      showSelectedIcon: false,
      onSelectionChanged: (value) {
        final next = value.single;
        setState(() => _range = next);
        widget.onRangeChanged?.call(next);
      },
    );
  }
}
