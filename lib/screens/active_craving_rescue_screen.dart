import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../theme/app_colors.dart';
import 'recommended_rescue_tool_screen.dart';

class ActiveCravingRescueScreen extends StatefulWidget {
  const ActiveCravingRescueScreen({
    super.key,
    required this.isSpanish,
    required this.tool,
    required this.elapsedSeconds,
    required this.isPaused,
    required this.voiceEnabled,
    required this.hapticsEnabled,
    required this.onElapsedChanged,
    required this.onPausedChanged,
    required this.onVoiceChanged,
    required this.onHapticsChanged,
    required this.onClose,
    required this.onComplete,
    required this.onSwitchTool,
    required this.onOpenSupport,
  });

  final bool isSpanish;
  final RescueTool tool;
  final int elapsedSeconds;
  final bool isPaused;
  final bool voiceEnabled;
  final bool hapticsEnabled;

  final ValueChanged<int> onElapsedChanged;
  final ValueChanged<bool> onPausedChanged;
  final ValueChanged<bool> onVoiceChanged;
  final ValueChanged<bool> onHapticsChanged;

  final VoidCallback onClose;
  final VoidCallback onComplete;
  final VoidCallback onSwitchTool;
  final VoidCallback onOpenSupport;

  @override
  State<ActiveCravingRescueScreen> createState() =>
      _ActiveCravingRescueScreenState();
}

class _ActiveCravingRescueScreenState extends State<ActiveCravingRescueScreen> {
  int get _durationSeconds =>
    widget.tool == RescueTool.move ? 180 : 120;

  Timer? _timer;
  late final FlutterTts _tts;

  bool get _isSpanish => widget.isSpanish;

  bool get _isInhale => (widget.elapsedSeconds % 10) < 4;

  int get _cycleSecond => widget.elapsedSeconds % 10;

  int get _phaseCountdown {
    if (_isInhale) {
      return 4 - _cycleSecond;
    }
    return 10 - _cycleSecond;
  }

  int get _remainingSeconds =>
      math.max(0, _durationSeconds - widget.elapsedSeconds).toInt();

  double get _overallProgress =>
      (widget.elapsedSeconds / _durationSeconds).clamp(0.0, 1.0);

  double get _breathProgress {
    if (_isInhale) {
      return (_cycleSecond / 4).clamp(0.0, 1.0);
    }
    return ((_cycleSecond - 4) / 6).clamp(0.0, 1.0);
  }

  String get _remainingLabel {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    unawaited(_configureTts());
    _syncTimer();

    if (widget.voiceEnabled && widget.tool == RescueTool.slowBreathing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_speakCurrentCue());
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant ActiveCravingRescueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isPaused != widget.isPaused) {
      _syncTimer();

      if (widget.isPaused) {
        unawaited(_stopSpeech());
      } else if (widget.voiceEnabled &&
          widget.tool == RescueTool.slowBreathing) {
        unawaited(_speakCurrentCue());
      }
    }

    if (oldWidget.voiceEnabled != widget.voiceEnabled) {
      if (!widget.voiceEnabled) {
        unawaited(_stopSpeech());
      } else if (!widget.isPaused && widget.tool == RescueTool.slowBreathing) {
        unawaited(_speakCurrentCue());
      }
    }

    final oldPhase = (oldWidget.elapsedSeconds % 10) < 4;
    final newPhase = (widget.elapsedSeconds % 10) < 4;

