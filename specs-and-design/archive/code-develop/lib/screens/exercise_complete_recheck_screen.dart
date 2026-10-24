import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum StressResetHelpfulChoice {
  slowBreathing,
  water,
  switchingActivities,
  notSure,
}

class ExerciseCompleteRecheckScreen extends StatefulWidget {
  const ExerciseCompleteRecheckScreen({
    required this.isSpanish,
    required this.elapsedSeconds,
    required this.beforeCraving,
    required this.currentCraving,
    required this.helpfulChoice,
    required this.resultSaved,
    required this.onCravingChanged,
    required this.onHelpfulChoiceChanged,
    required this.onSave,
    required this.onRepeat,
    required this.onOpenRescue,
    required this.onClose,
    super.key,
  });

  final bool isSpanish;
  final int elapsedSeconds;
  final int beforeCraving;
  final int currentCraving;
  final StressResetHelpfulChoice? helpfulChoice;
  final bool resultSaved;
  final ValueChanged<int> onCravingChanged;
  final ValueChanged<StressResetHelpfulChoice?> onHelpfulChoiceChanged;
  final VoidCallback onSave;
  final VoidCallback onRepeat;
  final VoidCallback onOpenRescue;
  final VoidCallback onClose;

  @override
  State<ExerciseCompleteRecheckScreen> createState() =>
      _ExerciseCompleteRecheckScreenState();
}

