import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Screen 21 — Craving Rescue result.
///
/// Uses the same cream / paper / deep-teal / mint / coral / lime visual
/// language as the preceding Craving Rescue screens. Values are patient
/// reported and are not presented as a clinical measurement.
class RescueResultNextStepScreen extends StatelessWidget {
  const RescueResultNextStepScreen({
    required this.beforeCraving,
    required this.afterCraving,
    required this.toolName,
    required this.helpfulness,
    required this.isSpanish,
    required this.triggerLabel,
    required this.reasonText,
    required this.practiceLabel,
    this.onContinue,
    this.onRepeatRescue,
    this.onHumanSupport,
    this.onBackToToday,
    super.key,
  });

  final int beforeCraving;
  final int afterCraving;
  final String toolName;
  final String helpfulness;
  final bool isSpanish;
  final String triggerLabel;
  final String reasonText;
  final String practiceLabel;
  final VoidCallback? onContinue;
  final VoidCallback? onRepeatRescue;
  final VoidCallback? onHumanSupport;
  final VoidCallback? onBackToToday;

  String get _toolLabel {
    if (!isSpanish) {
      return toolName.toLowerCase() == 'slow breathing'
          ? 'Breathing'
          : toolName;
    }
    switch (toolName.toLowerCase()) {
      case 'slow breathing':
        return 'Respiración';
      case 'movement':
        return 'Movimiento';
      case 'changing your surroundings':
        return 'Cambiar de entorno';
      default:
        return toolName;
    }
  }

  String get _helpfulnessLabel {
    if (!isSpanish) return helpfulness;
    switch (helpfulness.toLowerCase()) {
      case 'yes':
        return 'Sí';
      case 'a little':
        return 'Un poco';
      case 'not this time':
        return 'Esta vez no';
      case 'not selected':
        return 'No seleccionado';
      default:
        return helpfulness;
    }
  }

  int get _change => beforeCraving - afterCraving;

  bool get _eased => _change > 0;

  bool get _increased => _change < 0;

  String get _resultTitle {
    if (_eased) {
      return isSpanish ? 'Este antojo disminuyó.' : 'This craving eased.';
    }
    if (_increased) {
      return isSpanish
          ? 'El antojo sigue presente.'
          : 'The craving is still here.';
    }
    return isSpanish
        ? 'Tu antojo se mantuvo igual.'
        : 'Your craving stayed about the same.';
  }

  String get _resultSubtitle {
    if (_eased) {
      return isSpanish
          ? 'Le diste tiempo al antojo para cambiar antes de actuar.'
          : 'You gave the urge time to change before acting on it.';
    }
    if (_increased) {
      return isSpanish
          ? 'Eso está bien. Practicar una herramienta sigue siendo una forma de responder a este momento.'
          : 'That is okay. You practiced a way to respond to this moment.';
    }
    return isSpanish
        ? 'Eso está bien. Practicar una herramienta puede ayudarte a atravesar este momento sin actuar sobre el antojo.'
        : 'That is okay. Practicing a tool can help you move through this moment without acting on the craving.';
  }

  String get _pointsLabel {
    if (_change > 0) {
      return isSpanish ? 'MENOS ESTA VEZ' : 'LOWER THIS TIME';
    }
    if (_change < 0) {
      return isSpanish ? 'MÁS ESTA VEZ' : 'HIGHER THIS TIME';
    }
    return isSpanish ? 'SIN CAMBIO' : 'NO CHANGE';
  }

  String get _triggerText {
    if (!isSpanish) return triggerLabel;
    return triggerLabel == 'Stress' ? 'Estrés' : triggerLabel;
  }

  String get _planText {
    if (!isSpanish) {
      return 'Slow breathing will be offered first for similar stress cravings.';
    }
    return 'La respiración lenta se ofrecerá primero para antojos de estrés similares.';
  }

  String get _nextStepTitle => isSpanish
      ? 'Protege los próximos 10 minutos.'
      : 'Protect the next 10 minutes.';

  String get _nextStepBody => isSpanish
      ? 'Quédate en un lugar sin humo y toma unos sorbos de agua.'
      : 'Stay in a smoke-free place and take a few sips of water.';

  String get _nextStepCallout => isSpanish
      ? 'Rescate de antojo sigue a un toque de distancia de Inicio.'
      : 'Craving Rescue stays one tap away from Home.';

  String get _repeatTitle => isSpanish ? 'Repetir rescate' : 'Repeat rescue';

  String get _repeatSubtitle =>
      isSpanish ? 'Usar respiración de nuevo' : 'Use breathing again';

  String get _supportTitle =>
      isSpanish ? 'Obtener apoyo humano' : 'Get human support';

