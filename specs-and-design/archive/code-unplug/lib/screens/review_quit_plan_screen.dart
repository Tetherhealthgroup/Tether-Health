import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'choose_quit_path_screen.dart';
import 'my_reasons_screen.dart';
import 'support_preparation_screen.dart';

class ReviewQuitPlanScreen extends StatelessWidget {
  const ReviewQuitPlanScreen({
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
    required this.onBack,
    required this.onEditQuitDate,
    required this.onEditApproach,
    required this.onEditReasons,
    required this.onEditSupport,
    required this.onEditPreparation,
    required this.onEditTreatment,
    required this.onStartPlan,
    required this.onSaveForLater,
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
  final VoidCallback onBack;
  final VoidCallback onEditQuitDate;
  final VoidCallback onEditApproach;
  final VoidCallback onEditReasons;
  final VoidCallback onEditSupport;
  final VoidCallback onEditPreparation;
  final VoidCallback onEditTreatment;
  final VoidCallback onStartPlan;
  final VoidCallback onSaveForLater;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  DateTime get _effectiveDate => DateUtils.dateOnly(
        quitDate ??
            switch (quitPath) {
              QuitPlanPath.setQuitDate => _today.add(const Duration(days: 7)),
              QuitPlanPath.quitToday => _today,
              QuitPlanPath.reduceGradually =>
                _today.add(const Duration(days: 14)),
            },
      );

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

  String _weekdayName(int weekday, {bool short = false}) {
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
    final value = (isSpanish ? spanish : english)[weekday - 1];
    if (!short || value.length <= 3) return value;
    return value.substring(0, 3);
  }

  String get _longDate {
    final date = _effectiveDate;
    if (isSpanish) {
      return '${_weekdayName(date.weekday)}, ${date.day} de '
          '${_monthName(date.month)}';
    }
    return '${_weekdayName(date.weekday)}, ${_monthName(date.month)} '
        '${date.day}';
  }

  String get _timingLabel {
    final days = _effectiveDate.difference(_today).inDays;
    if (days <= 0) return isSpanish ? 'Comienza hoy' : 'Starting today';
    if (quitPath == QuitPlanPath.reduceGradually) {
      return isSpanish
          ? '$days días para reducir gradualmente'
          : '$days days to reduce gradually';
    }
    return isSpanish ? '$days días para prepararte' : '$days days to prepare';
  }

  String get _approachLabel => switch (quitPath) {
        QuitPlanPath.setQuitDate =>
          isSpanish ? 'Elegir una fecha' : 'Set a quit date',
        QuitPlanPath.quitToday =>
          isSpanish ? 'Dejar de fumar hoy' : 'Quit today',
        QuitPlanPath.reduceGradually =>
          isSpanish ? 'Reducir gradualmente' : 'Reduce gradually',
      };

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

  QuitReason? get _effectiveTopReason {
    if (topReason != null && selectedReasons.contains(topReason)) {
      return topReason;
    }
    for (final reason in QuitReason.values) {
      if (selectedReasons.contains(reason)) return reason;
    }
    return null;
  }

  String get _topReasonLabel {
    final reason = _effectiveTopReason;
    if (reason == null) {
      return isSpanish ? 'Ninguna razón seleccionada' : 'No reason selected';
    }
    return _reasonLabel(reason);
  }

  SupportPersonPlan? get _primarySupporter {
    for (final person in supportPeople) {
      if (person.enabled) return person;
    }
    return null;
  }

  String get _supportLabel {
    final person = _primarySupporter;
    if (person == null) {
      return isSpanish
          ? 'Ninguna persona de apoyo activa'
          : 'No active supporter';
    }
    final normalized = person.checkIn.toLowerCase();
    final timing = normalized.contains('evening before')
        ? (isSpanish ? 'Noche anterior' : 'Evening before')
        : person.channel == SupportChannel.text
            ? (isSpanish ? 'Mensaje de texto' : 'Text message')
            : (isSpanish ? 'Llamada' : 'Phone call');
    return '${person.name} · $timing';
  }

  String get _preparationLabel {
    final count = completedTasks.length;
    return isSpanish
        ? '$count de ${PreparationTask.values.length} tareas completadas'
        : '$count of ${PreparationTask.values.length} tasks complete';
  }

  String get _treatmentLabel {
    if (!treatmentSupport) {
      return isSpanish ? 'No incluido' : 'Not included';
    }
    if (careTeamReminder) {
      return isSpanish
          ? 'Recordatorio para hablar con el equipo activado'
          : 'Care-team discussion reminder on';
    }
    return isSpanish
        ? 'Educación sobre tratamiento guardada'
        : 'Treatment education saved';
  }

  void _saveForLater(BuildContext context) {
    onSaveForLater();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        key: const ValueKey('review-saved-snackbar'),
        behavior: SnackBarBehavior.floating,
        content: Text(
          isSpanish
              ? 'Tu plan está guardado. Puedes volver cuando estés listo.'
              : 'Your plan is saved. Come back whenever you are ready.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('functional-review-quit-plan-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 250) onBack();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 380;
              final compact = constraints.maxHeight < 760;
              final horizontalPadding = narrow ? 18.0 : 22.0;

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 5 : 9,
                      horizontalPadding,
                      0,
                    ),
                    child: _ReviewHeader(
                      isSpanish: isSpanish,
                      onBack: onBack,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 5 : 8,
                      horizontalPadding,
                      compact ? 7 : 10,
                    ),
                    child: _ReviewProgress(isSpanish: isSpanish),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('review-content-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 7 : 12,
                        horizontalPadding,
                        18,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSpanish
                                    ? 'TU PLAN PARA DEJARLO'
                                    : 'YOUR QUIT PLAN',
                                style: const TextStyle(
                                  color: AppColors.mutedTeal,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isSpanish
                                    ? 'Tu plan está listo.'
                                    : 'Your plan is ready.',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: narrow ? 30 : 34,
                                      height: 1.06,
                                    ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                isSpanish
                                    ? 'Dale una última mirada. Puedes editar cualquier parte ahora o más adelante.'
                                    : 'Take one final look. You can edit any part now or later.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppColors.tealSecondary,
                                      fontSize: narrow ? 14 : 15,
                                      height: 1.35,
                                    ),
                              ),
                              SizedBox(height: compact ? 14 : 18),
                              _QuitDateHero(
                                isSpanish: isSpanish,
                                date: _effectiveDate,
                                longDate: _longDate,
                                timingLabel: _timingLabel,
                                monthLabel: _monthName(_effectiveDate.month,
                                    short: true),
                                weekdayLabel: _weekdayName(
                                  _effectiveDate.weekday,
                                  short: true,
                                ),
                                quitPath: quitPath,
                                onEdit: onEditQuitDate,
                                compact: compact,
                              ),
                              SizedBox(height: compact ? 16 : 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isSpanish
                                          ? 'DETALLES DEL PLAN'
                                          : 'PLAN DETAILS',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.mutedTeal,
                                        fontSize: 11,
                                        letterSpacing: 1.8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      isSpanish
                                          ? 'Toca para editar'
                                          : 'Tap any item to edit',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        color: AppColors.mutedTeal,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              _PlanDetailsCard(
                                isSpanish: isSpanish,
                                approachLabel: _approachLabel,
                                topReasonLabel: _topReasonLabel,
                                supportLabel: _supportLabel,
                                preparationLabel: _preparationLabel,
                                treatmentLabel: _treatmentLabel,
                                onEditApproach: onEditApproach,
                                onEditReasons: onEditReasons,
                                onEditSupport: onEditSupport,
                                onEditPreparation: onEditPreparation,
                                onEditTreatment: onEditTreatment,
                              ),
                              SizedBox(height: compact ? 13 : 17),
                              _ActivationNote(isSpanish: isSpanish),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _ReviewBottomActions(
                    isSpanish: isSpanish,
                    compact: compact,
                    horizontalPadding: horizontalPadding,
                    onStartPlan: onStartPlan,
                    onSaveForLater: () => _saveForLater(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.isSpanish, required this.onBack});

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('review-back'),
            tooltip: isSpanish ? 'Atrás' : 'Back',
            onPressed: onBack,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.deepTeal,
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              isSpanish ? 'Revisa tu plan' : 'Review your plan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              isSpanish ? '5 DE 5' : '5 OF 5',
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewProgress extends StatelessWidget {
  const _ReviewProgress({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              isSpanish ? 'PLAN PARA DEJARLO' : 'QUIT PLAN',
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 10,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            const Text(
              '100%',
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(
            key: ValueKey('review-progress'),
            value: 1,
            minHeight: 6,
            backgroundColor: Color(0xFFDCE7E1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
          ),
        ),
      ],
    );
  }
}

class _QuitDateHero extends StatelessWidget {
  const _QuitDateHero({
    required this.isSpanish,
    required this.date,
    required this.longDate,
    required this.timingLabel,
    required this.monthLabel,
    required this.weekdayLabel,
    required this.quitPath,
    required this.onEdit,
    required this.compact,
  });

  final bool isSpanish;
  final DateTime date;
  final String longDate;
  final String timingLabel;
  final String monthLabel;
  final String weekdayLabel;
  final QuitPlanPath quitPath;
  final VoidCallback onEdit;
  final bool compact;

  String get _badgeLabel => switch (quitPath) {
        QuitPlanPath.setQuitDate =>
          isSpanish ? 'VENTANA RECOMENDADA' : 'RECOMMENDED WINDOW',
        QuitPlanPath.quitToday => isSpanish ? 'COMIENZA HOY' : 'STARTS TODAY',
        QuitPlanPath.reduceGradually =>
          isSpanish ? 'OBJETIVO GRADUAL' : 'GRADUAL TARGET',
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('review-quit-date-card'),
      color: AppColors.deepTeal,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isSpanish ? 'FECHA PARA DEJARLO' : 'QUIT DATE',
                      style: const TextStyle(
                        color: AppColors.mintStrong,
                        fontSize: 10.5,
                        letterSpacing: 1.7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    key: const ValueKey('review-edit-date'),
                    tooltip: isSpanish ? 'Editar fecha' : 'Edit date',
                    onPressed: onEdit,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF234E48),
                      foregroundColor: AppColors.lime,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                ],
              ),
              SizedBox(height: compact ? 5 : 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: compact ? 84 : 92,
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          color: AppColors.coral,
                          child: Text(
                            monthLabel.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 5, 6, 7),
                          child: Column(
                            children: [
                              Text(
                                '${date.day}',
                                style: const TextStyle(
                                  color: AppColors.deepTeal,
                                  fontSize: 35,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                weekdayLabel.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.mutedTeal,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          longDate,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 18 : 20,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$timingLabel · ${isSpanish ? 'Hora del Pacífico' : 'Pacific Time'}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.mintStrong,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF234E48),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.lime,
                                size: 17,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _badgeLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 13 : 16),
              const _PlanTimeline(),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    isSpanish ? 'HOY' : 'TODAY',
                    style: const TextStyle(
                      color: AppColors.mintStrong,
                      fontSize: 9,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isSpanish ? 'DÍA DE DEJARLO' : 'QUIT DAY',
                    style: const TextStyle(
                      color: AppColors.mintStrong,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanTimeline extends StatelessWidget {
  const _PlanTimeline();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
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
          );
        },
      ),
    );
  }
}

class _PlanDetailsCard extends StatelessWidget {
  const _PlanDetailsCard({
    required this.isSpanish,
    required this.approachLabel,
    required this.topReasonLabel,
    required this.supportLabel,
    required this.preparationLabel,
    required this.treatmentLabel,
    required this.onEditApproach,
    required this.onEditReasons,
    required this.onEditSupport,
    required this.onEditPreparation,
    required this.onEditTreatment,
  });

  final bool isSpanish;
  final String approachLabel;
  final String topReasonLabel;
  final String supportLabel;
  final String preparationLabel;
  final String treatmentLabel;
  final VoidCallback onEditApproach;
  final VoidCallback onEditReasons;
  final VoidCallback onEditSupport;
  final VoidCallback onEditPreparation;
  final VoidCallback onEditTreatment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E9E4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D123C37),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _PlanDetailRow(
            rowKey: const ValueKey('review-edit-approach'),
            label: isSpanish ? 'ENFOQUE' : 'QUIT APPROACH',
            value: approachLabel,
            icon: Icons.alt_route_rounded,
            iconColor: AppColors.deepTeal,
            iconBackground: AppColors.mint,
            onTap: onEditApproach,
          ),
          const Divider(height: 1, indent: 18, endIndent: 18),
          _PlanDetailRow(
            rowKey: const ValueKey('review-edit-reasons'),
            label: isSpanish ? 'RAZÓN PRINCIPAL' : 'TOP REASON',
            value: topReasonLabel,
            icon: Icons.favorite_rounded,
            iconColor: AppColors.coral,
            iconBackground: AppColors.coralLight,
            onTap: onEditReasons,
          ),
          const Divider(height: 1, indent: 18, endIndent: 18),
          _PlanDetailRow(
            rowKey: const ValueKey('review-edit-support'),
            label: isSpanish ? 'CONTACTO DE APOYO' : 'SUPPORT CHECK-IN',
            value: supportLabel,
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.deepTeal,
            iconBackground: AppColors.mint,
            onTap: onEditSupport,
          ),
          const Divider(height: 1, indent: 18, endIndent: 18),
          _PlanDetailRow(
            rowKey: const ValueKey('review-edit-preparation'),
            label: isSpanish ? 'PREPARA TU ESPACIO' : 'PREPARE YOUR SPACE',
            value: preparationLabel,
            icon: Icons.check_rounded,
            iconColor: AppColors.deepTeal,
            iconBackground: AppColors.mint,
            onTap: onEditPreparation,
          ),
          const Divider(height: 1, indent: 18, endIndent: 18),
          _PlanDetailRow(
            rowKey: const ValueKey('review-edit-treatment'),
            label: isSpanish ? 'APOYO DE TRATAMIENTO' : 'TREATMENT SUPPORT',
            value: treatmentLabel,
            icon: Icons.medication_outlined,
            iconColor: AppColors.coral,
            iconBackground: AppColors.coralLight,
            onTap: onEditTreatment,
          ),
        ],
      ),
    );
  }
}

