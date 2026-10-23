import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
                    child: _AssessmentHeader(
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
                    child: _AssessmentProgress(isSpanish: isSpanish),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _AssessmentBottomAction(
                    isSpanish: isSpanish,
                    canContinue: dailyCigaretteUse != null,
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

class _AssessmentHeader extends StatelessWidget {
  const _AssessmentHeader({
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
            key: const ValueKey('baseline-back'),
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
              isSpanish ? 'Sobre tu consumo' : 'About your smoking',
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
            height: 30,
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
          ),
        ],
      ),
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
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    Container(
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
                    ),
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
    return Container(
      key: const ValueKey('baseline-why-we-ask'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mintStrong),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
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
            ),
          ),
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
                SizedBox(
                  width: double.infinity,
                  height: compact ? 50 : 54,
                  child: FilledButton(
                    key: const ValueKey('baseline-next'),
                    onPressed: canContinue ? onContinue : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      disabledForegroundColor: AppColors.tealSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isSpanish ? 'Siguiente' : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: canContinue
                              ? AppColors.lime
                              : AppColors.mutedTeal,
                        ),
                      ],
                    ),
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
