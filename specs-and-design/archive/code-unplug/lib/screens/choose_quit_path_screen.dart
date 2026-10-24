import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum QuitPlanPath { setQuitDate, quitToday, reduceGradually }

class ChooseQuitPathScreen extends StatelessWidget {
  const ChooseQuitPathScreen({
    required this.isSpanish,
    required this.selectedPath,
    required this.onPathChanged,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final bool isSpanish;
  final QuitPlanPath selectedPath;
  final ValueChanged<QuitPlanPath> onPathChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  String _pathLabel(QuitPlanPath path) {
    return switch (path) {
      QuitPlanPath.setQuitDate =>
        isSpanish ? 'Elegir una fecha' : 'Set a quit date',
      QuitPlanPath.quitToday => isSpanish ? 'Dejar de fumar hoy' : 'Quit today',
      QuitPlanPath.reduceGradually =>
        isSpanish ? 'Reducir gradualmente' : 'Reduce gradually',
    };
  }

  String _savedMessage() {
    final path = _pathLabel(selectedPath);
    return isSpanish
        ? '$path seleccionado · Guardado automáticamente'
        : '$path selected · Saved automatically';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('functional-choose-quit-path-screen'),
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
                    child: _QuitPathHeader(
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
                    child: _QuitPlanProgress(isSpanish: isSpanish),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('quit-path-content-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 5 : 10,
                        horizontalPadding,
                        18,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PathIllustration(compact: compact),
                              SizedBox(height: compact ? 12 : 20),
                              Text(
                                isSpanish
                                    ? 'ELIGE TU CAMINO'
                                    : 'CHOOSE YOUR PATH',
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
                                    ? '¿Qué te parece posible ahora mismo?'
                                    : 'What feels possible right now?',
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
                                    ? 'No hay un lugar incorrecto para empezar. Elige lo que se adapte a ti.'
                                    : 'There is no wrong place to start. Choose what fits you.',
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
                              _QuitPathCard(
                                key: const ValueKey(
                                  'quit-path-choice-setQuitDate',
                                ),
                                selectionKey: const ValueKey(
                                  'quit-path-selected-setQuitDate',
                                ),
                                title: _pathLabel(QuitPlanPath.setQuitDate),
                                description: isSpanish
                                    ? 'Prepárate durante 7–14 días y luego deja de fumar por completo en la fecha que elijas. Te guiaremos con un paso pequeño cada día.'
                                    : 'Prepare for 7–14 days, then stop completely on the date you choose. We’ll guide one small step each day.',
                                supportingText: isSpanish
                                    ? 'Coincide con tu preferencia de preparación'
                                    : 'Matches your preparation preference',
                                icon: Icons.event_available_rounded,
                                iconColor: AppColors.coral,
                                iconBackground: AppColors.coralLight,
                                recommended: true,
                                recommendedLabel:
                                    isSpanish ? 'RECOMENDADO' : 'RECOMMENDED',
                                selected:
                                    selectedPath == QuitPlanPath.setQuitDate,
                                onTap: () => onPathChanged(
                                  QuitPlanPath.setQuitDate,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _QuitPathCard(
                                key: const ValueKey(
                                  'quit-path-choice-quitToday',
                                ),
                                selectionKey: const ValueKey(
                                  'quit-path-selected-quitToday',
                                ),
                                title: _pathLabel(QuitPlanPath.quitToday),
                                description: isSpanish
                                    ? 'Empieza ahora tu tiempo sin fumar y recibe apoyo adicional durante el primer día.'
                                    : 'Begin your smoke-free time now and get extra support through the first day.',
                                icon: Icons.schedule_rounded,
                                iconColor: AppColors.coral,
                                iconBackground: AppColors.coralLight,
                                selected:
                                    selectedPath == QuitPlanPath.quitToday,
                                onTap: () => onPathChanged(
                                  QuitPlanPath.quitToday,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _QuitPathCard(
                                key: const ValueKey(
                                  'quit-path-choice-reduceGradually',
                                ),
                                selectionKey: const ValueKey(
                                  'quit-path-selected-reduceGradually',
                                ),
                                title: _pathLabel(QuitPlanPath.reduceGradually),
                                description: isSpanish
                                    ? 'Sigue un programa de reducción gradual y avanza hacia dejar de fumar por completo en una fecha futura.'
                                    : 'Follow a step-down schedule and work toward stopping completely on a future date.',
                                icon: Icons.format_align_center_rounded,
                                iconColor: AppColors.deepTeal,
                                iconBackground: AppColors.mint,
                                selected: selectedPath ==
                                    QuitPlanPath.reduceGradually,
                                onTap: () => onPathChanged(
                                  QuitPlanPath.reduceGradually,
                                ),
                              ),
                              const SizedBox(height: 13),
                              _FlexiblePathNote(isSpanish: isSpanish),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _QuitPathBottomAction(
                    isSpanish: isSpanish,
                    savedMessage: _savedMessage(),
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

class _QuitPathHeader extends StatelessWidget {
  const _QuitPathHeader({required this.isSpanish, required this.onBack});

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('quit-path-back'),
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
              isSpanish ? 'Crea tu plan' : 'Build your plan',
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              isSpanish ? '1 DE 5' : '1 OF 5',
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuitPlanProgress extends StatelessWidget {
  const _QuitPlanProgress({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              isSpanish ? 'PLAN PARA DEJARLO' : 'QUIT PLAN',
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 10,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            const Text(
              '20%',
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
            key: ValueKey('quit-path-progress'),
            value: 0.2,
            minHeight: 6,
            backgroundColor: Color(0xFFDCE7E1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
          ),
        ),
      ],
    );
  }
}

class _PathIllustration extends StatelessWidget {
  const _PathIllustration({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 136.0 : 164.0;
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
                color: AppColors.mint.withValues(alpha: 0.4),
                border: Border.all(color: AppColors.mintStrong),
              ),
            ),
            Container(
              width: size * 0.76,
              height: size * 0.76,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mint,
              ),
            ),
            CustomPaint(
              size: Size(size * 0.58, size * 0.58),
              painter: _PathPainter(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.deepTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height * 0.53);
    final topLeft = Offset(size.width * 0.2, size.height * 0.23);
    final topRight = Offset(size.width * 0.8, size.height * 0.23);
    final bottom = Offset(size.width / 2, size.height * 0.87);

    canvas.drawLine(bottom, center, line);
    canvas.drawLine(center, topLeft, line);
    canvas.drawLine(center, topRight, line);
    canvas.drawLine(center, Offset(size.width / 2, size.height * 0.15), line);

    final node = Paint()
      ..color = AppColors.paper
      ..style = PaintingStyle.fill;
    final nodeBorder = Paint()
      ..color = AppColors.deepTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final point in [topLeft, topRight]) {
      canvas.drawCircle(point, 13, node);
      canvas.drawCircle(point, 13, nodeBorder);
    }
    canvas.drawCircle(bottom, 7, Paint()..color = AppColors.coral);
    final selected = Offset(size.width / 2, size.height * 0.11);
    canvas.drawCircle(selected, 13, Paint()..color = AppColors.coral);
    final check = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final checkPath = Path()
      ..moveTo(selected.dx - 6, selected.dy)
      ..lineTo(selected.dx - 1, selected.dy + 5)
      ..lineTo(selected.dx + 7, selected.dy - 6);
    canvas.drawPath(checkPath, check);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QuitPathCard extends StatelessWidget {
  const _QuitPathCard({
    required this.selectionKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.selected,
    required this.onTap,
    this.supportingText,
    this.recommended = false,
    this.recommendedLabel = 'RECOMMENDED',
    super.key,
  });

  final Key selectionKey;
  final String title;
  final String description;
  final String? supportingText;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool recommended;
  final String recommendedLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mint : AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.coral : AppColors.border,
          width: selected ? 1.8 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.deepTeal,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (recommended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepTeal,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        recommendedLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  else
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      key: selected ? selectionKey : null,
                      color: selected ? AppColors.coral : AppColors.border,
                      size: 28,
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.tealSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              if (supportingText != null) ...[
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      key: selected ? selectionKey : null,
                      color:
                          selected ? AppColors.deepTeal : AppColors.mutedTeal,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        supportingText!,
                        style: const TextStyle(
                          color: AppColors.deepTeal,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FlexiblePathNote extends StatelessWidget {
  const _FlexiblePathNote({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.mint,
          child: Icon(
            Icons.check_rounded,
            color: AppColors.deepTeal,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isSpanish
                ? 'Tu camino es flexible. Puedes ajustarlo en cualquier momento.'
                : 'Your path is flexible. You can adjust it at any time.',
            style: const TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuitPathBottomAction extends StatelessWidget {
  const _QuitPathBottomAction({
    required this.isSpanish,
    required this.savedMessage,
    required this.onContinue,
    required this.horizontalPadding,
    required this.compact,
  });

  final bool isSpanish;
  final String savedMessage;
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
                    key: const ValueKey('quit-path-continue'),
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
                            isSpanish
                                ? 'Continuar con este camino'
                                : 'Continue with this path',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
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
                    savedMessage,
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
