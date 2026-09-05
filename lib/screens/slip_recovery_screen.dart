import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Screen 23 — Slip Recovery.
///
/// Screen 23 is matched to the approved SVG using the same device-calibrated
/// typography approach as the previously approved Flutter screens. SVG geometry
/// remains the visual source of truth, while text sizes are calibrated by role
/// instead of dividing SVG font sizes by the device export scale.
class SlipRecoveryScreen extends StatefulWidget {
  const SlipRecoveryScreen({
    required this.isSpanish,
    required this.onClose,
    required this.onSave,
    required this.onOpenNextStep,
    required this.onOpenSupport,
    this.initiallySaved = false,
    super.key,
  });

  final bool isSpanish;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onOpenNextStep;
  final VoidCallback onOpenSupport;
  final bool initiallySaved;

  @override
  State<SlipRecoveryScreen> createState() => _SlipRecoveryScreenState();
}

class _SlipRecoveryScreenState extends State<SlipRecoveryScreen> {
  String _whatHappened = 'One cigarette';
  String _whenChoice = 'Just now';
  final Set<String> _triggers = <String>{'Stress'};
  String _recoveryChoice = 'Continue from this moment';
  late bool _saved;

  @override
  void initState() {
    super.initState();
    _saved = widget.initiallySaved;
  }

