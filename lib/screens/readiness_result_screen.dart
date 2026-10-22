import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import '../theme/app_colors.dart';
import '../widgets/large_text.dart';
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

  String _usageLabel(BuildContext context) {
    return switch (dailyCigaretteUse) {
      DailyCigaretteUse.notEveryDay =>
        AppLocalizations.of(context).readinessResultPatternNotEveryDay,
      DailyCigaretteUse.tenOrFewer =>
        AppLocalizations.of(context).readinessResultPatternTenOrFewer,
      DailyCigaretteUse.elevenToTwenty =>
        AppLocalizations.of(context).readinessResultPatternElevenToTwenty,
      DailyCigaretteUse.twentyOneToThirty =>
        AppLocalizations.of(context).readinessResultPatternTwentyOneToThirty,
      DailyCigaretteUse.thirtyOneOrMore =>
        AppLocalizations.of(context).readinessResultPatternThirtyOneOrMore,
      null => AppLocalizations.of(context).readinessResultPatternNone,
    };
  }

  String _triggerLabel(BuildContext context, SmokingTrigger trigger) {
    return switch (trigger) {
      SmokingTrigger.stress =>
        AppLocalizations.of(context).readinessResultTriggerStress,
      SmokingTrigger.afterMeals =>
        AppLocalizations.of(context).readinessResultTriggerAfterMeals,
      SmokingTrigger.driving =>
        AppLocalizations.of(context).readinessResultTriggerDriving,
      SmokingTrigger.coffee =>
        AppLocalizations.of(context).readinessResultTriggerCoffee,
      SmokingTrigger.socialSettings =>
        AppLocalizations.of(context).readinessResultTriggerSocialSettings,
      SmokingTrigger.workBreaks =>
        AppLocalizations.of(context).readinessResultTriggerWorkBreaks,
      SmokingTrigger.alcohol =>
        AppLocalizations.of(context).readinessResultTriggerAlcohol,
      SmokingTrigger.boredom =>
        AppLocalizations.of(context).readinessResultTriggerBoredom,
      SmokingTrigger.morning =>
        AppLocalizations.of(context).readinessResultTriggerMorning,
      SmokingTrigger.beforeBed =>
        AppLocalizations.of(context).readinessResultTriggerBeforeBed,
    };
  }

  List<String> _allTriggerLabels(BuildContext context) {
    final labels =
        selectedTriggers.map((t) => _triggerLabel(context, t)).toList();
    final normalizedCustom = customTrigger?.trim();
    if (normalizedCustom != null && normalizedCustom.isNotEmpty) {
      labels.add(normalizedCustom);
    }
    return labels;
  }

  String _triggerSummary(BuildContext context) {
    final labels = _allTriggerLabels(context);
    if (labels.isEmpty) {
      return AppLocalizations.of(context).readinessResultTriggersNone;
    }
    if (labels.length == 1) {
      return AppLocalizations.of(context)
          .readinessResultTriggersOne(labels.first);
    }
    if (labels.length == 2) {
      return AppLocalizations.of(context)
          .readinessResultTriggersTwo(labels.first, labels.last);
    }
    final remaining = labels.length - 2;
    return AppLocalizations.of(context)
        .readinessResultTriggersMany(labels[0], labels[1], remaining);
  }

  String _startingPointSummary(BuildContext context) {
    final count = _allTriggerLabels(context).length;
    if (count == 0) {
      return AppLocalizations.of(context).readinessResultStartingPointNone;
    }
    return AppLocalizations.of(context)
        .readinessResultStartingPointCount(count);
  }

  String _actionLabel(BuildContext context) {
    return switch (selectedPath) {
      ReadinessPath.prepare =>
        AppLocalizations.of(context).readinessResultContinuePrepareButton,
      ReadinessPath.explore =>
        AppLocalizations.of(context).readinessResultContinueExploreButton,
      ReadinessPath.connect =>
        AppLocalizations.of(context).readinessResultContinueConnectButton,
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
                AppLocalizations.of(context)
                    .readinessResultWhyThisFitsSheetTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.deepTeal,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)
                    .readinessResultWhyThisFitsSheetBody,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.tealSecondary,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)
                    .readinessResultWhyThisFitsSheetNote,
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
                  child: Text(AppLocalizations.of(context)
                      .readinessResultWhyThisFitsSheetDoneButton),
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
      isSpanish == (Localizations.localeOf(context).languageCode == 'es'),
      'the screen language must match the app locale',
    );
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
              // Above 140% text the side margins narrow so long words fit, and
              // the header, progress and main action scroll with the content
              // so they never squeeze the questions out of view.
              final largeText = usesLargeTextLayout(context);
              final horizontalPadding =
                  largeText ? 12.0 : (narrow ? 18.0 : 24.0);

              final footer = _ReadinessBottomAction(
                isSpanish: isSpanish,
                label: _actionLabel(context),
                onContinue: onContinue,
                horizontalPadding: largeText ? 0 : horizontalPadding,
                compact: compact,
              );

              final header = _ReadinessHeader(
                isSpanish: isSpanish,
                onBack: onBack,
              );
              final progress = _ReadinessProgress(isSpanish: isSpanish);

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
                              if (largeText) ...[
                                header,
                                const SizedBox(height: 10),
                                progress,
                                const SizedBox(height: 18),
                              ],
                              _ReadinessIllustration(compact: compact),
                              SizedBox(height: compact ? 12 : 20),
                              Text(
                                AppLocalizations.of(context)
                                    .readinessResultEyebrow,
                                style: const TextStyle(
                                  color: AppColors.mutedTeal,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                AppLocalizations.of(context)
                                    .readinessResultTitle,
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
                                AppLocalizations.of(context)
                                    .readinessResultIntro,
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
                                usage: _usageLabel(context),
                                triggers: _triggerSummary(context),
                                startingPoint: _startingPointSummary(context),
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
                                AppLocalizations.of(context)
                                    .readinessResultOtherPathsLabel,
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

class _ReadinessHeader extends StatelessWidget {
  const _ReadinessHeader({required this.isSpanish, required this.onBack});

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final back = IconButton.outlined(
      key: const ValueKey('readiness-back'),
      tooltip: AppLocalizations.of(context).readinessResultBackTooltip,
      onPressed: onBack,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.deepTeal,
        side: const BorderSide(color: AppColors.border),
      ),
      icon: const Icon(Icons.arrow_back_rounded),
    );
    final label = AppLocalizations.of(context).readinessResultHeaderTitle;
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
            AppLocalizations.of(context).readinessResultCompleteBadge,
            style: const TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
          Expanded(child: title),
          step,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                AppLocalizations.of(context).readinessResultProgressLabel,
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
      // Narrower side padding at accessibility text sizes leaves room for
      // long words.
      padding: EdgeInsets.symmetric(
        horizontal: usesLargeTextLayout(context) ? 8 : 14,
        vertical: 4,
      ),
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
            label: AppLocalizations.of(context).readinessResultPatternLabel,
            value: usage,
          ),
          const Divider(height: 1, color: AppColors.border),
          _ReflectionRow(
            icon: Icons.route_rounded,
            iconColor: AppColors.deepTeal,
            iconBackground: AppColors.mint,
            label: AppLocalizations.of(context).readinessResultTriggersLabel,
            value: triggers,
          ),
          const Divider(height: 1, color: AppColors.border),
          _ReflectionRow(
            icon: Icons.tune_rounded,
            iconColor: AppColors.deepTeal,
            iconBackground: const Color(0xFFF1F8C7),
            label:
                AppLocalizations.of(context).readinessResultStartingPointLabel,
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
    final badge = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: iconBackground,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 21),
    );
    final text = Column(
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
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      // At accessibility text sizes the text takes the row's full width
      // under the icon.
      child: usesLargeTextLayout(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [badge, const SizedBox(height: 8), text],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                badge,
                const SizedBox(width: 11),
                Expanded(child: text),
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
    final title =
        AppLocalizations.of(context).readinessResultRecommendedPathName;
    const titleStyle = TextStyle(
      color: AppColors.deepTeal,
      fontSize: 20,
      fontWeight: FontWeight.w800,
    );
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
              // A Wrap rather than a Row: at accessibility text sizes the
              // badge can take a line of its own instead of overflowing.
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepTeal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppLocalizations.of(context)
                            .readinessResultRecommendedBadge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color:
                          selected ? AppColors.coral : AppColors.tealSecondary,
                      size: 28,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              // The card's heading: a word too long for the line scales down
              // instead of splitting.
              LayoutBuilder(
                builder: (context, constraints) => Text(
                  title,
                  textScaler: wordFitScaler(
                    context,
                    title,
                    titleStyle,
                    constraints.maxWidth,
                  ),
                  style: titleStyle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)
                    .readinessResultRecommendedPathDescription,
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
                  AppLocalizations.of(context).readinessResultWhyThisFitsLink,
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
      title: AppLocalizations.of(context).readinessResultPathExploreName,
      subtitle:
          AppLocalizations.of(context).readinessResultPathExploreDescription,
      selected: selectedPath == ReadinessPath.explore,
      onTap: () => onPathChanged(ReadinessPath.explore),
    );
    final connect = _AlternativePathCard(
      key: const ValueKey('readiness-path-connect'),
      icon: Icons.support_agent_rounded,
      iconColor: AppColors.coral,
      iconBackground: AppColors.coralLight,
      title: AppLocalizations.of(context).readinessResultPathConnectName,
      subtitle:
          AppLocalizations.of(context).readinessResultPathConnectDescription,
      selected: selectedPath == ReadinessPath.connect,
      onTap: () => onPathChanged(ReadinessPath.connect),
    );

    // Side by side, the cards' words split at accessibility text sizes.
    if (narrow || usesLargeTextLayout(context)) {
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
                FilledButton(
                  key: const ValueKey('readiness-continue'),
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                    foregroundColor: Colors.white,
                    // A minimum, not a fixed height: large text wraps and
                    // grows the button instead of being clipped.
                    minimumSize: Size.fromHeight(compact ? 54 : 60),
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
                          label,
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
                if (!compact) ...[
                  const SizedBox(height: 7),
                  Text(
                    AppLocalizations.of(context).readinessResultInControlNote,
                    textAlign: TextAlign.center,
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
