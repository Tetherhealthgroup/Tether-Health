import 'package:flutter/material.dart';

enum RescueTool {
  slowBreathing,
  move,
  changeScene,
}

class RecommendedRescueToolScreen extends StatelessWidget {
  const RecommendedRescueToolScreen({
    required this.isSpanish,
    required this.intensity,
    required this.stressSelected,
    required this.supportName,
    required this.selectedTool,
    required this.onToolChanged,
    required this.onBack,
    required this.onStart,
    required this.onViewSupport,
    super.key,
  });

  final bool isSpanish;
  final int intensity;
  final bool stressSelected;
  final String supportName;
  final RescueTool selectedTool;
  final ValueChanged<RescueTool> onToolChanged;
  final VoidCallback onBack;
  final VoidCallback onStart;
  final VoidCallback onViewSupport;

  static const _cream = Color(0xFFF8F4EA);
  static const _deepTeal = Color(0xFF0D4B43);
  static const _teal = Color(0xFF245E55);
  static const _mutedTeal = Color(0xFF6A8882);
  static const _mint = Color(0xFFDDF1E9);
  static const _lime = Color(0xFFD6F36A);
  static const _coral = Color(0xFFFF765F);
  static const _coralSoft = Color(0xFFFFEEE9);
  static const _paper = Color(0xFFFFFDF7);
  static const _line = Color(0xFFD4E3DE);

  bool get _strongCraving => intensity >= 7;

  String _t(String english, String spanish) => isSpanish ? spanish : english;

  String get _primaryContext => stressSelected
      ? _t('Stress selected', 'Estrés seleccionado')
      : _t('Personalized match', 'Recomendación personalizada');

