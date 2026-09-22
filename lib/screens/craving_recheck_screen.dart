import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'recommended_rescue_tool_screen.dart';

enum RescueHelpfulChoice {
  yes,
  aLittle,
  notThisTime,
}

class CravingRecheckScreen extends StatefulWidget {
  const CravingRecheckScreen({
    required this.isSpanish,
    required this.beforeIntensity,
    required this.tool,
    required this.selectedIntensity,
    required this.helpfulChoice,
    required this.onIntensityChanged,
    required this.onHelpfulChoiceChanged,
    required this.onBack,
    required this.onSaveAndSeeResult,
    required this.onRepeatRescue,
    super.key,
  });

  final bool isSpanish;
  final int beforeIntensity;
  final RescueTool tool;
  final int? selectedIntensity;
  final RescueHelpfulChoice? helpfulChoice;
  final ValueChanged<int> onIntensityChanged;
  final ValueChanged<RescueHelpfulChoice?> onHelpfulChoiceChanged;
  final VoidCallback onBack;
  final VoidCallback onSaveAndSeeResult;
  final VoidCallback onRepeatRescue;

  String _intensityLabel(int value) {
    if (value == 0) return isSpanish ? 'Sin antojo' : 'No craving';
    if (value <= 3) return isSpanish ? 'Leve' : 'Mild';
    if (value <= 6) return isSpanish ? 'Moderado' : 'Moderate';
    if (value <= 8) return isSpanish ? 'Fuerte' : 'Strong';
    return isSpanish ? 'Muy fuerte' : 'Very strong';
  }

  String _helpfulLabel(RescueHelpfulChoice choice) => switch (choice) {
        RescueHelpfulChoice.yes => isSpanish ? 'Sí' : 'Yes',
        RescueHelpfulChoice.aLittle => isSpanish ? 'Un poco' : 'A little',
        RescueHelpfulChoice.notThisTime =>
          isSpanish ? 'Esta vez no' : 'Not this time',
      };

  int get _durationMinutes => tool == RescueTool.move ? 3 : 2;

  String get _helpfulQuestion {
    if (tool == RescueTool.slowBreathing) {
      return isSpanish
          ? '¿Te ayudó la respiración lenta?'
          : 'Was slow breathing helpful?';
    }
    if (tool == RescueTool.move) {
      return isSpanish ? '¿Te ayudó el movimiento?' : 'Was movement helpful?';
    }
    return isSpanish
        ? '¿Te ayudó cambiar de entorno?'
        : 'Was changing your surroundings helpful?';
  }

  @override
  State<CravingRecheckScreen> createState() => _CravingRecheckScreenState();
}

class _CravingRecheckScreenState extends State<CravingRecheckScreen> {
  bool get _isSpanish => widget.isSpanish;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 760;
    final horizontalPadding = size.width < 390 ? 16.0 : 20.0;
    final now = widget.selectedIntensity;
    final hasSelection = now != null;
    final before = widget.beforeIntensity.clamp(0, 10).toInt();
    final change = now == null ? 0 : before - now;
    final positiveChange = change > 0;
    final neutralChange = change == 0;

