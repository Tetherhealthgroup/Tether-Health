import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'my_reasons_screen.dart';
import 'support_preparation_screen.dart';

/// Screen 22 — Quit-day home.
///
/// Visual implementation follows the approved Screen 22 design:
/// design/approved/screen-22-quit-day-home-iphone.svg
class QuitDayHomeScreen extends StatefulWidget {
  const QuitDayHomeScreen({
    required this.isSpanish,
    required this.quitDate,
    required this.topReason,
    required this.customReason,
    required this.supportPeople,
    required this.treatmentSupport,
    required this.onOpenRescue,
    required this.onOpenSlipRecovery,
    required this.onOpenDailyCheckIn,
    required this.onOpenPlan,
    required this.onOpenProgress,
    required this.onOpenLearn,
    required this.onOpenSupport,
    required this.onNotifications,
    required this.onOpenProfile,
    super.key,
  });

  final bool isSpanish;
  final DateTime? quitDate;
  final QuitReason? topReason;
  final String? customReason;
  final List<SupportPersonPlan> supportPeople;
  final bool treatmentSupport;

  final VoidCallback onOpenRescue;
  final VoidCallback onOpenSlipRecovery;
  final VoidCallback onOpenDailyCheckIn;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenLearn;
  final VoidCallback onOpenSupport;
  final VoidCallback onNotifications;
  final VoidCallback onOpenProfile;

  @override
  State<QuitDayHomeScreen> createState() => _QuitDayHomeScreenState();
}

class _QuitDayHomeScreenState extends State<QuitDayHomeScreen> {
  Timer? _timer;
  bool _morningActionComplete = false;

  DateTime get _effectiveQuitDate =>
      widget.quitDate ?? DateUtils.dateOnly(DateTime.now());