    if (oldPhase != newPhase &&
        widget.tool == RescueTool.slowBreathing &&
        !widget.isPaused) {
      if (widget.voiceEnabled) {
        unawaited(_speakCurrentCue());
      }

      if (widget.hapticsEnabled) {
        unawaited(HapticFeedback.lightImpact());
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_stopSpeech());
    super.dispose();
  }

Future<void> _configureTts() async {
  try {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
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

    await _tts.setLanguage(_isSpanish ? 'es-US' : 'en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    
  } catch (e) {
    debugPrint('TTS configuration unavailable: $e');
  }
}

 Future<void> _speakCurrentCue() async {
  if (!widget.voiceEnabled || widget.isPaused) {
    return;
  }

  String message;

  if (widget.tool == RescueTool.slowBreathing) {
    message = _isInhale
        ? (_isSpanish ? 'Inhala lentamente' : 'Breathe in slowly')
        : (_isSpanish ? 'Exhala lentamente' : 'Breathe out slowly');
  } else if (widget.tool == RescueTool.move) {
    final elapsed = widget.elapsedSeconds;

    if (elapsed == 0) {
      message = _isSpanish ? 'Empieza a moverte' : 'Start moving';
    } else if (elapsed == 120) {
      message = _isSpanish ? 'Te queda un minuto' : 'One minute left';
    } else if (elapsed == 150) {
      message =
          _isSpanish ? 'Te quedan treinta segundos' : 'Thirty seconds left';
    } else if (elapsed == 170) {
      message = _isSpanish ? 'Diez segundos más' : 'Ten seconds left';
    } else if (elapsed >= 180) {
      message = _isSpanish
          ? 'Muy bien. Completaste tres minutos.'
          : 'Great job. You completed three minutes.';
    } else if (elapsed % 30 == 0) {
      message = _isSpanish ? 'Sigue moviéndote' : 'Keep moving';
    } else {
      return;
    }
  } else {
    return;
  }

  try {
    
    await _tts.speak(message);
  } catch (_) {
    // Keep the exercise usable if speech is unavailable.
  }

  
  }

  Future<void> _stopSpeech() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore optional speech errors.
    }
  }

 void _syncTimer() {
  _timer?.cancel();

  if (widget.isPaused || widget.elapsedSeconds >= _durationSeconds) {
    return;
  }

  _timer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (!mounted || widget.isPaused) {
      return;
    }

    final next = math.min(
      _durationSeconds,
      widget.elapsedSeconds + 1,
    );

 

    if (widget.tool == RescueTool.move &&
        widget.voiceEnabled &&
        (next == 30 ||
            next == 60 ||
            next == 90 ||
            next == 120 ||
            next == 150 ||
            next == 170)) {
      unawaited(_speakMovementCue(next));
    }
    widget.onElapsedChanged(next);
    if (widget.tool == RescueTool.changeScene &&
    widget.voiceEnabled &&
    (next == 30 || next == 60 || next == 90)) {
  unawaited(_speakChangeSceneCue(next));
}
    if (next >= _durationSeconds) {
      _timer?.cancel();

      if (widget.tool == RescueTool.move && widget.voiceEnabled) {
        unawaited(_speakMovementCue(next));
      }

      widget.onComplete();
    }
  });
}