  String get _supportSubtitle =>
      isSpanish ? 'Persona de apoyo o línea de ayuda' : 'Supporter or quitline';

  String get _reasonLabel => isSpanish ? 'MI RAZÓN' : 'YOUR REASON';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 390;
    final horizontal = compact ? 16.0 : 22.0;

    return Scaffold(
      key: const ValueKey('screen-image-21'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              isSpanish: isSpanish,
              compact: compact,
              onBack: onBackToToday,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 30),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProgressHeader(isSpanish: isSpanish),
                        const SizedBox(height: 14),
                        _ResultHero(
                          isSpanish: isSpanish,
                          before: beforeCraving,
                          now: afterCraving,
                          change: _change,
                          title: _resultTitle,
                          subtitle: _resultSubtitle,
                          pointsLabel: _pointsLabel,
                        ),
                        const SizedBox(height: 16),
                        _PlanCard(
                          isSpanish: isSpanish,
                          trigger: _triggerText,
                          tool: _toolLabel,
                          practice: practiceLabel,
                          helpfulness: _helpfulnessLabel,
                          planText: _planText,
                        ),
                        const SizedBox(height: 16),
                        _NextStepCard(
                          isSpanish: isSpanish,
                          title: _nextStepTitle,
                          body: _nextStepBody,
                          callout: _nextStepCallout,
                        ),
                        const SizedBox(height: 16),
                        _ReasonCard(
                          label: _reasonLabel,
                          reason: reasonText,
                          isSpanish: isSpanish,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isSpanish ? 'Si necesitas más' : 'If you need more',
                          style: const TextStyle(
                            color: AppColors.deepTeal,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stacked = constraints.maxWidth < 540;
                            final children = [
                              _ActionCard(
                                icon: Icons.arrow_forward_rounded,
                                title: _repeatTitle,
                                subtitle: _repeatSubtitle,
                                onTap: onRepeatRescue,
                                coral: false,
                              ),
                              _ActionCard(
                                icon: Icons.person_outline_rounded,
                                title: _supportTitle,
                                subtitle: _supportSubtitle,
                                onTap: onHumanSupport,
                                coral: true,
                              ),
                            ];

                            if (stacked) {
                              return Column(
                                children: [
                                  children[0],
                                  const SizedBox(height: 10),
                                  children[1],
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: children[0]),
                                const SizedBox(width: 12),
                                Expanded(child: children[1]),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 60,
                          child: FilledButton(
                            key: const ValueKey('screen-21-back-to-today'),
                            onPressed: onBackToToday ?? onContinue,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.deepTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isSpanish ? 'Volver a Hoy' : 'Back to Today',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.lime,
                                  size: 27,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PrivacyBar(isSpanish: isSpanish),
                        const SizedBox(height: 24),
                        Text(
                          isSpanish
                              ? 'Ver detalles del progreso'
                              : 'View progress details',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.deepTeal,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          isSpanish
                              ? 'Puedes eliminar este resultado de tu historial'
                              : 'You can delete this result from your history',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.mutedTeal,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.isSpanish,
    required this.compact,
    required this.onBack,
  });

  final bool isSpanish;
  final bool compact;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 20, 12, compact ? 16 : 20, 4),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: AppColors.border),
                  shape: const CircleBorder(),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.deepTeal,
                  size: 20,
                ),
              ),
            ),
            Expanded(
              child: Text(
                isSpanish ? 'Rescate de antojo' : 'Craving Rescue',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                isSpanish ? '5 DE 5' : '5 OF 5',
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 11,
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

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              isSpanish ? 'RESULTADO GUARDADO' : 'RESULT SAVED',
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            const Text(
              '100%',
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: const SizedBox(
            height: 7,
            child: LinearProgressIndicator(
              value: 1,
              backgroundColor: Color(0xFFDCE8E2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultHero extends StatelessWidget {
  const _ResultHero({
    required this.isSpanish,
    required this.before,
    required this.now,
    required this.change,
    required this.title,
    required this.subtitle,
    required this.pointsLabel,
  });

  final bool isSpanish;
  final int before;
  final int now;
  final int change;
  final String title;
  final String subtitle;
  final String pointsLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.deepTeal,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A123C37),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF234E48),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.lime,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSpanish ? 'RESCATE GUARDADO' : 'RESCUE SAVED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFBFD5CD),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x332F6B61),
                      ),
                    ),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0x6689A9A0),
                          width: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      width: 66,
                      height: 66,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lime,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.deepTeal,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF234E48),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroScore(
                    label: isSpanish ? 'ANTES' : 'BEFORE',
                    value: before,
                    descriptor: _descriptor(before, isSpanish),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.lime,
                  size: 38,
                ),
                Expanded(
                  child: _HeroScore(
                    label: isSpanish ? 'AHORA' : 'NOW',
                    value: now,
                    descriptor: _descriptor(now, isSpanish),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 112),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${change.abs()} ${isSpanish ? 'puntos' : 'points'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.deepTeal,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pointsLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.tealSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSpanish
                            ? 'Tu calificación, no un diagnóstico'
                            : 'Your rating, not a diagnosis',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.tealSecondary,
                          fontSize: 6.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isSpanish
                ? 'Cada resultado puede ser diferente. Registrarlo te ayuda a aprender qué funciona.'
                : 'Every result can be different. Checking in helps you learn what works.',
            style: const TextStyle(
              color: Color(0xFFBFD5CD),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  static String _descriptor(int value, bool isSpanish) {
    if (value <= 3) return isSpanish ? 'Leve' : 'Mild';
    if (value <= 6) return isSpanish ? 'Moderado' : 'Moderate';
    return isSpanish ? 'Fuerte' : 'Strong';
  }
}

class _HeroScore extends StatelessWidget {
  const _HeroScore({
    required this.label,
    required this.value,
    required this.descriptor,
  });

  final String label;
  final int value;
  final String descriptor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFBFD5CD),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          descriptor,
          style: const TextStyle(
            color: Color(0xFFBFD5CD),
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.isSpanish,
    required this.trigger,
    required this.tool,
    required this.practice,
    required this.helpfulness,
    required this.planText,
  });

  final bool isSpanish;
  final String trigger;
  final String tool;
  final String practice;
  final String helpfulness;
  final String planText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
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
                  isSpanish
                      ? 'Lo que esto agrega a tu plan'
                      : 'What this adds to your plan',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(
                'Today · 9:41 AM',
                style: TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _MiniPlanCard(
                  icon: Icons.priority_high_rounded,
                  iconColor: AppColors.coral,
                  label: isSpanish ? 'DISPARADOR' : 'TRIGGER',
                  value: trigger,
                  footer: isSpanish
                      ? 'Seleccionado antes del rescate'
                      : 'Selected before rescue',
                ),
                _MiniPlanCard(
                  icon: Icons.check_rounded,
                  iconColor: AppColors.deepTeal,
                  label: isSpanish ? 'HERRAMIENTA' : 'TOOL',
                  value: tool,
                  footer: isSpanish ? 'Marcado como útil' : 'Marked helpful',
                ),
                _MiniPlanCard(
                  icon: Icons.schedule_rounded,
                  iconColor: AppColors.lime,
                  label: isSpanish ? 'PRÁCTICA' : 'PRACTICE',
                  value: practice,
                  footer: isSpanish
                      ? 'Completado sin conexión'
                      : 'Completed offline',
                ),
              ];

              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 8),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 8),
                  Expanded(child: cards[2]),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            planText,
            style: const TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPlanCard extends StatelessWidget {
  const _MiniPlanCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.footer,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.fromLTRB(9, 9, 7, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor,
                ),
                child: Icon(
                  icon,
                  color: iconColor == AppColors.lime
                      ? AppColors.deepTeal
                      : Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            footer,
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 9,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({
    required this.isSpanish,
    required this.title,
    required this.body,
    required this.callout,
  });

  final bool isSpanish;
  final String title;
  final String body;
  final String callout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.mintStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.deepTeal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_circle_rounded,
                  color: AppColors.lime,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  isSpanish ? 'SIGUIENTE MEJOR PASO' : 'NEXT BEST STEP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 16,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF4EF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.deepTeal,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    callout,
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  isSpanish ? 'Sin temporizador' : 'No timer needed',
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 10,
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

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({
    required this.label,
    required this.reason,
    required this.isSpanish,
  });

  final String label;
  final String reason;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.coralLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.coral,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isSpanish ? 'Guardado en Mi Plan' : 'Saved in My Plan',
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 7.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.coral,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool coral;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: coral ? AppColors.coralLight : AppColors.paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: coral ? const Color(0xFFFFB5A4) : const Color(0xFFE2E9E5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: coral ? AppColors.coral : const Color(0xFFEAF4EF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: coral ? Colors.white : AppColors.deepTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.deepTeal,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyBar extends StatelessWidget {
  const _PrivacyBar({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.mutedTeal,
            size: 22,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              isSpanish
                  ? 'Guardado de forma privada. Los resultados sin conexión se sincronizan una vez conectado.'
                  : 'Saved privately. Offline results sync once when connected.',
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 11,
              ),
            ),
          ),
          const Text(
            'Content v1.0',
            style: TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
