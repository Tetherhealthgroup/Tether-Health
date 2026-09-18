import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ConsentPrivacyScreen extends StatelessWidget {
  const ConsentPrivacyScreen({
    required this.isSpanish,
    required this.helpfulReminders,
    required this.shareWithCareTeam,
    required this.helpImproveBreatheFree,
    required this.onHelpfulRemindersChanged,
    required this.onShareWithCareTeamChanged,
    required this.onHelpImproveBreatheFreeChanged,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final bool isSpanish;
  final bool helpfulReminders;
  final bool shareWithCareTeam;
  final bool helpImproveBreatheFree;
  final ValueChanged<bool> onHelpfulRemindersChanged;
  final ValueChanged<bool> onShareWithCareTeamChanged;
  final ValueChanged<bool> onHelpImproveBreatheFreeChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  void _showPrivacyReview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.deepTeal,
                  size: 27,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSpanish
                    ? 'Términos y Aviso de privacidad'
                    : 'Terms and Privacy Notice',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.deepTeal,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                isSpanish
                    ? 'Esta versión de desarrollo muestra cómo se presentarán los documentos legales. Antes del lanzamiento, aquí estarán los Términos de uso y el Aviso de privacidad completos, con las prácticas de datos, los períodos de conservación y tus derechos.'
                    : 'This development build demonstrates how the legal documents will be presented. Before release, the complete Terms of Use and Privacy Notice will appear here, including data practices, retention periods, and your rights.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.tealSecondary,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 14),
              Text(
                isSpanish
                    ? 'Los controles opcionales se pueden cambiar más adelante en Configuración. Las funciones obligatorias se limitarán a lo necesario para proporcionar y proteger el servicio.'
                    : 'Optional controls can be changed later in Settings. Required processing will be limited to what is necessary to provide and secure the service.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.tealSecondary,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('consent-sheet-done'),
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
      key: const ValueKey('functional-consent-privacy-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity > 250) {
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
                      compact ? 6 : 12,
                      horizontalPadding,
                      4,
                    ),
                    child: _ConsentHeader(
                      isSpanish: isSpanish,
                      onBack: onBack,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('consent-content-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 2 : 8,
                        horizontalPadding,
                        18,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ConsentHero(compact: compact),
                              SizedBox(height: compact ? 8 : 14),
                              Text(
                                isSpanish ? 'TU PRIVACIDAD' : 'YOUR PRIVACY',
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
                                    ? 'Tu historia sigue siendo tuya.'
                                    : 'Your story stays yours.',
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
                                    ? 'Elige cómo se usa tu información. Los elementos obligatorios mantienen la aplicación funcionando; las opciones se pueden cambiar en cualquier momento.'
                                    : 'Choose how your information is used. Required items keep the app working; optional choices can change anytime.',
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
                              _RequiredConsentCard(
                                isSpanish: isSpanish,
                                onReview: () => _showPrivacyReview(context),
                              ),
                              const SizedBox(height: 12),
                              _OptionalConsentCard(
                                isSpanish: isSpanish,
                                helpfulReminders: helpfulReminders,
                                shareWithCareTeam: shareWithCareTeam,
                                helpImproveBreatheFree: helpImproveBreatheFree,
                                onHelpfulRemindersChanged:
                                    onHelpfulRemindersChanged,
                                onShareWithCareTeamChanged:
                                    onShareWithCareTeamChanged,
                                onHelpImproveBreatheFreeChanged:
                                    onHelpImproveBreatheFreeChanged,
                              ),
                              const SizedBox(height: 14),
                              _TrustNote(isSpanish: isSpanish),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _ConsentBottomAction(
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

class _ConsentHeader extends StatelessWidget {
  const _ConsentHeader({
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
            key: const ValueKey('consent-back'),
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
              '2 OF 3',
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

class _ConsentHero extends StatelessWidget {
  const _ConsentHero({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 132 : 188,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _ConsentHeroPainter()),
          ),
          Container(
            width: compact ? 72 : 96,
            height: compact ? 72 : 96,
            decoration: const BoxDecoration(
              color: AppColors.paper,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: CustomPaint(
              painter: const _ShieldPainter(),
              child: Icon(
                Icons.check_rounded,
                color: AppColors.deepTeal,
                size: compact ? 42 : 55,
              ),
            ),
          ),
          Positioned(
            left: compact ? 58 : 72,
            top: compact ? 24 : 34,
            child: _HeroBadge(
              size: compact ? 34 : 42,
              background: AppColors.coralLight,
              icon: Icons.check_rounded,
              iconColor: AppColors.coral,
            ),
          ),
          Positioned(
            right: compact ? 56 : 70,
            bottom: compact ? 22 : 30,
            child: _HeroBadge(
              size: compact ? 34 : 42,
              background: const Color(0xFFF3F8CE),
              icon: Icons.lock_outline_rounded,
              iconColor: AppColors.deepTeal,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.size,
    required this.background,
    required this.icon,
    required this.iconColor,
  });

  final double size;
  final Color background;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: size * .58),
    );
  }
}

class _ConsentHeroPainter extends CustomPainter {
  const _ConsentHeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .45;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.mint.withValues(alpha: .42)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.mintStrong.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      center,
      radius * .72,
      Paint()
        ..color = AppColors.mintStrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ConsentHeroPainter oldDelegate) => false;
}

class _ShieldPainter extends CustomPainter {
  const _ShieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .22, size.height * .21)
      ..lineTo(size.width * .5, size.height * .11)
      ..lineTo(size.width * .78, size.height * .21)
      ..lineTo(size.width * .78, size.height * .53)
      ..quadraticBezierTo(
        size.width * .72,
        size.height * .73,
        size.width * .5,
        size.height * .86,
      )
      ..quadraticBezierTo(
        size.width * .28,
        size.height * .73,
        size.width * .22,
        size.height * .53,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = AppColors.mintStrong.withValues(alpha: .72),
    );
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) => false;
}

class _RequiredConsentCard extends StatelessWidget {
  const _RequiredConsentCard({
    required this.isSpanish,
    required this.onReview,
  });

  final bool isSpanish;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          _CardSectionHeader(
            title: isSpanish
                ? 'OBLIGATORIO PARA USAR BREATHEFREE'
                : 'REQUIRED TO USE BREATHEFREE',
            badge: isSpanish ? 'Obligatorio' : 'Required',
          ),
          const SizedBox(height: 10),
          _ConsentInfoRow(
            icon: Icons.check_rounded,
            iconBackground: AppColors.deepTeal,
            iconColor: Colors.white,
            title: isSpanish
                ? 'Datos esenciales de la aplicación'
                : 'Essential app data',
            subtitle: isSpanish
                ? 'Guarda tu cuenta, plan para dejar de fumar y progreso de forma segura.'
                : 'Save your account, quit plan, and progress securely.',
          ),
          const Divider(height: 18),
          _ConsentInfoRow(
            icon: Icons.check_rounded,
            iconBackground: AppColors.deepTeal,
            iconColor: Colors.white,
            title: isSpanish ? 'Información de salud' : 'Health information',
            subtitle: isSpanish
                ? 'Personaliza tu plan, herramientas de apoyo e información de recuperación.'
                : 'Personalize your plan, support tools, and recovery insights.',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('consent-review-privacy'),
                onTap: onReview,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          isSpanish
                              ? 'Revisar Términos y Aviso de privacidad'
                              : 'Review Terms and Privacy Notice',
                          style: const TextStyle(
                            color: AppColors.deepTeal,
                            fontSize: 12,
                            height: 1.2,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.deepTeal,
                        size: 17,
                      ),
                    ],
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

class _OptionalConsentCard extends StatelessWidget {
  const _OptionalConsentCard({
    required this.isSpanish,
    required this.helpfulReminders,
    required this.shareWithCareTeam,
    required this.helpImproveBreatheFree,
    required this.onHelpfulRemindersChanged,
    required this.onShareWithCareTeamChanged,
    required this.onHelpImproveBreatheFreeChanged,
  });

  final bool isSpanish;
  final bool helpfulReminders;
  final bool shareWithCareTeam;
  final bool helpImproveBreatheFree;
  final ValueChanged<bool> onHelpfulRemindersChanged;
  final ValueChanged<bool> onShareWithCareTeamChanged;
  final ValueChanged<bool> onHelpImproveBreatheFreeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mintStrong),
      ),
      child: Column(
        children: [
          _CardSectionHeader(
            title: isSpanish ? 'TUS OPCIONES' : 'YOUR CHOICES',
            badge: isSpanish ? 'Opcional' : 'Optional',
            lightBadge: true,
          ),
          const SizedBox(height: 7),
          _ConsentSwitchRow(
            switchKey: const ValueKey('consent-helpful-reminders'),
            icon: Icons.chat_bubble_outline_rounded,
            title: isSpanish ? 'Recordatorios útiles' : 'Helpful reminders',
            subtitle: isSpanish
                ? 'Recibe controles privados y recordatorios del plan.'
                : 'Receive private check-ins and plan reminders.',
            value: helpfulReminders,
            onChanged: onHelpfulRemindersChanged,
          ),
          const Divider(height: 1),
          _ConsentSwitchRow(
            switchKey: const ValueKey('consent-share-care-team'),
            icon: Icons.person_outline_rounded,
            title: isSpanish
                ? 'Compartir con mi equipo de atención'
                : 'Share with my care team',
            subtitle: isSpanish
                ? 'Permite que un profesional conectado vea resúmenes de progreso.'
                : 'Allow a connected clinician to view progress summaries.',
            value: shareWithCareTeam,
            onChanged: onShareWithCareTeamChanged,
          ),
          const Divider(height: 1),
          _ConsentSwitchRow(
            switchKey: const ValueKey('consent-help-improve'),
            icon: Icons.show_chart_rounded,
            title: isSpanish
                ? 'Ayudar a mejorar BreatheFree'
                : 'Help improve BreatheFree',
            subtitle: isSpanish
                ? 'Aporta información desidentificada a investigaciones aprobadas.'
                : 'Contribute de-identified information to approved research.',
            value: helpImproveBreatheFree,
            onChanged: onHelpImproveBreatheFreeChanged,
          ),
        ],
      ),
    );
  }
}

class _CardSectionHeader extends StatelessWidget {
  const _CardSectionHeader({
    required this.title,
    required this.badge,
    this.lightBadge = false,
  });

  final String title;
  final String badge;
  final bool lightBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 10,
              height: 1.25,
              letterSpacing: 1.7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: lightBadge ? AppColors.paper : AppColors.mint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsentInfoRow extends StatelessWidget {
  const _ConsentInfoRow({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 11),
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.tealSecondary,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsentSwitchRow extends StatelessWidget {
  const _ConsentSwitchRow({
    required this.switchKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.paper,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.deepTeal, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 13.5,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            key: switchKey,
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.deepTeal,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: AppColors.coralLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.coral,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSpanish
                    ? 'Sin anuncios. Sin financiación de la industria tabacalera.'
                    : 'No ads. No tobacco-industry funding.',
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                isSpanish
                    ? 'Nunca vendemos información de salud del paciente.'
                    : 'We never sell patient health information.',
                style: const TextStyle(
                  color: AppColors.tealSecondary,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsentBottomAction extends StatelessWidget {
  const _ConsentBottomAction({
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
          compact ? 8 : 11,
          horizontalPadding,
          compact ? 7 : 10,
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
                    key: const ValueKey('consent-agree-continue'),
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isSpanish
                                ? 'Aceptar y continuar'
                                : 'Agree and continue',
                            style: const TextStyle(
                              fontSize: 16,
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
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  Text(
                    isSpanish
                        ? 'Puedes cambiar las opciones en Configuración.'
                        : 'You can change optional choices anytime in Settings.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PageDot(),
                    SizedBox(width: 7),
                    _PageDot(active: true),
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
        color: active ? AppColors.coral : AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