  Duration get _elapsedSinceQuit {
    final start = _effectiveQuitDate;
    final now = DateTime.now();

    if (now.isBefore(start)) {
      return Duration.zero;
    }

    return now.difference(start);
  }

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
   Future<void> _openNotifications() async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.paper,
    builder: (sheetContext) {
return _QuitDayNotificationsSheet(
  isSpanish: widget.isSpanish,
  onStartCheckIn: widget.onOpenDailyCheckIn,
  onCravingSupport: widget.onOpenRescue,
  onProgress: widget.onOpenProgress,
  onDone: () => Navigator.of(sheetContext).pop(),
);
    },
  );
}

 String _greeting() {
  final hour = DateTime.now().hour;

  if (hour < 12) {
    return widget.isSpanish
        ? 'Buenos días, Alex.'
        : 'Good morning, Alex.';
  }

  if (hour < 17) {
    return widget.isSpanish
        ? 'Buenas tardes, Alex.'
        : 'Good afternoon, Alex.';
  }

  return widget.isSpanish
      ? 'Buenas noches, Alex.'
      : 'Good evening, Alex.';
}
  String _month(int month) {
    const names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return names[month - 1];
  }

  String _quitDayLabel() {
    final d = _effectiveQuitDate;

    return widget.isSpanish
        ? 'DÍA DE DEJARLO · ${_month(d.month).toUpperCase()} ${d.day}'
        : 'QUIT DAY · ${_month(d.month).toUpperCase()} ${d.day}';
  }

  String _elapsedLabel() {
    final elapsed = _elapsedSinceQuit;

    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }

  String _timeLabel() {
    final d = _effectiveQuitDate;

    final hour = d.hour == 0
        ? 12
        : d.hour > 12
            ? d.hour - 12
            : d.hour;

    final minute = d.minute.toString().padLeft(2, '0');
    final suffix = d.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $suffix';
  }

  String _reasonLabel() {
    final reason = widget.topReason;

    if (reason == null) {
      return widget.isSpanish
          ? 'Mi razón para dejarlo.'
          : 'My reason to quit.';
    }

    return switch (reason) {
      QuitReason.family => widget.isSpanish
          ? 'Proteger a mi familia.'
          : 'Protect my family.',
      QuitReason.breatheEasier => widget.isSpanish
          ? 'Respirar mejor.'
          : 'Breathe easier.',
      QuitReason.improveHealth => widget.isSpanish
          ? 'Mejorar mi salud.'
          : 'Improve my health.',
      QuitReason.saveMoney => widget.isSpanish
          ? 'Ahorrar dinero.'
          : 'Save money.',
      QuitReason.control => widget.isSpanish
          ? 'Sentirme en control.'
          : 'Feel more in control.',
      QuitReason.future => widget.isSpanish
          ? 'Estar presente para mi futuro.'
          : 'Be there for my future.',
      QuitReason.custom => widget.customReason?.trim().isNotEmpty == true
          ? '${widget.customReason!.trim()}.'
          : (widget.isSpanish ? 'Mi propia razón.' : 'My own reason.'),
    };
  }

  SupportPersonPlan? get _supportPerson {
    for (final person in widget.supportPeople) {
      if (person.enabled) {
        return person;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final supportPerson = _supportPerson;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
               isSpanish: widget.isSpanish,
               hasUnreadNotifications: true,
               onNotifications: _openNotifications,
               onProfile: widget.onOpenProfile,
                 ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuitDayBadge(
                      label: _quitDayLabel(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _greeting(),
                      style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                        ),
                       ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isSpanish
                          ? 'Mantén el día sencillo. Una elección a la vez.'
                          : 'Keep today simple. One choice at a time.',
                      style: const TextStyle(
                        color: AppColors.tealSecondary,
                        fontSize: 15,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _QuitDayHero(
                      elapsed: _elapsedLabel(),
                      startedAt: _timeLabel(),
                      isSpanish: widget.isSpanish,
                      onCraving: widget.onOpenRescue,
                      onSlip: widget.onOpenSlipRecovery,
                    ),
                    const SizedBox(height: 10),
                    _NextBestStepCard(
                      isSpanish: widget.isSpanish,
                      completed: _morningActionComplete,
                      onComplete: () {
                        setState(() {
                          _morningActionComplete = true;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _SectionHeader(
                      title: widget.isSpanish
                          ? 'Lo esencial de hoy'
                          : "Today's essentials",
                      count: widget.isSpanish ? '2 elementos' : '2 items',
                    ),
                    const SizedBox(height: 6),
                    _EssentialsCard(
                      isSpanish: widget.isSpanish,
                      treatmentSupport: widget.treatmentSupport,
                      onCheckIn: widget.onOpenDailyCheckIn,
                      onTreatmentPlan: widget.onOpenPlan,
                    ),
                    const SizedBox(height: 10),
                    _ReasonCard(
                      isSpanish: widget.isSpanish,
                      reason: _reasonLabel(),
                    ),
                    const SizedBox(height: 10),
                    _SupportCard(
                      isSpanish: widget.isSpanish,
                      supportPerson: supportPerson,
                      onTap: widget.onOpenSupport,
                    ),
                    const SizedBox(height: 8),
                    const _AdaptiveMessage(),
                  ],
                ),
              ),
            ),
            _BottomNavigation(
              isSpanish: widget.isSpanish,
              onHome: () {},
              onPlan: widget.onOpenPlan,
              onProgress: widget.onOpenProgress,
              onLearn: widget.onOpenLearn,
              onSupport: widget.onOpenSupport,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
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
    return Padding(
  padding: const EdgeInsets.symmetric(horizontal: 18),
  child: SizedBox(
    height: 54,
    child: Row(
        children: [
          const CircleAvatar(
            radius: 23,
            backgroundColor: AppColors.deepTeal,
            child: Icon(
              Icons.eco_rounded,
              color: AppColors.lime,
              size: 29,
            ),
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
                tooltip: 'Notifications',
                onPressed: onNotifications,
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.deepTeal,
                  side: const BorderSide(
                    color: AppColors.border,
                  ),
                ),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                ),
              ),
              if (hasUnreadNotifications)
                const Positioned(
                  right: 3,
                  top: 2,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: AppColors.coral,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(24),
            child: const CircleAvatar(
              radius: 23,
              backgroundColor: AppColors.mint,
              foregroundColor: AppColors.deepTeal,
              child: Text(
                'A',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
     ),
    );
  }
}

class _QuitDayBadge extends StatelessWidget {
  const _QuitDayBadge({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.coral,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuitDayHero extends StatelessWidget {
  const _QuitDayHero({
    required this.elapsed,
    required this.startedAt,
    required this.isSpanish,
    required this.onCraving,
    required this.onSlip,
  });

  final String elapsed;
  final String startedAt;
  final bool isSpanish;
  final VoidCallback onCraving;
  final VoidCallback onSlip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 11),
      decoration: BoxDecoration(
        color: AppColors.deepTeal,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SINCE YOUR PLANNED QUIT TIME',
            style: TextStyle(
              color: AppColors.mint,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),

          // Compact text area. The orb is intentionally allowed
          // to extend outside this Stack without increasing its height.
          SizedBox(
            height: 69,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 104),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        elapsed,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          height: .92,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isSpanish
                            ? 'Comenzaste a las $startedAt · Hora del Pacífico'
                            : 'Started at $startedAt · Pacific Time',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),

                // The orb is 112x112 but floats independently
                // so it does not create a large gap before the craving card.
                const Positioned(
                  right: -75,
                  top: -53,
                  child: _BreathingOrb(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          _CravingAction(
            isSpanish: isSpanish,
            onTap: onCraving,
          ),

          const SizedBox(height: 7),

          _SlipAction(
            isSpanish: isSpanish,
            onTap: onSlip,
          ),
        ],
      ),
    );
  }
}

class _BreathingOrb extends StatelessWidget {
  const _BreathingOrb();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      height: 145,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 145,
            height: 145,
            decoration: BoxDecoration(
              color: AppColors.mutedTeal.withValues(alpha: .32),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 105,
            height: 105,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.mint.withValues(alpha: .35),
                width: 1.3,
              ),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 69,
            height: 69,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.air_rounded,
              color: AppColors.deepTeal,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _CravingAction extends StatelessWidget {
  const _CravingAction({
    required this.isSpanish,
    required this.onTap,
  });

  final bool isSpanish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.coralLight,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 9),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.air_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish ? 'Tengo un antojo' : 'I have a craving',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSpanish
                          ? 'Abre apoyo rápido para los próximos minutos.'
                          : 'Open fast support for the next few minutes.',
                      style: const TextStyle(
                        color: AppColors.tealSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isSpanish ? 'Abrir Rescate' : 'Open Rescue',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlipAction extends StatelessWidget {
  const _SlipAction({
    required this.isSpanish,
    required this.onTap,
  });

  final bool isSpanish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.mint.withValues(alpha: .32),
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.remove_rounded,
                  color: AppColors.deepTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  isSpanish
                      ? 'Fumé o tuve un desliz'
                      : 'I smoked or had a slip',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                isSpanish
                    ? 'Tu progreso no se borrará'
                    : 'Your progress will not be erased',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.lime,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextBestStepCard extends StatelessWidget {
  const _NextBestStepCard({
    required this.isSpanish,
    required this.completed,
    required this.onComplete,
  });

  final bool isSpanish;
  final bool completed;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.mutedTeal.withValues(alpha: .18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.deepTeal,
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.deepTeal,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isSpanish ? 'SIGUIENTE PASO' : 'NEXT BEST STEP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isSpanish
                      ? 'Haz tu acción de la mañana'
                      : 'Take your planned morning action',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isSpanish
                      ? 'Bebe agua y camina cinco minutos en un lugar sin humo.'
                      : 'Drink water, then walk for five minutes in a smoke-free place.',
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isSpanish
                      ? 'De tu plan de desencadenantes · Unos 5 minutos'
                      : 'From your trigger plan · About 5 minutes',
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: completed ? null : onComplete,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.deepTeal,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                completed
                    ? (isSpanish ? 'Listo' : 'Done')
                    : (isSpanish ? 'Completar' : 'Mark complete'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            color: AppColors.mutedTeal,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _EssentialsCard extends StatelessWidget {
  const _EssentialsCard({
    required this.isSpanish,
    required this.treatmentSupport,
    required this.onCheckIn,
    required this.onTreatmentPlan,
  });

  final bool isSpanish;
  final bool treatmentSupport;
  final VoidCallback onCheckIn;
  final VoidCallback onTreatmentPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _EssentialRow(
            icon: Icons.air_rounded,
            iconBackground: AppColors.mint,
            label: isSpanish ? 'REGISTRO DE LA MAÑANA' : 'MORNING CHECK-IN',
            title: isSpanish
                ? '¿Cómo va tu primera mañana?'
                : 'How is your first morning going?',
            subtitle: null,
            action: isSpanish ? 'Registrar' : 'Check in',
            onTap: onCheckIn,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(
              height: 1,
              color: AppColors.mutedTeal.withValues(alpha: .16),
            ),
          ),
          _EssentialRow(
            icon: Icons.medication_outlined,
            iconBackground: AppColors.coralLight,
            label: isSpanish
                ? 'PLAN DE TRATAMIENTO REGISTRADO'
                : 'RECORDED TREATMENT PLAN',
            title: isSpanish
                ? 'Confirma el estado de tu plan matutino'
                : 'Confirm your morning plan status',
            subtitle: isSpanish
                ? 'Sigue solo el plan registrado contigo o con tu equipo de atención.'
                : 'Follow only the plan recorded with you or your care team.',
            action: isSpanish ? 'Revisar estado' : 'Review status',
            onTap: onTreatmentPlan,
          ),
        ],
      ),
    );
  }
}

class _EssentialRow extends StatelessWidget {
  const _EssentialRow({
    required this.icon,
    required this.iconBackground,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final String label;
  final String title;
  final String? subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.deepTeal,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.tealSecondary,
                        fontSize: 8.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({
    required this.isSpanish,
    required this.reason,
  });

  final bool isSpanish;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.coralLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.coral,
              size: 25,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpanish ? 'TU RAZÓN HOY' : 'YOUR REASON TODAY',
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '“${reason.replaceAll(RegExp(r'[.]$'), '')}.”',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontFamily: 'Georgia',
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isSpanish ? 'De mi plan' : 'From My Plan',
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 8.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.isSpanish,
    required this.supportPerson,
    required this.onTap,
  });

  final bool isSpanish;
  final SupportPersonPlan? supportPerson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final person = supportPerson;

    return Material(
      color: AppColors.coralLight,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person == null
                          ? (isSpanish
                              ? 'Tu equipo de apoyo'
                              : 'Your support team')
                          : '${person.name} is part of your support plan',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isSpanish
                          ? 'Envía tu frase de ayuda guardada o contacta a un consejero.'
                          : 'Send your saved help phrase or contact a quitline counselor.',
                      style: const TextStyle(
                        color: AppColors.tealSecondary,
                        fontSize: 9,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSpanish
                          ? 'Nada se envía a menos que tú lo elijas.'
                          : 'Nothing is sent unless you choose it.',
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 7.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isSpanish ? 'Ver apoyo' : 'View support',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdaptiveMessage extends StatelessWidget {
  const _AdaptiveMessage();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.wifi_tethering_rounded,
            color: AppColors.deepTeal,
            size: 13,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Today adapts to your answers. There is no perfect way to do this.',
            style: TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 8.5,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.isSpanish,
    required this.onHome,
    required this.onPlan,
    required this.onProgress,
    required this.onLearn,
    required this.onSupport,
  });

  final bool isSpanish;
  final VoidCallback onHome;
  final VoidCallback onPlan;
  final VoidCallback onProgress;
  final VoidCallback onLearn;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: .08),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: isSpanish ? 'Inicio' : 'Home',
            selected: true,
            onTap: onHome,
          ),
          _NavItem(
            icon: Icons.description_outlined,
            label: 'Plan',
            onTap: onPlan,
          ),
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: isSpanish ? 'Progreso' : 'Progress',
            onTap: onProgress,
          ),
          _NavItem(
            icon: Icons.menu_book_outlined,
            label: isSpanish ? 'Aprender' : 'Learn',
            onTap: onLearn,
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: isSpanish ? 'Apoyo' : 'Support',
            onTap: onSupport,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? AppColors.mint : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 24,
                color: selected
                    ? AppColors.deepTeal
                    : AppColors.mutedTeal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.deepTeal
                    : AppColors.mutedTeal,
                fontSize: 9,
                fontWeight:
                    selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuitDayNotificationsSheet extends StatelessWidget {
  const _QuitDayNotificationsSheet({
    required this.isSpanish,
    required this.onStartCheckIn,
    required this.onCravingSupport,
    required this.onProgress,
    required this.onDone,
  });

  final bool isSpanish;
  final VoidCallback onStartCheckIn;
  final VoidCallback onCravingSupport;
  final VoidCallback onProgress;
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
              isSpanish ? 'Recordatorios de hoy' : 'Today’s reminders',
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSpanish
                  ? 'Tu día para dejarlo está en marcha. Estos recordatorios pueden ayudarte a mantenerte enfocado y acompañado.'
                  : 'Your quit day is underway. These reminders can help you stay focused and supported.',
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Daily check-in
            Material(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(17),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  onStartCheckIn();
                },
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

            // Craving support
            Material(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(17),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  onCravingSupport();
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.coralLight,
                        foregroundColor: AppColors.deepTeal,
                        child: Icon(Icons.air_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSpanish
                                  ? 'Apoyo para los antojos'
                                  : 'Craving support',
                              style: const TextStyle(
                                color: AppColors.deepTeal,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSpanish
                                  ? 'Tus herramientas de rescate están listas cuando las necesites.'
                                  : 'Your rescue tools are ready whenever you need them.',
                              style: const TextStyle(
                                color: AppColors.tealSecondary,
                                fontSize: 12,
                                height: 1.3,
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

            // Quit-day progress
            Material(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(17),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  onProgress();
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.mint,
                        foregroundColor: AppColors.deepTeal,
                        child: Icon(Icons.bar_chart_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSpanish
                                  ? 'Tu progreso de hoy'
                                  : 'Your quit-day progress',
                              style: const TextStyle(
                                color: AppColors.deepTeal,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSpanish
                                  ? 'Mira lo que has logrado desde tu hora planificada para dejarlo.'
                                  : 'See what you have accomplished since your planned quit time.',
                              style: const TextStyle(
                                color: AppColors.tealSecondary,
                                fontSize: 12,
                                height: 1.3,
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

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isSpanish ? 'Listo' : 'Done',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}