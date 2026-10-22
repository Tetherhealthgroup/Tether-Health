import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import '../theme/app_colors.dart';
import '../widgets/large_text.dart';

enum WelcomeLanguage { english, spanish }

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    required this.language,
    required this.onLanguageSelected,
    required this.onGetStarted,
    required this.onSignIn,
    super.key,
  });

  final WelcomeLanguage language;
  final ValueChanged<WelcomeLanguage> onLanguageSelected;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool get _isSpanish => widget.language == WelcomeLanguage.spanish;

  void _selectLanguage(WelcomeLanguage language) {
    widget.onLanguageSelected(language);
  }

  void _showInformationSheet({
    required String title,
    required String message,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.deepTeal,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)
                      .welcomeShowInformationSheetText),
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
    // The text comes from the app locale; the language the screen was given
    // must be the same one.
    assert(
      (widget.language == WelcomeLanguage.spanish) ==
          (Localizations.localeOf(context).languageCode == 'es'),
      'the screen language must match the app locale',
    );
    return Scaffold(
      key: const ValueKey('functional-welcome-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth < 380 ? 20.0 : 26.0;
              final compactHeight = constraints.maxHeight < 880;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  compactHeight ? 10 : 22,
                  horizontalPadding,
                  compactHeight ? 20 : 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WelcomeHeader(
                          language: widget.language,
                          onLanguageSelected: _selectLanguage,
                        ),
                        SizedBox(height: compactHeight ? 12 : 26),
                        _WelcomeHero(compact: compactHeight),
                        SizedBox(height: compactHeight ? 12 : 24),
                        Text(
                          AppLocalizations.of(context).welcomeText,
                          style: const TextStyle(
                            color: AppColors.mutedTeal,
                            fontSize: 12,
                            height: 1.2,
                            letterSpacing: 2.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: compactHeight ? 8 : 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final headline =
                                AppLocalizations.of(context).welcomeHeadline;
                            final style = Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: compactHeight ? 36 : 40,
                                      height: compactHeight ? 1.05 : 1.08,
                                    ) ??
                                const TextStyle();
                            return Text(
                              headline,
                              // Already the largest text on screen; past 180%
                              // its longest words no longer fit a phone-width
                              // line, and on the narrowest phones a word too
                              // long for the line scales down instead of
                              // splitting.
                              textScaler: wordFitScaler(
                                context,
                                headline,
                                style,
                                constraints.maxWidth,
                                maxScaleFactor: 1.8,
                              ),
                              style: style,
                            );
                          },
                        ),
                        SizedBox(height: compactHeight ? 10 : 18),
                        Text(
                          AppLocalizations.of(context).welcomeText2,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: compactHeight ? 16 : 17,
                                    height: compactHeight ? 1.35 : 1.48,
                                  ),
                        ),
                        SizedBox(height: compactHeight ? 14 : 24),
                        _WelcomeBenefits(isSpanish: _isSpanish),
                        SizedBox(height: compactHeight ? 16 : 28),
                        FilledButton(
                          key: const ValueKey('welcome-get-started'),
                          onPressed: widget.onGetStarted,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.deepTeal,
                            foregroundColor: Colors.white,
                            // A minimum, not a fixed height, so large text
                            // grows the button instead of being clipped.
                            minimumSize:
                                Size.fromHeight(compactHeight ? 54 : 58),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  AppLocalizations.of(context).welcomeText3,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 17,
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
                        SizedBox(height: compactHeight ? 2 : 10),
                        Center(
                          child: TextButton(
                            key: const ValueKey('welcome-sign-in'),
                            onPressed: widget.onSignIn,
                            child: Text(
                              AppLocalizations.of(context).welcomeSignInText,
                              style: const TextStyle(
                                color: AppColors.deepTeal,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compactHeight ? 2 : 12),
                        OutlinedButton(
                          key: const ValueKey('welcome-spanish'),
                          onPressed: () => _selectLanguage(
                            widget.language == WelcomeLanguage.spanish
                                ? WelcomeLanguage.english
                                : WelcomeLanguage.spanish,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.deepTeal,
                            minimumSize:
                                Size.fromHeight(compactHeight ? 52 : 56),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).welcomeText4,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(height: compactHeight ? 6 : 12),
                        _WelcomeLegalText(
                          isSpanish: _isSpanish,
                          onTerms: () => _showInformationSheet(
                            title: AppLocalizations.of(context).welcomeTitle,
                            message:
                                AppLocalizations.of(context).welcomeMessage,
                          ),
                          onPrivacy: () => _showInformationSheet(
                            title: AppLocalizations.of(context).welcomeTitle2,
                            message:
                                AppLocalizations.of(context).welcomeMessage2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({
    required this.language,
    required this.onLanguageSelected,
  });

  final WelcomeLanguage language;
  final ValueChanged<WelcomeLanguage> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    // A full-width Wrap rather than a Row: when large text leaves no room
    // beside the brand, the language menu moves to its own line instead of
    // squeezing the brand to an ellipsis.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.deepTeal, width: 2),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 24,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(width: 10),
              // The brand is a single word: at the largest sizes it scales
              // down to the line instead of being cut to "B…".
              const Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'BreatheFree',
                    maxLines: 1,
                    style: TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          PopupMenuButton<WelcomeLanguage>(
            key: const ValueKey('welcome-language-menu'),
            initialValue: language,
            onSelected: onLanguageSelected,
            color: AppColors.paper,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: WelcomeLanguage.english,
                child: Text('English'),
              ),
              PopupMenuItem(
                value: WelcomeLanguage.spanish,
                child: Text('Español'),
              ),
            ],
            child: Container(
              constraints: const BoxConstraints(minHeight: 42),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 18,
                    color: AppColors.deepTeal,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      language == WelcomeLanguage.spanish
                          ? 'Español'
                          : 'English',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.deepTeal,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.compact});

  final bool compact;

  static const _noJudgment = _HeroCallout(
    icon: Icons.location_on_rounded,
    iconColor: AppColors.coral,
    iconBackground: AppColors.coralLight,
    title: 'No judgment',
    subtitle: 'just support',
  );

  static const _private = _HeroCallout(
    icon: Icons.check_rounded,
    iconColor: AppColors.deepTeal,
    iconBackground: AppColors.mint,
    title: 'Private',
    subtitle: 'by design',
  );

  @override
  Widget build(BuildContext context) {
    final art = SizedBox(
      height: compact ? 190 : 292,
      child: const CustomPaint(
        size: Size.infinite,
        painter: _WelcomeHeroPainter(),
      ),
    );

    // Large text makes the floating cards taller and wider than the space
    // between them, so they would overlap each other and the art. List them
    // under the art instead.
    if (usesLargeTextLayout(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          art,
          const SizedBox(height: 12),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [_noJudgment, _private],
          ),
        ],
      );
    }

    return SizedBox(
      height: compact ? 190 : 292,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _WelcomeHeroPainter()),
          ),
          // Spanning the width bounds each card, so its text wraps rather
          // than overflowing on narrow screens.
          Positioned(
            left: 0,
            right: 0,
            top: compact ? 26 : 48,
            child: const Align(
              alignment: Alignment.centerRight,
              child: _noJudgment,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: compact ? 26 : 45,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: _private,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCallout extends StatelessWidget {
  const _HeroCallout({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 9),
          Flexible(
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
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 11,
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

class _WelcomeHeroPainter extends CustomPainter {
  const _WelcomeHeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.40;

    final outerPaint = Paint()
      ..color = AppColors.mintStrong.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, outerPaint);

    final dashedPaint = Paint()
      ..color = AppColors.mintStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashCount = 34;
    for (var index = 0; index < dashCount; index++) {
      final start = (index / dashCount) * 6.283185307;
      final end = start + 0.09;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.82),
        start,
        end - start,
        false,
        dashedPaint,
      );
    }

    canvas.drawCircle(
      center,
      radius * 0.61,
      Paint()..color = AppColors.mintStrong.withValues(alpha: 0.72),
    );

    final leaf = Path()
      ..moveTo(center.dx - 58, center.dy + 49)
      ..cubicTo(
        center.dx - 30,
        center.dy - 39,
        center.dx + 14,
        center.dy - 61,
        center.dx + 29,
        center.dy - 28,
      )
      ..cubicTo(
        center.dx + 45,
        center.dy + 7,
        center.dx + 10,
        center.dy + 49,
        center.dx - 58,
        center.dy + 49,
      )
      ..close();
    canvas.drawPath(leaf, Paint()..color = AppColors.coral);

    final stemPaint = Paint()
      ..color = AppColors.paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final stem = Path()
      ..moveTo(center.dx - 53, center.dy + 53)
      ..quadraticBezierTo(
        center.dx - 19,
        center.dy - 11,
        center.dx + 38,
        center.dy - 44,
      );
    canvas.drawPath(stem, stemPaint);

    final windPaint = Paint()
      ..color = AppColors.deepTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 3; index++) {
      final y = center.dy - 47 + (index * 30);
      final wind = Path()
        ..moveTo(center.dx + 61, y)
        ..quadraticBezierTo(
          center.dx + 111,
          y + 7,
          center.dx + 125,
          y + 37,
        );
      canvas.drawPath(
        wind,
        index == 0
            ? windPaint
            : (Paint()
              ..color = AppColors.mutedTeal
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..strokeCap = StrokeCap.round),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WelcomeHeroPainter oldDelegate) => false;
}

class _WelcomeBenefits extends StatelessWidget {
  const _WelcomeBenefits({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final cravings = _WelcomeBenefit(
      icon: Icons.add_rounded,
      iconBackground: AppColors.mint,
      iconColor: AppColors.deepTeal,
      title: AppLocalizations.of(context).welcomeBenefitsTitle,
      subtitle: AppLocalizations.of(context).welcomeBenefitsSubtitle,
    );
    final progress = _WelcomeBenefit(
      icon: Icons.check_rounded,
      iconBackground: AppColors.coralLight,
      iconColor: AppColors.coral,
      title: AppLocalizations.of(context).welcomeBenefitsTitle2,
      subtitle: AppLocalizations.of(context).welcomeBenefitsSubtitle2,
    );

    // Two half-width columns split words mid-way at large text sizes.
    if (usesLargeTextLayout(context)) {
      return Column(
        children: [cravings, const SizedBox(height: 14), progress],
      );
    }
    return Row(
      children: [
        Expanded(child: cravings),
        const SizedBox(width: 14),
        Expanded(child: progress),
      ],
    );
  }
}

class _WelcomeBenefit extends StatelessWidget {
  const _WelcomeBenefit({
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
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
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
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeLegalText extends StatelessWidget {
  const _WelcomeLegalText({
    required this.isSpanish,
    required this.onTerms,
    required this.onPrivacy,
  });

  final bool isSpanish;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context).welcomeLegalText,
          style: const TextStyle(
            color: AppColors.mutedTeal,
            fontSize: 11,
          ),
        ),
        TextButton(
          onPressed: onTerms,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            minimumSize: const Size(0, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(AppLocalizations.of(context).welcomeLegalText2),
        ),
        Text(
          AppLocalizations.of(context).welcomeLegalText3,
          style: const TextStyle(
            color: AppColors.mutedTeal,
            fontSize: 11,
          ),
        ),
        TextButton(
          onPressed: onPrivacy,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            minimumSize: const Size(0, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(AppLocalizations.of(context).welcomeLegalText4),
        ),
      ],
    );
  }
}
