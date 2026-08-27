import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'choose_quit_path_screen.dart';
import 'my_reasons_screen.dart';
import 'support_preparation_screen.dart';

class HomePreparationScreen extends StatelessWidget {
  const HomePreparationScreen({
    required this.isSpanish,
    required this.quitPath,
    required this.quitDate,
    required this.selectedReasons,
    required this.customReason,
    required this.topReason,
    required this.supportPeople,
    required this.completedTasks,
    required this.treatmentSupport,
    required this.careTeamReminder,
    required this.hasUnreadNotifications,
    required this.onNotificationsViewed,
    required this.onTaskCompleted,
    required this.onOpenRescue,
    required this.onOpenPlan,
    required this.onOpenProgress,
    required this.onOpenLearn,
    required this.onOpenSupport,
    required this.onOpenProfile,
    required this.onOpenReasons,
    required this.onOpenPreparation,
    required this.onOpenDailyCheckIn,
    super.key,
  });

  final bool isSpanish;
  final QuitPlanPath quitPath;
  final DateTime? quitDate;
  final Set<QuitReason> selectedReasons;
  final String? customReason;
  final QuitReason? topReason;
  final List<SupportPersonPlan> supportPeople;
  final Set<PreparationTask> completedTasks;
  final bool treatmentSupport;
  final bool careTeamReminder;
  final bool hasUnreadNotifications;
  final VoidCallback onNotificationsViewed;
  final ValueChanged<PreparationTask> onTaskCompleted;
  final VoidCallback onOpenRescue;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenLearn;
  final VoidCallback onOpenSupport;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenReasons;
  final VoidCallback onOpenPreparation;
  final VoidCallback onOpenDailyCheckIn;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return isSpanish ? 'Buenos días, Alex.' : 'Good morning, Alex.';
    }
    if (hour < 17) {
      return isSpanish ? 'Buenas tardes, Alex.' : 'Good afternoon, Alex.';
    }
    return isSpanish ? 'Buenas noches, Alex.' : 'Good evening, Alex.';
  }

  DateTime get _effectiveQuitDate => DateUtils.dateOnly(
        quitDate ??
            switch (quitPath) {
              QuitPlanPath.setQuitDate => _today.add(const Duration(days: 7)),
              QuitPlanPath.quitToday => _today,
              QuitPlanPath.reduceGradually =>
                _today.add(const Duration(days: 14)),
            },
      );

  int get _daysToQuit =>
      math.max(0, _effectiveQuitDate.difference(_today).inDays);

  PreparationTask? get _nextTask {
    for (final task in PreparationTask.values) {
      if (!completedTasks.contains(task)) return task;
    }
    return null;
  }

  List<SupportPersonPlan> get _activeSupporters =>
      supportPeople.where((person) => person.enabled).toList();

  QuitReason? get _effectiveTopReason {
    if (topReason != null && selectedReasons.contains(topReason)) {
      return topReason;
    }
    for (final reason in QuitReason.values) {
      if (selectedReasons.contains(reason)) return reason;
    }
    return null;
  }

  String _monthName(int month, {bool short = false}) {
    const english = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const spanish = <String>[
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final value = (isSpanish ? spanish : english)[month - 1];
    if (!short || value.length <= 3) return value;
    return value.substring(0, 3);
  }

  String _weekdayName(int weekday) {
    const english = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const spanish = <String>[
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return (isSpanish ? spanish : english)[weekday - 1];
  }

  String _longDate(DateTime date) {
    if (isSpanish) {
      return '${_weekdayName(date.weekday)}, ${date.day} de '
          '${_monthName(date.month)}';
    }
    return '${_weekdayName(date.weekday)}, ${_monthName(date.month)} '
        '${date.day}';
  }

  String get _countdownLabel {
    if (_daysToQuit == 0) return isSpanish ? 'Hoy' : 'Today';
    if (_daysToQuit == 1) return isSpanish ? '1 día' : '1 day';
    return isSpanish ? '$_daysToQuit días' : '$_daysToQuit days';
  }

  String get _heroLabel => switch (quitPath) {
        QuitPlanPath.reduceGradually =>
          isSpanish ? 'TU FECHA OBJETIVO' : 'YOUR TARGET DAY',
        _ => isSpanish ? 'TU DÍA PARA DEJARLO' : 'YOUR QUIT DAY',
      };

  String _taskLabel(PreparationTask task) {
    return switch (task) {
      PreparationTask.removeSupplies => isSpanish
          ? 'Retira cigarrillos, encendedores y ceniceros'
          : 'Remove cigarettes, lighters and ashtrays',
      PreparationTask.smokeFreeSpaces => isSpanish
          ? 'Haz que tu casa y auto estén libres de humo'
          : 'Make your home and car smoke-free',
      PreparationTask.stockAlternatives => isSpanish
          ? 'Ten chicle, agua o refrigerios saludables'
          : 'Stock gum, water or healthy snacks',
    };
  }

  String _reasonLabel(QuitReason reason) {
    return switch (reason) {
      QuitReason.family =>
        isSpanish ? 'Proteger a mi familia' : 'Protect my family',
      QuitReason.breatheEasier =>
        isSpanish ? 'Respirar mejor' : 'Breathe easier',
      QuitReason.improveHealth =>
        isSpanish ? 'Mejorar mi salud' : 'Improve my health',
      QuitReason.saveMoney => isSpanish ? 'Ahorrar dinero' : 'Save money',
      QuitReason.control =>
        isSpanish ? 'Sentirme en control' : 'Feel more in control',
      QuitReason.future =>
        isSpanish ? 'Estar presente para mi futuro' : 'Be there for my future',
      QuitReason.custom => customReason?.trim().isNotEmpty == true
          ? customReason!.trim()
          : (isSpanish ? 'Mi propia razón' : 'My own reason'),
    };
  }

  String get _topReasonLabel {
    final reason = _effectiveTopReason;
    if (reason == null) {
      return isSpanish ? 'Mi razón para dejarlo' : 'My reason to quit';
    }
    return _reasonLabel(reason);
  }

  DateTime _clampedReminderDate(int daysBefore) {
    final date = _effectiveQuitDate.subtract(Duration(days: daysBefore));
    return date.isBefore(_today) ? _today : date;
  }

  List<_UpcomingPlanItem> get _upcomingItems {
    final items = <_UpcomingPlanItem>[];
    if (treatmentSupport && careTeamReminder) {
      items.add(
        _UpcomingPlanItem(
          date: _clampedReminderDate(4),
          label: isSpanish ? 'RECORDATORIO DEL EQUIPO' : 'CARE-TEAM REMINDER',
          title: isSpanish
              ? 'Hablar sobre opciones de tratamiento'
              : 'Discuss treatment options',
          accent: AppColors.mint,
          onTap: onOpenPreparation,
        ),
      );
    }
    final supporter = _activeSupporters.firstOrNull;
    if (supporter != null) {
      items.add(
        _UpcomingPlanItem(
          date: _clampedReminderDate(1),
          label: isSpanish ? 'CONTACTO DE APOYO' : 'SUPPORT CHECK-IN',
          title: isSpanish
              ? 'Revisar el mensaje de ${supporter.name} antes de enviarlo'
              : 'Review ${supporter.name}’s message before sending',
          accent: AppColors.coralLight,
          onTap: onOpenSupport,
        ),
      );
    }
    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  Future<void> _openNotifications(BuildContext context) async {
    onNotificationsViewed();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (sheetContext) => _PreparationNotificationsSheet(
        isSpanish: isSpanish,
        upcomingItems: _upcomingItems,
        onStartCheckIn: () {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onOpenDailyCheckIn();
          });
        },
        onDone: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextTask = _nextTask;
    final supporterCount = _activeSupporters.length;

    return Scaffold(
      key: const ValueKey('functional-home-preparation-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 420;
            final compact = constraints.maxHeight < 760;
            final horizontalPadding = narrow ? 18.0 : 22.0;

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? 5 : 8,
                    horizontalPadding,
                    compact ? 5 : 8,
                  ),
                  child: _PreparationHomeHeader(
                    isSpanish: isSpanish,
                    hasUnreadNotifications: hasUnreadNotifications,
                    onNotifications: () => _openNotifications(context),
                    onProfile: onOpenProfile,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('preparation-home-scroll'),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 8 : 12,
                      horizontalPadding,
                      20,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _longDate(_today).toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.mutedTeal,
                                fontSize: 10.5,
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _greeting,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    fontSize: narrow ? 29 : 33,
                                    height: 1.05,
                                  ),
                            ),
                            SizedBox(height: compact ? 14 : 18),
                            _QuitCountdownCard(
                              isSpanish: isSpanish,
                              heroLabel: _heroLabel,
                              countdownLabel: _countdownLabel,
                              quitDateLabel: _longDate(_effectiveQuitDate),
                              daysToQuit: _daysToQuit,
                              nextTask: nextTask,
                              nextTaskLabel: nextTask == null
                                  ? (isSpanish
                                      ? 'Tu preparación está completa'
                                      : 'Your preparation is complete')
                                  : _taskLabel(nextTask),
                              onPrimaryAction: nextTask == null
                                  ? onOpenPlan
                                  : () => onTaskCompleted(nextTask),
                              narrow: narrow,
                              compact: compact,
                            ),
                            SizedBox(height: compact ? 13 : 17),
                            _CravingRescueCard(
                              isSpanish: isSpanish,
                              narrow: narrow,
                              onOpen: onOpenRescue,
                            ),
                            SizedBox(height: compact ? 18 : 23),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isSpanish
                                        ? 'Tu preparación'
                                        : 'Your preparation',
                                    style: const TextStyle(
                                      color: AppColors.deepTeal,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  key: const ValueKey(
                                    'preparation-view-progress',
                                  ),
                                  onPressed: onOpenProgress,
                                  child: Text(
                                    isSpanish
                                        ? 'Ver progreso'
                                        : 'View progress',
                                    style: const TextStyle(
                                      color: AppColors.mutedTeal,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _PreparationSummaryRow(
                              isSpanish: isSpanish,
                              completedTaskCount: completedTasks.length,
                              supporterCount: supporterCount,
                              supporterName:
                                  _activeSupporters.firstOrNull?.name,
                              onPlan: onOpenPlan,
                              onSpace: onOpenPreparation,
                              onSupport: onOpenSupport,
                            ),
                            SizedBox(height: compact ? 16 : 20),
                            _TopReasonCard(
                              isSpanish: isSpanish,
                              reason: _topReasonLabel,
                              onTap: onOpenReasons,
                            ),
                            SizedBox(height: compact ? 18 : 22),
                            Text(
                              isSpanish ? 'Próximamente' : 'Coming up',
                              style: const TextStyle(
                                color: AppColors.deepTeal,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 9),
                            _UpcomingPlanCard(
                              isSpanish: isSpanish,
                              items: _upcomingItems,
                              monthLabel: (date) =>
                                  _monthName(date.month, short: true),
                            ),
                            const SizedBox(height: 14),
                            _OfflineNote(isSpanish: isSpanish),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _PreparationBottomNavigation(
                  isSpanish: isSpanish,
                  compact: compact,
                  onHome: () {},
                  onPlan: onOpenPlan,
                  onProgress: onOpenProgress,
                  onLearn: onOpenLearn,
                  onSupport: onOpenSupport,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _PreparationHomeHeader extends StatelessWidget {
  const _PreparationHomeHeader({
    required this.isSpanish,
    required this.hasUnreadNotifications,
    required this.onNotifications,
    required this.onProfile,
  });

  final bool isSpanish;
  final bool hasUnreadNotifications;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 23,
            backgroundColor: AppColors.deepTeal,
            child: Icon(Icons.eco_rounded, color: AppColors.lime, size: 29),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'BreatheFree',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.deepTeal,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton.outlined(
                key: const ValueKey('preparation-notifications'),
                tooltip: isSpanish ? 'Notificaciones' : 'Notifications',
                onPressed: onNotifications,
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.deepTeal,
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              if (hasUnreadNotifications)
                const Positioned(
                  right: 3,
                  top: 2,
                  child: CircleAvatar(
                    key: ValueKey('preparation-notification-dot'),
                    radius: 5,
                    backgroundColor: AppColors.coral,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          InkWell(
            key: const ValueKey('preparation-profile'),
            onTap: onProfile,
            borderRadius: BorderRadius.circular(24),
            child: const CircleAvatar(
              radius: 23,
              backgroundColor: AppColors.mint,
              foregroundColor: AppColors.deepTeal,
              child: Text(
                'A',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuitCountdownCard extends StatelessWidget {
  const _QuitCountdownCard({
    required this.isSpanish,
    required this.heroLabel,
    required this.countdownLabel,
    required this.quitDateLabel,
    required this.daysToQuit,
    required this.nextTask,
    required this.nextTaskLabel,
    required this.onPrimaryAction,
    required this.narrow,
    required this.compact,
  });

  final bool isSpanish;
  final String heroLabel;
  final String countdownLabel;
  final String quitDateLabel;
  final int daysToQuit;
  final PreparationTask? nextTask;
  final String nextTaskLabel;
  final VoidCallback onPrimaryAction;
  final bool narrow;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('preparation-countdown-card'),
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.deepTeal,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A123C37),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  heroLabel,
                  style: const TextStyle(
                    color: AppColors.mintStrong,
                    fontSize: 10.5,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF234E48),
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.lime,
                  size: 26,
                ),
              ),
            ],
          ),
          Text(
            countdownLabel,
            key: const ValueKey('preparation-countdown'),
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 45 : 52,
              height: 1,
              letterSpacing: -2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$quitDateLabel · ${isSpanish ? 'Hora del Pacífico' : 'Pacific Time'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.mintStrong,
              fontSize: 12,
              height: 1.25,
            ),
          ),
          SizedBox(height: compact ? 12 : 15),
          const _CountdownTimeline(),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                isSpanish ? 'DÍA 1' : 'DAY 1',
                style: const TextStyle(
                  color: AppColors.mintStrong,
                  fontSize: 9,
                ),
              ),
              const Spacer(),
              Text(
                daysToQuit == 0
                    ? (isSpanish ? 'HOY' : 'TODAY')
                    : (isSpanish ? 'DÍA DE DEJARLO' : 'QUIT DAY'),
                style: const TextStyle(
                  color: AppColors.mintStrong,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 15),
          Container(
            key: const ValueKey('preparation-next-step-card'),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 23,
                      backgroundColor: AppColors.mint,
                      child: Icon(
                        Icons.check_rounded,
                        color: AppColors.deepTeal,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextTask == null
                                ? (isSpanish
                                    ? 'PREPARACIÓN LISTA'
                                    : 'PREPARATION READY')
                                : (isSpanish
                                    ? 'PRÓXIMO PASO DE HOY'
                                    : 'TODAY’S NEXT STEP'),
                            style: const TextStyle(
                              color: AppColors.mutedTeal,
                              fontSize: 9.5,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            nextTaskLabel,
                            style: const TextStyle(
                              color: AppColors.deepTeal,
                              fontSize: 14,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            nextTask == null
                                ? (isSpanish
                                    ? 'Revisa tu plan cuando quieras'
                                    : 'Review your plan whenever you want')
                                : (isSpanish
                                    ? 'Aproximadamente 3 minutos'
                                    : 'About 3 minutes'),
                            style: const TextStyle(
                              color: AppColors.mutedTeal,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!narrow) ...[
                      const SizedBox(width: 8),
                      FilledButton(
                        key: const ValueKey('preparation-primary-action'),
                        onPressed: onPrimaryAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.deepTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text(
                          nextTask == null
                              ? (isSpanish ? 'Ver plan' : 'View plan')
                              : (isSpanish ? 'Completar' : 'Mark complete'),
                        ),
                      ),
                    ],
                  ],
                ),
                if (narrow) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('preparation-primary-action'),
                      onPressed: onPrimaryAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.deepTeal,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        nextTask == null
                            ? (isSpanish ? 'Ver plan' : 'View plan')
                            : (isSpanish
                                ? 'Marcar como hecha'
                                : 'Mark complete'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    nextTask == null
                        ? (isSpanish
                            ? 'Has completado tus tres tareas de preparación.'
                            : 'You completed all three preparation tasks.')
                        : (isSpanish
                            ? 'Una pequeña acción es suficiente por hoy.'
                            : 'One small action is enough for today.'),
                    style: const TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownTimeline extends StatelessWidget {
  const _CountdownTimeline();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            color: AppColors.mutedTeal,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final edge = index == 0 || index == 5;
              return Container(
                width: edge ? 13 : 9,
                height: edge ? 13 : 9,
                decoration: BoxDecoration(
                  color: index == 0
                      ? AppColors.lime
                      : index == 5
                          ? AppColors.coral
                          : AppColors.mutedTeal,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CravingRescueCard extends StatelessWidget {
  const _CravingRescueCard({
    required this.isSpanish,
    required this.narrow,
    required this.onOpen,
  });

  final bool isSpanish;
  final bool narrow;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('preparation-rescue-card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.coralLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB6A6)),
      ),
      child: narrow
          ? Column(
              children: [
                _RescueMessage(isSpanish: isSpanish),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('preparation-open-rescue'),
                    onPressed: onOpen,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isSpanish ? 'Abrir Rescate' : 'Open Rescue',
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _RescueMessage(isSpanish: isSpanish)),
                const SizedBox(width: 12),
                FilledButton(
                  key: const ValueKey('preparation-open-rescue'),
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isSpanish ? 'Abrir Rescate' : 'Open Rescue'),
                ),
              ],
            ),
    );
  }
}

class _RescueMessage extends StatelessWidget {
  const _RescueMessage({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.coral,
          child: Icon(Icons.waves_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSpanish ? '¿Tienes un antojo?' : 'Craving now?',
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isSpanish
                    ? 'Recibe apoyo durante los próximos minutos.'
                    : 'Get support for the next few minutes.',
                style: const TextStyle(
                  color: AppColors.tealSecondary,
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreparationSummaryRow extends StatelessWidget {
  const _PreparationSummaryRow({
    required this.isSpanish,
    required this.completedTaskCount,
    required this.supporterCount,
    required this.supporterName,
    required this.onPlan,
    required this.onSpace,
    required this.onSupport,
  });

  final bool isSpanish;
  final int completedTaskCount;
  final int supporterCount;
  final String? supporterName;
  final VoidCallback onPlan;
  final VoidCallback onSpace;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final tasksLeft = PreparationTask.values.length - completedTaskCount;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _PreparationStatCard(
              cardKey: const ValueKey('preparation-plan-card'),
              icon: Icons.check_rounded,
              iconBackground: AppColors.mint,
              headline: isSpanish ? 'Plan listo' : 'Plan ready',
              detail: isSpanish ? 'Activado hoy' : 'Activated today',
              onTap: onPlan,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PreparationStatCard(
              cardKey: const ValueKey('preparation-space-card'),
              leadingText:
                  '$completedTaskCount/${PreparationTask.values.length}',
              leadingColor: AppColors.coral,
              headline: isSpanish ? 'Espacio listo' : 'Space ready',
              detail: tasksLeft == 0
                  ? (isSpanish ? 'Todo completo' : 'All complete')
                  : tasksLeft == 1
                      ? (isSpanish ? 'Falta una tarea' : 'One task left')
                      : (isSpanish
                          ? 'Faltan $tasksLeft tareas'
                          : '$tasksLeft tasks left'),
              onTap: onSpace,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PreparationStatCard(
              cardKey: const ValueKey('preparation-support-card'),
              icon: Icons.person_outline_rounded,
              iconBackground: AppColors.mint,
              headline: isSpanish
                  ? '$supporterCount ${supporterCount == 1 ? 'persona' : 'personas'}'
                  : '$supporterCount ${supporterCount == 1 ? 'supporter' : 'supporters'}',
              detail: supporterName == null
                  ? (isSpanish ? 'Agrega apoyo' : 'Add support')
                  : (isSpanish
                      ? '$supporterName agregado'
                      : '$supporterName added'),
              onTap: onSupport,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreparationStatCard extends StatelessWidget {
  const _PreparationStatCard({
    required this.cardKey,
    required this.headline,
    required this.detail,
    required this.onTap,
    this.icon,
    this.iconBackground,
    this.leadingText,
    this.leadingColor,
  });

  final Key cardKey;
  final String headline;
  final String detail;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconBackground;
  final String? leadingText;
  final Color? leadingColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: cardKey,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leadingText != null)
                Text(
                  leadingText!,
                  style: TextStyle(
                    color: leadingColor,
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                CircleAvatar(
                  radius: 16,
                  backgroundColor: iconBackground,
                  child: Icon(icon, color: AppColors.deepTeal, size: 20),
                ),
              const SizedBox(height: 9),
              Text(
                headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 12.5,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 9.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopReasonCard extends StatelessWidget {
  const _TopReasonCard({
    required this.isSpanish,
    required this.reason,
    required this.onTap,
  });

  final bool isSpanish;
  final String reason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(19),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('preparation-top-reason'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.coralLight,
                child: Icon(
                  Icons.favorite_rounded,
                  color: AppColors.coral,
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish ? 'TU RAZÓN PRINCIPAL' : 'YOUR TOP REASON',
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 9.5,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '“$reason.”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontFamily: 'Georgia',
                        fontStyle: FontStyle.italic,
                        fontSize: 19,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.deepTeal,
                size: 29,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingPlanItem {
  const _UpcomingPlanItem({
    required this.date,
    required this.label,
    required this.title,
    required this.accent,
    required this.onTap,
  });

  final DateTime date;
  final String label;
  final String title;
  final Color accent;
  final VoidCallback onTap;
}

class _UpcomingPlanCard extends StatelessWidget {
  const _UpcomingPlanCard({
    required this.isSpanish,
    required this.items,
    required this.monthLabel,
  });

  final bool isSpanish;
  final List<_UpcomingPlanItem> items;
  final String Function(DateTime) monthLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        key: const ValueKey('preparation-no-reminders'),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          isSpanish
              ? 'No hay recordatorios programados. Puedes agregarlos desde tu plan.'
              : 'No reminders are scheduled. You can add them from your plan.',
          style: const TextStyle(
            color: AppColors.tealSecondary,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      );
    }

    return Container(
      key: const ValueKey('preparation-upcoming-card'),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(19),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _UpcomingRow(
              item: items[index],
              month: monthLabel(items[index].date),
            ),
            if (index < items.length - 1)
              const Divider(height: 1, indent: 14, endIndent: 14),
          ],
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.item, required this.month});

  final _UpcomingPlanItem item;
  final String month;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: item.accent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                children: [
                  Text(
                    month.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${item.date.day}',
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedTeal,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 15,
          backgroundColor: AppColors.mint,
          child: Icon(
            Icons.wifi_off_rounded,
            color: AppColors.deepTeal,
            size: 17,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            isSpanish
                ? 'Tu plan y las herramientas de Rescate siguen disponibles sin conexión.'
                : 'Your plan and Rescue tools remain available offline.',
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreparationBottomNavigation extends StatelessWidget {
  const _PreparationBottomNavigation({
    required this.isSpanish,
    required this.compact,
    required this.onHome,
    required this.onPlan,
    required this.onProgress,
    required this.onLearn,
    required this.onSupport,
  });

  final bool isSpanish;
  final bool compact;
  final VoidCallback onHome;
  final VoidCallback onPlan;
  final VoidCallback onProgress;
  final VoidCallback onLearn;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('preparation-bottom-navigation'),
      height: compact ? 68 : 76,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: Color(0xFFDCE5DF))),
      ),
      child: Row(
        children: [
          _PreparationNavItem(
            itemKey: const ValueKey('preparation-nav-home'),
            label: isSpanish ? 'Inicio' : 'Home',
            icon: Icons.home_outlined,
            selected: true,
            onTap: onHome,
          ),
          _PreparationNavItem(
            itemKey: const ValueKey('preparation-nav-plan'),
            label: isSpanish ? 'Plan' : 'Plan',
            icon: Icons.article_outlined,
            onTap: onPlan,
          ),
          _PreparationNavItem(
            itemKey: const ValueKey('preparation-nav-progress'),
            label: isSpanish ? 'Progreso' : 'Progress',
            icon: Icons.bar_chart_rounded,
            onTap: onProgress,
          ),
          _PreparationNavItem(
            itemKey: const ValueKey('preparation-nav-learn'),
            label: isSpanish ? 'Aprender' : 'Learn',
            icon: Icons.menu_book_outlined,
            onTap: onLearn,
          ),
          _PreparationNavItem(
            itemKey: const ValueKey('preparation-nav-support'),
            label: isSpanish ? 'Apoyo' : 'Support',
            icon: Icons.support_agent_rounded,
            onTap: onSupport,
          ),
        ],
      ),
    );
  }
}

class _PreparationNavItem extends StatelessWidget {
  const _PreparationNavItem({
    required this.itemKey,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final Key itemKey;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        key: itemKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.mint : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.deepTeal : AppColors.mutedTeal,
                size: 25,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.deepTeal : AppColors.mutedTeal,
                  fontSize: 9.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreparationNotificationsSheet extends StatelessWidget {
  const _PreparationNotificationsSheet({
    required this.isSpanish,
    required this.upcomingItems,
    required this.onStartCheckIn,
    required this.onDone,
  });

  final bool isSpanish;
  final List<_UpcomingPlanItem> upcomingItems;
  final VoidCallback onStartCheckIn;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSpanish ? 'Recordatorios próximos' : 'Upcoming reminders',
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSpanish
                  ? 'Los recordatorios están activados. Tú decides antes de enviar cualquier mensaje de apoyo.'
                  : 'Reminders are on. You still approve every support message before it is sent.',
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(17),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const ValueKey('preparation-start-check-in'),
                onTap: onStartCheckIn,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.deepTeal,
                        foregroundColor: AppColors.lime,
                        child: Icon(Icons.checklist_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSpanish
                                  ? 'Tu registro diario está listo'
                                  : 'Your daily check-in is ready',
                              style: const TextStyle(
                                color: AppColors.deepTeal,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSpanish
                                  ? 'Aproximadamente 60 segundos'
                                  : 'About 60 seconds',
                              style: const TextStyle(
                                color: AppColors.tealSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.deepTeal,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (upcomingItems.isEmpty)
              Text(
                isSpanish
                    ? 'No hay recordatorios programados.'
                    : 'No reminders are scheduled.',
              )
            else
              for (final item in upcomingItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      backgroundColor: item.accent,
                      foregroundColor: AppColors.deepTeal,
                      child: Text(
                        '${item.date.day}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(item.label),
                  ),
                ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('preparation-notifications-done'),
                onPressed: onDone,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                ),
                child: Text(isSpanish ? 'Listo' : 'Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
