import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'recommended_rescue_tool_screen.dart';

/// Screen 20 answer to "Was this tool helpful?".
///
/// Deliberately three options and no free text: the approved artwork offers
/// "Yes", "A little" and "Not this time", and the answer only ever tunes which
/// tool is recommended first. It is not a clinical outcome.
enum RescueHelpfulChoice {
  yes,
  aLittle,
  notThisTime,
}

/// Screen 20 — Craving recheck.
///
/// Rechecks craving intensity after the Screen 19 rescue exercise and hands the
/// patient-reported change to Screen 21. Two things here are requirements
/// rather than decoration, both drawn by the approved artwork:
///
/// * The rating is reachable **two ways** — tap a number or drag the slider.
///   The artwork says "Tap a number or drag the slider", and a 0-10 row of
///   targets is the only version of this that works for someone who cannot
///   operate a slider precisely.
/// * Stronger support appears at 7-10. The artwork reserves that space with
///   "If you select 7-10, stronger support appears here", so a high rating must
///   surface a route to another tool, a supporter or a quitline — not just
///   record the number and continue.
///
/// The screen never claims the recheck is a measurement. Every comparison is
/// labelled patient-reported, and the copy says "Not a medical measurement".
class CravingRecheckScreen extends StatefulWidget {
  const CravingRecheckScreen({
    required this.isSpanish,
    required this.tool,
    required this.elapsedSeconds,
    required this.beforeCraving,
    required this.currentCraving,
    required this.helpfulChoice,
    required this.resultSaved,
    required this.onCravingChanged,
    required this.onHelpfulChoiceChanged,
    required this.onSave,
    required this.onRepeat,
    required this.onSwitchTool,
    required this.onOpenSupport,
    required this.onClose,
    super.key,
  });

  final bool isSpanish;
  final RescueTool tool;
  final int elapsedSeconds;
  final int beforeCraving;
  final int currentCraving;
  final RescueHelpfulChoice? helpfulChoice;
  final bool resultSaved;
  final ValueChanged<int> onCravingChanged;
  final ValueChanged<RescueHelpfulChoice?> onHelpfulChoiceChanged;
  final VoidCallback onSave;
  final VoidCallback onRepeat;
  final VoidCallback onSwitchTool;
  final VoidCallback onOpenSupport;
  final VoidCallback onClose;

  @override
  State<CravingRecheckScreen> createState() => _CravingRecheckScreenState();
}

class _CravingRecheckScreenState extends State<CravingRecheckScreen> {
  bool get _isSpanish => widget.isSpanish;

  /// True when the recheck itself warrants offering more than "continue".
  ///
  /// 7 is the threshold the approved artwork names, and it is deliberately
  /// evaluated on the CURRENT rating rather than the change: someone who came
  /// down from 10 to 8 has improved and still needs support.
  bool get _needsStrongerSupport => widget.currentCraving >= 7;

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

  /// The tool label, lower-case, for use inside a sentence.
  String get _toolLabel => switch (widget.tool) {
        RescueTool.slowBreathing =>
          _isSpanish ? 'respirar despacio' : 'slow breathing',
        RescueTool.move => _isSpanish ? 'moverte' : 'moving',
        RescueTool.changeScene =>
          _isSpanish ? 'cambiar de ambiente' : 'changing scene',
      };

  /// The banner shown across the top of the exercise summary.
  String get _toolBanner => switch (widget.tool) {
        RescueTool.slowBreathing => _isSpanish ? 'RESPIRACIÓN' : 'BREATHING',
        RescueTool.move => _isSpanish ? 'MOVIMIENTO' : 'MOVEMENT',
        RescueTool.changeScene => _isSpanish ? 'AMBIENTE' : 'SCENE CHANGE',
      };

  String _choiceLabel(RescueHelpfulChoice choice) => switch (choice) {
        RescueHelpfulChoice.yes => _isSpanish ? 'Sí' : 'Yes',
        RescueHelpfulChoice.aLittle => _isSpanish ? 'Un poco' : 'A little',
        RescueHelpfulChoice.notThisTime =>
          _isSpanish ? 'No esta vez' : 'Not this time',
      };

