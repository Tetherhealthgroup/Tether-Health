import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'daily_check_in_screen.dart';
import 'support_preparation_screen.dart';

enum NextStepStrategy { stressReset, cravingRescue, supportCheckIn }

class PersonalizedNextStepScreen extends StatelessWidget {
  const PersonalizedNextStepScreen({
    required this.isSpanish,
    required this.mood,
    required this.stressLevel,
    required this.smokingStatus,
    required this.cigaretteCount,
    required this.strongestCraving,
    required this.confidence,
    required this.symptoms,
    required this.otherSymptom,
    required this.supportPeople,
    required this.strategyOverride,
    required this.copingPlanStrategies,
    required this.onBack,
    required this.onStrategyChanged,
    required this.onCopingPlanChanged,
    required this.onPractice,
    required this.onOpenRescue,
    required this.onOpenSupport,
    super.key,
  });

  final bool isSpanish;
  final DailyMood mood;
  final int stressLevel;
  final DailySmokingStatus smokingStatus;
  final int cigaretteCount;
  final int strongestCraving;
  final int confidence;
  final Set<DailySymptom> symptoms;
  final String? otherSymptom;
  final List<SupportPersonPlan> supportPeople;
  final NextStepStrategy? strategyOverride;
  final Set<NextStepStrategy> copingPlanStrategies;
  final VoidCallback onBack;
  final ValueChanged<NextStepStrategy> onStrategyChanged;
  final void Function(NextStepStrategy strategy, bool added)
      onCopingPlanChanged;
  final ValueChanged<NextStepStrategy> onPractice;
  final VoidCallback onOpenRescue;
  final VoidCallback onOpenSupport;

  NextStepStrategy get _automaticStrategy {
    if (strongestCraving >= 8) return NextStepStrategy.cravingRescue;
    if (stressLevel >= 4) return NextStepStrategy.stressReset;
    if (confidence <= 4) return NextStepStrategy.supportCheckIn;
    if (smokingStatus != DailySmokingStatus.none && strongestCraving >= 6) {
      return NextStepStrategy.cravingRescue;
    }
    return NextStepStrategy.stressReset;
  }

  NextStepStrategy get _strategy => strategyOverride ?? _automaticStrategy;

  String get _supporterName {
    for (final person in supportPeople) {
      if (person.enabled) return person.name;
    }
    return isSpanish ? 'una persona de apoyo' : 'a support person';
  }

  String _strategyTitle(NextStepStrategy strategy) => switch (strategy) {
        NextStepStrategy.stressReset =>
          isSpanish ? 'Reinicio del estrés' : 'Stress reset',
        NextStepStrategy.cravingRescue =>
          isSpanish ? 'Rescate para el antojo' : 'Craving rescue',
        NextStepStrategy.supportCheckIn =>
          isSpanish ? 'Conectar con apoyo' : 'Support check-in',
      };

  String _headline(NextStepStrategy strategy) => switch (strategy) {
        NextStepStrategy.stressReset => isSpanish
            ? 'Prueba un reinicio del estrés de 3 minutos.'
            : 'Try a 3-minute stress reset.',
        NextStepStrategy.cravingRescue => isSpanish
            ? 'Prueba un rescate breve para el antojo.'
            : 'Try a quick craving rescue.',
        NextStepStrategy.supportCheckIn => isSpanish
            ? 'Conecta con alguien de tu equipo de apoyo.'
            : 'Check in with someone on your support team.',
      };

  String _strategySubtitle(NextStepStrategy strategy) => switch (strategy) {
        NextStepStrategy.stressReset =>
          isSpanish ? 'Respira. Bebe. Cambia.' : 'Breathe. Sip. Switch.',
        NextStepStrategy.cravingRescue => isSpanish
            ? 'Pausa. Cambia. Supera la ola.'
            : 'Pause. Change. Ride it out.',
        NextStepStrategy.supportCheckIn =>
          isSpanish ? 'Nombra. Contacta. Planea.' : 'Name it. Reach out. Plan.',
      };

