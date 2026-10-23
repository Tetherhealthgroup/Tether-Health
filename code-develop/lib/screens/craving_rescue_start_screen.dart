import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

enum RescueContext {
  stress,
  afterMeal,
  aroundSmoking,
  driving,
  alcohol,
  bored,
  notSure,
}

class CravingRescueStartScreen extends StatelessWidget {
  const CravingRescueStartScreen({
    required this.isSpanish,
    required this.intensity,
    required this.selectedContexts,
    required this.topReason,
    required this.supportName,
    required this.onIntensityChanged,
    required this.onContextsChanged,
    required this.onClose,
    required this.onContinue,
    required this.onViewSupport,
    super.key,
  });

  final bool isSpanish;
  final int intensity;
  final Set<RescueContext> selectedContexts;
  final String topReason;
  final String supportName;
  final ValueChanged<int> onIntensityChanged;
  final ValueChanged<Set<RescueContext>> onContextsChanged;
  final VoidCallback onClose;
  final VoidCallback onContinue;
  final VoidCallback onViewSupport;

  String _contextLabel(RescueContext context) => switch (context) {
        RescueContext.stress => isSpanish ? 'Estrés' : 'Stress',
        RescueContext.afterMeal =>
          isSpanish ? 'Después de comer' : 'After a meal',
        RescueContext.aroundSmoking =>
          isSpanish ? 'Cerca de alguien que fuma' : 'Around someone smoking',
        RescueContext.driving => isSpanish ? 'Al conducir' : 'Driving',
        RescueContext.alcohol => isSpanish ? 'Alcohol' : 'Alcohol',
        RescueContext.bored => isSpanish ? 'Aburrimiento' : 'Bored',
        RescueContext.notSure => isSpanish ? 'No estoy seguro' : 'Not sure',
      };

  String _intensityLabel(int value) {
    if (value <= 3) return isSpanish ? 'Leve' : 'Mild';
    if (value <= 6) return isSpanish ? 'Moderado' : 'Moderate';
    if (value <= 8) return isSpanish ? 'Fuerte' : 'Strong';
    return isSpanish ? 'Muy fuerte' : 'Very strong';
  }

  void _toggleContext(RescueContext context) {
    final updated = Set<RescueContext>.of(selectedContexts);
    if (updated.contains(context)) {
      updated.remove(context);
    } else if (context == RescueContext.notSure) {
      updated
        ..clear()
        ..add(context);
    } else {
      updated
        ..remove(RescueContext.notSure)
        ..add(context);
    }
    onContextsChanged(updated);
  }

