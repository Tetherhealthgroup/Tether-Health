import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import '../theme/app_colors.dart';
import '../widgets/large_text.dart';

const _choiceLabelStyle = TextStyle(
  color: AppColors.deepTeal,
  fontSize: 13.5,
  height: 1.1,
  fontWeight: FontWeight.w800,
);

enum QuitReason {
  family,
  breatheEasier,
  improveHealth,
  saveMoney,
  control,
  future,
  custom,
}

class MyReasonsScreen extends StatelessWidget {
  const MyReasonsScreen({
    required this.isSpanish,
    required this.selectedReasons,
    required this.customReason,
    required this.topReason,
    required this.onSelectionChanged,
    required this.onCustomReasonChanged,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final bool isSpanish;
  final Set<QuitReason> selectedReasons;
  final String? customReason;
  final QuitReason? topReason;
  final void Function(Set<QuitReason>, QuitReason?) onSelectionChanged;
  final ValueChanged<String?> onCustomReasonChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  static const _standardReasons = <QuitReason>[
    QuitReason.family,
    QuitReason.breatheEasier,
    QuitReason.improveHealth,
    QuitReason.saveMoney,
    QuitReason.control,
    QuitReason.future,
  ];

  String _labelFor(BuildContext context, QuitReason reason) {
    return switch (reason) {
      QuitReason.family => AppLocalizations.of(context).myReasonsLabelFor,
      QuitReason.breatheEasier =>
        AppLocalizations.of(context).myReasonsLabelFor2,
      QuitReason.improveHealth =>
        AppLocalizations.of(context).myReasonsLabelFor3,
      QuitReason.saveMoney => AppLocalizations.of(context).myReasonsLabelFor4,
      QuitReason.control => AppLocalizations.of(context).myReasonsLabelFor5,
      QuitReason.future => AppLocalizations.of(context).myReasonsLabelFor6,
      QuitReason.custom => customReason?.trim().isNotEmpty == true
          ? customReason!.trim()
          : (AppLocalizations.of(context).myReasonsLabelFor7),
    };
  }

  IconData _iconFor(QuitReason reason) {
    return switch (reason) {
      QuitReason.family => Icons.favorite_rounded,
      QuitReason.breatheEasier => Icons.air_rounded,
      QuitReason.improveHealth => Icons.health_and_safety_rounded,
      QuitReason.saveMoney => Icons.savings_outlined,
      QuitReason.control => Icons.check_rounded,
      QuitReason.future => Icons.eco_outlined,
      QuitReason.custom => Icons.edit_rounded,
    };
  }

  Color _accentFor(QuitReason reason) {
    return switch (reason) {
      QuitReason.family || QuitReason.improveHealth => AppColors.coral,
      QuitReason.saveMoney => AppColors.deepTeal,
      QuitReason.custom => AppColors.coral,
      _ => AppColors.deepTeal,
    };
  }

  QuitReason? _firstSelected(Set<QuitReason> reasons) {
    for (final reason in [..._standardReasons, QuitReason.custom]) {
      if (reasons.contains(reason)) return reason;
    }
    return null;
  }

  void _toggleReason(QuitReason reason) {
    final updated = Set<QuitReason>.of(selectedReasons);
    QuitReason? updatedTop = topReason;
    if (!updated.add(reason)) {
      updated.remove(reason);
      if (updatedTop == reason) updatedTop = _firstSelected(updated);
    } else {
      updatedTop ??= reason;
    }
    onSelectionChanged(updated, updatedTop);
  }

  void _makeTop(QuitReason reason) {
    final updated = Set<QuitReason>.of(selectedReasons)..add(reason);
    onSelectionChanged(updated, reason);
  }

  Future<void> _showCustomReasonEditor(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (sheetContext) => _CustomReasonEditorSheet(
        isSpanish: isSpanish,
        initialValue: customReason ?? '',
        initiallyTop: topReason == QuitReason.custom,
        onSave: (value, makeTop) {
          final updated = Set<QuitReason>.of(selectedReasons)
            ..add(QuitReason.custom);
          onCustomReasonChanged(value);
          onSelectionChanged(
            updated,
            makeTop ? QuitReason.custom : (topReason ?? QuitReason.custom),
          );
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  void _removeCustomReason() {
    final updated = Set<QuitReason>.of(selectedReasons)
      ..remove(QuitReason.custom);
    onCustomReasonChanged(null);
    onSelectionChanged(
      updated,
      topReason == QuitReason.custom ? _firstSelected(updated) : topReason,
    );
  }

  String _previewFor(BuildContext context, QuitReason? reason) {
    if (reason == null) {
      return AppLocalizations.of(context).myReasonsPreviewFor;
    }
    if (reason == QuitReason.custom) {
      final value = customReason?.trim() ?? '';
      return AppLocalizations.of(context).myReasonsPreviewFor2(value);
    }
    return switch (reason) {
      QuitReason.family => AppLocalizations.of(context).myReasonsPreviewFor3,
      QuitReason.breatheEasier =>
        AppLocalizations.of(context).myReasonsPreviewFor4,
      QuitReason.improveHealth =>
        AppLocalizations.of(context).myReasonsPreviewFor5,
      QuitReason.saveMoney => AppLocalizations.of(context).myReasonsPreviewFor6,
      QuitReason.control => AppLocalizations.of(context).myReasonsPreviewFor7,
      QuitReason.future => AppLocalizations.of(context).myReasonsPreviewFor8,
      QuitReason.custom => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    // The text comes from the app locale; the language the screen was given
    // must be the same one.
    assert(
      isSpanish == (Localizations.localeOf(context).languageCode == 'es'),
      'the screen language must match the app locale',
    );
    final hasCustom = customReason?.trim().isNotEmpty == true;
    final selectionCount = selectedReasons.length;
    final canContinue = selectionCount > 0;

    return Scaffold(
      key: const ValueKey('functional-my-reasons-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 250) onBack();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 380;
              final compact = constraints.maxHeight < 760;
              // Above 140% text the side margins narrow so long words fit, and
              // the header, progress and main action scroll with the content
              // so they never squeeze the questions out of view.
              final largeText = usesLargeTextLayout(context);
              final horizontalPadding =
                  largeText ? 12.0 : (narrow ? 18.0 : 22.0);

              final selectAll = Text(
                AppLocalizations.of(context).myReasonsText,
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              );
              final selectedCount = Container(
                key: const ValueKey('reasons-selected-count'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  AppLocalizations.of(context)
                      .myReasonsSelectedCountText(selectionCount),
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );

              final footer = _ReasonsBottomAction(
                isSpanish: isSpanish,
                selectionCount: selectionCount,
                hasTopReason: topReason != null,
                canContinue: canContinue,
                onContinue: onContinue,
                horizontalPadding: largeText ? 0 : horizontalPadding,
                compact: compact,
              );

              final header = _ReasonsHeader(
                isSpanish: isSpanish,
                onBack: onBack,
              );
              final progress = _ReasonsProgress(isSpanish: isSpanish);

              return Column(
                children: [
                  if (!largeText)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 5 : 9,
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
                      key: const ValueKey('reasons-content-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 8 : 13,
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
                              Text(
                                AppLocalizations.of(context).myReasonsText2,
                                style: const TextStyle(
                                  color: AppColors.mutedTeal,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context).myReasonsText3,
                                // Already the largest text on screen; past
                                // 180% its longest words no longer fit.
                                textScaler: MediaQuery.textScalerOf(context)
                                    .clamp(maxScaleFactor: 1.8),
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: narrow ? 29 : 33,
                                      height: 1.06,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(context).myReasonsText4,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppColors.tealSecondary,
                                      fontSize: narrow ? 14 : 15,
                                      height: 1.35,
                                    ),
                              ),
                              SizedBox(height: compact ? 14 : 18),
                              // Beside the count, the heading's words split at accessibility
                              // text sizes.
                              if (largeText) ...[
                                selectAll,
                                const SizedBox(height: 6),
                                selectedCount,
                              ] else
                                Row(
                                  children: [
                                    Expanded(child: selectAll),
                                    const SizedBox(width: 8),
                                    selectedCount,
                                  ],
                                ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, gridConstraints) {
                                  const gap = 10.0;
                                  final halfWidth =
                                      (gridConstraints.maxWidth - gap) / 2;
                                  // Two columns at the default text size
                                  // on phones 360pt and wider, and at
                                  // larger sizes while every label's
                                  // longest word still fits a half-width
                                  // card; otherwise one column.
                                  final enlarged = MediaQuery.textScalerOf(
                                        context,
                                      ).scale(10) >
                                      10;
                                  final twoColumns = gridConstraints.maxWidth >=
                                          300 &&
                                      (!enlarged ||
                                          wordsFit(
                                            context,
                                            _standardReasons.map(
                                                (r) => _labelFor(context, r)),
                                            halfWidth - _ReasonChoice.chrome,
                                            _choiceLabelStyle,
                                          ));
                                  final itemWidth = twoColumns
                                      ? halfWidth
                                      : gridConstraints.maxWidth;
                                  return Wrap(
                                    spacing: gap,
                                    runSpacing: gap,
                                    children: [
                                      for (final reason in _standardReasons)
                                        SizedBox(
                                          width: itemWidth,
                                          child: _ReasonChoice(
                                            reason: reason,
                                            label: _labelFor(context, reason),
                                            icon: _iconFor(reason),
                                            accent: _accentFor(reason),
                                            selected: selectedReasons
                                                .contains(reason),
                                            isTop: topReason == reason,
                                            isSpanish: isSpanish,
                                            onTap: () => _toggleReason(reason),
                                            onMakeTop: () => _makeTop(reason),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _CustomReasonCard(
                                isSpanish: isSpanish,
                                customReason: hasCustom ? customReason : null,
                                isTop: topReason == QuitReason.custom,
                                onEdit: () => _showCustomReasonEditor(context),
                                onMakeTop: () => _makeTop(QuitReason.custom),
                                onRemove: _removeCustomReason,
                              ),
                              const SizedBox(height: 12),
                              _MotivationPreview(
                                isSpanish: isSpanish,
                                message: _previewFor(context, topReason),
                                topLabel: topReason == null
                                    ? null
                                    : _labelFor(context, topReason!),
                              ),
                              const SizedBox(height: 12),
                              _ReasonsPrivacyNote(isSpanish: isSpanish),
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

class _ReasonsHeader extends StatelessWidget {
  const _ReasonsHeader({required this.isSpanish, required this.onBack});

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final back = IconButton.outlined(
      key: const ValueKey('reasons-back'),
      tooltip: AppLocalizations.of(context).myReasonsReasonsHeaderBackTooltip,
      onPressed: onBack,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.deepTeal,
        side: const BorderSide(color: AppColors.border),
      ),
      icon: const Icon(Icons.arrow_back_rounded),
    );
    final label = AppLocalizations.of(context).myReasonsReasonsHeaderBackLabel;
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
        textScaler: wordFitScaler(
          context,
          label,
          style,
          constraints.maxWidth,
        ),
        style: style,
      ),
    );
    final step = Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        AppLocalizations.of(context).myReasonsReasonsHeaderText,
        style: const TextStyle(
          color: AppColors.tealSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    // Between the back button and the step, the title's words split at
    // accessibility text sizes, so it takes a line of its own.
    if (usesLargeTextLayout(context)) {
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
      child: Row(
        children: [
          back,
          const SizedBox(width: 8),
          Expanded(child: title),
          const SizedBox(width: 8),
          step,
        ],
      ),
    );
  }
}

class _ReasonsProgress extends StatelessWidget {
  const _ReasonsProgress({required this.isSpanish});

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
                AppLocalizations.of(context).myReasonsReasonsProgressText,
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
              '60%',
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
            key: ValueKey('reasons-progress'),
            value: 0.6,
            minHeight: 6,
            backgroundColor: Color(0xFFDCE7E1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
          ),
        ),
      ],
    );
  }
}

class _ReasonChoice extends StatelessWidget {
  const _ReasonChoice({
    required this.reason,
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.isTop,
    required this.isSpanish,
    required this.onTap,
    required this.onMakeTop,
  });

  final QuitReason reason;
  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final bool isTop;
  final bool isSpanish;
  final VoidCallback onTap;
  final VoidCallback onMakeTop;

  /// Width of the padding, icon, gap and star column beside the label.
  static const chrome = 10.0 + 40 + 9 + 21 + 9;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        key: ValueKey('reason-choice-${reason.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          key: selected ? ValueKey('reason-selected-${reason.name}') : null,
          duration: const Duration(milliseconds: 150),
          // A minimum height: larger text grows the card instead of cutting
          // the label off.
          constraints: const BoxConstraints(minHeight: 91),
          padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.mint : AppColors.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTop
                  ? AppColors.coral
                  : selected
                      ? AppColors.mintStrong
                      : AppColors.border,
              width: isTop ? 1.7 : 1.1,
            ),
          ),
          // The star and check keep to the card's top and bottom corners
          // however tall larger text makes it.
          child: IntrinsicHeight(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: accent == AppColors.coral
                      ? AppColors.coralLight
                      : AppColors.cream,
                  child: Icon(icon, color: accent, size: 25),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(label, style: _choiceLabelStyle),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkResponse(
                      key: ValueKey('reason-top-${reason.name}'),
                      onTap: onMakeTop,
                      radius: 18,
                      child: Icon(
                        isTop ? Icons.star_rounded : Icons.star_border_rounded,
                        color: isTop ? AppColors.coral : AppColors.border,
                        size: 21,
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected ? AppColors.deepTeal : AppColors.border,
                      size: 19,
                    ),
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

class _CustomReasonCard extends StatelessWidget {
  const _CustomReasonCard({
    required this.isSpanish,
    required this.customReason,
    required this.isTop,
    required this.onEdit,
    required this.onMakeTop,
    required this.onRemove,
  });

  final bool isSpanish;
  final String? customReason;
  final bool isTop;
  final VoidCallback onEdit;
  final VoidCallback onMakeTop;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasValue = customReason?.trim().isNotEmpty == true;
    return Container(
      key: ValueKey(hasValue ? 'reason-custom-card' : 'reason-custom-editor'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: hasValue ? AppColors.coralLight : AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop ? AppColors.coral : AppColors.border,
          width: isTop ? 1.7 : 1.1,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.mint,
                child: Icon(
                  hasValue ? Icons.edit_rounded : Icons.add_rounded,
                  color: AppColors.deepTeal,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasValue
                          ? (AppLocalizations.of(context)
                              .myReasonsCustomReasonCard)
                          : (AppLocalizations.of(context)
                              .myReasonsCustomReasonCard2),
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasValue
                          ? customReason!.trim()
                          : (AppLocalizations.of(context)
                              .myReasonsCustomReasonCard3),
                      style: TextStyle(
                        color: hasValue
                            ? AppColors.deepTeal
                            : AppColors.tealSecondary,
                        fontSize: hasValue ? 14 : 11.5,
                        fontWeight:
                            hasValue ? FontWeight.w800 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasValue) ...[
                IconButton(
                  key: const ValueKey('reason-top-custom'),
                  tooltip: AppLocalizations.of(context)
                      .myReasonsCustomReasonCardReasonTopCustomTooltip,
                  onPressed: onMakeTop,
                  icon: Icon(
                    isTop ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isTop ? AppColors.coral : AppColors.border,
                  ),
                ),
                IconButton(
                  key: const ValueKey('reason-custom-remove'),
                  tooltip: AppLocalizations.of(context)
                      .myReasonsCustomReasonCardReasonCustomRemoveTooltip,
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, color: AppColors.coral),
                ),
              ] else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.deepTeal,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotivationPreview extends StatelessWidget {
  const _MotivationPreview({
    required this.isSpanish,
    required this.message,
    required this.topLabel,
  });

  final bool isSpanish;
  final String message;
  final String? topLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('reason-preview'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
      decoration: BoxDecoration(
        color: AppColors.deepTeal,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)
                      .myReasonsMotivationPreviewReasonPreviewText,
                  style: const TextStyle(
                    color: AppColors.mintStrong,
                    fontSize: 9.5,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF28514C),
                child: Icon(Icons.favorite_rounded,
                    color: AppColors.coral, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).myReasonsMotivationPreviewText,
            style: const TextStyle(
              color: AppColors.lime,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.paper,
              fontSize: 17,
              height: 1.25,
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 9),
          const Divider(height: 1, color: Color(0x556A8982)),
          const SizedBox(height: 7),
          Text(
            topLabel == null
                ? (AppLocalizations.of(context).myReasonsMotivationPreview)
                : (AppLocalizations.of(context)
                    .myReasonsMotivationPreview2(topLabel!)),
            style: const TextStyle(
              color: AppColors.mintStrong,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonsPrivacyNote extends StatelessWidget {
  const _ReasonsPrivacyNote({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              color: AppColors.mutedTeal, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              AppLocalizations.of(context).myReasonsReasonsPrivacyNoteText,
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 10.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonsBottomAction extends StatelessWidget {
  const _ReasonsBottomAction({
    required this.isSpanish,
    required this.selectionCount,
    required this.hasTopReason,
    required this.canContinue,
    required this.onContinue,
    required this.horizontalPadding,
    required this.compact,
  });

  final bool isSpanish;
  final int selectionCount;
  final bool hasTopReason;
  final bool canContinue;
  final VoidCallback onContinue;
  final double horizontalPadding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        compact ? 8 : 11,
        horizontalPadding,
        compact ? 7 : 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: Color(0x224A6B65))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                key: const ValueKey('reasons-save'),
                onPressed: canContinue ? onContinue : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  disabledBackgroundColor: AppColors.border,
                  foregroundColor: Colors.white,
                  // A minimum, not a fixed height: large text wraps and
                  // grows the button instead of being clipped.
                  minimumSize: Size.fromHeight(compact ? 52 : 56),
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
                        AppLocalizations.of(context)
                            .myReasonsReasonsBottomActionText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_rounded,
                        color: AppColors.lime),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).myReasonsSelectionSummary(
                  selectionCount,
                  hasTopReason.toString(),
                ),
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
    );
  }
}

class _CustomReasonEditorSheet extends StatefulWidget {
  const _CustomReasonEditorSheet({
    required this.isSpanish,
    required this.initialValue,
    required this.initiallyTop,
    required this.onSave,
  });

  final bool isSpanish;
  final String initialValue;
  final bool initiallyTop;
  final void Function(String, bool) onSave;

  @override
  State<_CustomReasonEditorSheet> createState() =>
      _CustomReasonEditorSheetState();
}

class _CustomReasonEditorSheetState extends State<_CustomReasonEditorSheet> {
  late final TextEditingController _controller;
  late bool _makeTop;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _makeTop = widget.initiallyTop;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 4, 22, keyboard + 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)
                .myReasonsCustomReasonEditorSheetStateText,
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            AppLocalizations.of(context)
                .myReasonsCustomReasonEditorSheetStateText2,
            style:
                const TextStyle(color: AppColors.tealSecondary, fontSize: 14),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('reason-custom-text-field'),
            controller: _controller,
            autofocus: true,
            maxLength: 100,
            minLines: 2,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)
                  .myReasonsCustomReasonEditorSheetStateReasonCustomTextFieldHintText,
              filled: true,
              fillColor: AppColors.cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          SwitchListTile(
            key: const ValueKey('reason-custom-make-top'),
            contentPadding: EdgeInsets.zero,
            value: _makeTop,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.deepTeal,
            title: Text(
              AppLocalizations.of(context)
                  .myReasonsCustomReasonEditorSheetStateReasonCustomMakeTopText,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            onChanged: (value) => setState(() => _makeTop = value),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const ValueKey('reason-custom-save'),
              onPressed: _controller.text.trim().isEmpty
                  ? null
                  : () => widget.onSave(_controller.text.trim(), _makeTop),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)
                    .myReasonsCustomReasonEditorSheetStateReasonCustomSaveText,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