    return Scaffold(
      key: const ValueKey('functional-craving-recheck-screen'),
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
              child: _RecheckHeader(
                isSpanish: _isSpanish,
                onBack: widget.onBack,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('craving-recheck-scroll'),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  compact ? 8 : 14,
                  horizontalPadding,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RescueProgress(),
                        SizedBox(height: compact ? 14 : 20),
                        _CompletionCard(
                          isSpanish: _isSpanish,
                          tool: widget.tool,
                          durationMinutes: widget._durationMinutes,
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _RatingCard(
                          isSpanish: _isSpanish,
                          value: now,
                          compact: compact,
                          onChanged: widget.onIntensityChanged,
                          intensityLabel: now == null
                              ? (_isSpanish
                                  ? 'Elige un número'
                                  : 'Choose a number')
                              : widget._intensityLabel(now),
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _BeforeAfterCard(
                          isSpanish: _isSpanish,
                          before: before,
                          now: now,
                          change: change,
                          positiveChange: positiveChange,
                          neutralChange: neutralChange,
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _HelpfulCard(
                          isSpanish: _isSpanish,
                          question: widget._helpfulQuestion,
                          selected: widget.helpfulChoice,
                          onChanged: widget.onHelpfulChoiceChanged,
                          labelFor: widget._helpfulLabel,
                        ),
                        if (widget.helpfulChoice != null) ...[
                          const SizedBox(height: 14),
                          _PersonalizationNote(
                            isSpanish: _isSpanish,
                            tool: widget.tool,
                            choice: widget.helpfulChoice!,
                          ),
                        ],
                        if (now != null && now >= 7) ...[
                          const SizedBox(height: 14),
                          _StrongerSupportNote(isSpanish: _isSpanish),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 58,
                          child: FilledButton(
                            key: const ValueKey('craving-recheck-save'),
                            onPressed:
                                hasSelection ? widget.onSaveAndSeeResult : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.deepTeal,
                              disabledBackgroundColor:
                                  AppColors.border.withValues(alpha: .55),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: AppColors.mutedTeal,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _isSpanish
                                        ? 'Guardar y ver resultado'
                                        : 'Save and see result',
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward_rounded),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF5F1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: AppColors.mutedTeal,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _isSpanish
                                      ? 'Guardado de forma privada en este dispositivo mientras estás sin conexión.'
                                      : 'Saved privately on this device while offline.',
                                  style: const TextStyle(
                                    color: AppColors.mutedTeal,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          key: const ValueKey('craving-recheck-repeat'),
                          onPressed: widget.onRepeatRescue,
                          child: Text(
                            widget.tool == RescueTool.move
                                ? (_isSpanish
                                    ? 'Repetir el rescate de 3 minutos'
                                    : 'Repeat 3-minute rescue')
                                : widget.tool == RescueTool.changeScene
                                    ? (_isSpanish
                                        ? 'Repetir el cambio de entorno'
                                        : 'Repeat change-the-scene rescue')
                                    : (_isSpanish
                                        ? 'Repetir la respiración de 2 minutos'
                                        : 'Repeat 2-minute breathing'),
                            style: const TextStyle(
                              color: AppColors.deepTeal,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSpanish
                              ? 'Cualquier respuesta es útil. La aplicación responde a lo que eliges.'
                              : 'Any answer is useful. The app responds to what you choose.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.mutedTeal,
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                        if (hasSelection && !positiveChange) ...[
                          const SizedBox(height: 8),
                          Text(
                            neutralChange
                                ? (_isSpanish
                                    ? 'Tu calificación puede quedarse igual. No necesitas sentirte diferente para que este registro sea útil.'
                                    : 'Your rating can stay the same. You do not need to feel different for this check-in to be useful.')
                                : (_isSpanish
                                    ? 'No pasa nada si el antojo sigue fuerte. Puedes elegir otra ayuda.'
                                    : 'It is okay if the craving is still strong. You can choose another support option.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.tealSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
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
    );
  }
}

class _RecheckHeader extends StatelessWidget {
  const _RecheckHeader({
    required this.isSpanish,
    required this.onBack,
  });

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: const ValueKey('craving-recheck-back'),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.deepTeal,
          tooltip: isSpanish ? 'Atrás' : 'Back',
        ),
        const Expanded(
          child: Text(
            'Craving Rescue',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.deepTeal,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F1EA),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            isSpanish ? '4 DE 5' : '4 OF 5',
            style: const TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _RescueProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            Text(
              'RECHECK CRAVING',
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
            Spacer(),
            Text(
              '80%',
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: const LinearProgressIndicator(
            value: .8,
            minHeight: 7,
            backgroundColor: Color(0xFFDCE6E0),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
          ),
        ),
      ],
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({
    required this.isSpanish,
    required this.tool,
    required this.durationMinutes,
  });

  final bool isSpanish;
  final RescueTool tool;
  final int durationMinutes;

  String get _toolLabel => switch (tool) {
        RescueTool.slowBreathing => isSpanish ? 'RESPIRACIÓN' : 'BREATHING',
        RescueTool.move => isSpanish ? 'MOVIMIENTO' : 'MOVEMENT',
        RescueTool.changeScene =>
          isSpanish ? 'CAMBIO DE ENTORNO' : 'CHANGE SCENE',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.mintStrong),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D123C37),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.deepTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.lime,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpanish
                      ? 'RESCATE DE $durationMinutes MINUTOS COMPLETADO'
                      : '$durationMinutes-MINUTE RESCUE COMPLETE',
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isSpanish
                      ? 'Te quedaste con el antojo.'
                      : 'You stayed with the urge.',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSpanish
                      ? 'Ahora nota lo que es verdad, no lo que debería ser.'
                      : 'Now notice what is true—not what you think should be true.',
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  '2:00',
                  style: TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _toolLabel,
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6,
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

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.isSpanish,
    required this.value,
    required this.compact,
    required this.onChanged,
    required this.intensityLabel,
  });

  final bool isSpanish;
  final int? value;
  final bool compact;
  final ValueChanged<int> onChanged;
  final String intensityLabel;

  @override
  Widget build(BuildContext context) {
    final safeValue = (value ?? 0).clamp(0, 10).toDouble();

    return Container(
      padding: EdgeInsets.all(compact ? 18 : 20),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD8E1DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D123C37),
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
                child: Text(
                  isSpanish
                      ? '¿Qué tan fuerte es el antojo ahora?'
                      : 'How strong is the craving now?',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (value != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$value · $intensityLabel',
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            isSpanish
                ? 'Toca un número o arrastra el control.'
                : 'Tap a number or drag the slider.',
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.deepTeal,
              inactiveTrackColor: const Color(0xFFDCE6E0),
              thumbColor: AppColors.deepTeal,
              overlayColor: AppColors.deepTeal.withValues(alpha: .12),
              trackHeight: 7,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              key: const ValueKey('craving-recheck-slider'),
              min: 0,
              max: 10,
              divisions: 10,
              value: safeValue,
              label: value?.toString(),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              11,
              (index) => InkWell(
                key: ValueKey('craving-recheck-number-$index'),
                borderRadius: BorderRadius.circular(18),
                onTap: () => onChanged(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 4,
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: value == index
                          ? AppColors.deepTeal
                          : AppColors.mutedTeal,
                      fontWeight:
                          value == index ? FontWeight.w900 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5F1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.lime,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSpanish
                        ? 'Cualquier respuesta es útil. La aplicación responde a lo que eliges.'
                        : 'Any answer is useful. The app responds to what you choose.',
                    style: const TextStyle(
                      color: AppColors.tealSecondary,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ),
                Text(
                  isSpanish ? 'Obligatorio' : 'Required',
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 10.5,
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

class _BeforeAfterCard extends StatelessWidget {
  const _BeforeAfterCard({
    required this.isSpanish,
    required this.before,
    required this.now,
    required this.change,
    required this.positiveChange,
    required this.neutralChange,
  });

  final bool isSpanish;
  final int before;
  final int? now;
  final int change;
  final bool positiveChange;
  final bool neutralChange;

  @override
  Widget build(BuildContext context) {
    final displayNow = now ?? '—';
    final message = now == null
        ? (isSpanish
            ? 'Elige una calificación para comparar este rescate.'
            : 'Choose a rating to compare this rescue.')
        : positiveChange
            ? (isSpanish
                ? 'El antojo ha bajado en este registro.'
                : 'The craving has eased in this check-in.')
            : neutralChange
                ? (isSpanish
                    ? 'Tu calificación se mantiene igual en este registro.'
                    : 'Your rating stayed the same in this check-in.')
                : (isSpanish
                    ? 'El antojo sigue presente. Puedes elegir otra ayuda.'
                    : 'The craving is still present. You can choose another support option.');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.deepTeal,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A123C37),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isSpanish ? 'ESTE RESCATE' : 'THIS RESCUE',
            style: const TextStyle(
              color: Color(0xFFBFD5CD),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ScoreTile(
                  title: isSpanish ? 'ANTES' : 'BEFORE',
                  value: '$before / 10',
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.lime,
                  size: 24,
                ),
              ),
              Expanded(
                child: _ScoreTile(
                  title: isSpanish ? 'AHORA' : 'NOW',
                  value: '$displayNow / 10',
                ),
              ),
              if (now != null) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 68),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        change > 0
                            ? '↓ $change'
                            : change < 0
                                ? '↑ ${change.abs()}'
                                : '—',
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
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSpanish
                ? 'No es una medición médica'
                : 'Not a medical measurement',
            style: const TextStyle(
              color: Color(0xFFBFD5CD),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF234E48),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFBFD5CD),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpfulCard extends StatelessWidget {
  const _HelpfulCard({
    required this.isSpanish,
    required this.question,
    required this.selected,
    required this.onChanged,
    required this.labelFor,
  });

  final bool isSpanish;
  final String question;
  final RescueHelpfulChoice? selected;
  final ValueChanged<RescueHelpfulChoice?> onChanged;
  final String Function(RescueHelpfulChoice) labelFor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD8E1DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                isSpanish ? 'Opcional' : 'Optional',
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            isSpanish
                ? 'Esto mejora las recomendaciones futuras.'
                : 'This improves future recommendations.',
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RescueHelpfulChoice.values.map((choice) {
              final isSelected = selected == choice;
              return ChoiceChip(
                key: ValueKey('craving-recheck-helpful-${choice.name}'),
                selected: isSelected,
                onSelected: (_) => onChanged(isSelected ? null : choice),
                label: Text(labelFor(choice)),
                selectedColor: AppColors.mint,
                backgroundColor: AppColors.paper,
                side: BorderSide(
                  color: isSelected ? AppColors.coral : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                labelStyle: TextStyle(
                  color:
                      isSelected ? AppColors.deepTeal : AppColors.tealSecondary,
                  fontWeight: FontWeight.w800,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PersonalizationNote extends StatelessWidget {
  const _PersonalizationNote({
    required this.isSpanish,
    required this.tool,
    required this.choice,
  });

  final bool isSpanish;
  final RescueTool tool;
  final RescueHelpfulChoice choice;

  @override
  Widget build(BuildContext context) {
    final helped = choice == RescueHelpfulChoice.yes;
    final aLittle = choice == RescueHelpfulChoice.aLittle;
    final toolName = switch (tool) {
      RescueTool.slowBreathing =>
        isSpanish ? 'la respiración lenta' : 'slow breathing',
      RescueTool.move => isSpanish ? 'el movimiento' : 'movement',
      RescueTool.changeScene =>
        isSpanish ? 'cambiar de entorno' : 'changing your surroundings',
    };

    final message = helped
        ? (isSpanish
            ? 'Recordaremos que $toolName te ayudó.'
            : "We'll remember that $toolName helped.")
        : aLittle
            ? (isSpanish
                ? 'Guardaremos que $toolName ayudó un poco.'
                : "We'll remember that $toolName helped a little.")
            : (isSpanish
                ? 'Guardaremos que esta vez necesitas otra opción.'
                : "We'll remember that you may need another option next time.");

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.deepTeal,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$message ${isSpanish ? 'Las recomendaciones personalizadas se pueden desactivar en Configuración.' : 'Personalized recommendations can be turned off in Settings.'}',
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrongerSupportNote extends StatelessWidget {
  const _StrongerSupportNote({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.coralLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFC6B7)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            child: Icon(Icons.add_rounded, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSpanish
                  ? 'Si eliges 7–10, aquí aparecerá apoyo adicional: otra herramienta, tu persona de apoyo o un consejero de la línea para dejar de fumar.'
                  : 'If you select 7–10, stronger support appears here: another rescue tool, your supporter, or a quitline counselor.',
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
