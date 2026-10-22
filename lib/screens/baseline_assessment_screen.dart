import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Above 140% text (the iOS accessibility sizes and Android 14's largest
/// font sizes) side-by-side pieces are stacked so text can grow.
bool _usesLargeTextLayout(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) > 14;

/// The text scale for [text] in [style], lowered only as far as needed for
/// its longest word to fit [width]: a word too long for a whole line scales
/// down instead of splitting.
TextScaler _wordFitScaler(
  BuildContext context,
  String text,
  TextStyle style,
  double width,
) {
  final scaler = MediaQuery.textScalerOf(context);
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
  );
  try {
    var fitted = scaler;
    for (var attempt = 0; attempt < 4; attempt++) {
      painter
        ..textScaler = fitted
        ..layout();
      final longestWord = painter.minIntrinsicWidth;
      if (longestWord <= width) return fitted;
      final fontSize = style.fontSize ?? 14;
      final factor = fitted.scale(fontSize) / fontSize * width / longestWord;
      fitted = scaler.clamp(maxScaleFactor: factor * 0.99);
    }
    return fitted;
  } finally {
    painter.dispose();
  }
}

enum DailyCigaretteUse {
  notEveryDay,
  tenOrFewer,
  elevenToTwenty,
  twentyOneToThirty,
  thirtyOneOrMore,
}

class BaselineAssessmentScreen extends StatelessWidget {
  const BaselineAssessmentScreen({
    required this.isSpanish,
    required this.dailyCigaretteUse,
    required this.onDailyCigaretteUseChanged,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final bool isSpanish;
  final DailyCigaretteUse? dailyCigaretteUse;
  final ValueChanged<DailyCigaretteUse> onDailyCigaretteUseChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  String _choiceLabel(DailyCigaretteUse choice) {
    return switch (choice) {
      DailyCigaretteUse.notEveryDay =>
        isSpanish ? 'No fumo todos los días' : 'I don’t smoke every day',
      DailyCigaretteUse.tenOrFewer =>
        isSpanish ? '10 cigarrillos o menos' : '10 or fewer cigarettes',
      DailyCigaretteUse.elevenToTwenty =>
        isSpanish ? '11–20 cigarrillos' : '11–20 cigarettes',
      DailyCigaretteUse.twentyOneToThirty =>
        isSpanish ? '21–30 cigarrillos' : '21–30 cigarettes',
      DailyCigaretteUse.thirtyOneOrMore =>
        isSpanish ? '31 cigarrillos o más' : '31 or more cigarettes',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('functional-baseline-assessment-screen'),
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
              // Above 140% text the side margins narrow so long words fit, and
              // the header, progress and main action scroll with the content
              // so they never squeeze the questions out of view.
              final largeText = _usesLargeTextLayout(context);
              final horizontalPadding =
                  largeText ? 12.0 : (narrow ? 18.0 : 24.0);

              final footer = _AssessmentBottomAction(
                isSpanish: isSpanish,
                canContinue: dailyCigaretteUse != null,
                onContinue: onContinue,
                horizontalPadding: largeText ? 0 : horizontalPadding,
                compact: compact,
              );

              final header = _AssessmentHeader(
                isSpanish: isSpanish,
                onBack: onBack,
              );
              final progress = _AssessmentProgress(isSpanish: isSpanish);

              return Column(
                children: [
                  if (!largeText)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 5 : 10,
                        horizontalPadding,
                        0,
                      ),
                      child: header,
                    ),
                  if (!largeText)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 5 : 8,
                        horizontalPadding,
                        compact ? 7 : 10,
                      ),
                      child: progress,
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('baseline-content-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 4 : 10,
                        horizontalPadding,
                        18,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (largeText) ...[
                                header,
                                const SizedBox(height: 10),
                                progress,
                                const SizedBox(height: 18),
                              ],
                              _AssessmentIcon(compact: compact),
                              SizedBox(height: compact ? 12 : 22),
                              Text(
                                isSpanish ? 'PREGUNTA 1' : 'QUESTION 1',
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
                                    ? 'En un día habitual, ¿cuántos cigarrillos fumas?'
                                    : 'On a typical day, how many cigarettes do you smoke?',
                                // Already the largest text on screen; past
                                // 180% its longest words no longer fit.
                                textScaler: MediaQuery.textScalerOf(context)
                                    .clamp(maxScaleFactor: 1.8),
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
                                    ? 'Elige la respuesta más cercana a tu día habitual.'
                                    : 'Choose the answer closest to your usual day.',
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
                              for (final choice
                                  in DailyCigaretteUse.values) ...[
                                _AssessmentChoice(
                                  choice: choice,
                                  label: _choiceLabel(choice),
                                  isSpanish: isSpanish,
                                  selected: dailyCigaretteUse == choice,
                                  onTap: () =>
                                      onDailyCigaretteUseChanged(choice),
                                ),
                                if (choice != DailyCigaretteUse.values.last)
                                  SizedBox(height: compact ? 8 : 10),
                              ],
                              SizedBox(height: compact ? 14 : 18),
                              _WhyWeAskCard(isSpanish: isSpanish),
                              if (largeText) ...[
                                const SizedBox(height: 18),
                                footer,
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!largeText) footer,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AssessmentHeader extends StatelessWidget {
  const _AssessmentHeader({
    required this.isSpanish,
    required this.onBack,
  });

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final back = IconButton.outlined(
      key: const ValueKey('baseline-back'),
      tooltip: isSpanish ? 'Atrás' : 'Back',
      onPressed: onBack,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.deepTeal,
        side: const BorderSide(color: AppColors.border),
      ),
      icon: const Icon(Icons.arrow_back_rounded),
    );
    final label = isSpanish ? 'Sobre tu consumo' : 'About your smoking';
    const style = TextStyle(
      color: AppColors.deepTeal,
      fontSize: 16,
      fontWeight: FontWeight.w800,
    );
    // The title wraps instead of ending in "…"; a word too long for the
    // line scales down instead of splitting.
    final title = LayoutBuilder(
      builder: (context, constraints) => Text(
        label,
        textAlign: TextAlign.center,
        textScaler: _wordFitScaler(
          context,
          label,
          style,
          constraints.maxWidth,
        ),
        style: style,
      ),
    );
    final step = Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Text(
        '1 OF 8',
        style: TextStyle(
          color: AppColors.deepTeal,
          fontSize: 10,
          letterSpacing: .6,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    // Between the back button and the step, the title's words split at
    // accessibility text sizes, so it takes a line of its own.
    if (_usesLargeTextLayout(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [back, step],
            ),
          ),
          const SizedBox(height: 6),
          title,
        ],
      );
    }
    // A minimum height: larger text grows the header instead of clipping it.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(children: [back, Expanded(child: title), step]),
    );
  }
}

class _AssessmentProgress extends StatelessWidget {
  const _AssessmentProgress({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                isSpanish ? 'EVALUACIÓN' : 'ASSESSMENT',
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 10,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '12%',
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
            key: ValueKey('baseline-progress'),
            value: .125,
            minHeight: 6,
            backgroundColor: Color(0xFFDCE7E1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
          ),
        ),
      ],
    );
  }
}

