import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'baseline_assessment_screen.dart';
import 'trigger_map_screen.dart';

enum ReadinessPath { prepare, explore, connect }

class ReadinessResultScreen extends StatelessWidget {
  const ReadinessResultScreen({
    required this.isSpanish,
    required this.dailyCigaretteUse,
    required this.selectedTriggers,
    required this.customTrigger,
    required this.selectedPath,
    required this.onPathChanged,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final bool isSpanish;
  final DailyCigaretteUse? dailyCigaretteUse;
  final Set<SmokingTrigger> selectedTriggers;
  final String? customTrigger;
  final ReadinessPath selectedPath;
  final ValueChanged<ReadinessPath> onPathChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  String _usageLabel() {
    return switch (dailyCigaretteUse) {
      DailyCigaretteUse.notEveryDay =>
        isSpanish ? 'No fumas todos los días' : 'You do not smoke every day',
      DailyCigaretteUse.tenOrFewer => isSpanish
          ? '10 cigarrillos o menos en un día habitual'
          : '10 or fewer cigarettes on a typical day',
      DailyCigaretteUse.elevenToTwenty => isSpanish
          ? '11–20 cigarrillos en un día habitual'
          : '11–20 cigarettes on a typical day',
      DailyCigaretteUse.twentyOneToThirty => isSpanish
          ? '21–30 cigarrillos en un día habitual'
          : '21–30 cigarettes on a typical day',
      DailyCigaretteUse.thirtyOneOrMore => isSpanish
          ? '31 cigarrillos o más en un día habitual'
          : '31 or more cigarettes on a typical day',
      null => isSpanish
          ? 'Puedes añadir tu patrón de consumo cuando quieras'
          : 'You can add your smoking pattern anytime',
    };
  }

  String _triggerLabel(SmokingTrigger trigger) {
    return switch (trigger) {
      SmokingTrigger.stress => isSpanish ? 'estrés' : 'stress',
      SmokingTrigger.afterMeals =>
        isSpanish ? 'después de comer' : 'after meals',
      SmokingTrigger.driving => isSpanish ? 'conducir' : 'driving',
      SmokingTrigger.coffee => isSpanish ? 'café' : 'coffee',
      SmokingTrigger.socialSettings =>
        isSpanish ? 'entornos sociales' : 'social settings',
      SmokingTrigger.workBreaks =>
        isSpanish ? 'descansos laborales' : 'work breaks',
      SmokingTrigger.alcohol => isSpanish ? 'alcohol' : 'alcohol',
      SmokingTrigger.boredom => isSpanish ? 'aburrimiento' : 'boredom',
      SmokingTrigger.morning => isSpanish ? 'la mañana' : 'mornings',
      SmokingTrigger.beforeBed => isSpanish ? 'antes de dormir' : 'before bed',
    };
  }

  List<String> _allTriggerLabels() {
    final labels = selectedTriggers.map(_triggerLabel).toList();
    final normalizedCustom = customTrigger?.trim();
    if (normalizedCustom != null && normalizedCustom.isNotEmpty) {
      labels.add(normalizedCustom);
    }
    return labels;
  }

  String _triggerSummary() {
    final labels = _allTriggerLabels();
    if (labels.isEmpty) {
      return isSpanish
          ? 'Puedes identificar desencadenantes cuando quieras'
          : 'You can identify triggers anytime';
    }
    if (labels.length == 1) {
      return isSpanish
          ? 'Quieres prepararte para ${labels.first}'
          : 'You want support for ${labels.first}';
    }
    if (labels.length == 2) {
      return isSpanish
          ? 'Quieres prepararte para ${labels.first} y ${labels.last}'
          : 'You want support for ${labels.first} and ${labels.last}';
    }
    final remaining = labels.length - 2;
    return isSpanish
        ? '${labels[0]}, ${labels[1]} y $remaining más'
        : '${labels[0]}, ${labels[1]}, and $remaining more';
  }

  String _startingPointSummary() {
    final count = _allTriggerLabels().length;
    if (count == 0) {
      return isSpanish
          ? 'Puedes empezar con un paso pequeño y añadir detalles después'
          : 'You can start small and add details later';
    }
    return isSpanish
        ? 'Ya identificaste $count ${count == 1 ? 'situación' : 'situaciones'} para preparar'
        : 'You identified $count ${count == 1 ? 'situation' : 'situations'} to prepare for';
  }

  String _actionLabel() {
    return switch (selectedPath) {
      ReadinessPath.prepare => isSpanish
          ? 'Crear mi plan de preparación'
          : 'Build my preparation plan',
      ReadinessPath.explore => isSpanish
          ? 'Explorar sin fijar una fecha'
          : 'Explore without setting a date',
      ReadinessPath.connect =>
        isSpanish ? 'Buscar opciones de apoyo' : 'Find support options',
    };
  }

  Future<void> _showWhyThisFits(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSpanish
                    ? 'Por qué la preparación puede ayudarte'
                    : 'Why preparation may fit',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.deepTeal,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                isSpanish
                    ? 'Ya identificaste tu patrón de consumo y algunas situaciones que pueden provocar ganas de fumar. Practicar herramientas antes de elegir una fecha puede hacer que el siguiente paso se sienta más manejable.'
                    : 'You identified your smoking pattern and situations that may bring on an urge. Practicing coping tools before choosing a date can make the next step feel more manageable.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.tealSecondary,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                isSpanish
                    ? 'Esto es una recomendación flexible, no una evaluación médica. Puedes elegir otra ruta ahora o cambiarla después.'
                    : 'This is a flexible recommendation, not a medical assessment. You can choose another path now or change it later.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedTeal,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('readiness-why-done'),
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isSpanish ? 'Listo' : 'Done'),
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
    return Scaffold(
      key: const ValueKey('functional-readiness-result-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 250) {
              onBack();
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 380;
              final compact = constraints.maxHeight < 760;
              final horizontalPadding = narrow ? 18.0 : 24.0;

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 5 : 10,
                      horizontalPadding,
                      0,
                    ),
                    child: _ReadinessHeader(
                      isSpanish: isSpanish,
                      onBack: onBack,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 5 : 8,
                      horizontalPadding,
                      compact ? 7 : 10,
                    ),
                    child: _ReadinessProgress(isSpanish: isSpanish),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('readiness-content-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 6 : 12,
                        horizontalPadding,
                        18,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ReadinessIllustration(compact: compact),
                              SizedBox(height: compact ? 12 : 20),
                              Text(
                                isSpanish ? 'TU REFLEXIÓN' : 'YOUR REFLECTION',
                                style: const TextStyle(
                                  color: AppColors.mutedTeal,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                isSpanish
                                    ? 'Estás listo para prepararte—a tu propio ritmo.'
                                    : 'You’re ready to prepare—at your own pace.',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: narrow ? 30 : 34,
                                      height: 1.06,
                                    ),
                              ),
                              SizedBox(height: compact ? 9 : 13),
                              Text(
                                isSpanish
                                    ? 'Esto es lo que entendimos de tus respuestas.'
                                    : 'Here is what we heard from your answers.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppColors.tealSecondary,
                                      fontSize: narrow ? 15 : 16,
                                      height: 1.35,
                                    ),
                              ),
                              SizedBox(height: compact ? 14 : 20),
                              _ReflectionCard(
                                isSpanish: isSpanish,
                                usage: _usageLabel(),
                                triggers: _triggerSummary(),
                                startingPoint: _startingPointSummary(),
                              ),
                              const SizedBox(height: 12),
                              _RecommendationCard(
                                isSpanish: isSpanish,
                                selected: selectedPath == ReadinessPath.prepare,
                                onSelect: () =>
                                    onPathChanged(ReadinessPath.prepare),
                                onWhyThisFits: () => _showWhyThisFits(context),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                isSpanish
                                    ? 'PUEDES ELEGIR OTRA RUTA'
                                    : 'YOU CAN CHOOSE A DIFFERENT PATH',
                                style: const TextStyle(
                                  color: AppColors.mutedTeal,
                                  fontSize: 10,
                                  letterSpacing: 1.6,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 9),
                              _AlternativePaths(
                                isSpanish: isSpanish,
                                narrow: narrow,
                                selectedPath: selectedPath,
                                onPathChanged: onPathChanged,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _ReadinessBottomAction(
                    isSpanish: isSpanish,
                    label: _actionLabel(),
                    onContinue: onContinue,
                    horizontalPadding: horizontalPadding,
                    compact: compact,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReadinessHeader extends StatelessWidget {
  const _ReadinessHeader({required this.isSpanish, required this.onBack});

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('readiness-back'),
            tooltip: isSpanish ? 'Atrás' : 'Back',
            onPressed: onBack,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.deepTeal,
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              isSpanish ? 'Tu punto de partida' : 'Your starting point',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
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
                  isSpanish ? 'Completo' : 'Complete',
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 10,
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

class _ReadinessProgress extends StatelessWidget {
  const _ReadinessProgress({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              isSpanish ? 'EVALUACIÓN' : 'ASSESSMENT',
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 10,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            const Text(
              '100%',
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(
            key: ValueKey('readiness-progress'),
            value: 1,
            minHeight: 6,
            backgroundColor: Color(0xFFDCE7E1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
          ),
        ),
      ],
    );
  }
}

class _ReadinessIllustration extends StatelessWidget {
  const _ReadinessIllustration({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 142.0 : 170.0;
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mint.withValues(alpha: 0.45),
                border: Border.all(color: AppColors.mintStrong),
              ),
            ),
            Container(
              width: size * 0.7,
              height: size * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mint,
                border: Border.all(color: AppColors.paper, width: 12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.check_rounded,
                size: size * 0.38,
                color: AppColors.deepTeal,
              ),
            ),
            Positioned(
              right: 5,
              top: size * 0.27,
              child: const CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFFF1F8C7),
                child: Icon(
                  Icons.remove_rounded,
                  color: AppColors.deepTeal,
                ),
              ),
            ),
            Positioned(
              bottom: 2,
              right: size * 0.25,
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.paper,
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.deepTeal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({
    required this.isSpanish,
    required this.usage,
    required this.triggers,
    required this.startingPoint,
  });

  final bool isSpanish;
  final String usage;
  final String triggers;
  final String startingPoint;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('readiness-reflection-card'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _ReflectionRow(
            icon: Icons.smoke_free_rounded,
            iconColor: AppColors.coral,
            iconBackground: AppColors.coralLight,
            label: isSpanish ? 'TU PATRÓN' : 'YOUR PATTERN',
            value: usage,
          ),
          const Divider(height: 1, color: AppColors.border),
          _ReflectionRow(
            icon: Icons.route_rounded,
            iconColor: AppColors.deepTeal,
            iconBackground: AppColors.mint,
            label: isSpanish ? 'DESENCADENANTES' : 'TRIGGERS',
            value: triggers,
          ),
          const Divider(height: 1, color: AppColors.border),
          _ReflectionRow(
            icon: Icons.tune_rounded,
            iconColor: AppColors.deepTeal,
            iconBackground: const Color(0xFFF1F8C7),
            label: isSpanish ? 'PUNTO DE PARTIDA' : 'STARTING POINT',
            value: startingPoint,
          ),
        ],
      ),
    );
  }
}

class _ReflectionRow extends StatelessWidget {
  const _ReflectionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 13,
                    height: 1.25,
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

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.isSpanish,
    required this.selected,
    required this.onSelect,
    required this.onWhyThisFits,
  });

  final bool isSpanish;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onWhyThisFits;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? const Color(0xFF8FCDB5) : AppColors.mintStrong,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        key: const ValueKey('readiness-path-prepare'),
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.deepTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isSpanish ? 'RECOMENDADO' : 'RECOMMENDED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? AppColors.coral : AppColors.tealSecondary,
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                isSpanish ? 'Prepararte' : 'Prepare',
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isSpanish
                    ? 'Practica herramientas y elige una fecha para dejar de fumar en los próximos 7–14 días. Te guiaremos con un paso pequeño cada día.'
                    : 'Practice coping tools and choose a quit date in the next 7–14 days. We’ll guide one small step each day.',
                style: const TextStyle(
                  color: AppColors.tealSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                key: const ValueKey('readiness-why-fit'),
                onPressed: onWhyThisFits,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.deepTeal,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                label: Text(
                  isSpanish
                      ? 'Por qué encaja contigo'
                      : 'Why this fits your answers',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlternativePaths extends StatelessWidget {
  const _AlternativePaths({
    required this.isSpanish,
    required this.narrow,
    required this.selectedPath,
    required this.onPathChanged,
  });

  final bool isSpanish;
  final bool narrow;
  final ReadinessPath selectedPath;
  final ValueChanged<ReadinessPath> onPathChanged;

  @override
  Widget build(BuildContext context) {
    final explore = _AlternativePathCard(
      key: const ValueKey('readiness-path-explore'),
      icon: Icons.add_rounded,
      iconColor: AppColors.deepTeal,
      iconBackground: AppColors.mint,
      title: isSpanish ? 'Explorar primero' : 'Explore first',
      subtitle: isSpanish
          ? 'Aprende sin fijar una fecha'
          : 'Learn without setting a date',
      selected: selectedPath == ReadinessPath.explore,
      onTap: () => onPathChanged(ReadinessPath.explore),
    );
    final connect = _AlternativePathCard(
      key: const ValueKey('readiness-path-connect'),
      icon: Icons.support_agent_rounded,
      iconColor: AppColors.coral,
      iconBackground: AppColors.coralLight,
      title: isSpanish ? 'Conectar' : 'Connect',
      subtitle: isSpanish
          ? 'Habla con un asesor o equipo de atención'
          : 'Talk with a coach or care team',
      selected: selectedPath == ReadinessPath.connect,
      onTap: () => onPathChanged(ReadinessPath.connect),
    );

    if (narrow) {
      return Column(
        children: [
          explore,
          const SizedBox(height: 9),
          connect,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: explore),
        const SizedBox(width: 10),
        Expanded(child: connect),
      ],
    );
  }
}

class _AlternativePathCard extends StatelessWidget {
  const _AlternativePathCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.coralLight : AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.coral : AppColors.border,
          width: selected ? 1.7 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.tealSecondary,
                        fontSize: 10.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? AppColors.coral : AppColors.deepTeal,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadinessBottomAction extends StatelessWidget {
  const _ReadinessBottomAction({
    required this.isSpanish,
    required this.label,
    required this.onContinue,
    required this.horizontalPadding,
    required this.compact,
  });

  final bool isSpanish;
  final String label;
  final VoidCallback onContinue;
  final double horizontalPadding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: Color(0x1A123C37))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          compact ? 8 : 11,
          horizontalPadding,
          compact ? 8 : 11,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: compact ? 54 : 60,
                  child: FilledButton(
                    key: const ValueKey('readiness-continue'),
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                            ),
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
                        ? 'Tú tienes el control. Cambia tu ruta cuando quieras.'
                        : 'You’re in control. Change your path anytime.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