  String _duration(NextStepStrategy strategy) => switch (strategy) {
        NextStepStrategy.stressReset => '3:00',
        NextStepStrategy.cravingRescue => '2:00',
        NextStepStrategy.supportCheckIn => '2:00',
      };

  String _intro() {
    final cravingDescription = strongestCraving >= 8
        ? (isSpanish ? 'un antojo fuerte' : 'a strong craving')
        : strongestCraving >= 5
            ? (isSpanish ? 'un antojo moderado' : 'a moderate craving')
            : (isSpanish ? 'un antojo leve' : 'a mild craving');
    final stressDescription = stressLevel >= 4
        ? (isSpanish ? 'estrés alto' : 'high stress')
        : stressLevel == 3
            ? (isSpanish ? 'estrés moderado' : 'moderate stress')
            : (isSpanish ? 'estrés bajo' : 'lower stress');

    if (isSpanish) {
      return 'Hoy reportaste $stressDescription y $cravingDescription. '
          'Aquí tienes un paso pequeño basado en tu registro.';
    }
    return 'You reported $stressDescription and $cravingDescription today. '
        'Here is one small step based on your check-in.';
  }

  String _stressLabel() {
    if (stressLevel >= 4) return isSpanish ? 'Alto' : 'High';
    if (stressLevel == 3) return isSpanish ? 'Moderado' : 'Moderate';
    return isSpanish ? 'Bajo' : 'Low';
  }

  String _moodLabel() => switch (mood) {
        DailyMood.low => isSpanish ? 'bajo' : 'low',
        DailyMood.notGreat => isSpanish ? 'no muy bien' : 'not great',
        DailyMood.okay => isSpanish ? 'regular' : 'okay',
        DailyMood.good => isSpanish ? 'bien' : 'good',
        DailyMood.great => isSpanish ? 'muy bien' : 'great',
      };

  String _smokingSummary() => switch (smokingStatus) {
        DailySmokingStatus.none =>
          isSpanish ? 'No reportaste fumar.' : 'You reported no smoking.',
        DailySmokingStatus.puff =>
          isSpanish ? 'Reportaste una calada.' : 'You reported having a puff.',
        DailySmokingStatus.oneOrMore => isSpanish
            ? 'Reportaste aproximadamente $cigaretteCount cigarrillos.'
            : 'You reported about $cigaretteCount cigarettes.',
        DailySmokingStatus.skipped => isSpanish
            ? 'Omitiste la pregunta sobre fumar.'
            : 'You skipped the smoking question.',
      };