class _AssessmentIcon extends StatelessWidget {
  const _AssessmentIcon({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 46.0 : 54.0;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.mint,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.bar_chart_rounded,
            color: AppColors.deepTeal,
            size: 30,
          ),
          Positioned(
            top: compact ? 8 : 10,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.coral,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentChoice extends StatelessWidget {
  const _AssessmentChoice({
    required this.choice,
    required this.label,
    required this.isSpanish,
    required this.selected,
    required this.onTap,
  });

  final DailyCigaretteUse choice;
  final String label;
  final bool isSpanish;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final largeText = _usesLargeTextLayout(context);
    final answer = Text(
      label,
      style: const TextStyle(
        color: AppColors.deepTeal,
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w800,
      ),
    );
    final badge = Container(
      key: ValueKey('baseline-selected-${choice.name}'),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        isSpanish ? 'Elegido' : 'Selected',
        style: const TextStyle(
          color: AppColors.coral,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: selected ? AppColors.coralLight : AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.coral : AppColors.border,
            width: selected ? 1.7 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('baseline-choice-${choice.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.coral : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.coral : AppColors.border,
                        width: 1.6,
                      ),
                    ),
                    child: selected
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // At accessibility text sizes the "Selected" badge sits
                  // under the answer so the answer keeps the row's width.
                  if (largeText)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          answer,
                          if (selected) ...[
                            const SizedBox(height: 6),
                            badge,
                          ],
                        ],
                      ),
                    )
                  else ...[
                    Expanded(child: answer),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      badge,
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WhyWeAskCard extends StatelessWidget {
  const _WhyWeAskCard({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: AppColors.paper,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.info_outline_rounded,
        color: AppColors.deepTeal,
        size: 20,
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSpanish ? 'Por qué preguntamos' : 'Why we ask',
          style: const TextStyle(
            color: AppColors.deepTeal,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isSpanish
              ? 'Esto ayuda a adaptar tu plan y calcular el dinero ahorrado.'
              : 'This helps tailor your plan and estimate money saved.',
          style: const TextStyle(
            color: AppColors.tealSecondary,
            fontSize: 11,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isSpanish
              ? 'No es un diagnóstico ni un juicio.'
              : 'It is not a diagnosis or a judgment.',
          style: const TextStyle(
            color: AppColors.mutedTeal,
            fontSize: 10,
            height: 1.3,
          ),
        ),
      ],
    );
    return Container(
      key: const ValueKey('baseline-why-we-ask'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mintStrong),
      ),
      // At accessibility text sizes the text takes the card's full width
      // under the icon.
      child: _usesLargeTextLayout(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [icon, const SizedBox(height: 8), text],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: 11),
                Expanded(child: text),
              ],
            ),
    );
  }
}

class _AssessmentBottomAction extends StatelessWidget {
  const _AssessmentBottomAction({
    required this.isSpanish,
    required this.canContinue,
    required this.onContinue,
    required this.horizontalPadding,
    required this.compact,
  });

  final bool isSpanish;
  final bool canContinue;
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
                FilledButton(
                  key: const ValueKey('baseline-next'),
                  onPressed: canContinue ? onContinue : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.tealSecondary,
                    // A minimum, not a fixed height: large text wraps and
                    // grows the button instead of being clipped.
                    minimumSize: Size.fromHeight(compact ? 50 : 54),
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
                          isSpanish ? 'Siguiente' : 'Next',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color:
                            canContinue ? AppColors.lime : AppColors.mutedTeal,
                      ),
                    ],
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 7),
                  Text(
                    isSpanish
                        ? 'Tu respuesta se guarda automáticamente.'
                        : 'Your answer is saved automatically.',
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