class _PlanDetailRow extends StatelessWidget {
  const _PlanDetailRow({
    required this.rowKey,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  final Key rowKey;
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: rowKey,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: iconBackground,
                child: Icon(icon, color: iconColor, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 9.5,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.deepTeal,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivationNote extends StatelessWidget {
  const _ActivationNote({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.deepTeal,
            child: Icon(
              Icons.priority_high_rounded,
              color: AppColors.lime,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpanish
                      ? 'Al comenzar se activan tus tareas y recordatorios.'
                      : 'Starting activates your preparation tasks and reminders.',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isSpanish
                      ? 'Los mensajes de apoyo aún necesitan tu aprobación antes de enviarse.'
                      : 'Support messages still require your approval before sending.',
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 11,
                    height: 1.3,
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

class _ReviewBottomActions extends StatelessWidget {
  const _ReviewBottomActions({
    required this.isSpanish,
    required this.compact,
    required this.horizontalPadding,
    required this.onStartPlan,
    required this.onSaveForLater,
  });

  final bool isSpanish;
  final bool compact;
  final double horizontalPadding;
  final VoidCallback onStartPlan;
  final VoidCallback onSaveForLater;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        compact ? 8 : 10,
        horizontalPadding,
        compact ? 7 : 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: Color(0xFFDCE5DF))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                key: const ValueKey('review-start-plan'),
                onPressed: onStartPlan,
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(compact ? 48 : 54),
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        isSpanish
                            ? 'Comenzar mi plan para dejarlo'
                            : 'Start my quit plan',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.lime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              OutlinedButton(
                key: const ValueKey('review-save-later'),
                onPressed: onSaveForLater,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.fromHeight(compact ? 40 : 44),
                  foregroundColor: AppColors.deepTeal,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(
                  isSpanish
                      ? 'Guardar y terminar después'
                      : 'Save and finish later',
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 6),
                Text(
                  isSpanish
                      ? 'Guardado automáticamente · Puedes editar tu plan en cualquier momento'
                      : 'Saved automatically · You can edit your plan at any time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