  List<_PlanStep> _steps(NextStepStrategy strategy) => switch (strategy) {
        NextStepStrategy.stressReset => [
            _PlanStep(
              title: isSpanish
                  ? 'Haz 10 respiraciones lentas'
                  : 'Take 10 slow breaths',
              detail: isSpanish
                  ? 'Inhala por la nariz y exhala por la boca.'
                  : 'In through your nose, out through your mouth.',
              duration: isSpanish ? '60 S' : '60 SEC',
            ),
            _PlanStep(
              title:
                  isSpanish ? 'Bebe un vaso de agua' : 'Drink a glass of water',
              detail: isSpanish
                  ? 'Bebe despacio y nota la temperatura.'
                  : 'Sip slowly and notice the temperature.',
              duration: isSpanish ? '30 S' : '30 SEC',
            ),
            _PlanStep(
              title: isSpanish
                  ? 'Cambia lo que estás haciendo'
                  : 'Switch what you are doing',
              detail: isSpanish
                  ? 'Camina, pon música o empieza una tarea breve.'
                  : 'Walk, play music, or start one quick task.',
              duration: isSpanish ? '90 S' : '90 SEC',
            ),
          ],
        NextStepStrategy.cravingRescue => [
            _PlanStep(
              title: isSpanish ? 'Espera un minuto' : 'Delay for one minute',
              detail: isSpanish
                  ? 'Observa el antojo sin actuar de inmediato.'
                  : 'Notice the urge without acting right away.',
              duration: isSpanish ? '60 S' : '60 SEC',
            ),
            _PlanStep(
              title: isSpanish ? 'Cambia de lugar' : 'Change your location',
              detail: isSpanish
                  ? 'Aléjate de la señal que activó el antojo.'
                  : 'Step away from the cue that started the craving.',
              duration: isSpanish ? '30 S' : '30 SEC',
            ),
            _PlanStep(
              title: isSpanish
                  ? 'Ocupa tus manos y tu boca'
                  : 'Keep hands and mouth busy',
              detail: isSpanish
                  ? 'Usa agua, goma de mascar o una tarea sencilla.'
                  : 'Use water, gum, or one simple task.',
              duration: isSpanish ? '30 S' : '30 SEC',
            ),
          ],
        NextStepStrategy.supportCheckIn => [
            _PlanStep(
              title: isSpanish ? 'Nombra lo que sientes' : 'Name what you feel',
              detail: isSpanish
                  ? 'Una frase breve es suficiente.'
                  : 'One short sentence is enough.',
              duration: isSpanish ? '20 S' : '20 SEC',
            ),
            _PlanStep(
              title: isSpanish
                  ? 'Contacta a $_supporterName'
                  : 'Reach out to $_supporterName',
              detail: isSpanish
                  ? 'Pide el tipo específico de ayuda que necesitas.'
                  : 'Ask for the specific kind of help you need.',
              duration: isSpanish ? '60 S' : '60 SEC',
            ),
            _PlanStep(
              title:
                  isSpanish ? 'Planea la próxima hora' : 'Plan the next hour',
              detail: isSpanish
                  ? 'Elige un lugar y una actividad sin humo.'
                  : 'Choose one smoke-free place and activity.',
              duration: isSpanish ? '40 S' : '40 SEC',
            ),
          ],
      };

  String _whySummary() {
    final symptomNames = <String>[];
    if (symptoms.contains(DailySymptom.restless)) {
      symptomNames.add(isSpanish ? 'inquietud' : 'restlessness');
    }
    if (symptoms.contains(DailySymptom.irritable)) {
      symptomNames.add(isSpanish ? 'irritabilidad' : 'irritability');
    }
    if (symptoms.contains(DailySymptom.troubleConcentrating)) {
      symptomNames.add(
        isSpanish ? 'dificultad para concentrarte' : 'trouble concentrating',
      );
    }
    if (symptoms.contains(DailySymptom.troubleSleeping)) {
      symptomNames
          .add(isSpanish ? 'dificultad para dormir' : 'trouble sleeping');
    }
    if ((otherSymptom ?? '').trim().isNotEmpty) {
      symptomNames.add(otherSymptom!.trim());
    }

    final symptomText = symptomNames.isEmpty
        ? (isSpanish ? 'sin síntomas opcionales' : 'no optional symptoms')
        : symptomNames.take(2).join(isSpanish ? ' y ' : ' and ');
    if (isSpanish) {
      return 'Ánimo ${_moodLabel()}, estrés ${_stressLabel().toLowerCase()}, '
          '$symptomText y un antojo de $strongestCraving/10. '
          '${_smokingSummary()}';
    }
    return '${_moodLabel()} mood, ${_stressLabel().toLowerCase()} stress, '
        '$symptomText and a craving of $strongestCraving/10. '
        '${_smokingSummary()}';
  }