class _ExerciseCompleteRecheckScreenState
    extends State<ExerciseCompleteRecheckScreen> {
  bool get _isSpanish => widget.isSpanish;

  String get _formattedTime {
    final safeSeconds = widget.elapsedSeconds.clamp(0, 5999).toInt();
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _intensityLabel(int value) {
    if (value == 0) {
      return _isSpanish ? 'Ninguno' : 'None';
    }
    if (value <= 3) {
      return _isSpanish ? 'Leve' : 'Mild';
    }
    if (value <= 6) {
      return _isSpanish ? 'Moderado' : 'Moderate';
    }
    if (value <= 8) {
      return _isSpanish ? 'Fuerte' : 'Strong';
    }
    return _isSpanish ? 'Muy fuerte' : 'Very strong';
  }

  String _choiceLabel(StressResetHelpfulChoice choice) => switch (choice) {
        StressResetHelpfulChoice.slowBreathing =>
          _isSpanish ? 'Respirar despacio' : 'Slow breathing',
        StressResetHelpfulChoice.water => _isSpanish ? 'Agua' : 'Water',
        StressResetHelpfulChoice.switchingActivities =>
          _isSpanish ? 'Cambiar de actividad' : 'Switching activities',
        StressResetHelpfulChoice.notSure =>
          _isSpanish ? 'Aún no sé' : 'Not sure yet',
      };

  String get _insightTitle => switch (widget.helpfulChoice) {
        StressResetHelpfulChoice.slowBreathing => _isSpanish
            ? 'Priorizaremos respirar despacio cuando el estrés sea alto.'
            : 'We’ll prioritize slow breathing when stress is high.',
        StressResetHelpfulChoice.water => _isSpanish
            ? 'Priorizaremos una pausa con agua cuando el estrés sea alto.'
            : 'We’ll prioritize a water break when stress is high.',
        StressResetHelpfulChoice.switchingActivities => _isSpanish
            ? 'Priorizaremos cambiar de actividad cuando el estrés sea alto.'
            : 'We’ll prioritize switching activities when stress is high.',
        StressResetHelpfulChoice.notSure => _isSpanish
            ? 'Seguiremos aprendiendo qué estrategias te ayudan más.'
            : 'We’ll keep learning which strategies help you most.',
        null => _isSpanish
            ? 'Puedes decirnos qué ayudó cuando estés listo.'
            : 'You can tell us what helped whenever you’re ready.',
      };

  Future<void> _requestClose() async {
    if (widget.resultSaved) {
      widget.onClose();
      return;
    }

    final leave = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSpanish ? '¿Salir sin guardar?' : 'Leave without saving?',
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSpanish
                    ? 'El ejercicio está guardado, pero esta revisión todavía no.'
                    : 'The exercise is saved, but this recheck has not been saved yet.',
                style: const TextStyle(
                  color: AppColors.tealSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('exercise-recheck-exit-stay'),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    _isSpanish ? 'Continuar revisión' : 'Keep reviewing',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const ValueKey('exercise-recheck-exit-leave'),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    _isSpanish ? 'Salir de la revisión' : 'Leave review',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (mounted && leave == true) {
      widget.onClose();
    }
  }

  void _selectHelpfulChoice(StressResetHelpfulChoice choice) {
    widget.onHelpfulChoiceChanged(
      widget.helpfulChoice == choice ? null : choice,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final compact = media.height < 760;
    final horizontalPadding = media.width < 390 ? 16.0 : 20.0;

    return Scaffold(
      key: const ValueKey('functional-exercise-complete-recheck-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 4 : 8,
                horizontalPadding,
                6,
              ),
              child: _CompletionHeader(
                isSpanish: _isSpanish,
                onClose: _requestClose,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('exercise-recheck-scroll'),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  compact ? 8 : 12,
                  horizontalPadding,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CompletionHero(isSpanish: _isSpanish),
                        SizedBox(height: compact ? 18 : 24),
                        _CompletionSummary(
                          isSpanish: _isSpanish,
                          elapsed: _formattedTime,
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _CravingRecheckCard(
                          isSpanish: _isSpanish,
                          value: widget.currentCraving,
                          intensityLabel:
                              _intensityLabel(widget.currentCraving),
                          onChanged: widget.onCravingChanged,
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _BeforeAfterCard(
                          isSpanish: _isSpanish,
                          before: widget.beforeCraving,
                          now: widget.currentCraving,
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _WhatHelpedCard(
                          isSpanish: _isSpanish,
                          selected: widget.helpfulChoice,
                          labelFor: _choiceLabel,
                          onSelected: _selectHelpfulChoice,
                        ),
                        const SizedBox(height: 14),
                        _InsightCard(
                          isSpanish: _isSpanish,
                          title: _insightTitle,
                        ),
                        const SizedBox(height: 14),
                        _MoreSupportCard(
                          isSpanish: _isSpanish,
                          onTap: widget.onOpenRescue,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isSpanish
                              ? 'El resultado se guarda sin conexión y se sincroniza de forma segura.'
                              : 'Result saves offline and syncs securely.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.mutedTeal,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActions(
        isSpanish: _isSpanish,
        resultSaved: widget.resultSaved,
        onSave: widget.onSave,
        onRepeat: widget.onRepeat,
      ),
    );
  }
}

class _CompletionHeader extends StatelessWidget {
  const _CompletionHeader({required this.isSpanish, required this.onClose});

  final bool isSpanish;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('exercise-recheck-close'),
            tooltip: isSpanish ? 'Cerrar' : 'Close',
            onPressed: onClose,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.deepTeal,
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSpanish ? 'Reinicio del estrés' : 'Stress reset',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            key: const ValueKey('exercise-recheck-complete-badge'),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 17,
                  color: AppColors.deepTeal,
                ),
                const SizedBox(width: 5),
                Text(
                  isSpanish ? 'COMPLETO' : 'COMPLETE',
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 9,
                    letterSpacing: 0.7,
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

class _CompletionHero extends StatelessWidget {
  const _CompletionHero({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 106,
          height: 106,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: AppColors.deepTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.lime,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isSpanish
              ? 'Le diste tiempo a la sensación para cambiar.'
              : 'You gave the feeling time to change.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.deepTeal,
            fontSize: 27,
            height: 1.08,
            letterSpacing: -0.7,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isSpanish
              ? 'Tómate un momento para notar qué es diferente ahora.'
              : 'Take a moment to notice what is different now.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.tealSecondary,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _CompletionSummary extends StatelessWidget {
  const _CompletionSummary({required this.isSpanish, required this.elapsed});

  final bool isSpanish;
  final String elapsed;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              icon: Icons.schedule_rounded,
              label: isSpanish ? 'TIEMPO' : 'TIME',
              value: elapsed,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _SummaryItem(
              icon: Icons.check_circle_outline_rounded,
              label: isSpanish ? 'PASOS' : 'STEPS',
              value: isSpanish ? '3 de 3' : '3 of 3',
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _SummaryItem(
              icon: Icons.cloud_done_outlined,
              label: isSpanish ? 'ESTADO' : 'STATUS',
              value: isSpanish ? 'Guardado' : 'Saved',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.deepTeal, size: 21),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: AppColors.mutedTeal,
            fontSize: 8.5,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 72, color: const Color(0xFFE1E9E4));
  }
}

class _CravingRecheckCard extends StatelessWidget {
  const _CravingRecheckCard({
    required this.isSpanish,
    required this.value,
    required this.intensityLabel,
    required this.onChanged,
  });

  final bool isSpanish;
  final int value;
  final String intensityLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
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
                    Text(
                      isSpanish
                          ? '¿Qué tan fuerte es el antojo ahora?'
                          : 'How strong is the craving now?',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSpanish
                          ? 'Elige el número que se sienta más cercano.'
                          : 'Choose the number that feels closest.',
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                key: const ValueKey('exercise-recheck-rating-label'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$value · $intensityLabel',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.deepTeal,
              inactiveTrackColor: const Color(0xFFDCE6E0),
              thumbColor: AppColors.deepTeal,
              overlayColor: AppColors.deepTeal.withValues(alpha: 0.12),
              trackHeight: 7,
            ),
            child: Slider(
              key: const ValueKey('exercise-recheck-craving-slider'),
              min: 0,
              max: 10,
              divisions: 10,
              value: value.toDouble(),
              label: '$value',
              onChanged: (next) => onChanged(next.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSpanish ? 'Sin antojo' : 'No craving',
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 11,
                  ),
                ),
                Text(
                  isSpanish ? 'Más fuerte' : 'Strongest',
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5F1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              isSpanish
                  ? 'No hay una puntuación “buena”; las respuestas honestas mejoran tu apoyo.'
                  : 'There is no “good” score—honest answers improve your support.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BeforeAfterCard extends StatelessWidget {
  const _BeforeAfterCard({
    required this.isSpanish,
    required this.before,
    required this.now,
  });

  final bool isSpanish;
  final int before;
  final int now;

  @override
  Widget build(BuildContext context) {
    final difference = now - before;
    final changeText = difference == 0
        ? '— 0'
        : '${difference < 0 ? '↓' : '↑'} ${difference.abs()}';

    return Container(
      key: const ValueKey('exercise-recheck-result-card'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.deepTeal,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSpanish ? 'RESULTADO DE HOY' : 'TODAY’S RESULT',
            style: const TextStyle(
              color: AppColors.mintStrong,
              fontSize: 11,
              letterSpacing: 1.7,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ResultValue(
                  label: isSpanish ? 'ANTES' : 'BEFORE',
                  value: before,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.lime,
                  size: 26,
                ),
              ),
              Expanded(
                child: _ResultValue(
                  label: isSpanish ? 'AHORA' : 'NOW',
                  value: now,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                key: const ValueKey('exercise-recheck-change'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      changeText,
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      isSpanish ? 'PUNTOS' : 'POINTS',
                      style: const TextStyle(
                        color: AppColors.tealSecondary,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isSpanish
                ? 'Un resultado, no una promesa; los patrones se aclaran con el tiempo.'
                : 'One result, not a promise—patterns become clearer over time.',
            style: const TextStyle(
              color: AppColors.mintStrong,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultValue extends StatelessWidget {
  const _ResultValue({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF234E48),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mintStrong,
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            child: Text(
              '$value / 10',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatHelpedCard extends StatelessWidget {
  const _WhatHelpedCard({
    required this.isSpanish,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final bool isSpanish;
  final StressResetHelpfulChoice? selected;
  final String Function(StressResetHelpfulChoice choice) labelFor;
  final ValueChanged<StressResetHelpfulChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isSpanish ? '¿Qué ayudó más?' : 'What helped most?',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                isSpanish ? 'Opcional' : 'Optional',
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in StressResetHelpfulChoice.values)
                ChoiceChip(
                  key: ValueKey('exercise-recheck-helpful-${choice.name}'),
                  label: Text(labelFor(choice)),
                  selected: selected == choice,
                  showCheckmark: true,
                  checkmarkColor: AppColors.lime,
                  avatar: selected == choice
                      ? const CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.deepTeal,
                        )
                      : null,
                  onSelected: (_) => onSelected(choice),
                  backgroundColor: AppColors.paper,
                  selectedColor: AppColors.mint,
                  side: BorderSide(
                    color:
                        selected == choice ? AppColors.coral : AppColors.border,
                    width: selected == choice ? 1.5 : 1,
                  ),
                  labelStyle: const TextStyle(
                    color: AppColors.deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.isSpanish, required this.title});

  final bool isSpanish;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('exercise-recheck-insight'),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.deepTeal,
            child: Icon(Icons.check_rounded, color: AppColors.lime, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isSpanish
                      ? 'Puedes cambiar esta preferencia en cualquier momento.'
                      : 'You can change this preference anytime.',
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 12,
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

class _MoreSupportCard extends StatelessWidget {
  const _MoreSupportCard({required this.isSpanish, required this.onTap});

  final bool isSpanish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.coralLight,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const ValueKey('exercise-recheck-rescue'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFC6B7)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isSpanish
                      ? '¿Todavía necesitas más apoyo?'
                      : 'Still need more support?',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isSpanish ? 'Abrir Rescate' : 'Open Rescue',
                style: const TextStyle(
                  color: AppColors.coral,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.coral,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.isSpanish,
    required this.resultSaved,
    required this.onSave,
    required this.onRepeat,
  });

  final bool isSpanish;
  final bool resultSaved;
  final VoidCallback onSave;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(18, 10, 18, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                key: const ValueKey('exercise-recheck-save'),
                onPressed: onSave,
                icon: Icon(
                  resultSaved
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_rounded,
                  color: AppColors.lime,
                ),
                label: Text(
                  resultSaved
                      ? (isSpanish ? 'Resultado guardado' : 'Result saved')
                      : (isSpanish ? 'Guardar resultado' : 'Save result'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: TextButton(
                key: const ValueKey('exercise-recheck-repeat'),
                onPressed: onRepeat,
                child: Text(
                  isSpanish ? 'Repetir ejercicio' : 'Repeat exercise',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
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

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D123C37),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}
