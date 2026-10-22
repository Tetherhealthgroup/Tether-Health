import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import '../theme/app_colors.dart';
import '../widgets/large_text.dart';

const _choiceLabelStyle = TextStyle(
  color: AppColors.deepTeal,
  fontSize: 13.5,
  height: 1.15,
  fontWeight: FontWeight.w800,
);

enum SmokingTrigger {
  stress,
  afterMeals,
  driving,
  coffee,
  socialSettings,
  workBreaks,
  alcohol,
  boredom,
  morning,
  beforeBed,
}

class TriggerMapScreen extends StatelessWidget {
  const TriggerMapScreen({
    required this.isSpanish,
    required this.selectedTriggers,
    required this.customTrigger,
    required this.onSelectedTriggersChanged,
    required this.onCustomTriggerChanged,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final bool isSpanish;
  final Set<SmokingTrigger> selectedTriggers;
  final String? customTrigger;
  final ValueChanged<Set<SmokingTrigger>> onSelectedTriggersChanged;
  final ValueChanged<String?> onCustomTriggerChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  String _labelFor(BuildContext context, SmokingTrigger trigger) {
    return switch (trigger) {
      SmokingTrigger.stress =>
        AppLocalizations.of(context).triggerMapOptionStress,
      SmokingTrigger.afterMeals =>
        AppLocalizations.of(context).triggerMapOptionAfterMeals,
      SmokingTrigger.driving =>
        AppLocalizations.of(context).triggerMapOptionDriving,
      SmokingTrigger.coffee =>
        AppLocalizations.of(context).triggerMapOptionCoffee,
      SmokingTrigger.socialSettings =>
        AppLocalizations.of(context).triggerMapOptionSocialSettings,
      SmokingTrigger.workBreaks =>
        AppLocalizations.of(context).triggerMapOptionWorkBreaks,
      SmokingTrigger.alcohol =>
        AppLocalizations.of(context).triggerMapOptionAlcohol,
      SmokingTrigger.boredom =>
        AppLocalizations.of(context).triggerMapOptionBoredom,
      SmokingTrigger.morning =>
        AppLocalizations.of(context).triggerMapOptionMorning,
      SmokingTrigger.beforeBed =>
        AppLocalizations.of(context).triggerMapOptionBeforeBed,
    };
  }

  IconData _iconFor(SmokingTrigger trigger) {
    return switch (trigger) {
      SmokingTrigger.stress => Icons.bolt_rounded,
      SmokingTrigger.afterMeals => Icons.restaurant_rounded,
      SmokingTrigger.driving => Icons.directions_car_filled_rounded,
      SmokingTrigger.coffee => Icons.coffee_rounded,
      SmokingTrigger.socialSettings => Icons.groups_rounded,
      SmokingTrigger.workBreaks => Icons.work_rounded,
      SmokingTrigger.alcohol => Icons.wine_bar_rounded,
      SmokingTrigger.boredom => Icons.more_horiz_rounded,
      SmokingTrigger.morning => Icons.wb_sunny_outlined,
      SmokingTrigger.beforeBed => Icons.dark_mode_rounded,
    };
  }

  void _toggleTrigger(SmokingTrigger trigger) {
    final updated = Set<SmokingTrigger>.of(selectedTriggers);
    if (!updated.add(trigger)) {
      updated.remove(trigger);
    }
    onSelectedTriggersChanged(updated);
  }

  Future<void> _showCustomTriggerEditor(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (sheetContext) => _CustomTriggerEditorSheet(
        isSpanish: isSpanish,
        initialValue: customTrigger ?? '',
        onSave: (value) {
          onCustomTriggerChanged(value);
          Navigator.of(sheetContext).pop();
        },
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
    final hasCustomTrigger = customTrigger?.trim().isNotEmpty ?? false;
    final selectionCount = selectedTriggers.length + (hasCustomTrigger ? 1 : 0);
    final canContinue = selectionCount > 0;

    return Scaffold(
      key: const ValueKey('functional-trigger-map-screen'),
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

              final footer = _TriggerBottomAction(
                isSpanish: isSpanish,
                selectionCount: selectionCount,
                canContinue: canContinue,
                onContinue: onContinue,
                horizontalPadding: largeText ? 0 : horizontalPadding,
                compact: compact,
              );

              final header = _TriggerHeader(
                isSpanish: isSpanish,
                onBack: onBack,
              );
              final progress = _TriggerProgress(isSpanish: isSpanish);

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
                      key: const ValueKey('trigger-content-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 7 : 16,
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
                                AppLocalizations.of(context)
                                    .triggerMapQuestionLabel,
                                style: const TextStyle(
                                  color: AppColors.mutedTeal,
                                  fontSize: 11,
                                  height: 1.25,
                                  letterSpacing: 1.8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(context).triggerMapQuestion,
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
                                    .triggerMapQuestionHint,
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
                                            SmokingTrigger.values.map(
                                                (t) => _labelFor(context, t)),
                                            halfWidth - _TriggerChoice.chrome,
                                            _choiceLabelStyle,
                                          ));
                                  final itemWidth = twoColumns
                                      ? halfWidth
                                      : gridConstraints.maxWidth;
                                  return Wrap(
                                    spacing: gap,
                                    runSpacing: gap,
                                    children: [
                                      for (final trigger
                                          in SmokingTrigger.values)
                                        SizedBox(
                                          width: itemWidth,
                                          child: _TriggerChoice(
                                            trigger: trigger,
                                            label: _labelFor(context, trigger),
                                            icon: _iconFor(trigger),
                                            selected: selectedTriggers
                                                .contains(trigger),
                                            onTap: () =>
                                                _toggleTrigger(trigger),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _CustomTriggerCard(
                                isSpanish: isSpanish,
                                customTrigger: customTrigger,
                                onEdit: () => _showCustomTriggerEditor(context),
                                onRemove: () => onCustomTriggerChanged(null),
                              ),
                              const SizedBox(height: 12),
                              _TriggerPrivacyNote(isSpanish: isSpanish),
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

class _CustomTriggerEditorSheet extends StatefulWidget {
  const _CustomTriggerEditorSheet({
    required this.isSpanish,
    required this.initialValue,
    required this.onSave,
  });

  final bool isSpanish;
  final String initialValue;
  final ValueChanged<String> onSave;

  @override
  State<_CustomTriggerEditorSheet> createState() =>
      _CustomTriggerEditorSheetState();
}

class _CustomTriggerEditorSheetState extends State<_CustomTriggerEditorSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final normalized = _controller.text.trim();
    if (normalized.isNotEmpty) {
      widget.onSave(normalized);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).triggerMapCustomSheetTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.deepTeal,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).triggerMapCustomSheetIntro,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.tealSecondary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('trigger-custom-input'),
              controller: _controller,
              autofocus: true,
              maxLength: 50,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)
                    .triggerMapCustomSheetFieldLabel,
                hintText:
                    AppLocalizations.of(context).triggerMapCustomSheetHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, child) {
                  return FilledButton(
                    key: const ValueKey('trigger-custom-save'),
                    onPressed: value.text.trim().isEmpty ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      AppLocalizations.of(context)
                          .triggerMapCustomSheetSaveButton,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TriggerHeader extends StatelessWidget {
  const _TriggerHeader({required this.isSpanish, required this.onBack});

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final back = IconButton.outlined(
      key: const ValueKey('trigger-back'),
      tooltip: AppLocalizations.of(context).triggerMapBackTooltip,
      onPressed: onBack,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.deepTeal,
        side: const BorderSide(color: AppColors.border),
      ),
      icon: const Icon(Icons.arrow_back_rounded),
    );
    final label = AppLocalizations.of(context).triggerMapHeaderTitle;
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
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Text(
        '2 OF 2',
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

class _TriggerProgress extends StatelessWidget {
  const _TriggerProgress({required this.isSpanish});

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
                AppLocalizations.of(context).triggerMapProgressLabel,
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
            key: ValueKey('trigger-progress'),
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

class _TriggerChoice extends StatelessWidget {
  const _TriggerChoice({
    required this.trigger,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final SmokingTrigger trigger;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  /// Width of the padding, icon and gap beside the label.
  static const chrome = 11.0 + 34 + 9 + 11;

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
          key: ValueKey('trigger-choice-${trigger.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.coral : AppColors.mint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: selected ? Colors.white : AppColors.deepTeal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(label, style: _choiceLabelStyle),
                      ),
                    ],
                  ),
                  if (selected)
                    Positioned(
                      key: ValueKey('trigger-selected-${trigger.name}'),
                      top: 0,
                      right: 0,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.coral,
                        size: 17,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomTriggerCard extends StatelessWidget {
  const _CustomTriggerCard({
    required this.isSpanish,
    required this.customTrigger,
    required this.onEdit,
    required this.onRemove,
  });

  final bool isSpanish;
  final String? customTrigger;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasValue = customTrigger?.trim().isNotEmpty ?? false;
    final icon = Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: AppColors.mint,
        shape: BoxShape.circle,
      ),
      child: Icon(
        hasValue ? Icons.edit_rounded : Icons.add_rounded,
        color: AppColors.deepTeal,
        size: 22,
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasValue
              ? (AppLocalizations.of(context).triggerMapCustomCardLabelFilled)
              : (AppLocalizations.of(context).triggerMapCustomCardLabelEmpty),
          style: const TextStyle(
            color: AppColors.mutedTeal,
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hasValue
              ? customTrigger!
              : (AppLocalizations.of(context).triggerMapCustomCardPlaceholder),
          style: TextStyle(
            color: AppColors.deepTeal,
            fontSize: hasValue ? 13.5 : 12,
            fontWeight: hasValue ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
    final remove = IconButton(
      key: const ValueKey('trigger-custom-remove'),
      tooltip: AppLocalizations.of(context).triggerMapCustomRemoveTooltip,
      onPressed: onRemove,
      icon: const Icon(
        Icons.close_rounded,
        color: AppColors.coral,
      ),
    );
    return Material(
      color: hasValue ? AppColors.coralLight : AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: hasValue ? AppColors.coral : AppColors.border,
          width: hasValue ? 1.7 : 1,
        ),
      ),
      child: InkWell(
        key: const ValueKey('trigger-add-own'),
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
          // At accessibility text sizes the text takes the card's full width
          // under the icon.
          child: usesLargeTextLayout(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        icon,
                        const Spacer(),
                        if (hasValue) remove,
                      ],
                    ),
                    const SizedBox(height: 8),
                    text,
                  ],
                )
              : Row(
                  children: [
                    icon,
                    const SizedBox(width: 11),
                    Expanded(child: text),
                    if (hasValue) remove,
                  ],
                ),
        ),
      ),
    );
  }
}

class _TriggerPrivacyNote extends StatelessWidget {
  const _TriggerPrivacyNote({required this.isSpanish});

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
        Icons.lock_outline_rounded,
        color: AppColors.deepTeal,
        size: 21,
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).triggerMapPrivacyNoteTitle,
          style: const TextStyle(
            color: AppColors.deepTeal,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          AppLocalizations.of(context).triggerMapPrivacyNoteBody,
          style: const TextStyle(
            color: AppColors.tealSecondary,
            fontSize: 11,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          AppLocalizations.of(context).triggerMapPrivacyNoteLocation,
          style: const TextStyle(
            color: AppColors.mutedTeal,
            fontSize: 10,
            height: 1.3,
          ),
        ),
      ],
    );
    return Container(
      key: const ValueKey('trigger-privacy-note'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mintStrong),
      ),
      // At accessibility text sizes the text takes the card's full width
      // under the icon.
      child: usesLargeTextLayout(context)
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

class _TriggerBottomAction extends StatelessWidget {
  const _TriggerBottomAction({
    required this.isSpanish,
    required this.selectionCount,
    required this.canContinue,
    required this.onContinue,
    required this.horizontalPadding,
    required this.compact,
  });

  final bool isSpanish;
  final int selectionCount;
  final bool canContinue;
  final VoidCallback onContinue;
  final double horizontalPadding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final countLabel =
        AppLocalizations.of(context).triggerMapSelectionCount(selectionCount);

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
                  key: const ValueKey('trigger-continue'),
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
                          AppLocalizations.of(context).triggerMapContinueButton,
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
                    countLabel,
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