  Future<void> _showWhy(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSpanish
                  ? 'Por qué se recomendó esto'
                  : 'Why this was recommended',
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _whySummary(),
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 16,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isSpanish
                    ? 'Esta sugerencia usa solo las respuestas de tu registro de hoy. No es un diagnóstico ni reemplaza la atención médica.'
                    : 'This suggestion uses only today’s check-in answers. It is not a diagnosis and does not replace medical care.',
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('next-step-why-done'),
                onPressed: () => Navigator.pop(context),
                child: Text(isSpanish ? 'Listo' : 'Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseStrategy(BuildContext context) async {
    final selected = await showModalBottomSheet<NextStepStrategy>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSpanish ? 'Elige otra estrategia' : 'Choose another strategy',
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isSpanish
                    ? 'Tú decides qué apoyo probar.'
                    : 'You decide which support to try.',
                style: const TextStyle(color: AppColors.mutedTeal),
              ),
              const SizedBox(height: 14),
              for (final strategy in NextStepStrategy.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    key: ValueKey('next-step-strategy-${strategy.name}'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: strategy == _strategy
                            ? AppColors.coral
                            : AppColors.border,
                      ),
                    ),
                    tileColor:
                        strategy == _strategy ? AppColors.coralLight : null,
                    leading: Icon(
                      _strategyIcon(strategy),
                      color: AppColors.deepTeal,
                    ),
                    title: Text(
                      _strategyTitle(strategy),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(_strategySubtitle(strategy)),
                    trailing: strategy == _strategy
                        ? const Icon(Icons.check_circle, color: AppColors.coral)
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(context, strategy),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && selected != _strategy) {
      onStrategyChanged(selected);
    }
  }

