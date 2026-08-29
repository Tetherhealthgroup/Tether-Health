import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../theme/app_colors.dart';

enum StressResetStep { breathe, water, switchActivity }

typedef StressResetProgressChanged = void Function(
  StressResetStep step,
  int stepElapsedSeconds,
  int totalElapsedSeconds,
);

class GuidedStressResetScreen extends StatefulWidget {
  const GuidedStressResetScreen({
    required this.isSpanish,
    required this.step,
    required this.stepElapsedSeconds,
    required this.totalElapsedSeconds,
    required this.isPaused,
    required this.voiceGuidanceEnabled,
    required this.reducedMotionEnabled,
    required this.onProgressChanged,
    required this.onPausedChanged,
    required this.onVoiceGuidanceChanged,
    required this.onReducedMotionChanged,
    required this.onClose,
    required this.onComplete,
    required this.onOpenRescue,
    super.key,
  });

  final bool isSpanish;
  final StressResetStep step;
  final int stepElapsedSeconds;
  final int totalElapsedSeconds;
  final bool isPaused;
  final bool voiceGuidanceEnabled;
  final bool reducedMotionEnabled;
  final StressResetProgressChanged onProgressChanged;
  final ValueChanged<bool> onPausedChanged;
  final ValueChanged<bool> onVoiceGuidanceChanged;
  final ValueChanged<bool> onReducedMotionChanged;
  final VoidCallback onClose;
  final VoidCallback onComplete;
  final VoidCallback onOpenRescue;

  @override
  State<GuidedStressResetScreen> createState() =>
      _GuidedStressResetScreenState();
}

class _GuidedStressResetScreenState extends State<GuidedStressResetScreen> {
  static const _totalDurationSeconds = 180;
  static const _stepDurations = <StressResetStep, int>{
    StressResetStep.breathe: 80,
    StressResetStep.water: 30,
    StressResetStep.switchActivity: 70,
  };

  Timer? _timer;
  late final FlutterTts _speech;

  bool get _isSpanish => widget.isSpanish;