Future<void> _speakMovementCue(int elapsed) async {
  

  if (!widget.voiceEnabled || widget.isPaused) {
    return;
  }

  String message;

  switch (elapsed) {
    case 30:
    case 60:
    case 90:
      message = _isSpanish ? 'Sigue moviéndote' : 'Keep moving';
      break;

    case 120:
      message = _isSpanish ? 'Te queda un minuto' : 'One minute left';
      break;

    case 150:
      message = _isSpanish
          ? 'Te quedan treinta segundos'
          : 'Thirty seconds left';
      break;

    case 170:
      message = _isSpanish ? 'Diez segundos más' : 'Ten seconds left';
      break;

    case 180:
      message = _isSpanish
          ? 'Muy bien. Completaste tres minutos.'
          : 'Great job. You completed three minutes.';
      break;

    default:
      return;
  }

  try {
    

    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(message);

    
  } catch (e) {
    debugPrint('Movement voice unavailable: $e');
  }
}
Future<void> _speakChangeSceneCue(int elapsed) async {
  if (!widget.voiceEnabled || widget.isPaused) {
    return;
  }

  String message;

  switch (elapsed) {
    case 30:
      message = _isSpanish
          ? 'Sigue moviéndote a un lugar sin humo.'
          : 'Keep moving to a smoke-free place.';
      break;
    case 60:
      message = _isSpanish
          ? 'Ya estás a la mitad. Sigue adelante.'
          : 'You are halfway there. Keep going.';
      break;
    case 90:
      message = _isSpanish
          ? 'Sigue adelante. Estás haciendo un cambio positivo.'
          : 'Keep going. You are making a positive change.';
      break;
    case 120:
      message = _isSpanish
          ? 'Muy bien. Has cambiado de entorno.'
          : 'Great job. You changed your surroundings.';
      break;
    default:
      return;
  }

  try {
    await _tts.stop();
    await _tts.speak(message);
  } catch (_) {
    // Keep the exercise usable if speech is unavailable.
  }
}

  Future<void> _showCloseConfirmation() async {
    widget.onPausedChanged(true);

    final leave = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSpanish ? '¿Salir del ejercicio?' : 'Leave this exercise?',
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSpanish
                  ? 'Tu progreso se mantendrá para que puedas volver.'
                  : 'Your progress will be kept so you can return.',
              style: const TextStyle(
                color: AppColors.tealSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('active-rescue-close-stay'),
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  _isSpanish ? 'Seguir respirando' : 'Keep breathing',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const ValueKey('active-rescue-close-leave'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  _isSpanish ? 'Guardar y salir' : 'Save and leave',
                ),
              ),
            ),
          ],
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
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
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
                  ? 'A continuación podrás volver a calificar el antojo.'
                  : 'You can rate the craving again next.',
              style: const TextStyle(
                color: AppColors.tealSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('active-rescue-end-confirm'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  _isSpanish ? 'Terminar y revisar' : 'End and recheck',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const ValueKey('active-rescue-end-cancel'),
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  _isSpanish ? 'Seguir practicando' : 'Keep practicing',
                ),
              ),
            ),
          ],
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
      key: const ValueKey('functional-active-craving-rescue-screen'),
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
              child: _Header(
                isSpanish: _isSpanish,
                onClose: _showCloseConfirmation,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _ProgressHeader(
                progress: 0.6,
                isSpanish: _isSpanish,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('active-rescue-scroll'),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  8,
                  horizontalPadding,
                  26,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isSpanish
                              ? 'Quédate con este momento.'
                              : 'Stay with this moment.',
                          style: TextStyle(
                            color: AppColors.deepTeal,
                            fontSize: compact ? 25 : 29,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _isSpanish
                              ? 'Sigue el círculo o respira lentamente a tu manera.'
                              : 'Follow the circle—or breathe slowly in your own way.',
                          style: const TextStyle(
                            color: AppColors.tealSecondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (widget.tool == RescueTool.slowBreathing)
  _BreathingCard(
    isSpanish: _isSpanish,
    remainingLabel: _remainingLabel,
    isInhale: _isInhale,
    phaseCountdown: _phaseCountdown,
    breathProgress: _breathProgress,
    overallProgress: _overallProgress,
    paused: widget.isPaused,
    voiceEnabled: widget.voiceEnabled,
    hapticsEnabled: widget.hapticsEnabled,
    onPausedChanged: widget.onPausedChanged,
    onVoiceChanged: widget.onVoiceChanged,
    onHapticsChanged: widget.onHapticsChanged,
  )
else if (widget.tool == RescueTool.move)
  _MovementCard(
    isSpanish: _isSpanish,
    remainingLabel: _remainingLabel,
    overallProgress: _overallProgress,
    paused: widget.isPaused,
    voiceEnabled: widget.voiceEnabled,
    hapticsEnabled: widget.hapticsEnabled,
    onPausedChanged: widget.onPausedChanged,
    onVoiceChanged: widget.onVoiceChanged,
    onHapticsChanged: widget.onHapticsChanged,
  )
else
  _ChangeSceneCard(
    isSpanish: _isSpanish,
    remainingLabel: _remainingLabel,
    overallProgress: _overallProgress,
    paused: widget.isPaused,
    voiceEnabled: widget.voiceEnabled,
    hapticsEnabled: widget.hapticsEnabled,
    onPausedChanged: widget.onPausedChanged,
    onVoiceChanged: widget.onVoiceChanged,
    onHapticsChanged: widget.onHapticsChanged,
  ),
                        const SizedBox(height: 16),
                        _EncouragementCard(isSpanish: _isSpanish),
                        const SizedBox(height: 16),
                        _AlternateSupportCard(
                          isSpanish: _isSpanish,
                          onSwitchTool: () {
                            widget.onPausedChanged(true);
                            widget.onSwitchTool();
                          },
                          onOpenSupport: () {
                            widget.onPausedChanged(true);
                            widget.onOpenSupport();
                          },
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          key: const ValueKey('active-rescue-end'),
                          onPressed: _showEndConfirmation,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.deepTeal,
                            side: const BorderSide(color: AppColors.border),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _isSpanish ? 'Terminar ejercicio' : 'End exercise',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.deepTeal,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _isSpanish
                                      ? 'No se envían ni comparten datos durante este ejercicio.\nContenido v1.0'
                                      : 'No data is being sent or shared during this exercise.\nContent v1.0',
                                  style: const TextStyle(
                                    color: AppColors.tealSecondary,
                                    fontSize: 11.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isSpanish
                              ? 'Después de 2 minutos, volverás a calificar el antojo'
                              : 'After 2 minutes, you’ll rate the craving again',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.tealSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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

class _Header extends StatelessWidget {
  const _Header({
    required this.isSpanish,
    required this.onClose,
  });

  final bool isSpanish;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: const ValueKey('active-rescue-close'),
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              color: AppColors.deepTeal,
              tooltip: isSpanish ? 'Cerrar' : 'Close',
            ),
          ),
          const Text(
            'Craving Rescue',
            style: TextStyle(
              color: AppColors.deepTeal,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                isSpanish ? '3 DE 5' : '3 OF 5',
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.progress,
    required this.isSpanish,
  });

  final double progress;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('active-rescue-progress'),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isSpanish ? 'HERRAMIENTA ACTIVA' : 'ACTIVE TOOL',
                style: const TextStyle(
                  color: AppColors.tealSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const Text(
              '60%',
              style: TextStyle(
                color: AppColors.deepTeal,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: progress,
            backgroundColor: AppColors.mint,
            valueColor: const AlwaysStoppedAnimation(AppColors.coral),
          ),
        ),
      ],
    );
  }
}

class _BreathingCard extends StatelessWidget {
  const _BreathingCard({
    required this.isSpanish,
    required this.remainingLabel,
    required this.isInhale,
    required this.phaseCountdown,
    required this.breathProgress,
    required this.overallProgress,
    required this.paused,
    required this.voiceEnabled,
    required this.hapticsEnabled,
    required this.onPausedChanged,
    required this.onVoiceChanged,
    required this.onHapticsChanged,
  });

  final bool isSpanish;
  final String remainingLabel;
  final bool isInhale;
  final int phaseCountdown;
  final double breathProgress;
  final double overallProgress;
  final bool paused;
  final bool voiceEnabled;
  final bool hapticsEnabled;

  final ValueChanged<bool> onPausedChanged;
  final ValueChanged<bool> onVoiceChanged;
  final ValueChanged<bool> onHapticsChanged;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Container(
      key: const ValueKey('active-rescue-breathing-card'),
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 17),
      decoration: BoxDecoration(
        color: AppColors.deepTeal,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26123C37),
            blurRadius: 24,
            offset: Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF234F49),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.mutedTeal),
                ),
                child: Text(
                  isSpanish ? 'RESPIRACIÓN LENTA' : 'SLOW BREATHING',
                  style: const TextStyle(
                    color: AppColors.mintStrong,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF234F49),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$remainingLabel ${isSpanish ? 'REST.' : 'LEFT'}',
                  key: const ValueKey('active-rescue-time-left'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          AnimatedContainer(
            key: const ValueKey('active-rescue-breath-circle'),
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            width: isInhale ? 194 : 176,
            height: isInhale ? 194 : 176,
            decoration: BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0x55718A84),
                width: 12,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66D5EF75),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isInhale
                        ? (isSpanish ? 'INHALA' : 'BREATHE IN')
                        : (isSpanish ? 'EXHALA' : 'BREATHE OUT'),
                    key: const ValueKey('active-rescue-phase'),
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 16,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSpanish ? 'Lentamente' : 'Slowly',
                    style: const TextStyle(
                      color: AppColors.tealSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$phaseCountdown',
                    key: const ValueKey('active-rescue-countdown'),
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 44,
                      height: .95,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isSpanish ? 'SEGUNDOS' : 'SECONDS',
                    style: const TextStyle(
                      color: AppColors.tealSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isInhale
                ? (isSpanish
                    ? 'Deja que el aire entre suavemente.'
                    : 'Let the breath come in gently.')
                : (isSpanish
                    ? 'Deja que los hombros se relajen al exhalar.'
                    : 'Let your shoulders soften as you exhale.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                isSpanish ? 'ESTA RESPIRACIÓN' : 'THIS BREATH',
                style: const TextStyle(
                  color: AppColors.mintStrong,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              const Text(
                'In 4 · Out 6',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              key: const ValueKey('active-rescue-breath-progress'),
              minHeight: 5,
              value: breathProgress,
              backgroundColor: const Color(0xFF315C55),
              valueColor: const AlwaysStoppedAnimation(AppColors.lime),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  isSpanish ? 'Inhala suavemente' : 'Inhale gently',
                  style: const TextStyle(
                    color: AppColors.mintStrong,
                    fontSize: 10,
                  ),
                ),
              ),
              Text(
                isSpanish ? 'Exhala lentamente' : 'Exhale slowly',
                style: const TextStyle(
                  color: AppColors.mintStrong,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  key: const ValueKey('active-rescue-pause'),
                  icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  label: paused
                      ? (isSpanish ? 'Reanudar' : 'Resume')
                      : (isSpanish ? 'Pausar' : 'Pause'),
                  active: true,
                  onTap: () => onPausedChanged(!paused),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ControlButton(
                  key: const ValueKey('active-rescue-voice'),
                  icon: voiceEnabled
                      ? Icons.volume_up_outlined
                      : Icons.volume_off_outlined,
                  label: '${isSpanish ? 'Voz' : 'Voice'}\n'
                      '${voiceEnabled ? (isSpanish ? 'Sí' : 'On') : (isSpanish ? 'No' : 'Off')}',
                  active: voiceEnabled,
                  onTap: () => onVoiceChanged(!voiceEnabled),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ControlButton(
                  key: const ValueKey('active-rescue-haptics'),
                  icon: Icons.vibration_rounded,
                  label: '${isSpanish ? 'Hápticos' : 'Haptics'}\n'
                      '${hapticsEnabled ? (isSpanish ? 'Sí' : 'On') : (isSpanish ? 'No' : 'Off')}',
                  active: hapticsEnabled,
                  onTap: () => onHapticsChanged(!hapticsEnabled),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(
            height: 1,
            color: Color(0x55718A84),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.motion_photos_off_outlined,
                color: AppColors.mintStrong,
                size: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  isSpanish
                      ? 'Movimiento reducido sigue la configuración del teléfono'
                      : 'Reduced motion follows your phone setting',
                  style: const TextStyle(
                    color: AppColors.mintStrong,
                    fontSize: 9.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.offline_bolt_outlined,
                color: AppColors.lime,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isSpanish ? 'Sin conexión' : 'Works offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            minHeight: 2,
            value: overallProgress,
            backgroundColor: const Color(0xFF315C55),
            valueColor: const AlwaysStoppedAnimation(AppColors.coral),
          ),
        ],
      ),
    );
  }
}
class _MovementCard extends StatelessWidget {
  const _MovementCard({
    required this.isSpanish,
    required this.remainingLabel,
    required this.overallProgress,
    required this.paused,
    required this.voiceEnabled,
    required this.hapticsEnabled,
    required this.onPausedChanged,
    required this.onVoiceChanged,
    required this.onHapticsChanged,
  });

  final bool isSpanish;
  final String remainingLabel;
  final double overallProgress;
  final bool paused;
  final bool voiceEnabled;
  final bool hapticsEnabled;
  final ValueChanged<bool> onPausedChanged;
  final ValueChanged<bool> onVoiceChanged;
  final ValueChanged<bool> onHapticsChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('active-rescue-movement-card'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF234F49),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26123C37),
            blurRadius: 24,
            offset: Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF315C55),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isSpanish ? 'MOVIMIENTO' : 'MOVEMENT',
                  style: const TextStyle(
                    color: AppColors.mintStrong,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$remainingLabel ${isSpanish ? 'RESTANTE' : 'LEFT'}',
                key: const ValueKey('active-rescue-time-left'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: 178,
            height: 178,
            decoration: BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0x55718A84),
                width: 10,
              ),
            ),
            child: const Center(
               child: Icon(
                Icons.directions_walk_rounded,
                size: 72,
                color: AppColors.deepTeal,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSpanish ? 'MUÉVETE' : 'KEEP MOVING',
            key: const ValueKey('active-rescue-phase'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isSpanish
                ? 'Camina, estírate o muévete suavemente.'
                : 'Walk, stretch, or move gently.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mintStrong,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            key: const ValueKey('active-rescue-progress'),
            minHeight: 5,
            value: overallProgress,
            backgroundColor: const Color(0xFF315C55),
            valueColor: const AlwaysStoppedAnimation(AppColors.lime),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  key: const ValueKey('active-rescue-pause'),
                  icon: paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  label: paused
                      ? (isSpanish ? 'Reanudar' : 'Resume')
                      : (isSpanish ? 'Pausar' : 'Pause'),
                  active: paused,
                  onTap: () => onPausedChanged(!paused),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ControlButton(
                  key: const ValueKey('active-rescue-voice'),
                  icon: voiceEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  label: voiceEnabled
                      ? (isSpanish ? 'Voz ON' : 'Voice ON')
                      : (isSpanish ? 'Voz OFF' : 'Voice OFF'),
                  active: voiceEnabled,
                  onTap: () => onVoiceChanged(!voiceEnabled),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ControlButton(
                  key: const ValueKey('active-rescue-haptics'),
                  icon: hapticsEnabled
                      ? Icons.vibration_rounded
                      : Icons.smartphone_rounded,
                  label: hapticsEnabled
                      ? (isSpanish ? 'Hápticos ON' : 'Haptics ON')
                      : (isSpanish ? 'Hápticos OFF' : 'Haptics OFF'),
                  active: hapticsEnabled,
                  onTap: () => onHapticsChanged(!hapticsEnabled),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeSceneCard extends StatelessWidget {
  const _ChangeSceneCard({
    required this.isSpanish,
    required this.remainingLabel,
    required this.overallProgress,
    required this.paused,
    required this.voiceEnabled,
    required this.hapticsEnabled,
    required this.onPausedChanged,
    required this.onVoiceChanged,
    required this.onHapticsChanged,
  });

  final bool isSpanish;
  final String remainingLabel;
  final double overallProgress;
  final bool paused;
  final bool voiceEnabled;
  final bool hapticsEnabled;
  final ValueChanged<bool> onPausedChanged;
  final ValueChanged<bool> onVoiceChanged;
  final ValueChanged<bool> onHapticsChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('active-rescue-change-scene-card'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF234F49),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26123C37),
            blurRadius: 24,
            offset: Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF315C55),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isSpanish ? 'CAMBIA DE ENTORNO' : 'CHANGE THE SCENE',
                  style: const TextStyle(
                    color: AppColors.mintStrong,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$remainingLabel ${isSpanish ? 'RESTANTE' : 'LEFT'}',
                key: const ValueKey('active-rescue-time-left'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            width: 178,
            height: 178,
            decoration: BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0x55718A84),
                width: 10,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.swap_horiz_rounded,
                size: 72,
                color: AppColors.deepTeal,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            isSpanish ? 'CAMBIA EL ENTORNO' : 'CHANGE YOUR SURROUNDINGS',
            key: const ValueKey('active-rescue-phase'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSpanish
                ? 'Ve a otro lugar sin humo y cambia lo que estás haciendo.'
                : 'Go somewhere smoke-free and change what you are doing.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mintStrong,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            key: const ValueKey('active-rescue-progress'),
            minHeight: 5,
            value: overallProgress,
            backgroundColor: const Color(0xFF315C55),
            valueColor: const AlwaysStoppedAnimation(AppColors.lime),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  key: const ValueKey('active-rescue-pause'),
                  icon: paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  label: paused
                      ? (isSpanish ? 'Reanudar' : 'Resume')
                      : (isSpanish ? 'Pausar' : 'Pause'),
                  active: paused,
                  onTap: () => onPausedChanged(!paused),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ControlButton(
                  key: const ValueKey('active-rescue-voice'),
                  icon: voiceEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  label: voiceEnabled
                      ? (isSpanish ? 'Voz ON' : 'Voice ON')
                      : (isSpanish ? 'Voz OFF' : 'Voice OFF'),
                  active: voiceEnabled,
                  onTap: () => onVoiceChanged(!voiceEnabled),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ControlButton(
                  key: const ValueKey('active-rescue-haptics'),
                  icon: hapticsEnabled
                      ? Icons.vibration_rounded
                      : Icons.smartphone_rounded,
                  label: hapticsEnabled
                      ? (isSpanish ? 'Hápticos ON' : 'Haptics ON')
                      : (isSpanish ? 'Hápticos OFF' : 'Haptics OFF'),
                  active: hapticsEnabled,
                  onTap: () => onHapticsChanged(!hapticsEnabled),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.lime : const Color(0xFF234F49),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: active ? AppColors.lime : AppColors.mutedTeal,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: active ? AppColors.deepTeal : Colors.white,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? AppColors.deepTeal : Colors.white,
                  fontSize: 10,
                  height: 1.1,
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

class _EncouragementCard extends StatelessWidget {
  const _EncouragementCard({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSpanish ? 'El antojo es una ola.' : 'The urge is a wave.',
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isSpanish
                ? 'Puedes dejar que suba y pase sin fumar.'
                : 'You can let it rise and pass without smoking.',
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isSpanish
                ? 'Solo necesitas quedarte con esta respiración, no resolver todo el día.'
                : 'You only need to stay with this breath—not solve the whole day.',
            style: const TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternateSupportCard extends StatelessWidget {
  const _AlternateSupportCard({
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
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSpanish
                ? '¿Necesitas otro tipo de apoyo ahora?'
                : 'Need different support right now?',
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSpanish
                ? 'Puedes cambiar de herramienta sin perder este registro.'
                : 'You can change tools without losing this check-in.',
            style: const TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('active-rescue-switch-tool'),
              onPressed: onSwitchTool,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(
                isSpanish ? 'Cambiar herramienta' : 'Switch coping tool',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('active-rescue-support'),
              onPressed: onOpenSupport,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: AppColors.deepTeal,
              ),
              icon: const Icon(Icons.people_outline_rounded),
              label: Text(
                isSpanish
                    ? 'Obtener apoyo de una persona'
                    : 'Get support from a person',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