  Future<void> _showEmergencyGuidance(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.coralLight,
                    foregroundColor: AppColors.coral,
                    child: Icon(Icons.local_hospital_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isSpanish ? 'Emergencia médica' : 'Medical emergency',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                isSpanish
                    ? 'Si es una emergencia médica o estás en peligro inmediato, llama al 911 ahora.'
                    : 'If this is a medical emergency or you are in immediate danger, call 911 now.',
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSpanish
                    ? 'BreatheFree no realizará ninguna llamada automáticamente.'
                    : 'BreatheFree will only start a call when you tap “Call 911.”',
                style: const TextStyle(
                  color: AppColors.tealSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('rescue-start-call-911'),
                  onPressed: () async {
                    final uri = Uri(scheme: 'tel', path: '911');
                    final launched = await launchUrl(uri);

                    if (!launched && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isSpanish
                                ? 'No se pudo abrir la aplicación Teléfono.'
                                : 'Could not open the Phone app.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.phone_rounded),
                  label: Text(isSpanish ? 'Llamar al 911' : 'Call 911'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const ValueKey('rescue-start-emergency-done'),
                  onPressed: () => Navigator.pop(context),
                  child: Text(isSpanish ? 'Cerrar' : 'Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 760;
    final horizontalPadding = size.width < 390 ? 16.0 : 20.0;

    return Scaffold(
      key: const ValueKey('functional-craving-rescue-start-screen'),
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
              child: _RescueHeader(
                isSpanish: isSpanish,
                onClose: onClose,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('rescue-start-scroll'),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  compact ? 8 : 14,
                  horizontalPadding,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isSpanish ? 'AHORA MISMO' : 'RIGHT NOW',
                          style: const TextStyle(
                            color: AppColors.mutedTeal,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSpanish
                              ? 'Superemos este momento.'
                              : 'Let’s get through this moment.',
                          style: TextStyle(
                            color: AppColors.deepTeal,
                            fontFamily: 'Georgia',
                            fontSize: compact ? 31 : 36,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSpanish
                              ? 'Empieza con lo que sientes ahora. No necesitas escribir.'
                              : 'Start with what you feel now. No typing is required.',
                          style: const TextStyle(
                            color: AppColors.tealSecondary,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 22),
                        _IntensityCard(
                          isSpanish: isSpanish,
                          intensity: intensity,
                          intensityLabel: _intensityLabel(intensity),
                          onChanged: onIntensityChanged,
                          compact: compact,
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      isSpanish
                                          ? '¿Qué puede estar detrás?'
                                          : 'What might be behind it?',
                                      style: const TextStyle(
                                        color: AppColors.deepTeal,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isSpanish
                                        ? 'Opcional'
                                        : 'Optional · Skip anytime',
                                    style: const TextStyle(
                                      color: AppColors.mutedTeal,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final item in RescueContext.values)
                                    FilterChip(
                                      key: ValueKey(
                                        'rescue-start-context-${item.name}',
                                      ),
                                      selected: selectedContexts.contains(item),
                                      onSelected: (_) => _toggleContext(item),
                                      label: Text(_contextLabel(item)),
                                      showCheckmark: true,
                                      checkmarkColor: AppColors.lime,
                                      selectedColor: AppColors.mint,
                                      backgroundColor: AppColors.paper,
                                      side: BorderSide(
                                        color: selectedContexts.contains(item)
                                            ? AppColors.coral
                                            : AppColors.border,
                                      ),
                                      labelStyle: const TextStyle(
                                        color: AppColors.deepTeal,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              _PrivacyNote(isSpanish: isSpanish),
                            ],
                          ),
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _TopReasonCard(
                          isSpanish: isSpanish,
                          reason: topReason,
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _SupportCard(
                          isSpanish: isSpanish,
                          supportName: supportName,
                          onTap: onViewSupport,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(top: BorderSide(color: Color(0xFFE0E7E3))),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              10,
              horizontalPadding,
              compact ? 8 : 12,
            ),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: compact ? 50 : 54,
                      child: FilledButton.icon(
                        key: const ValueKey('rescue-start-continue'),
                        onPressed: onContinue,
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          isSpanish
                              ? 'Muéstrame qué hacer'
                              : 'Show me what to do',
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.mutedTeal,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            isSpanish
                                ? 'Privado · Funciona sin conexión'
                                : 'Private · Works offline',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.mutedTeal,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('rescue-start-emergency'),
                          onPressed: () => _showEmergencyGuidance(context),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            isSpanish
                                ? '¿Emergencia médica?'
                                : 'Medical emergency?',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      isSpanish
                          ? 'Los detalles son opcionales y nunca bloquean Rescate.'
                          : 'Trigger details are optional and never block Rescue.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RescueHeader extends StatelessWidget {
  const _RescueHeader({required this.isSpanish, required this.onClose});

  final bool isSpanish;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('rescue-start-close'),
            onPressed: onClose,
            tooltip: isSpanish ? 'Volver' : 'Go back',
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.paper,
              foregroundColor: AppColors.deepTeal,
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSpanish ? 'Rescate del antojo' : 'Craving Rescue',
              maxLines: 1,
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
              color: const Color(0xFFE6F1EA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.signal_wifi_off_rounded,
                  color: AppColors.deepTeal,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isSpanish ? 'SIN CONEXIÓN' : 'OFFLINE READY',
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
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

class _IntensityCard extends StatelessWidget {
  const _IntensityCard({
    required this.isSpanish,
    required this.intensity,
    required this.intensityLabel,
    required this.onChanged,
    required this.compact,
  });

  final bool isSpanish;
  final int intensity;
  final String intensityLabel;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 22),
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
                      isSpanish ? 'INTENSIDAD DEL ANTOJO' : 'CRAVING INTENSITY',
                      style: const TextStyle(
                        color: Color(0xFFBFD5CD),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSpanish
                          ? '¿Qué tan fuerte es ahora?'
                          : 'How strong is it right now?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                key: const ValueKey('rescue-start-intensity-label'),
                width: compact ? 82 : 92,
                height: compact ? 82 : 92,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$intensity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        height: .9,
                      ),
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      child: Text(
                        intensityLabel.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.coralLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.coral,
              inactiveTrackColor: const Color(0xFF456A63),
              thumbColor: AppColors.coral,
              overlayColor: AppColors.coral.withValues(alpha: .18),
              trackHeight: 8,
            ),
            child: Slider(
              key: const ValueKey('rescue-start-intensity-slider'),
              min: 1,
              max: 10,
              divisions: 9,
              value: intensity.clamp(1, 10).toDouble(),
              label: '$intensity',
              onChanged: (value) => onChanged(value.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSpanish ? 'Leve' : 'Mild',
                  style: const TextStyle(
                    color: Color(0xFFBFD5CD),
                    fontSize: 11,
                  ),
                ),
                Text(
                  isSpanish ? 'Más fuerte' : 'Strongest',
                  style: const TextStyle(
                    color: Color(0xFFBFD5CD),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          const Divider(color: Color(0xFF3F6660), height: 1),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF234E48),
                foregroundColor: AppColors.lime,
                child: Icon(Icons.waves_rounded, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish
                          ? 'Solo necesitas elegir un número.'
                          : 'You only need to choose a number.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isSpanish
                          ? 'La siguiente pantalla ofrece una acción recomendada.'
                          : 'The next screen gives one recommended action.',
                      style: const TextStyle(
                        color: Color(0xFFBFD5CD),
                        fontSize: 12,
                        height: 1.35,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E1DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D123C37),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFFE6F1EA),
          foregroundColor: AppColors.deepTeal,
          child: Icon(Icons.info_outline_rounded, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: isSpanish
                      ? 'Se usa para personalizar el apoyo, nunca para vigilarte.\n'
                      : 'Used to personalize support — never to monitor you.\n',
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: isSpanish
                      ? 'Sin rastreo de ubicación ni conversaciones.'
                      : 'No background location or conversation tracking.',
                  style: const TextStyle(color: AppColors.mutedTeal),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _TopReasonCard extends StatelessWidget {
  const _TopReasonCard({required this.isSpanish, required this.reason});

  final bool isSpanish;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.mintStrong),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 23,
            backgroundColor: AppColors.coralLight,
            foregroundColor: AppColors.coral,
            child: Icon(Icons.favorite_rounded),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpanish ? 'TU RAZÓN PRINCIPAL' : 'YOUR TOP REASON',
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '“$reason.”',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isSpanish
                      ? 'Este momento puede pasar sin cambiar tu meta.'
                      : 'This moment can pass without changing your goal.',
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 12,
                    height: 1.35,
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

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.isSpanish,
    required this.supportName,
    required this.onTap,
  });

  final bool isSpanish;
  final String supportName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFE6F1EA),
                foregroundColor: AppColors.deepTeal,
                child: Icon(Icons.person_outline_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish
                          ? '¿Prefieres hablar con alguien?'
                          : 'Want a person instead?',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isSpanish
                          ? 'Contacta a $supportName o a un consejero capacitado.'
                          : 'Contact $supportName or a trained quitline counselor.',
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const ValueKey('rescue-start-support'),
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                child: Text(isSpanish ? 'Ver apoyo' : 'View support'),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            isSpanish
                ? 'Los mensajes y llamadas solo ocurren cuando tú los eliges.'
                : 'Messages and calls only happen when you choose them.',
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
