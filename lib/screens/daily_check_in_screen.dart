import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum DailyMood { low, notGreat, okay, good, great }

enum DailySmokingStatus { none, puff, oneOrMore, skipped }

enum DailySymptom {
  restless,
  irritable,
  troubleConcentrating,
  troubleSleeping,
  other,
}

class DailyCheckInScreen extends StatelessWidget {
  const DailyCheckInScreen({
    required this.isSpanish,
    required this.mood,
    required this.stressLevel,
    required this.smokingStatus,
    required this.cigaretteCount,
    required this.strongestCraving,
    required this.confidence,
    required this.symptoms,
    required this.otherSymptom,
    required this.onMoodChanged,
    required this.onStressChanged,
    required this.onSmokingStatusChanged,
    required this.onCigaretteCountChanged,
    required this.onStrongestCravingChanged,
    required this.onConfidenceChanged,
    required this.onSymptomsChanged,
    required this.onOtherSymptomChanged,
    required this.onClose,
    required this.onOpenRescue,
    required this.onSave,
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
  final ValueChanged<DailyMood> onMoodChanged;
  final ValueChanged<int> onStressChanged;
  final ValueChanged<DailySmokingStatus> onSmokingStatusChanged;
  final ValueChanged<int> onCigaretteCountChanged;
  final ValueChanged<int> onStrongestCravingChanged;
  final ValueChanged<int> onConfidenceChanged;
  final ValueChanged<Set<DailySymptom>> onSymptomsChanged;
  final ValueChanged<String?> onOtherSymptomChanged;
  final VoidCallback onClose;
  final VoidCallback onOpenRescue;
  final VoidCallback onSave;

  String _monthName(int month) {
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
    return (isSpanish ? spanish : english)[month - 1];
  }

  String get _todayLabel {
    final now = DateTime.now();
    if (isSpanish) {
      return 'HOY · ${now.day} DE ${_monthName(now.month).toUpperCase()}';
    }
    return 'TODAY · ${_monthName(now.month).toUpperCase()} ${now.day}';
  }

  String _moodLabel(DailyMood value) => switch (value) {
        DailyMood.low => isSpanish ? 'Bajo' : 'Low',
        DailyMood.notGreat => isSpanish ? 'No muy bien' : 'Not great',
        DailyMood.okay => isSpanish ? 'Regular' : 'Okay',
        DailyMood.good => isSpanish ? 'Bien' : 'Good',
        DailyMood.great => isSpanish ? 'Muy bien' : 'Great',
      };

  IconData _moodIcon(DailyMood value) => switch (value) {
        DailyMood.low => Icons.sentiment_very_dissatisfied_rounded,
        DailyMood.notGreat => Icons.sentiment_dissatisfied_rounded,
        DailyMood.okay => Icons.sentiment_neutral_rounded,
        DailyMood.good => Icons.sentiment_satisfied_rounded,
        DailyMood.great => Icons.sentiment_very_satisfied_rounded,
      };

  String _stressLabel(int value) {
    if (value <= 1) return isSpanish ? 'Bajo' : 'Low';
    if (value == 2) return isSpanish ? 'Leve' : 'Mild';
    if (value == 3) return isSpanish ? 'Moderado' : 'Moderate';
    return isSpanish ? 'Alto' : 'High';
  }

  String _smokingLabel(DailySmokingStatus value) => switch (value) {
        DailySmokingStatus.none => isSpanish ? 'No' : 'No',
        DailySmokingStatus.puff => isSpanish ? 'Una calada' : 'A puff',
        DailySmokingStatus.oneOrMore => isSpanish ? 'Uno o más' : 'One or more',
        DailySmokingStatus.skipped => isSpanish ? 'Omitir' : 'Skip',
      };

  String _symptomLabel(DailySymptom value) => switch (value) {
        DailySymptom.restless => isSpanish ? 'Inquietud' : 'Restless',
        DailySymptom.irritable => isSpanish ? 'Irritabilidad' : 'Irritable',
        DailySymptom.troubleConcentrating =>
          isSpanish ? 'Dificultad para concentrarme' : 'Trouble concentrating',
        DailySymptom.troubleSleeping =>
          isSpanish ? 'Dificultad para dormir' : 'Trouble sleeping',
        DailySymptom.other => isSpanish ? 'Otro' : 'Other',
      };

  void _toggleSymptom(DailySymptom symptom) {
    final updated = Set<DailySymptom>.from(symptoms);
    if (!updated.add(symptom)) {
      updated.remove(symptom);
      if (symptom == DailySymptom.other) onOtherSymptomChanged(null);
    }
    onSymptomsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final compact = media.height < 760;
    final horizontalPadding = media.width < 390 ? 16.0 : 20.0;

    return Scaffold(
      key: const ValueKey('functional-daily-check-in-screen'),
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
                6,
              ),
              child: _CheckInHeader(
                isSpanish: isSpanish,
                onClose: onClose,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _todayLabel,
                          style: const TextStyle(
                            color: AppColors.mutedTeal,
                            fontSize: 10,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        isSpanish ? 'CASI LISTO' : 'ALMOST DONE',
                        style: const TextStyle(
                          color: AppColors.mutedTeal,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: const LinearProgressIndicator(
                      key: ValueKey('checkin-progress'),
                      value: 0.84,
                      minHeight: 5,
                      backgroundColor: Color(0xFFDDE7E2),
                      valueColor: AlwaysStoppedAnimation(AppColors.coral),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('daily-check-in-scroll'),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  compact ? 18 : 24,
                  horizontalPadding,
                  20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSpanish
                              ? '¿Cómo estás hoy?'
                              : 'How are you doing today?',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontSize: media.width < 390 ? 31 : 36,
                                height: 1.04,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSpanish
                              ? 'No hay respuestas correctas. Esto nos ayuda a ofrecerte el apoyo que necesitas.'
                              : 'No right answers. This helps us support what you need next.',
                          style: const TextStyle(
                            color: AppColors.tealSecondary,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 20),
                        _MoodAndStressCard(
                          isSpanish: isSpanish,
                          mood: mood,
                          moodLabel: _moodLabel,
                          moodIcon: _moodIcon,
                          stressLevel: stressLevel,
                          stressLabel: _stressLabel(stressLevel),
                          onMoodChanged: onMoodChanged,
                          onStressChanged: onStressChanged,
                        ),
                        const SizedBox(height: 14),
                        _SmokingCard(
                          isSpanish: isSpanish,
                          status: smokingStatus,
                          cigaretteCount: cigaretteCount,
                          statusLabel: _smokingLabel,
                          onStatusChanged: onSmokingStatusChanged,
                          onCountChanged: onCigaretteCountChanged,
                        ),
                        const SizedBox(height: 14),
                        _RatingCard(
                          isSpanish: isSpanish,
                          strongestCraving: strongestCraving,
                          confidence: confidence,
                          onStrongestCravingChanged: onStrongestCravingChanged,
                          onConfidenceChanged: onConfidenceChanged,
                        ),
                        const SizedBox(height: 14),
                        _SymptomsCard(
                          isSpanish: isSpanish,
                          symptoms: symptoms,
                          otherSymptom: otherSymptom,
                          symptomLabel: _symptomLabel,
                          onToggle: _toggleSymptom,
                          onOtherChanged: onOtherSymptomChanged,
                        ),
                        const SizedBox(height: 14),
                        _ImmediateSupportCard(
                          isSpanish: isSpanish,
                          onOpenRescue: onOpenRescue,
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
      bottomNavigationBar: _CheckInBottomAction(
        isSpanish: isSpanish,
        compact: compact,
        horizontalPadding: horizontalPadding,
        onSave: onSave,
      ),
    );
  }
}

class _CheckInHeader extends StatelessWidget {
  const _CheckInHeader({required this.isSpanish, required this.onClose});

  final bool isSpanish;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('checkin-close'),
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
              isSpanish ? 'Registro diario' : 'Daily check-in',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              isSpanish ? 'APROX. 60 S' : 'ABOUT 60 SEC',
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D123C37),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MoodAndStressCard extends StatelessWidget {
  const _MoodAndStressCard({
    required this.isSpanish,
    required this.mood,
    required this.moodLabel,
    required this.moodIcon,
    required this.stressLevel,
    required this.stressLabel,
    required this.onMoodChanged,
    required this.onStressChanged,
  });

  final bool isSpanish;
  final DailyMood mood;
  final String Function(DailyMood) moodLabel;
  final IconData Function(DailyMood) moodIcon;
  final int stressLevel;
  final String stressLabel;
  final ValueChanged<DailyMood> onMoodChanged;
  final ValueChanged<int> onStressChanged;

  @override
  Widget build(BuildContext context) {
    return _CheckInCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isSpanish ? '¿Cómo te sientes?' : 'How do you feel?',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                moodLabel(mood),
                style: const TextStyle(
                  color: AppColors.coral,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final value in DailyMood.values)
                Expanded(
                  child: _MoodChoice(
                    value: value,
                    label: moodLabel(value),
                    icon: moodIcon(value),
                    selected: mood == value,
                    onTap: () => onMoodChanged(value),
                  ),
                ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  isSpanish ? 'Estrés hoy' : 'Stress today',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                stressLabel,
                key: const ValueKey('checkin-stress-label'),
                style: const TextStyle(
                  color: AppColors.coral,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.coral,
              inactiveTrackColor: const Color(0xFFDDE7E2),
              thumbColor: AppColors.coral,
              overlayColor: const Color(0x22FF7D61),
              trackHeight: 7,
            ),
            child: Slider(
              key: const ValueKey('checkin-stress-slider'),
              value: stressLevel.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: stressLabel,
              onChanged: (value) => onStressChanged(value.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChoice extends StatelessWidget {
  const _MoodChoice({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final DailyMood value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('checkin-mood-${value.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.mint : const Color(0xFFF0F4F1),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: AppColors.coral, width: 2)
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: selected ? AppColors.deepTeal : AppColors.mutedTeal,
                    size: 29,
                  ),
                ),
                if (selected)
                  const Positioned(
                    right: -2,
                    top: -3,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: AppColors.coral,
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppColors.deepTeal : AppColors.mutedTeal,
                fontSize: 9.5,
                height: 1.1,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmokingCard extends StatelessWidget {
  const _SmokingCard({
    required this.isSpanish,
    required this.status,
    required this.cigaretteCount,
    required this.statusLabel,
    required this.onStatusChanged,
    required this.onCountChanged,
  });

  final bool isSpanish;
  final DailySmokingStatus status;
  final int cigaretteCount;
  final String Function(DailySmokingStatus) statusLabel;
  final ValueChanged<DailySmokingStatus> onStatusChanged;
  final ValueChanged<int> onCountChanged;

  @override
  Widget build(BuildContext context) {
    return _CheckInCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSpanish
                ? 'Desde tu último registro, ¿fumaste?'
                : 'Since your last check-in, did you smoke?',
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSpanish
                ? 'Antes del día para dejarlo, esto es esperado; no es un retroceso.'
                : 'Before your quit day, this is expected — it is not a setback.',
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in DailySmokingStatus.values)
                    SizedBox(
                      width: width,
                      child: ChoiceChip(
                        key: ValueKey('checkin-smoking-${value.name}'),
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(
                            statusLabel(value),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        selected: status == value,
                        showCheckmark: status == value,
                        selectedColor: AppColors.mintStrong,
                        backgroundColor: AppColors.paper,
                        side: BorderSide(
                          color: status == value
                              ? AppColors.coral
                              : AppColors.border,
                          width: status == value ? 2 : 1,
                        ),
                        labelStyle: const TextStyle(
                          color: AppColors.deepTeal,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => onStatusChanged(value),
                      ),
                    ),
                ],
              );
            },
          ),
          if (status == DailySmokingStatus.oneOrMore) ...[
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSpanish
                            ? '¿Aproximadamente cuántos?'
                            : 'About how many?',
                        style: const TextStyle(
                          color: AppColors.deepTeal,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isSpanish
                            ? 'Una estimación es suficiente'
                            : 'An estimate is enough',
                        style: const TextStyle(
                          color: AppColors.mutedTeal,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  key: const ValueKey('checkin-cigarette-minus'),
                  tooltip: isSpanish ? 'Disminuir' : 'Decrease',
                  onPressed: cigaretteCount > 1
                      ? () => onCountChanged(cigaretteCount - 1)
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '$cigaretteCount',
                    key: const ValueKey('checkin-cigarette-count'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.filled(
                  key: const ValueKey('checkin-cigarette-plus'),
                  tooltip: isSpanish ? 'Aumentar' : 'Increase',
                  onPressed: cigaretteCount < 99
                      ? () => onCountChanged(cigaretteCount + 1)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                    foregroundColor: AppColors.lime,
                  ),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.isSpanish,
    required this.strongestCraving,
    required this.confidence,
    required this.onStrongestCravingChanged,
    required this.onConfidenceChanged,
  });

  final bool isSpanish;
  final int strongestCraving;
  final int confidence;
  final ValueChanged<int> onStrongestCravingChanged;
  final ValueChanged<int> onConfidenceChanged;

  String _cravingWord(int value) {
    if (value == 0) return isSpanish ? 'Ninguno' : 'None';
    if (value <= 3) return isSpanish ? 'Leve' : 'Mild';
    if (value <= 6) return isSpanish ? 'Moderado' : 'Moderate';
    return isSpanish ? 'Fuerte' : 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    return _CheckInCard(
      child: Column(
        children: [
          _RatingSlider(
            sliderKey: const ValueKey('checkin-craving-slider'),
            title: isSpanish
                ? 'Antojo más fuerte de hoy'
                : 'Strongest craving today',
            value: strongestCraving,
            badge: '$strongestCraving · ${_cravingWord(strongestCraving)}',
            accent: AppColors.coral,
            lowLabel: isSpanish ? '0 · Ninguno' : '0 · None',
            highLabel: isSpanish ? '10 · Más fuerte' : '10 · Strongest',
            onChanged: onStrongestCravingChanged,
          ),
          const Divider(height: 28),
          _RatingSlider(
            sliderKey: const ValueKey('checkin-confidence-slider'),
            title: isSpanish
                ? 'Confianza para las próximas 24 horas'
                : 'Confidence for the next 24 hours',
            value: confidence,
            badge: '$confidence / 10',
            accent: AppColors.deepTeal,
            lowLabel: isSpanish ? '0 · Baja' : '0 · Low',
            highLabel: isSpanish ? '10 · Alta' : '10 · High',
            onChanged: onConfidenceChanged,
          ),
        ],
      ),
    );
  }
}

class _RatingSlider extends StatelessWidget {
  const _RatingSlider({
    required this.sliderKey,
    required this.title,
    required this.value,
    required this.badge,
    required this.accent,
    required this.lowLabel,
    required this.highLabel,
    required this.onChanged,
  });

  final Key sliderKey;
  final String title;
  final int value;
  final String badge;
  final Color accent;
  final String lowLabel;
  final String highLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: accent == AppColors.coral
                    ? AppColors.coralLight
                    : AppColors.mint,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            inactiveTrackColor: const Color(0xFFDDE7E2),
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.12),
            trackHeight: 7,
          ),
          child: Slider(
            key: sliderKey,
            value: value.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '$value',
            onChanged: (next) => onChanged(next.round()),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                lowLabel,
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 9.5,
                ),
              ),
            ),
            Text(
              highLabel,
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SymptomsCard extends StatelessWidget {
  const _SymptomsCard({
    required this.isSpanish,
    required this.symptoms,
    required this.otherSymptom,
    required this.symptomLabel,
    required this.onToggle,
    required this.onOtherChanged,
  });

  final bool isSpanish;
  final Set<DailySymptom> symptoms;
  final String? otherSymptom;
  final String Function(DailySymptom) symptomLabel;
  final ValueChanged<DailySymptom> onToggle;
  final ValueChanged<String?> onOtherChanged;

  @override
  Widget build(BuildContext context) {
    return _CheckInCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isSpanish
                      ? '¿Algo te está afectando hoy?'
                      : 'Anything affecting you today?',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                isSpanish ? 'Opcional' : 'Optional',
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in DailySymptom.values)
                FilterChip(
                  key: ValueKey('checkin-symptom-${value.name}'),
                  label: Text(symptomLabel(value)),
                  selected: symptoms.contains(value),
                  selectedColor: AppColors.mintStrong,
                  backgroundColor: AppColors.paper,
                  checkmarkColor: AppColors.lime,
                  side: const BorderSide(color: AppColors.border),
                  labelStyle: const TextStyle(
                    color: AppColors.deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => onToggle(value),
                ),
            ],
          ),
          if (symptoms.contains(DailySymptom.other)) ...[
            const SizedBox(height: 10),
            TextFormField(
              key: const ValueKey('checkin-other-symptom-field'),
              initialValue: otherSymptom,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: isSpanish ? 'Otro síntoma' : 'Other symptom',
                hintText: isSpanish
                    ? 'Escribe una descripción breve'
                    : 'Add a short description',
                border: const OutlineInputBorder(),
              ),
              onChanged: onOtherChanged,
            ),
          ],
          const SizedBox(height: 9),
          Text(
            isSpanish
                ? 'Podemos sugerir apoyo adicional para síntomas intensos o inesperados.'
                : 'We may suggest extra support for severe or unexpected symptoms.',
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImmediateSupportCard extends StatelessWidget {
  const _ImmediateSupportCard({
    required this.isSpanish,
    required this.onOpenRescue,
  });

  final bool isSpanish;
  final VoidCallback onOpenRescue;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.coralLight,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('checkin-open-rescue'),
        onTap: onOpenRescue,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFB6A6)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.coral,
                child: Icon(Icons.waves_rounded, color: Colors.white),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  isSpanish
                      ? '¿Necesitas apoyo ahora?'
                      : 'Need support right now?',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                isSpanish ? 'Abrir Rescate' : 'Open Rescue',
                style: const TextStyle(
                  color: AppColors.coral,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.coral),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckInBottomAction extends StatelessWidget {
  const _CheckInBottomAction({
    required this.isSpanish,
    required this.compact,
    required this.horizontalPadding,
    required this.onSave,
  });

  final bool isSpanish;
  final bool compact;
  final double horizontalPadding;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.cream,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          10,
          horizontalPadding,
          compact ? 7 : 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: compact ? 50 : 54,
              child: FilledButton(
                key: const ValueKey('checkin-save'),
                onPressed: onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isSpanish ? 'Guardar registro' : 'Save check-in',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.lime,
                    ),
                  ],
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 7),
              Text(
                isSpanish
                    ? 'Privado · Funciona sin conexión · Se sincroniza de forma segura'
                    : 'Private · Works offline · Syncs securely when connected',
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
    );
  }
}