  /// What the app says it will do with the answer.
  ///
  /// Each branch states a consequence the app can actually deliver — which
  /// tool it offers first — and nothing about the patient's condition.
  String get _insightTitle => switch (widget.helpfulChoice) {
        RescueHelpfulChoice.yes => _isSpanish
            ? 'Recordaremos que $_toolLabel ayudó con el estrés.'
            : 'We’ll remember that $_toolLabel helped with stress.',
        RescueHelpfulChoice.aLittle => _isSpanish
            ? 'Mantendremos $_toolLabel y probaremos otra opción junto a ella.'
            : 'We’ll keep $_toolLabel and try another option alongside it.',
        RescueHelpfulChoice.notThisTime => _isSpanish
            ? 'Ofreceremos una herramienta distinta la próxima vez.'
            : 'We’ll offer a different tool first next time.',
        null => _isSpanish
            ? 'Puedes decirnos si ayudó cuando quieras.'
            : 'You can tell us whether it helped whenever you’re ready.',
      };

  /// A plain reading of the change, with no causal claim attached.
  String get _changeSummary {
    final difference = widget.currentCraving - widget.beforeCraving;
    if (difference < 0) {
      return _isSpanish
          ? 'El antojo bajó en esta revisión.'
          : 'The craving has eased in this check-in.';
    }
    if (difference == 0) {
      return _isSpanish
          ? 'El antojo se mantuvo igual en esta revisión.'
          : 'The craving stayed the same in this check-in.';
    }
    return _isSpanish
        ? 'El antojo subió en esta revisión. Eso también es información útil.'
        : 'The craving rose in this check-in. That is useful information too.';
  }

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
                  key: const ValueKey('craving-recheck-exit-stay'),
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
                  key: const ValueKey('craving-recheck-exit-leave'),
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

  void _selectHelpfulChoice(RescueHelpfulChoice choice) {
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
                onClose: _requestClose,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('craving-recheck-scroll'),
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
                        _RescueCompleteHero(isSpanish: _isSpanish),
                        SizedBox(height: compact ? 18 : 24),
                        _RescueSummary(
                          isSpanish: _isSpanish,
                          elapsed: _formattedTime,
                          toolBanner: _toolBanner,
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _CravingRatingCard(
                          isSpanish: _isSpanish,
                          value: widget.currentCraving,
                          intensityLabel: _intensityLabel(
                            widget.currentCraving,
                          ),
                          onChanged: widget.onCravingChanged,
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _ThisRescueCard(
                          isSpanish: _isSpanish,
                          before: widget.beforeCraving,
                          now: widget.currentCraving,
                          summary: _changeSummary,
                        ),
                        if (_needsStrongerSupport) ...[
                          SizedBox(height: compact ? 14 : 18),
                          _StrongerSupportCard(
                            isSpanish: _isSpanish,
                            onSwitchTool: widget.onSwitchTool,
                            onOpenSupport: widget.onOpenSupport,
                          ),
                        ],
                        SizedBox(height: compact ? 14 : 18),
                        _WasItHelpfulCard(
                          isSpanish: _isSpanish,
                          toolLabel: _toolLabel,
                          selected: widget.helpfulChoice,
                          labelFor: _choiceLabel,
                          onSelected: _selectHelpfulChoice,
                        ),
                        const SizedBox(height: 14),
                        _InsightCard(
                          isSpanish: _isSpanish,
                          title: _insightTitle,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isSpanish
                              ? 'Guardado en privado en este dispositivo sin conexión.'
                              : 'Saved privately on this device while offline.',
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
      bottomNavigationBar: _RecheckBottomActions(
        isSpanish: _isSpanish,
        resultSaved: widget.resultSaved,
        toolLabel: _toolLabel,
        onSave: widget.onSave,
        onRepeat: widget.onRepeat,
      ),
    );
  }
}

class _RecheckHeader extends StatelessWidget {
  const _RecheckHeader({required this.isSpanish, required this.onClose});

  final bool isSpanish;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSpanish ? 'Rescate de antojos' : 'Craving Rescue',
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSpanish ? '4 DE 5 · REVISAR' : '4 OF 5 · RECHECK',
                    style: const TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: isSpanish ? 'Cerrar revisión' : 'Close recheck',
              child: IconButton(
                key: const ValueKey('craving-recheck-close'),
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.deepTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: const LinearProgressIndicator(
            key: ValueKey('craving-recheck-progress'),
            value: 0.8,
            minHeight: 6,
            backgroundColor: AppColors.mint,
            valueColor: AlwaysStoppedAnimation(AppColors.deepTeal),
          ),
        ),
      ],
    );
  }
}