  String get _startLabel => switch (selectedTool) {
        RescueTool.slowBreathing => _t(
            'Start recommended tool',
            'Iniciar herramienta recomendada',
          ),
        RescueTool.move =>
          _t('Start 3-minute movement', 'Iniciar movimiento de 3 minutos'),
        RescueTool.changeScene =>
          _t('Start scene change', 'Cambiar de entorno'),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('functional-recommended-rescue-tool-screen'),
      backgroundColor: _cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              isSpanish: isSpanish,
              onBack: onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('rescue-tool-scroll'),
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProgressIntro(isSpanish: isSpanish),
                        const SizedBox(height: 26),
                        Text(
                          _t('BEST MATCH', 'MEJOR OPCIÓN'),
                          style: const TextStyle(
                            color: _mutedTeal,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _t(
                            'Start with what helped before.',
                            'Empieza con lo que te ayudó antes.',
                          ),
                          style: const TextStyle(
                            color: _deepTeal,
                            fontSize: 31,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _t(
                            'One recommended action, based on this craving and your results.',
                            'Una acción recomendada según este antojo y tus resultados.',
                          ),
                          style: const TextStyle(
                            color: _teal,
                            fontSize: 16,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _RecommendedCard(
                          isSpanish: isSpanish,
                          selected: selectedTool == RescueTool.slowBreathing,
                          contextLabel: _primaryContext,
                          onSelect: () =>
                              onToolChanged(RescueTool.slowBreathing),
                          onStart: () {
                            onToolChanged(RescueTool.slowBreathing);
                            onStart();
                          },
                        ),
                        const SizedBox(height: 16),
                        _WhyMatchCard(
                          isSpanish: isSpanish,
                          intensity: intensity,
                          stressSelected: stressSelected,
                          onTap: () => _showWhyMatch(context),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _t(
                                  'Or choose another action',
                                  'O elige otra acción',
                                ),
                                style: const TextStyle(
                                  color: _deepTeal,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              _t('Your choice', 'Tu elección'),
                              style: const TextStyle(
                                color: _mutedTeal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stackCards = constraints.maxWidth < 430;
                            final move = _AlternateToolCard(
                              key: const ValueKey('rescue-tool-move'),
                              title: _t('Move for 3 minutes',
                                  'Muévete por 3 minutos'),
                              subtitle:
                                  _t('Walk or stretch', 'Camina o estírate'),
                              footer: _t('Offline · No equipment',
                                  'Sin conexión · Sin equipo'),
                              icon: Icons.directions_walk_rounded,
                              selected: selectedTool == RescueTool.move,
                              onTap: () => onToolChanged(RescueTool.move),
                            );
                            final change = _AlternateToolCard(
                              key: const ValueKey('rescue-tool-change-scene'),
                              title:
                                  _t('Change the scene', 'Cambia de entorno'),
                              subtitle: _t(
                                'Go somewhere smoke-free',
                                'Ve a un lugar sin humo',
                              ),
                              footer: _t(
                                'Quick environment shift',
                                'Cambio rápido de ambiente',
                              ),
                              icon: Icons.swap_horiz_rounded,
                              selected: selectedTool == RescueTool.changeScene,
                              onTap: () =>
                                  onToolChanged(RescueTool.changeScene),
                            );

                            if (stackCards) {
                              return Column(
                                children: [
                                  move,
                                  const SizedBox(height: 12),
                                  change,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: move),
                                const SizedBox(width: 12),
                                Expanded(child: change),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _SupportCard(
                          isSpanish: isSpanish,
                          supportName: supportName,
                          strongCraving: _strongCraving,
                          onViewSupport: onViewSupport,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3EF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                color: _mutedTeal,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _t(
                                    'Recommendation uses your data only for personalized support.',
                                    'La recomendación usa tus datos solo para apoyo personalizado.',
                                  ),
                                  style: const TextStyle(
                                    color: _mutedTeal,
                                    fontSize: 12.5,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Content v1.0',
                                style: TextStyle(
                                  color: _teal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            _t(
                              'You can switch tools at any time',
                              'Puedes cambiar de herramienta en cualquier momento',
                            ),
                            style: const TextStyle(
                              color: _mutedTeal,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: _cream,
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  key: const ValueKey('rescue-tool-start'),
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: _deepTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _startLabel,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, color: _lime),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showWhyMatch(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _paper,
      builder: (context) {
        final triggerText = stressSelected
            ? _t('Stress trigger', 'Desencadenante: estrés')
            : _t('Your current context', 'Tu contexto actual');
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Why this match?', '¿Por qué esta opción?'),
                  style: const TextStyle(
                    color: _deepTeal,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _t(
                    '$triggerText + craving $intensity/10 + a previously helpful breathing result make slow breathing a practical first step.',
                    '$triggerText + antojo $intensity/10 + un resultado previo útil con respiración hacen que la respiración lenta sea un buen primer paso.',
                  ),
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _t(
                    'You can choose another action now or change personalization later in Settings.',
                    'Puedes elegir otra acción ahora o cambiar la personalización más tarde en Configuración.',
                  ),
                  style: const TextStyle(
                    color: _mutedTeal,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('rescue-tool-why-done'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(_t('Got it', 'Entendido')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isSpanish, required this.onBack});

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('rescue-tool-back'),
            tooltip: isSpanish ? 'Volver' : 'Go back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: RecommendedRescueToolScreen._deepTeal,
              side: const BorderSide(color: RecommendedRescueToolScreen._line),
            ),
          ),
          const Expanded(
            child: Text(
              'Craving Rescue',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RecommendedRescueToolScreen._deepTeal,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F1EB),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              isSpanish ? '2 DE 5' : '2 OF 5',
              style: const TextStyle(
                color: RecommendedRescueToolScreen._teal,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressIntro extends StatelessWidget {
  const _ProgressIntro({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              isSpanish ? 'ELIGE APOYO' : 'CHOOSE SUPPORT',
              style: const TextStyle(
                color: RecommendedRescueToolScreen._mutedTeal,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
            const Spacer(),
            const Text(
              '40%',
              style: TextStyle(
                color: RecommendedRescueToolScreen._mutedTeal,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: const LinearProgressIndicator(
            key: ValueKey('rescue-tool-progress'),
            value: .4,
            minHeight: 7,
            backgroundColor: RecommendedRescueToolScreen._line,
            valueColor: AlwaysStoppedAnimation<Color>(
              RecommendedRescueToolScreen._coral,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.isSpanish,
    required this.selected,
    required this.contextLabel,
    required this.onSelect,
    required this.onStart,
  });

  final bool isSpanish;
  final bool selected;
  final String contextLabel;
  final VoidCallback onSelect;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: const ValueKey('rescue-tool-slow-breathing-card'),
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: RecommendedRescueToolScreen._deepTeal,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              selected ? RecommendedRescueToolScreen._lime : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A655C),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: RecommendedRescueToolScreen._coral,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isSpanish ? 'RECOMENDADO' : 'RECOMMENDED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSpanish ? 'Respiración lenta' : 'Slow breathing',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isSpanish
                                ? 'Deja que el antojo suba y baje mientras sigues una guía de respiración tranquila.'
                                : 'Let the urge rise and fall while you follow a calm breathing cue.',
                            style: const TextStyle(
                              color: Color(0xFFD5E6E1),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 106,
                      height: 106,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: RecommendedRescueToolScreen._lime,
                        shape: BoxShape.circle,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '2:00',
                            style: TextStyle(
                              color: RecommendedRescueToolScreen._deepTeal,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'MINUTES',
                            style: TextStyle(
                              color: RecommendedRescueToolScreen._teal,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF20594F),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSpanish
                                  ? 'TU ÚLTIMO RESULTADO'
                                  : 'YOUR LAST RESULT',
                              style: const TextStyle(
                                color: Color(0xFFBFD4CD),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              isSpanish
                                  ? 'La respiración lenta fue la más útil.'
                                  : 'Slow breathing was selected as most helpful.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isSpanish
                                  ? 'El antojo cambió de 6 a 3 después del ejercicio.'
                                  : 'Craving changed from 6 to 3 after the exercise.',
                              style: const TextStyle(
                                color: Color(0xFFC7DAD4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: RecommendedRescueToolScreen._lime,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              '6 → 3',
                              style: TextStyle(
                                color: RecommendedRescueToolScreen._deepTeal,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'LAST TIME',
                              style: TextStyle(
                                color: RecommendedRescueToolScreen._teal,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(text: contextLabel, icon: Icons.circle, accent: true),
                    _Pill(
                      text:
                          isSpanish ? 'Funciona sin conexión' : 'Works offline',
                      icon: Icons.wifi_rounded,
                    ),
                    _Pill(
                      text: isSpanish ? 'Voz opcional' : 'Voice optional',
                      icon: Icons.volume_up_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    key: const ValueKey('rescue-tool-start-breathing'),
                    onPressed: onStart,
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    label: Text(
                      isSpanish
                          ? 'Iniciar respiración de 2 minutos'
                          : 'Start 2-minute breathing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: RecommendedRescueToolScreen._lime,
                      foregroundColor: RecommendedRescueToolScreen._deepTeal,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.icon,
    this.accent = false,
  });

  final String text;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF56857B)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: accent
                ? RecommendedRescueToolScreen._coral
                : RecommendedRescueToolScreen._lime,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyMatchCard extends StatelessWidget {
  const _WhyMatchCard({
    required this.isSpanish,
    required this.intensity,
    required this.stressSelected,
    required this.onTap,
  });

  final bool isSpanish;
  final int intensity;
  final bool stressSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RecommendedRescueToolScreen._mint,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const ValueKey('rescue-tool-why-match'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: RecommendedRescueToolScreen._paper,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: RecommendedRescueToolScreen._deepTeal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish ? '¿Por qué esta opción?' : 'Why this match?',
                      style: const TextStyle(
                        color: RecommendedRescueToolScreen._deepTeal,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stressSelected
                          ? (isSpanish
                              ? 'Estrés + antojo $intensity/10 + tu resultado útil anterior.'
                              : 'Stress trigger + craving $intensity/10 + your previous helpful result.')
                          : (isSpanish
                              ? 'Antojo $intensity/10 + tu resultado útil anterior.'
                              : 'Craving $intensity/10 + your previous helpful result.'),
                      style: const TextStyle(
                        color: RecommendedRescueToolScreen._teal,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: RecommendedRescueToolScreen._deepTeal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlternateToolCard extends StatelessWidget {
  const _AlternateToolCard({
    required super.key,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String footer;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RecommendedRescueToolScreen._paper,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? RecommendedRescueToolScreen._coral
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? RecommendedRescueToolScreen._coralSoft
                          : RecommendedRescueToolScreen._mint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: selected
                          ? RecommendedRescueToolScreen._coral
                          : RecommendedRescueToolScreen._deepTeal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: RecommendedRescueToolScreen._deepTeal,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: RecommendedRescueToolScreen._mutedTeal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: RecommendedRescueToolScreen._coral,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(
                  height: 1, color: RecommendedRescueToolScreen._line),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      footer,
                      style: const TextStyle(
                        color: RecommendedRescueToolScreen._teal,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: RecommendedRescueToolScreen._deepTeal,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.isSpanish,
    required this.supportName,
    required this.strongCraving,
    required this.onViewSupport,
  });

  final bool isSpanish;
  final String supportName;
  final bool strongCraving;
  final VoidCallback onViewSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RecommendedRescueToolScreen._coralSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFAF9F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: RecommendedRescueToolScreen._coral,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strongCraving
                          ? (isSpanish
                              ? 'Tu antojo es fuerte. ¿Quieres hablar con alguien?'
                              : 'Your craving is strong. Want a person?')
                          : (isSpanish
                              ? '¿Prefieres apoyo de una persona?'
                              : 'Want a person instead?'),
                      style: const TextStyle(
                        color: RecommendedRescueToolScreen._deepTeal,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isSpanish
                          ? 'Contacta a $supportName o a un consejero capacitado de la línea para dejar de fumar.'
                          : 'Contact $supportName or a trained quitline counselor.',
                      style: const TextStyle(
                        color: RecommendedRescueToolScreen._teal,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('rescue-tool-support'),
              onPressed: onViewSupport,
              style: FilledButton.styleFrom(
                backgroundColor: RecommendedRescueToolScreen._coral,
                foregroundColor: Colors.white,
              ),
              child: Text(isSpanish ? 'Ver apoyo' : 'View support'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSpanish
                ? 'No se envía ni comparte nada a menos que tú lo elijas.'
                : 'Nothing is sent or shared unless you choose it.',
            style: const TextStyle(
              color: Color(0xFF8E756E),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
