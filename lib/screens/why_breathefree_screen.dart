import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class WhyBreatheFreeScreen extends StatelessWidget {
  const WhyBreatheFreeScreen({
    required this.isSpanish,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final bool isSpanish;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  void _showCardDetails(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 27),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.deepTeal,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.tealSecondary,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('why-sheet-done'),
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
      key: const ValueKey('functional-why-breathefree-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity > 250) {
              onBack();
            } else if (velocity < -250) {
              onContinue();
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
                      compact ? 6 : 12,
                      horizontalPadding,
                      4,
                    ),
                    child: _WhyHeader(
                      isSpanish: isSpanish,
                      onBack: onBack,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('why-content-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 2 : 8,
                        horizontalPadding,
                        16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _WhyHero(compact: compact),
                              SizedBox(height: compact ? 8 : 14),
                              Text(
                                isSpanish
                                    ? 'UNA MEJOR FORMA DE DEJARLO'
                                    : 'A BETTER WAY TO QUIT',
                                style: const TextStyle(
                                  color: AppColors.mutedTeal,
                                  fontSize: 12,
                                  height: 1.2,
                                  letterSpacing: 2.1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                isSpanish
                                    ? 'Apoyo para los momentos más importantes.'
                                    : 'Support for the moments that matter most.',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: narrow ? 32 : 36,
                                      height: 1.06,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isSpanish
                                    ? 'BreatheFree responde a lo que necesitas ahora y te ayuda a proteger el progreso que ya has logrado.'
                                    : 'BreatheFree responds to what you need now—and helps you protect the progress you have already made.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppColors.tealSecondary,
                                      fontSize: narrow ? 15 : 16,
                                      height: 1.4,
                                    ),
                              ),
                              SizedBox(height: compact ? 14 : 20),
                              _WhySupportCard(
                                cardKey: const ValueKey('why-card-craving'),
                                icon: Icons.air_rounded,
                                iconColor: AppColors.coral,
                                iconBackground: AppColors.coralLight,
                                title: isSpanish
                                    ? 'Cuando llega un antojo'
                                    : 'When a craving hits',
                                subtitle: isSpanish
                                    ? 'Abre una herramienta calmante con un toque, incluso sin conexión.'
                                    : 'Open a calming tool in one tap—available offline.',
                                onTap: () => _showCardDetails(
                                  context,
                                  title: isSpanish
                                      ? 'Cuando llega un antojo'
                                      : 'When a craving hits',
                                  message: isSpanish
                                      ? 'Usa una respiración guiada, una distracción breve o tu razón principal para dejar de fumar. Las herramientas esenciales estarán disponibles sin conexión.'
                                      : 'Use guided breathing, a brief distraction, or your top reason for quitting. Essential tools will remain available offline.',
                                  icon: Icons.air_rounded,
                                  iconColor: AppColors.coral,
                                  iconBackground: AppColors.coralLight,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _WhySupportCard(
                                cardKey: const ValueKey('why-card-healing'),
                                icon: Icons.bar_chart_rounded,
                                iconColor: AppColors.deepTeal,
                                iconBackground: AppColors.mint,
                                title: isSpanish
                                    ? 'Mientras tu cuerpo se recupera'
                                    : 'As your body heals',
                                subtitle: isSpanish
                                    ? 'Consulta el tiempo sin fumar, el dinero ahorrado y tu recuperación.'
                                    : 'See smoke-free time, money saved, and recovery.',
                                onTap: () => _showCardDetails(
                                  context,
                                  title: isSpanish
                                      ? 'Mientras tu cuerpo se recupera'
                                      : 'As your body heals',
                                  message: isSpanish
                                      ? 'Sigue tu tiempo sin fumar y el dinero que has elegido no gastar en tabaco. Los hitos de recuperación serán educativos y no sustituirán el consejo médico.'
                                      : 'Track your smoke-free time and the money you chose not to spend on tobacco. Recovery milestones will be educational and will not replace medical advice.',
                                  icon: Icons.bar_chart_rounded,
                                  iconColor: AppColors.deepTeal,
                                  iconBackground: AppColors.mint,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _WhySupportCard(
                                cardKey: const ValueKey('why-card-slip'),
                                icon: Icons.check_rounded,
                                iconColor: AppColors.deepTeal,
                                iconBackground: AppColors.paper,
                                emphasized: true,
                                title: isSpanish
                                    ? 'Si ocurre un desliz'
                                    : 'If a slip happens',
                                subtitle: isSpanish
                                    ? 'Conserva tu progreso. Aprende, ajusta y continúa.'
                                    : 'Keep your progress. Learn, adjust, and continue.',
                                onTap: () => _showCardDetails(
                                  context,
                                  title: isSpanish
                                      ? 'Si ocurre un desliz'
                                      : 'If a slip happens',
                                  message: isSpanish
                                      ? 'Un desliz no borra el esfuerzo que ya hiciste. BreatheFree te ayudará a registrar lo ocurrido sin juicios y a elegir tu próximo paso.'
                                      : 'A slip does not erase the work you have already done. BreatheFree will help you record what happened without judgment and choose your next step.',
                                  icon: Icons.check_rounded,
                                  iconColor: AppColors.deepTeal,
                                  iconBackground: AppColors.mint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _WhyBottomAction(
                    isSpanish: isSpanish,
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

class _WhyHeader extends StatelessWidget {
  const _WhyHeader({
    required this.isSpanish,
    required this.onBack,
  });

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('why-back'),
            tooltip: isSpanish ? 'Atrás' : 'Back',
            onPressed: onBack,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.deepTeal,
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco_rounded, color: AppColors.coral, size: 23),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'BreatheFree',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              '1 OF 3',
              style: TextStyle(
                color: AppColors.deepTeal,
                fontSize: 10,
                letterSpacing: .6,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyHero extends StatelessWidget {
  const _WhyHero({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 146 : 205,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final nodeSize = compact ? 48.0 : 62.0;
          final centerSize = compact ? 66.0 : 82.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _WhyHeroPainter()),
              ),
              _WhyOrbitNode(
                size: centerSize,
                icon: Icons.wifi_tethering_rounded,
                iconColor: AppColors.deepTeal,
                background: AppColors.paper,
                shadow: true,
              ),
              Positioned(
                left: constraints.maxWidth * .18,
                top: compact ? 10 : 25,
                child: _WhyOrbitNode(
                  size: nodeSize,
                  icon: Icons.air_rounded,
                  iconColor: AppColors.coral,
                  background: AppColors.paper,
                  shadow: true,
                ),
              ),
              Positioned(
                right: constraints.maxWidth * .14,
                top: compact ? 61 : 91,
                child: _WhyOrbitNode(
                  size: nodeSize,
                  icon: Icons.bar_chart_rounded,
                  iconColor: AppColors.deepTeal,
                  background: AppColors.paper,
                  shadow: true,
                ),
              ),
              Positioned(
                bottom: 0,
                child: _WhyOrbitNode(
                  size: nodeSize,
                  icon: Icons.check_rounded,
                  iconColor: AppColors.deepTeal,
                  background: const Color(0xFFF3F8CE),
                  shadow: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WhyOrbitNode extends StatelessWidget {
  const _WhyOrbitNode({
    required this.size,
    required this.icon,
    required this.iconColor,
    required this.background,
    this.shadow = false,
  });

  final double size;
  final IconData icon;
  final Color iconColor;
  final Color background;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 15,
                  offset: Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: iconColor, size: size * .46),
    );
  }
}

class _WhyHeroPainter extends CustomPainter {
  const _WhyHeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .46;

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = AppColors.mint.withValues(alpha: .78),
    );
    canvas.drawCircle(
      center,
      radius * .76,
      Paint()..color = AppColors.paper,
    );
    canvas.drawCircle(
      center,
      radius * .55,
      Paint()..color = AppColors.mintStrong.withValues(alpha: .72),
    );

    final orbit = Paint()
      ..color = AppColors.coral.withValues(alpha: .82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * .87),
      math.pi * .82,
      math.pi * 1.02,
      false,
      orbit,
    );

    final connector = Paint()
      ..color = AppColors.mutedTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * .66),
      math.pi * 1.03,
      math.pi * .38,
      false,
      connector,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * .78),
      math.pi * 1.82,
      math.pi * .30,
      false,
      connector,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * .70),
      math.pi * .18,
      math.pi * .44,
      false,
      connector,
    );
  }

  @override
  bool shouldRepaint(covariant _WhyHeroPainter oldDelegate) => false;
}

class _WhySupportCard extends StatelessWidget {
  const _WhySupportCard({
    required this.cardKey,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  final Key cardKey;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: cardKey,
      color: emphasized ? AppColors.mint : AppColors.paper,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: emphasized ? AppColors.mintStrong : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.tealSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.mutedTeal,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhyBottomAction extends StatelessWidget {
  const _WhyBottomAction({
    required this.isSpanish,
    required this.onContinue,
    required this.horizontalPadding,
    required this.compact,
  });

  final bool isSpanish;
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
          compact ? 9 : 12,
          horizontalPadding,
          compact ? 8 : 12,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: compact ? 50 : 54,
                  child: FilledButton(
                    key: const ValueKey('why-continue'),
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
                        Text(
                          isSpanish ? 'Continuar' : 'Continue',
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
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PageDot(active: true),
                    SizedBox(width: 7),
                    _PageDot(),
                    SizedBox(width: 7),
                    _PageDot(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: active ? 20 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? AppColors.deepTeal : AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