class _RescueCompleteHero extends StatelessWidget {
  const _RescueCompleteHero({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            isSpanish
                ? 'RESCATE DE 2 MINUTOS COMPLETO'
                : '2-MINUTE RESCUE COMPLETE',
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 10,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isSpanish
              ? 'Te quedaste con el impulso.'
              : 'You stayed with the urge.',
          style: const TextStyle(
            color: AppColors.deepTeal,
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isSpanish
              ? 'Ahora nota lo que es cierto, no lo que crees que debería ser cierto.'
              : 'Now notice what is true—not what you think should be true.',
          style: const TextStyle(
            color: AppColors.tealSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _RescueSummary extends StatelessWidget {
  const _RescueSummary({
    required this.isSpanish,
    required this.elapsed,
    required this.toolBanner,
  });

  final bool isSpanish;
  final String elapsed;
  final String toolBanner;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpanish ? 'TIEMPO' : 'TIME',
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  elapsed,
                  key: const ValueKey('craving-recheck-elapsed'),
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              toolBanner,
              key: const ValueKey('craving-recheck-tool-banner'),
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The rating control.
///
/// Both input routes the artwork promises are real: a row of 0-10 targets and
/// a slider, bound to the same value. The number row is not decoration — it is
/// the accessible path for anyone who cannot land a slider thumb precisely, and
/// each number carries its own semantic button label.
class _CravingRatingCard extends StatelessWidget {
  const _CravingRatingCard({
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isSpanish
                                ? '¿Qué tan fuerte es el antojo ahora?'
                                : 'How strong is the craving now?',
                            style: const TextStyle(
                              color: AppColors.deepTeal,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RequirementChip(
                          label: isSpanish ? 'Obligatorio' : 'Required',
                          emphasised: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSpanish
                          ? 'Toca un número o arrastra el control.'
                          : 'Tap a number or drag the slider.',
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              key: const ValueKey('craving-recheck-rating-label'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
          ),
          const SizedBox(height: 14),
          _NumberScale(
            isSpanish: isSpanish,
            value: value,
            onChanged: onChanged,
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.deepTeal,
              inactiveTrackColor: const Color(0xFFDCE6E0),
              thumbColor: AppColors.deepTeal,
              overlayColor: AppColors.deepTeal.withValues(alpha: 0.12),
              trackHeight: 7,
            ),
            child: Slider(
              key: const ValueKey('craving-recheck-slider'),
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
                  ? 'Cualquier respuesta es útil. La app responde a lo que elijas.'
                  : 'Any answer is useful. The app responds to what you choose.',
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

/// The 0-10 tap row.
///
/// Wraps rather than scrolls, so no number is ever off-screen on a narrow
/// device — an unreachable rating would silently force the slider path.
class _NumberScale extends StatelessWidget {
  const _NumberScale({
    required this.isSpanish,
    required this.value,
    required this.onChanged,
  });

  final bool isSpanish;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (var number = 0; number <= 10; number++)
          Semantics(
            button: true,
            selected: number == value,
            label: isSpanish
                ? 'Antojo $number de 10'
                : 'Craving $number out of 10',
            child: SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: number == value ? AppColors.deepTeal : AppColors.paper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: number == value
                        ? AppColors.deepTeal
                        : AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                child: InkWell(
                  key: ValueKey('craving-recheck-number-$number'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onChanged(number),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        color:
                            number == value ? Colors.white : AppColors.deepTeal,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThisRescueCard extends StatelessWidget {
  const _ThisRescueCard({
    required this.isSpanish,
    required this.before,
    required this.now,
    required this.summary,
  });

  final bool isSpanish;
  final int before;
  final int now;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final difference = now - before;
    final changeText = difference == 0
        ? '— 0'
        : '${difference < 0 ? '↓' : '↑'} ${difference.abs()}';

    return Container(
      key: const ValueKey('craving-recheck-result-card'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.deepTeal,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSpanish ? 'ESTE RESCATE' : 'THIS RESCUE',
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
                key: const ValueKey('craving-recheck-change'),
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
            summary,
            key: const ValueKey('craving-recheck-change-summary'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.mintStrong,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isSpanish
                      ? 'No es una medición médica'
                      : 'Not a medical measurement',
                  style: const TextStyle(
                    color: AppColors.mintStrong,
                    fontSize: 11,
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

/// Shown only at 7-10.
///
/// The artwork reserves this space for exactly that case. It offers routes, not
/// reassurance: another tool, a supporter, or a quitline counselor.
class _StrongerSupportCard extends StatelessWidget {
  const _StrongerSupportCard({
    required this.isSpanish,
    required this.onSwitchTool,
    required this.onOpenSupport,
  });

  final bool isSpanish;
  final VoidCallback onSwitchTool;
  final VoidCallback onOpenSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('craving-recheck-stronger-support'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.coralLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.support_rounded,
                color: AppColors.coral,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSpanish
                      ? 'El antojo sigue fuerte'
                      : 'The craving is still strong',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isSpanish
                ? 'Elige otra herramienta de rescate, tu persona de apoyo o un consejero de la línea para dejar de fumar.'
                : 'Choose another rescue tool, your supporter, or a quitline counselor.',
            style: const TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: FilledButton(
              key: const ValueKey('craving-recheck-switch-tool'),
              onPressed: onSwitchTool,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isSpanish
                    ? 'Elegir otra herramienta'
                    : 'Choose another rescue tool',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: OutlinedButton(
              key: const ValueKey('craving-recheck-open-support'),
              onPressed: onOpenSupport,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.deepTeal,
                side: const BorderSide(color: AppColors.deepTeal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isSpanish ? 'Hablar con una persona' : 'Talk to a person',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WasItHelpfulCard extends StatelessWidget {
  const _WasItHelpfulCard({
    required this.isSpanish,
    required this.toolLabel,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final bool isSpanish;
  final String toolLabel;
  final RescueHelpfulChoice? selected;
  final String Function(RescueHelpfulChoice choice) labelFor;
  final ValueChanged<RescueHelpfulChoice> onSelected;

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
                child: Text(
                  isSpanish
                      ? '¿Te ayudó $toolLabel?'
                      : 'Was $toolLabel helpful?',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _RequirementChip(
                label: isSpanish ? 'Opcional' : 'Optional',
                emphasised: false,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isSpanish
                ? 'Esto mejora las recomendaciones futuras.'
                : 'This improves future recommendations.',
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in RescueHelpfulChoice.values)
                _ChoiceChip(
                  key: ValueKey('craving-recheck-helpful-${choice.name}'),
                  label: labelFor(choice),
                  selected: selected == choice,
                  onTap: () => onSelected(choice),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isSpanish
                ? 'Las recomendaciones personalizadas se pueden desactivar en Ajustes.'
                : 'Personalized recommendations can be turned off in Settings.',
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.deepTeal : AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected
                ? AppColors.deepTeal
                : AppColors.border.withValues(alpha: 0.7),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 88),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.deepTeal,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({required this.label, required this.emphasised});

  final String label;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: emphasised ? AppColors.coralLight : const Color(0xFFEFF5F1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: emphasised ? AppColors.coral : AppColors.tealSecondary,
          fontSize: 9,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w800,
        ),
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
      key: const ValueKey('craving-recheck-insight'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.deepTeal,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecheckBottomActions extends StatelessWidget {
  const _RecheckBottomActions({
    required this.isSpanish,
    required this.resultSaved,
    required this.toolLabel,
    required this.onSave,
    required this.onRepeat,
  });

  final bool isSpanish;
  final bool resultSaved;
  final String toolLabel;
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
                key: const ValueKey('craving-recheck-save'),
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
                      : (isSpanish
                          ? 'Guardar y ver resultado'
                          : 'Save and see result'),
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
                key: const ValueKey('craving-recheck-repeat'),
                onPressed: onRepeat,
                child: Text(
                  isSpanish
                      ? 'Repetir $toolLabel de 2 minutos'
                      : 'Repeat 2-minute $toolLabel',
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