  @override
  void didUpdateWidget(covariant SlipRecoveryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallySaved != widget.initiallySaved) {
      _saved = widget.initiallySaved;
    }
  }

  static const List<String> _whatHappenedChoices = <String>[
    'A puff or two',
    'One cigarette',
    'More than one',
    'Prefer not to answer',
  ];

  static const List<String> _whenChoices = <String>[
    'Just now',
    'Earlier today',
    'Another day',
  ];

  static const List<String> _triggerChoices = <String>[
    'Stress',
    'Around smokers',
    'Routine',
    'Alcohol',
    'After a meal',
    'Not sure',
    'Something else',
  ];

  String _whatHappenedLabel(String value) {
    if (!widget.isSpanish) return value;
    switch (value) {
      case 'A puff or two':
        return 'Una o dos bocanadas';
      case 'One cigarette':
        return 'Un cigarrillo';
      case 'More than one':
        return 'Más de uno';
      case 'Prefer not to answer':
        return 'Prefiero no responder';
      default:
        return value;
    }
  }

  String _whenLabel(String value) {
    if (!widget.isSpanish) return value;
    switch (value) {
      case 'Just now':
        return 'Justo ahora';
      case 'Earlier today':
        return 'Hoy más temprano';
      case 'Another day':
        return 'Otro día';
      default:
        return value;
    }
  }

  String _triggerLabel(String value) {
    if (!widget.isSpanish) return value;
    switch (value) {
      case 'Stress':
        return 'Estrés';
      case 'Around smokers':
        return 'Cerca de fumadores';
      case 'Routine':
        return 'Rutina';
      case 'Alcohol':
        return 'Alcohol';
      case 'After a meal':
        return 'Después de comer';
      case 'Not sure':
        return 'No estoy seguro';
      case 'Something else':
        return 'Algo más';
      default:
        return value;
    }
  }

  String _recoveryLabel(String value) {
    if (!widget.isSpanish) return value;
    switch (value) {
      case 'Continue from this moment':
        return 'Continuar desde este momento';
      case 'Choose a new quit time':
        return 'Elegir una nueva hora para dejarlo';
      case 'Help me decide':
        return 'Ayúdame a decidir';
      default:
        return value;
    }
  }

  void _save() {
    if (_saved) return;
    setState(() => _saved = true);
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sx = math.min(1.0, constraints.maxWidth / 430.0);
            final contentWidth = 430.0 * sx;

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  children: [
                    _TopBar(
                      sx: sx,
                      isSpanish: widget.isSpanish,
                      onClose: widget.onClose,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey('slip-recovery-scroll'),
                        padding: EdgeInsets.fromLTRB(
                          24 * sx,
                          6,
                          24 * sx,
                          22,
                        ),
                        child: Column(
                          children: [
                            _ReassuranceCard(
                              sx: sx,
                              isSpanish: widget.isSpanish,
                            ),
                            const SizedBox(height: 14.5),
                            _WhatHappenedCard(
                              sx: sx,
                              isSpanish: widget.isSpanish,
                              selectedWhatHappened: _whatHappened,
                              selectedWhen: _whenChoice,
                              whatHappenedLabel: _whatHappenedLabel,
                              whenLabel: _whenLabel,
                              onWhatHappenedChanged: (value) {
                                setState(() => _whatHappened = value);
                              },
                              onWhenChanged: (value) {
                                setState(() => _whenChoice = value);
                              },
                            ),
                            const SizedBox(height: 14.3),
                            _TriggersCard(
                              sx: sx,
                              isSpanish: widget.isSpanish,
                              selected: _triggers,
                              label: _triggerLabel,
                              onChanged: (value) {
                                setState(() {
                                  if (_triggers.contains(value)) {
                                    _triggers.remove(value);
                                  } else {
                                    _triggers.add(value);
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 14.3),
                            _RecoveryChoiceCard(
                              sx: sx,
                              isSpanish: widget.isSpanish,
                              selected: _recoveryChoice,
                              label: _recoveryLabel,
                              onChanged: (value) {
                                setState(() => _recoveryChoice = value);
                              },
                            ),
                            const SizedBox(height: 14.3),
                            _NextStepCard(
                              sx: sx,
                              isSpanish: widget.isSpanish,
                              enabled: _saved,
                              onOpen: widget.onOpenNextStep,
                            ),
                            const SizedBox(height: 14.3),
                            _SupportCard(
                              sx: sx,
                              isSpanish: widget.isSpanish,
                              onTap: widget.onOpenSupport,
                            ),
                            const SizedBox(height: 14.7),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                key: const ValueKey('slip-recovery-save'),
                                onPressed: _saved ? null : _save,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.deepTeal,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.deepTeal,
                                  disabledForegroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
  child: FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      _saved
          ? (widget.isSpanish ? 'Guardado' : 'Saved')
          : (widget.isSpanish
              ? 'Guardar y comenzar la recuperación'
              : 'Save and start recovery'),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Arial',
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    ),
  ),
),
                                    if (!_saved) ...[
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: AppColors.lime,
                                        size: 17,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12.7),
                            _PrivacyNote(
                              sx: sx,
                              isSpanish: widget.isSpanish,
                            ),
                            const SizedBox(height: 11),
                            TextButton(
                              key: const ValueKey('slip-recovery-skip'),
                              onPressed: widget.onClose,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                widget.isSpanish
                                    ? 'Omitir por ahora y volver a Inicio'
                                    : 'Skip for now and return Home',
                                style: const TextStyle(
                                  fontFamily: 'Arial',
                                  color: AppColors.mutedTeal,
                                  fontSize: 11,
                                  height: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.sx,
    required this.isSpanish,
    required this.onClose,
  });

  final double sx;
  final bool isSpanish;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24 * sx, 8, 24 * sx, 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: SizedBox(
                width: 180 * sx,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isSpanish
                        ? 'Recuperación tras un desliz'
                        : 'Slip recovery',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      color: AppColors.deepTeal,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 25,
                height: 25,
                child: IconButton(
                  key: const ValueKey('slip-recovery-close'),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.border,
                      width: 0.8,
                    ),
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.deepTeal,
                    size: 17,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 100 * sx,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1EA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.deepTeal,
                      size: 11,
                    ),
                    SizedBox(width: 5 * sx),
                    Text(
                      isSpanish ? 'PRIVADO' : 'PRIVATE',
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        color: AppColors.tealSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReassuranceCard extends StatelessWidget {
  const _ReassuranceCard({
    required this.sx,
    required this.isSpanish,
  });

  final double sx;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 105,
      padding: EdgeInsets.symmetric(
        horizontal: 12 * sx,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE8F5ED),
            Color(0xFFC7E6D8),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFB9DCCB),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A123C37),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.paper,
                shape: BoxShape.circle,
              ),
              child: CustomPaint(
                painter: _SlipRecoveryIconPainter(),
              ),
            ),
          ),
          SizedBox(width: 12 * sx),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpanish
                      ? 'TU PROGRESO SIGUE AQUÍ'
                      : 'YOUR PROGRESS IS STILL HERE',
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    color: AppColors.mutedTeal,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isSpanish
                        ? 'Un desliz es información, no el final.'
                        : 'A slip is information—not the end.',
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      color: AppColors.deepTeal,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isSpanish
                        ? 'Comparte solo lo que te resulte útil. Te ayudaremos con la siguiente elección.'
                        : 'Share only what feels useful. We’ll help with the next choice.',
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      color: AppColors.tealSecondary,
                      fontSize: 13,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isSpanish
                        ? 'Nada de lo que aparece abajo cambia ni elimina tu progreso anterior.'
                        : 'Nothing below changes or deletes your earlier progress.',
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      color: AppColors.mutedTeal,
                      fontSize: 11,
                      height: 1,
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

class _WhatHappenedCard extends StatelessWidget {
  const _WhatHappenedCard({
    required this.sx,
    required this.isSpanish,
    required this.selectedWhatHappened,
    required this.selectedWhen,
    required this.whatHappenedLabel,
    required this.whenLabel,
    required this.onWhatHappenedChanged,
    required this.onWhenChanged,
  });

  final double sx;
  final bool isSpanish;
  final String selectedWhatHappened;
  final String selectedWhen;
  final String Function(String) whatHappenedLabel;
  final String Function(String) whenLabel;
  final ValueChanged<String> onWhatHappenedChanged;
  final ValueChanged<String> onWhenChanged;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      height: 168,
      sx: sx,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: isSpanish ? '¿Qué pasó?' : 'What happened?',
            trailing: isSpanish ? 'Elige uno' : 'Choose one',
          ),
          const SizedBox(height: 10.5),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = 14.67 * sx;
              final width = (constraints.maxWidth - gap) / 2;
              const values =
                  _SlipRecoveryScreenState._whatHappenedChoices;

              return Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: width,
                        child: _EventChoice(
                          label: whatHappenedLabel(values[0]),
                          selected: selectedWhatHappened == values[0],
                          onTap: () => onWhatHappenedChanged(values[0]),
                        ),
                      ),
                      SizedBox(width: gap),
                      SizedBox(
                        width: width,
                        child: _EventChoice(
                          label: whatHappenedLabel(values[1]),
                          selected: selectedWhatHappened == values[1],
                          onTap: () => onWhatHappenedChanged(values[1]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      SizedBox(
                        width: width,
                        child: _EventChoice(
                          label: whatHappenedLabel(values[2]),
                          selected: selectedWhatHappened == values[2],
                          onTap: () => onWhatHappenedChanged(values[2]),
                        ),
                      ),
                      SizedBox(width: gap),
                      SizedBox(
                        width: width,
                        child: _EventChoice(
                          label: whatHappenedLabel(values[3]),
                          selected: selectedWhatHappened == values[3],
                          onTap: () => onWhatHappenedChanged(values[3]),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 11.5),
          Row(
            children: [
              SizedBox(
                width: 43.33 * sx,
                child: Text(
                  isSpanish ? '¿CUÁNDO?' : 'WHEN?',
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    color: AppColors.mutedTeal,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.67,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(
                width: 244 * sx,
                child: Row(
                  children: [
                    Expanded(
                      flex: 221,
                      child: _WhenChoice(
                        label: whenLabel(
                          _SlipRecoveryScreenState._whenChoices[0],
                        ),
                        selected: selectedWhen ==
                            _SlipRecoveryScreenState._whenChoices[0],
                        onTap: () => onWhenChanged(
                          _SlipRecoveryScreenState._whenChoices[0],
                        ),
                      ),
                    ),
                    SizedBox(width: 6 * sx),
                    Expanded(
                      flex: 246,
                      child: _WhenChoice(
                        label: whenLabel(
                          _SlipRecoveryScreenState._whenChoices[1],
                        ),
                        selected: selectedWhen ==
                            _SlipRecoveryScreenState._whenChoices[1],
                        onTap: () => onWhenChanged(
                          _SlipRecoveryScreenState._whenChoices[1],
                        ),
                      ),
                    ),
                    SizedBox(width: 6 * sx),
                    Expanded(
                      flex: 229,
                      child: _WhenChoice(
                        label: whenLabel(
                          _SlipRecoveryScreenState._whenChoices[2],
                        ),
                        selected: selectedWhen ==
                            _SlipRecoveryScreenState._whenChoices[2],
                        onTap: () => onWhenChanged(
                          _SlipRecoveryScreenState._whenChoices[2],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventChoice extends StatelessWidget {
  const _EventChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE8F5ED) : AppColors.paper,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.coral : AppColors.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: selected ? 11 : 10,
                height: selected ? 11 : 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      selected ? AppColors.deepTeal : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.deepTeal
                        : AppColors.mutedTeal,
                    width: 1,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.lime,
                        size: 8,
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: 'Arial',
                    color: selected
                        ? AppColors.deepTeal
                        : AppColors.tealSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1,
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

class _WhenChoice extends StatelessWidget {
  const _WhenChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.deepTeal : AppColors.paper,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: selected
                ? null
                : Border.all(
                    color: AppColors.border,
                    width: 0.7,
                  ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Arial',
                color: selected ? Colors.white : AppColors.tealSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TriggersCard extends StatelessWidget {
  const _TriggersCard({
    required this.sx,
    required this.isSpanish,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final double sx;
  final bool isSpanish;
  final Set<String> selected;
  final String Function(String) label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      height: 148,
      sx: sx,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: isSpanish
                ? '¿Qué estaba pasando?'
                : 'What was happening?',
            trailing: isSpanish ? 'Opcional' : 'Optional',
          ),
          const SizedBox(height: 5),
          Text(
            isSpanish
                ? 'Elige cualquiera que encaje. Esto ayuda a actualizar tu plan de desencadenantes.'
                : 'Choose any that fit. This helps update your trigger plan.',
            style: const TextStyle(
              fontFamily: 'Arial',
              color: AppColors.mutedTeal,
              fontSize: 11.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / 358.0;
              const values = _SlipRecoveryScreenState._triggerChoices;

              Widget pill(int index, double designWidth) {
                return SizedBox(
                  width: designWidth / 3 * scale,
                  child: _TriggerChoice(
                    label: label(values[index]),
                    selected: selected.contains(values[index]),
                    onTap: () => onChanged(values[index]),
                  ),
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      pill(0, 226),
                      SizedBox(width: 6 * scale),
                      pill(1, 282),
                      SizedBox(width: 6 * scale),
                      pill(2, 244),
                      SizedBox(width: 6 * scale),
                      pill(3, 268),
                    ],
                  ),
                  const SizedBox(height: 6.33),
                  Row(
                    children: [
                      pill(4, 269),
                      SizedBox(width: 6 * scale),
                      pill(5, 242),
                      SizedBox(width: 6 * scale),
                      pill(6, 294),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TriggerChoice extends StatelessWidget {
  const _TriggerChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE8F5ED) : AppColors.paper,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.coral : AppColors.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                Container(
                  width: 11.33,
                  height: 11.33,
                  decoration: const BoxDecoration(
                    color: AppColors.coral,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 7.5,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    color: AppColors.tealSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    height: 1,
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

class _RecoveryChoiceCard extends StatelessWidget {
  const _RecoveryChoiceCard({
    required this.sx,
    required this.isSpanish,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final double sx;
  final bool isSpanish;
  final String selected;
  final String Function(String) label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      height: 186,
      sx: sx,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: isSpanish
                ? '¿Qué te parece bien ahora?'
                : 'What feels right now?',
          ),
          const SizedBox(height: 5),
          Text(
            isSpanish
                ? 'Tú sigues teniendo el control del plan.'
                : 'You stay in control of the plan.',
            style: const TextStyle(
              fontFamily: 'Arial',
              color: AppColors.mutedTeal,
              fontSize: 11.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 11),
          _RecoveryChoice(
            height: 52,
            selected: selected == 'Continue from this moment',
            title: label('Continue from this moment'),
            subtitle: isSpanish
                ? 'Mantén el plan actual y actualiza el apoyo de hoy.'
                : 'Keep the current quit plan and update support for today.',
            recommended: true,
            onTap: () => onChanged('Continue from this moment'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _RecoveryChoice(
                  height: 54,
                  selected: selected == 'Choose a new quit time',
                  title: label('Choose a new quit time'),
                  subtitle:
                      isSpanish ? 'Hoy u otra fecha' : 'Today or another date',
                  onTap: () => onChanged('Choose a new quit time'),
                ),
              ),
              SizedBox(width: 14.67 * sx),
              Expanded(
                child: _RecoveryChoice(
                  height: 54,
                  selected: selected == 'Help me decide',
                  title: label('Help me decide'),
                  subtitle: isSpanish
                      ? 'Revisar opciones sin presión'
                      : 'Review options without pressure',
                  onTap: () => onChanged('Help me decide'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecoveryChoice extends StatelessWidget {
  const _RecoveryChoice({
    required this.height,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.recommended = false,
  });

  final double height;
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE8F5ED) : AppColors.paper,
      borderRadius: BorderRadius.circular(10.7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.7),
        child: Container(
          constraints: BoxConstraints(minHeight: height),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.coral : AppColors.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10.7),
          ),
          child: Row(
            children: [
              Container(
                width: recommended ? 15.33 : 14,
                height: recommended ? 15.33 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      selected ? AppColors.deepTeal : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.deepTeal
                        : AppColors.mutedTeal,
                    width: 1,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.lime,
                        size: 10,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontFamily: 'Arial',
                        color: recommended
                            ? AppColors.deepTeal
                            : AppColors.tealSecondary,
                        fontSize: recommended ? 15 : 14,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        color: AppColors.mutedTeal,
                        fontSize: 11,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              if (recommended) ...[
                const SizedBox(width: 6),
                Container(
                  width: 92,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.deepTeal,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'RECOMMENDED',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Arial',
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
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

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({
    required this.sx,
    required this.isSpanish,
    required this.enabled,
    required this.onOpen,
  });

  final double sx;
  final bool isSpanish;
  final bool enabled;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF123C37),
            Color(0xFF1D514A),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A123C37),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12 * sx,
            top: 14,
            right: 12 * sx,
            child: Text(
              isSpanish ? 'TU SIGUIENTE PASO' : 'YOUR NEXT STEP',
              style: const TextStyle(
                fontFamily: 'Arial',
                color: Color(0xFFBFD5CD),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.67,
                height: 1,
              ),
            ),
          ),
          Positioned(
            left: 12 * sx,
            top: 36,
            right: 12 * sx,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                isSpanish
                    ? 'Aleja los cigarrillos, luego usa un Rescate de 2 minutos.'
                    : 'Move cigarettes out of reach, then use a 2-minute Rescue.',
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Arial',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
          Positioned(
            left: 12 * sx,
            top: 68,
            child: Text(
              isSpanish
                  ? 'Según el desencadenante y lo que te ayudó antes.'
                  : 'Based on the stress trigger and what helped before.',
              style: const TextStyle(
                fontFamily: 'Arial',
                color: Color(0xFFBFD5CD),
                fontSize: 12.5,
                height: 1.1,
              ),
            ),
          ),
          Positioned(
            left: 12 * sx,
            right: 138 * sx,
            bottom: 16,
            child: Text(
              isSpanish
                  ? 'Puedes cambiar de herramienta o contactar con apoyo en cualquier momento.'
                  : 'You can switch tools or contact support at any time.',
              style: const TextStyle(
                fontFamily: 'Arial',
                color: Color(0xFFBFD5CD),
                fontSize: 10.5,
                height: 1.1,
              ),
            ),
          ),
          Positioned(
            right: 12 * sx,
            bottom: 12,
            child: SizedBox(
              width: 120 * sx,
              height: 30,
              child: TextButton(
                key: const ValueKey('slip-recovery-open-next-step'),
                onPressed: enabled ? onOpen : null,
                style: TextButton.styleFrom(
                  backgroundColor:
                      enabled ? AppColors.lime : const Color(0xFFE1E8E4),
                  foregroundColor:
                      enabled ? AppColors.deepTeal : AppColors.mutedTeal,
                  disabledBackgroundColor: const Color(0xFFE1E8E4),
                  disabledForegroundColor: AppColors.mutedTeal,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isSpanish ? 'Abrir después de guardar' : 'Open after saving',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Arial',
                      color:
                          enabled ? AppColors.deepTeal : AppColors.mutedTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.sx,
    required this.isSpanish,
    required this.onTap,
  });

  final double sx;
  final bool isSpanish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF0EB),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        key: const ValueKey('slip-recovery-support'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 56,
          padding: EdgeInsets.symmetric(horizontal: 12 * sx),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFFFC6B7),
              width: 0.67,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              SizedBox(width: 16.67 * sx),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isSpanish
                            ? '¿Quieres a Jordan o a un consejero de la línea de ayuda?'
                            : 'Want Jordan or a quitline counselor?',
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: 'Arial',
                          color: AppColors.deepTeal,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isSpanish
                          ? 'Nadie recibe una notificación a menos que tú lo elijas.'
                          : 'No one is notified unless you choose.',
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        color: AppColors.tealSecondary,
                        fontSize: 11,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8 * sx),
              SizedBox(
                width: 92 * sx,
                height: 30,
                child: TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isSpanish ? 'Ver apoyo' : 'View support',
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
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

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({
    required this.sx,
    required this.isSpanish,
  });

  final double sx;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 42,
      padding: EdgeInsets.symmetric(horizontal: 14.33 * sx),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5F1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.mutedTeal,
            size: 13,
          ),
          SizedBox(width: 8 * sx),
          Expanded(
            child: Text(
              isSpanish
                  ? 'Se guarda sin conexión y se sincroniza después. Puedes eliminar este evento más tarde.'
                  : 'Saves offline and syncs once. You can delete this event later.',
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontFamily: 'Arial',
                color: AppColors.mutedTeal,
                fontSize: 11,
                height: 1.15,
              ),
            ),
          ),
          SizedBox(width: 8 * sx),
          const Text(
            'Content v1.0',
            style: TextStyle(
              fontFamily: 'Arial',
              color: AppColors.tealSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.height,
    required this.sx,
    required this.child,
  });

  final double height;
  final double sx;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: height),
      padding: EdgeInsets.fromLTRB(
        12 * sx,
        12,
        12 * sx,
        10,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(13.7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A123C37),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.trailing,
  });

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Arial',
              color: AppColors.deepTeal,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              fontFamily: 'Arial',
              color: AppColors.mutedTeal,
              fontSize: 10,
              height: 1,
            ),
          ),
      ],
    );
  }
}

class _SlipRecoveryIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tealPaint = Paint()
      ..color = AppColors.deepTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.33
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final coralPaint = Paint()
      ..color = AppColors.coral
      ..style = PaintingStyle.fill;

    final sx = size.width / 52;
    final sy = size.height / 52;

    final upperCurve = Path()
      ..moveTo(12.7 * sx, 27.7 * sy)
      ..quadraticBezierTo(26 * sx, 8.7 * sy, 39.3 * sx, 27.7 * sy);

    final lowerCurve = Path()
      ..moveTo(16.7 * sx, 33.7 * sy)
      ..quadraticBezierTo(26 * sx, 22.7 * sy, 35.3 * sx, 33.7 * sy);

    canvas.drawPath(upperCurve, tealPaint);
    canvas.drawPath(lowerCurve, tealPaint);
    canvas.drawCircle(
      Offset(26 * sx, 16 * sy),
      3.33,
      coralPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