  Future<void> _showUrgeOptions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSpanish
                  ? '¿Todavía sientes el impulso?'
                  : 'Still feeling the urge?',
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSpanish
                  ? 'Elige el apoyo que quieres abrir. No se enviará ningún mensaje automáticamente.'
                  : 'Choose the support you want to open. No message will be sent automatically.',
              style: const TextStyle(color: AppColors.mutedTeal, height: 1.4),
            ),
            const SizedBox(height: 14),
            ListTile(
              key: const ValueKey('next-step-open-support'),
              leading: const Icon(Icons.people_alt_outlined),
              title: Text(
                isSpanish
                    ? 'Abrir apoyo para $_supporterName'
                    : 'Open support for $_supporterName',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pop(context, 'support'),
            ),
            ListTile(
              key: const ValueKey('next-step-open-rescue'),
              leading: const Icon(Icons.waves_rounded),
              title: Text(
                isSpanish ? 'Abrir Rescate de antojo' : 'Open Craving Rescue',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pop(context, 'rescue'),
            ),
          ],
        ),
      ),
    );
    if (action == 'support') onOpenSupport();
    if (action == 'rescue') onOpenRescue();
  }

  IconData _strategyIcon(NextStepStrategy strategy) => switch (strategy) {
        NextStepStrategy.stressReset => Icons.air_rounded,
        NextStepStrategy.cravingRescue => Icons.waves_rounded,
        NextStepStrategy.supportCheckIn => Icons.people_alt_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 760;
    final horizontalPadding = size.width < 390 ? 16.0 : 20.0;
    final strategy = _strategy;
    final inCopingPlan = copingPlanStrategies.contains(strategy);

    return Scaffold(
      key: const ValueKey('functional-personalized-next-step-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 4 : 8,
                horizontalPadding,
                8,
              ),
              child: _NextStepHeader(
                isSpanish: isSpanish,
                onBack: onBack,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('next-step-scroll'),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  compact ? 12 : 18,
                  horizontalPadding,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SavedBadge(isSpanish: isSpanish),
                        const SizedBox(height: 12),
                        Text(
                          _headline(strategy),
                          key: const ValueKey('next-step-headline'),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontSize: size.width < 390 ? 30 : 35,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _intro(),
                          style: const TextStyle(
                            color: AppColors.tealSecondary,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _RecommendationCard(
                          isSpanish: isSpanish,
                          title: _strategyTitle(strategy),
                          subtitle: _strategySubtitle(strategy),
                          duration: _duration(strategy),
                          stressLabel: _stressLabel(),
                          strongestCraving: strongestCraving,
                          confidence: confidence,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isSpanish
                                    ? 'Tu plan de ${_duration(strategy).startsWith('3') ? '3' : '2'} minutos'
                                    : 'Your ${_duration(strategy).startsWith('3') ? '3' : '2'}-minute plan',
                                style: const TextStyle(
                                  color: AppColors.deepTeal,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              isSpanish ? 'Sigue el orden' : 'Follow in order',
                              style: const TextStyle(
                                color: AppColors.mutedTeal,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _PlanCard(
                          isSpanish: isSpanish,
                          steps: _steps(strategy),
                          supporterName: _supporterName,
                          onStillUrge: () => _showUrgeOptions(context),
                        ),
                        const SizedBox(height: 14),
                        _WhyCard(
                          isSpanish: isSpanish,
                          summary: _whySummary(),
                          onTap: () => _showWhy(context),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          key: const ValueKey('next-step-choose-strategy'),
                          onTap: () => _chooseStrategy(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: isSpanish
                                          ? '¿No te parece adecuado? '
                                          : 'Not a good fit? ',
                                      style: const TextStyle(
                                        color: AppColors.mutedTeal,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: isSpanish
                                              ? 'Elige otra estrategia'
                                              : 'Choose another strategy',
                                          style: const TextStyle(
                                            color: AppColors.deepTeal,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
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
                        if (inCopingPlan) ...[
                          const SizedBox(height: 4),
                          Row(
                            key:
                                const ValueKey('next-step-coping-confirmation'),
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.deepTeal,
                                size: 18,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  isSpanish
                                      ? 'Guardado en tu plan de afrontamiento.'
                                      : 'Saved in your coping plan.',
                                  style: const TextStyle(
                                    color: AppColors.deepTeal,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _NextStepActions(
        isSpanish: isSpanish,
        compact: compact,
        horizontalPadding: horizontalPadding,
        inCopingPlan: inCopingPlan,
        onPractice: () => onPractice(strategy),
        onCopingPlan: () {
          onCopingPlanChanged(strategy, !inCopingPlan);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                !inCopingPlan
                    ? (isSpanish
                        ? 'Agregado a tu plan de afrontamiento'
                        : 'Added to your coping plan')
                    : (isSpanish
                        ? 'Eliminado de tu plan de afrontamiento'
                        : 'Removed from your coping plan'),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}

class _NextStepHeader extends StatelessWidget {
  const _NextStepHeader({required this.isSpanish, required this.onBack});

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('next-step-back'),
            tooltip: isSpanish ? 'Atrás' : 'Back',
            onPressed: onBack,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.deepTeal,
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSpanish ? 'Tu próximo paso' : 'Your next step',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.deepTeal,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  isSpanish ? 'PERSONAL' : 'PERSONALIZED',
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
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

class _SavedBadge extends StatelessWidget {
  const _SavedBadge({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.deepTeal,
            size: 17,
          ),
          const SizedBox(width: 6),
          Text(
            isSpanish ? 'REGISTRO GUARDADO' : 'CHECK-IN SAVED',
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.isSpanish,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.stressLabel,
    required this.strongestCraving,
    required this.confidence,
  });

  final bool isSpanish;
  final String title;
  final String subtitle;
  final String duration;
  final String stressLabel;
  final int strongestCraving;
  final int confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepTeal,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C123C37),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish ? 'RECOMENDADO PARA TI' : 'RECOMMENDED FOR YOU',
                      style: const TextStyle(
                        color: AppColors.mintStrong,
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      key: const ValueKey('next-step-strategy-title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.mintStrong,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x66718A84),
                    width: 7,
                  ),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        duration,
                        style: const TextStyle(
                          color: AppColors.deepTeal,
                          fontSize: 22,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSpanish ? 'MINUTOS' : 'MINUTES',
                        style: const TextStyle(
                          color: AppColors.tealSecondary,
                          fontSize: 7.5,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _MetricChip(
                color: AppColors.coral,
                label: '${isSpanish ? 'Estrés' : 'Stress'} · $stressLabel',
              ),
              _MetricChip(
                color: AppColors.coral,
                label:
                    '${isSpanish ? 'Antojo' : 'Craving'} · $strongestCraving/10',
              ),
              _MetricChip(
                color: AppColors.lime,
                label:
                    '${isSpanish ? 'Confianza' : 'Confidence'} · $confidence',
              ),
            ],
          ),
          const Divider(color: Color(0x55718A84), height: 25),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.lime,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSpanish
                      ? 'Disponible sin conexión cuando lo necesites'
                      : 'Available offline whenever you need it',
                  style: const TextStyle(
                    color: AppColors.mintStrong,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF234F49),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanStep {
  const _PlanStep({
    required this.title,
    required this.detail,
    required this.duration,
  });

  final String title;
  final String detail;
  final String duration;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.isSpanish,
    required this.steps,
    required this.supporterName,
    required this.onStillUrge,
  });

  final bool isSpanish;
  final List<_PlanStep> steps;
  final String supporterName;
  final VoidCallback onStillUrge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D123C37),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            _PlanStepRow(number: index + 1, step: steps[index]),
            if (index < steps.length - 1) const Divider(height: 1, indent: 46),
          ],
          const Divider(height: 1, indent: 46),
          Material(
            color: Colors.transparent,
            child: ListTile(
              key: const ValueKey('next-step-still-urge'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 2),
              leading: const CircleAvatar(
                backgroundColor: AppColors.coralLight,
                foregroundColor: AppColors.coral,
                child: Icon(Icons.person_outline_rounded),
              ),
              title: Text(
                isSpanish
                    ? '¿Todavía sientes el impulso?'
                    : 'Still feeling the urge?',
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                isSpanish
                    ? 'Abre apoyo para $supporterName o Rescate de antojo.'
                    : 'Open support for $supporterName or Craving Rescue.',
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.coral,
              ),
              onTap: onStillUrge,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_rounded,
                  color: AppColors.deepTeal,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    isSpanish
                        ? 'Los antojos cambian. Sigue probando estrategias hasta encontrar lo que te ayuda.'
                        : 'Cravings change. Keep trying strategies until you find what helps.',
                    style: const TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 10.5,
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

class _PlanStepRow extends StatelessWidget {
  const _PlanStepRow({required this.number, required this.step});

  final int number;
  final _PlanStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.deepTeal,
            foregroundColor: AppColors.lime,
            child: Text(
              '$number',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.detail,
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              step.duration,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyCard extends StatelessWidget {
  const _WhyCard({
    required this.isSpanish,
    required this.summary,
    required this.onTap,
  });

  final bool isSpanish;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('next-step-why'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.mintStrong),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.paper,
              foregroundColor: AppColors.deepTeal,
              child: Icon(Icons.schedule_rounded),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSpanish
                        ? 'Por qué se recomendó esto'
                        : 'Why this was recommended',
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.tealSecondary,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isSpanish
                        ? 'Basado solo en el registro de hoy · Versión 1.0'
                        : 'Based only on today’s check-in · Recommendation version 1.0',
                    style: const TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 9,
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
    );
  }
}

class _NextStepActions extends StatelessWidget {
  const _NextStepActions({
    required this.isSpanish,
    required this.compact,
    required this.horizontalPadding,
    required this.inCopingPlan,
    required this.onPractice,
    required this.onCopingPlan,
  });

  final bool isSpanish;
  final bool compact;
  final double horizontalPadding;
  final bool inCopingPlan;
  final VoidCallback onPractice;
  final VoidCallback onCopingPlan;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        boxShadow: [
          BoxShadow(
            color: Color(0x12123C37),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 8 : 10,
            horizontalPadding,
            8,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: compact ? 46 : 50,
                    child: FilledButton.icon(
                      key: const ValueKey('next-step-practice'),
                      onPressed: onPractice,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.deepTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.lime,
                      ),
                      label: Text(
                        isSpanish ? 'Practicar ahora' : 'Practice this now',
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    width: double.infinity,
                    height: compact ? 42 : 46,
                    child: OutlinedButton.icon(
                      key: const ValueKey('next-step-coping-plan'),
                      onPressed: onCopingPlan,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.deepTeal,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: Icon(
                        inCopingPlan
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        size: 18,
                      ),
                      label: Text(
                        inCopingPlan
                            ? (isSpanish
                                ? 'Agregado al plan de afrontamiento'
                                : 'Added to my coping plan')
                            : (isSpanish
                                ? 'Agregar a mi plan de afrontamiento'
                                : 'Add to my coping plan'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isSpanish
                        ? 'Apoyo educativo · Tú mantienes el control'
                        : 'Educational support · You remain in control',
                    style: const TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