  @override
  void initState() {
    super.initState();
    _speech = FlutterTts();
    unawaited(_configureSpeech(speakAfter: true));
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant GuidedStressResetScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPaused != widget.isPaused) {
      _syncTimer();
    }
    if (oldWidget.isSpanish != widget.isSpanish) {
      unawaited(_configureSpeech(speakAfter: widget.voiceGuidanceEnabled));
      return;
    }
    if (oldWidget.voiceGuidanceEnabled != widget.voiceGuidanceEnabled) {
      if (widget.voiceGuidanceEnabled && !widget.isPaused) {
        unawaited(_speakCurrentCue());
      } else {
        unawaited(_stopSpeech());
      }
      return;
    }
    if (!widget.voiceGuidanceEnabled) {
      return;
    }
    if (!oldWidget.isPaused && widget.isPaused) {
      unawaited(_stopSpeech());
      return;
    }
    if (oldWidget.isPaused && !widget.isPaused) {
      unawaited(_speakCurrentCue());
      return;
    }
    if (oldWidget.step != widget.step || _breathingPhaseChanged(oldWidget)) {
      unawaited(_speakCurrentCue());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_stopSpeech());
    super.dispose();
  }

  bool _breathingPhaseChanged(GuidedStressResetScreen oldWidget) {
    if (widget.step != StressResetStep.breathe ||
        oldWidget.step != StressResetStep.breathe) {
      return false;
    }
    return oldWidget.stepElapsedSeconds ~/ 4 != widget.stepElapsedSeconds ~/ 4;
  }

  Future<void> _configureSpeech({required bool speakAfter}) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _speech.setSharedInstance(true);
        await _speech.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          <IosTextToSpeechAudioCategoryOptions>[
            IosTextToSpeechAudioCategoryOptions.duckOthers,
            IosTextToSpeechAudioCategoryOptions
                .interruptSpokenAudioAndMixWithOthers,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }
      await _speech.setLanguage(widget.isSpanish ? 'es-US' : 'en-US');
      await _speech.setSpeechRate(0.42);
      await _speech.setPitch(1.0);
      await _speech.setVolume(1.0);
      if (speakAfter &&
          mounted &&
          widget.voiceGuidanceEnabled &&
          !widget.isPaused) {
        await _speakCurrentCue();
      }
    } catch (_) {
      // Speech is optional support. Visual guidance remains fully available
      // if a device has no installed voice or a platform service is unavailable.
    }
  }

  String _speechCue() {
    switch (widget.step) {
      case StressResetStep.breathe:
        final inhale = (widget.stepElapsedSeconds % 8) < 4;
        if (widget.isSpanish) {
          return inhale
              ? 'Inhala lentamente por la nariz.'
              : 'Exhala lentamente por la boca.';
        }
        return inhale
            ? 'Slowly breathe in through your nose.'
            : 'Slowly breathe out through your mouth.';
      case StressResetStep.water:
        return widget.isSpanish
            ? 'Bebe despacio y nota la temperatura.'
            : 'Sip slowly and notice the temperature.';
      case StressResetStep.switchActivity:
        return widget.isSpanish
            ? 'Cambia lo que estás haciendo. Camina, pon música o comienza una tarea breve.'
            : 'Switch what you are doing. Walk, play music, or start one quick task.';
    }
  }

  Future<void> _speakCurrentCue() async {
    if (!mounted || !widget.voiceGuidanceEnabled || widget.isPaused) {
      return;
    }
    try {
      await _speech.stop();
      await _speech.speak(_speechCue());
    } catch (_) {
      // Keep the timed visual exercise usable if speech is unavailable.
    }
  }

  Future<void> _stopSpeech() async {
    try {
      await _speech.stop();
    } catch (_) {
      // The platform speech service may already be unavailable or stopped.
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    if (widget.isPaused) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || widget.isPaused) {
      return;
    }
    final nextTotal = math
        .min(
          _totalDurationSeconds,
          widget.totalElapsedSeconds + 1,
        )
        .toInt();
    final nextStepElapsed = widget.stepElapsedSeconds + 1;
    final stepDuration = _stepDurations[widget.step]!;

    if (nextTotal >= _totalDurationSeconds) {
      _timer?.cancel();
      widget.onProgressChanged(
        StressResetStep.switchActivity,
        _stepDurations[StressResetStep.switchActivity]!,
        _totalDurationSeconds,
      );
      widget.onComplete();
      return;
    }

    if (nextStepElapsed >= stepDuration) {
      _advanceStep(nextTotal);
      return;
    }

    widget.onProgressChanged(widget.step, nextStepElapsed, nextTotal);
  }

  void _advanceStep([int? totalElapsed]) {
    switch (widget.step) {
      case StressResetStep.breathe:
        widget.onProgressChanged(
          StressResetStep.water,
          0,
          totalElapsed ?? widget.totalElapsedSeconds,
        );
        return;
      case StressResetStep.water:
        widget.onProgressChanged(
          StressResetStep.switchActivity,
          0,
          totalElapsed ?? widget.totalElapsedSeconds,
        );
        return;
      case StressResetStep.switchActivity:
        _timer?.cancel();
        widget.onComplete();
        return;
    }
  }

  String _stepName(StressResetStep step) => switch (step) {
        StressResetStep.breathe => _isSpanish ? 'RESPIRA' : 'BREATHE',
        StressResetStep.water => _isSpanish ? 'AGUA' : 'WATER',
        StressResetStep.switchActivity => _isSpanish ? 'CAMBIA' : 'SWITCH',
      };

  String _stepLabel(StressResetStep step) => switch (step) {
        StressResetStep.breathe => _isSpanish ? 'Respira' : 'Breathe',
        StressResetStep.water => _isSpanish ? 'Agua' : 'Water',
        StressResetStep.switchActivity => _isSpanish ? 'Cambia' : 'Switch',
      };

  IconData _stepIcon(StressResetStep step) => switch (step) {
        StressResetStep.breathe => Icons.air_rounded,
        StressResetStep.water => Icons.local_drink_outlined,
        StressResetStep.switchActivity => Icons.swap_horiz_rounded,
      };

  int get _stepNumber => widget.step.index + 1;

  String get _remainingTime {
    final remaining = math
        .max(
          0,
          _totalDurationSeconds - widget.totalElapsedSeconds,
        )
        .toInt();
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showExitConfirmation() async {
    widget.onPausedChanged(true);
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
                _isSpanish ? '¿Salir del ejercicio?' : 'Leave the exercise?',
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSpanish
                    ? 'Tu progreso parcial se guardará y podrás continuar después.'
                    : 'Your partial progress will be saved so you can continue later.',
                style: const TextStyle(
                  color: AppColors.tealSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('stress-reset-exit-stay'),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    _isSpanish ? 'Continuar ejercicio' : 'Continue exercise',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const ValueKey('stress-reset-exit-save'),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    _isSpanish ? 'Guardar y salir' : 'Save and leave',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) {
      return;
    }
    if (leave == true) {
      widget.onClose();
    } else {
      widget.onPausedChanged(false);
    }
  }

  Future<void> _showEndConfirmation() async {
    widget.onPausedChanged(true);
    final end = await showModalBottomSheet<bool>(
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
                _isSpanish
                    ? '¿Terminar el ejercicio ahora?'
                    : 'End the exercise now?',
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSpanish
                    ? 'El tiempo y los pasos completados se guardarán.'
                    : 'Your time and completed steps will still be saved.',
                style: const TextStyle(color: AppColors.tealSecondary),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('stress-reset-end-confirm'),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    _isSpanish ? 'Terminar y revisar' : 'End and review',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const ValueKey('stress-reset-end-cancel'),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    _isSpanish ? 'Seguir practicando' : 'Keep practicing',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) {
      return;
    }
    if (end == true) {
      widget.onComplete();
    } else {
      widget.onPausedChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 760;
    final horizontalPadding = size.width < 390 ? 16.0 : 20.0;

    return Scaffold(
      key: const ValueKey('functional-guided-stress-reset-screen'),
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
              child: _StressResetHeader(
                isSpanish: _isSpanish,
                voiceGuidanceEnabled: widget.voiceGuidanceEnabled,
                onClose: _showExitConfirmation,
                onVoiceChanged: widget.onVoiceGuidanceChanged,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _ExerciseProgress(
                stepNumber: _stepNumber,
                stepName: _stepName(widget.step),
                remainingTime: _remainingTime,
                progress: widget.totalElapsedSeconds / _totalDurationSeconds,
                isSpanish: _isSpanish,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('stress-reset-scroll'),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  8,
                  horizontalPadding,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ActiveExerciseCard(
                          isSpanish: _isSpanish,
                          step: widget.step,
                          stepElapsedSeconds: widget.stepElapsedSeconds,
                          isPaused: widget.isPaused,
                          voiceGuidanceEnabled: widget.voiceGuidanceEnabled,
                          reducedMotionEnabled: widget.reducedMotionEnabled,
                          onPauseChanged: widget.onPausedChanged,
                          onReducedMotionChanged: widget.onReducedMotionChanged,
                          onSkip: _advanceStep,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _isSpanish
                              ? 'Secuencia del ejercicio'
                              : 'Exercise sequence',
                          style: const TextStyle(
                            color: AppColors.deepTeal,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 9),
                        _ExerciseSequence(
                          isSpanish: _isSpanish,
                          currentStep: widget.step,
                          stepLabel: _stepLabel,
                          stepIcon: _stepIcon,
                        ),
                        const SizedBox(height: 16),
                        _RescueCard(
                          isSpanish: _isSpanish,
                          onTap: () {
                            widget.onPausedChanged(true);
                            widget.onOpenRescue();
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            key: const ValueKey('stress-reset-end'),
                            onPressed: _showEndConfirmation,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.deepTeal,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _isSpanish
                                  ? 'Terminar ejercicio'
                                  : 'End exercise',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isSpanish
                              ? 'El progreso parcial se guarda · Funciona sin conexión'
                              : 'Partial completion is saved · Works offline',
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
    );
  }
}

class _StressResetHeader extends StatelessWidget {
  const _StressResetHeader({
    required this.isSpanish,
    required this.voiceGuidanceEnabled,
    required this.onClose,
    required this.onVoiceChanged,
  });

  final bool isSpanish;
  final bool voiceGuidanceEnabled;
  final VoidCallback onClose;
  final ValueChanged<bool> onVoiceChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('stress-reset-close'),
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
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            toggled: voiceGuidanceEnabled,
            label: isSpanish ? 'Guía de voz' : 'Voice guidance',
            child: InkWell(
              key: const ValueKey('stress-reset-voice'),
              borderRadius: BorderRadius.circular(99),
              onTap: () => onVoiceChanged(!voiceGuidanceEnabled),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  color:
                      voiceGuidanceEnabled ? AppColors.mint : AppColors.paper,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      voiceGuidanceEnabled
                          ? Icons.volume_up_outlined
                          : Icons.volume_off_outlined,
                      color: AppColors.deepTeal,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      voiceGuidanceEnabled
                          ? (isSpanish ? 'VOZ SÍ' : 'VOICE ON')
                          : (isSpanish ? 'VOZ NO' : 'VOICE OFF'),
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseProgress extends StatelessWidget {
  const _ExerciseProgress({
    required this.stepNumber,
    required this.stepName,
    required this.remainingTime,
    required this.progress,
    required this.isSpanish,
  });

  final int stepNumber;
  final String stepName;
  final String remainingTime;
  final double progress;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${isSpanish ? 'PASO' : 'STEP'} $stepNumber ${isSpanish ? 'DE' : 'OF'} 3 · $stepName',
                key: const ValueKey('stress-reset-step-label'),
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$remainingTime ${isSpanish ? 'RESTANTES' : 'LEFT'}',
              key: const ValueKey('stress-reset-time-left'),
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: progress.clamp(0.0, 1.0).toDouble(),
            backgroundColor: const Color(0xFFDDE9E4),
            color: AppColors.coral,
          ),
        ),
      ],
    );
  }
}

class _ActiveExerciseCard extends StatelessWidget {
  const _ActiveExerciseCard({
    required this.isSpanish,
    required this.step,
    required this.stepElapsedSeconds,
    required this.isPaused,
    required this.voiceGuidanceEnabled,
    required this.reducedMotionEnabled,
    required this.onPauseChanged,
    required this.onReducedMotionChanged,
    required this.onSkip,
  });

  final bool isSpanish;
  final StressResetStep step;
  final int stepElapsedSeconds;
  final bool isPaused;
  final bool voiceGuidanceEnabled;
  final bool reducedMotionEnabled;
  final ValueChanged<bool> onPauseChanged;
  final ValueChanged<bool> onReducedMotionChanged;
  final VoidCallback onSkip;

  int get _breathNumber => math.min(10, (stepElapsedSeconds ~/ 8) + 1).toInt();

  bool get _isInhale => (stepElapsedSeconds % 8) < 4;

  int get _breathCountdown {
    final cycleSecond = stepElapsedSeconds % 8;
    return _isInhale ? 4 - cycleSecond : 8 - cycleSecond;
  }

  int get _stepCountdown {
    final duration = switch (step) {
      StressResetStep.breathe => 80,
      StressResetStep.water => 30,
      StressResetStep.switchActivity => 70,
    };
    return math.max(0, duration - stepElapsedSeconds).toInt();
  }

  String get _eyebrow => switch (step) {
        StressResetStep.breathe =>
          isSpanish ? 'RESPIRACIÓN LENTA' : 'SLOW BREATHING',
        StressResetStep.water => isSpanish ? 'PAUSA CON AGUA' : 'WATER BREAK',
        StressResetStep.switchActivity =>
          isSpanish ? 'CAMBIA LA ACTIVIDAD' : 'SWITCH ACTIVITIES',
      };

  String get _title => switch (step) {
        StressResetStep.breathe =>
          '${isSpanish ? 'Respiración' : 'Breath'} $_breathNumber ${isSpanish ? 'de' : 'of'} 10',
        StressResetStep.water =>
          isSpanish ? 'Bebe un vaso de agua' : 'Drink a glass of water',
        StressResetStep.switchActivity => isSpanish
            ? 'Cambia lo que estás haciendo'
            : 'Switch what you are doing',
      };

  String get _instruction => switch (step) {
        StressResetStep.breathe => _isInhale
            ? (isSpanish
                ? 'Inhala lentamente por la nariz.'
                : 'Slowly breathe in through your nose.')
            : (isSpanish
                ? 'Exhala lentamente por la boca.'
                : 'Slowly breathe out through your mouth.'),
        StressResetStep.water => isSpanish
            ? 'Bebe despacio y nota la temperatura.'
            : 'Sip slowly and notice the temperature.',
        StressResetStep.switchActivity => isSpanish
            ? 'Camina, pon música o comienza una tarea breve.'
            : 'Walk, play music, or start one quick task.',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.deepTeal,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x23123C37),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _eyebrow,
            style: const TextStyle(
              color: AppColors.mintStrong,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _title,
            key: const ValueKey('stress-reset-active-title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _ExerciseVisual(
            isSpanish: isSpanish,
            step: step,
            isInhale: _isInhale,
            countdown: step == StressResetStep.breathe
                ? _breathCountdown
                : _stepCountdown,
            reducedMotionEnabled: reducedMotionEnabled,
          ),
          const SizedBox(height: 15),
          Text(
            _instruction,
            key: const ValueKey('stress-reset-instruction'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSpanish
                ? 'Sigue el círculo, escucha o usa la cuenta regresiva.'
                : 'Follow the circle, listen, or use the countdown.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mintStrong,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreferenceChip(
                icon: voiceGuidanceEnabled
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
                label: voiceGuidanceEnabled
                    ? (isSpanish ? 'Guía de voz activa' : 'Voice guidance on')
                    : (isSpanish
                        ? 'Guía de voz desactivada'
                        : 'Voice guidance off'),
              ),
              InkWell(
                key: const ValueKey('stress-reset-motion'),
                onTap: () => onReducedMotionChanged(!reducedMotionEnabled),
                borderRadius: BorderRadius.circular(99),
                child: _PreferenceChip(
                  icon: reducedMotionEnabled
                      ? Icons.check_rounded
                      : Icons.motion_photos_on_outlined,
                  label: reducedMotionEnabled
                      ? (isSpanish
                          ? 'Movimiento reducido activo'
                          : 'Reduced motion on')
                      : (isSpanish
                          ? 'Movimiento completo activo'
                          : 'Full motion on'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0x55718A84), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    key: const ValueKey('stress-reset-pause'),
                    onPressed: () => onPauseChanged(!isPaused),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: AppColors.deepTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: Icon(
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    ),
                    label: Text(
                      isPaused
                          ? (isSpanish ? 'Reanudar' : 'Resume exercise')
                          : (isSpanish ? 'Pausar' : 'Pause exercise'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    key: const ValueKey('stress-reset-skip'),
                    onPressed: onSkip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.mutedTeal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      step == StressResetStep.switchActivity
                          ? (isSpanish ? 'Finalizar' : 'Finish')
                          : (isSpanish ? 'Omitir paso' : 'Skip step'),
                      textAlign: TextAlign.center,
                    ),
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

class _ExerciseVisual extends StatelessWidget {
  const _ExerciseVisual({
    required this.isSpanish,
    required this.step,
    required this.isInhale,
    required this.countdown,
    required this.reducedMotionEnabled,
  });

  final bool isSpanish;
  final StressResetStep step;
  final bool isInhale;
  final int countdown;
  final bool reducedMotionEnabled;

  @override
  Widget build(BuildContext context) {
    final isBreathing = step == StressResetStep.breathe;
    final icon = switch (step) {
      StressResetStep.breathe => Icons.air_rounded,
      StressResetStep.water => Icons.local_drink_outlined,
      StressResetStep.switchActivity => Icons.swap_horiz_rounded,
    };
    final label = switch (step) {
      StressResetStep.breathe => isInhale
          ? (isSpanish ? 'INHALA' : 'BREATHE IN')
          : (isSpanish ? 'EXHALA' : 'BREATHE OUT'),
      StressResetStep.water => isSpanish ? 'BEBE AGUA' : 'DRINK WATER',
      StressResetStep.switchActivity => isSpanish ? 'CAMBIA' : 'SWITCH',
    };

    return AnimatedContainer(
      key: const ValueKey('stress-reset-visual'),
      duration: reducedMotionEnabled
          ? Duration.zero
          : const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      width: isBreathing && isInhale ? 194 : 176,
      height: isBreathing && isInhale ? 194 : 176,
      decoration: BoxDecoration(
        color: AppColors.lime,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x66718A84), width: 12),
        boxShadow: const [
          BoxShadow(color: Color(0x66D5EF75), blurRadius: 24),
        ],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.deepTeal, size: 28),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 17,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$countdown',
                key: const ValueKey('stress-reset-countdown'),
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 42,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                isSpanish ? 'SEGUNDOS' : 'SECONDS',
                style: const TextStyle(
                  color: AppColors.tealSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF234F49),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.mutedTeal),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.lime, size: 18),
          const SizedBox(width: 7),
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

class _ExerciseSequence extends StatelessWidget {
  const _ExerciseSequence({
    required this.isSpanish,
    required this.currentStep,
    required this.stepLabel,
    required this.stepIcon,
  });

  final bool isSpanish;
  final StressResetStep currentStep;
  final String Function(StressResetStep step) stepLabel;
  final IconData Function(StressResetStep step) stepIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x0D123C37), blurRadius: 16),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final step in StressResetStep.values) ...[
                Expanded(
                  child: _SequenceItem(
                    key: ValueKey('stress-reset-sequence-${step.name}'),
                    icon: stepIcon(step),
                    label: stepLabel(step),
                    status: step.index < currentStep.index
                        ? (isSpanish ? 'HECHO' : 'DONE')
                        : step == currentStep
                            ? (isSpanish ? 'AHORA' : 'NOW')
                            : (isSpanish ? 'SIGUE' : 'NEXT'),
                    active: step == currentStep,
                    completed: step.index < currentStep.index,
                  ),
                ),
                if (step != StressResetStep.switchActivity)
                  Container(
                    width: 22,
                    height: 3,
                    color: step.index < currentStep.index
                        ? AppColors.deepTeal
                        : const Color(0xFFDDE9E4),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4F0),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              isSpanish
                  ? 'El temporizador se pausa automáticamente al salir.'
                  : 'The timer pauses automatically if you leave this screen.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SequenceItem extends StatelessWidget {
  const _SequenceItem({
    required this.icon,
    required this.label,
    required this.status,
    required this.active,
    required this.completed,
    super.key,
  });

  final IconData icon;
  final String label;
  final String status;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: active || completed
              ? AppColors.deepTeal
              : const Color(0xFFE7F1ED),
          foregroundColor:
              active || completed ? AppColors.lime : AppColors.mutedTeal,
          child: Icon(completed ? Icons.check_rounded : icon),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.deepTeal,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: active ? AppColors.coral : AppColors.mutedTeal,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RescueCard extends StatelessWidget {
  const _RescueCard({required this.isSpanish, required this.onTap});

  final bool isSpanish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('stress-reset-rescue'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.coralLight,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFFFB19E)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              child: Icon(Icons.waves_rounded, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isSpanish
                    ? '¿El antojo está aumentando?'
                    : 'Craving getting stronger?',
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              isSpanish ? 'Abrir Rescate' : 'Open Rescue',
              style: const TextStyle(
                color: AppColors.coral,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.coral),
          ],
        ),
      ),
    );
  }
}
