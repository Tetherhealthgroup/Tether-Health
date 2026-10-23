import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum RescueTool {
  slowBreathing,
  move,
  changeScene,
}

/// A Rescue the member finished and rated earlier in this session.
@immutable
class RescueLastResult {
  const RescueLastResult({
    required this.tool,
    required this.before,
    required this.after,
    required this.helpful,
  });

  final RescueTool tool;
  final int before;
  final int after;

  /// The member answered that the tool helped.
  final bool helpful;
}

class RecommendedRescueToolScreen extends StatelessWidget {
  const RecommendedRescueToolScreen({
    required this.isSpanish,
    required this.intensity,
    required this.stressSelected,
    required this.supportName,
    required this.selectedTool,
    required this.onToolChanged,
    required this.onBack,
    required this.onStart,
    required this.onViewSupport,
    this.lastResult,
    super.key,
  });

  final bool isSpanish;
  final int intensity;
  final bool stressSelected;
  final String supportName;
  final RescueTool selectedTool;
  final ValueChanged<RescueTool> onToolChanged;
  final VoidCallback onBack;
  final VoidCallback onStart;
  final VoidCallback onViewSupport;

  /// The member's last rated Rescue, or null when there is none. Only a real
  /// result is described; nothing is claimed without one.
  final RescueLastResult? lastResult;

  static const _cream = Color(0xFFF8F4EA);
  static const _deepTeal = Color(0xFF0D4B43);
  static const _teal = Color(0xFF245E55);
  static const _mutedTeal = Color(0xFF6A8882);
  static const _mint = Color(0xFFDDF1E9);
  static const _lime = Color(0xFFD6F36A);
  static const _coral = Color(0xFFFF765F);
  static const _coralSoft = Color(0xFFFFEEE9);
  static const _paper = Color(0xFFFFFDF7);
  static const _line = Color(0xFFD4E3DE);

  bool get _strongCraving => intensity >= 7;

  /// The last result, when it was the slow breathing this card recommends.
  RescueLastResult? get _breathingResult =>
      lastResult?.tool == RescueTool.slowBreathing ? lastResult : null;

  /// Slow breathing helped the member before.
  bool get _helpedBefore => _breathingResult?.helpful == true;

  String? _primaryContext(BuildContext context) {
    if (stressSelected) {
      return AppLocalizations.of(context).recommendedRescueToolContextStress;
    }
    if (_helpedBefore) {
      return AppLocalizations.of(context).recommendedRescueToolContextPersonal;
    }
    return null;
  }

  String _startLabel(BuildContext context) => switch (selectedTool) {
        RescueTool.slowBreathing => AppLocalizations.of(context)
            .recommendedRescueToolStartRecommendedButton,
        RescueTool.move =>
          AppLocalizations.of(context).recommendedRescueToolStartMoveButton,
        RescueTool.changeScene =>
          AppLocalizations.of(context).recommendedRescueToolStartSceneButton,
      };

  @override
  Widget build(BuildContext context) {
    // The text comes from the app locale; the language the screen was given
    // must be the same one.
    assert(
      isSpanish == (Localizations.localeOf(context).languageCode == 'es'),
      'the screen language must match the app locale',
    );
    return Scaffold(
      key: const ValueKey('functional-recommended-rescue-tool-screen'),
      backgroundColor: _cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              isSpanish: isSpanish,
              onBack: onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('rescue-tool-scroll'),
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProgressIntro(isSpanish: isSpanish),
                        const SizedBox(height: 26),
                        Text(
                          AppLocalizations.of(context)
                              .recommendedRescueToolEyebrow,
                          style: const TextStyle(
                            color: _mutedTeal,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _helpedBefore
                              ? AppLocalizations.of(context)
                                  .recommendedRescueToolTitleHelpedBefore
                              : AppLocalizations.of(context)
                                  .recommendedRescueToolTitle,
                          style: const TextStyle(
                            color: _deepTeal,
                            fontSize: 31,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lastResult == null
                              ? AppLocalizations.of(context)
                                  .recommendedRescueToolIntro
                              : AppLocalizations.of(context)
                                  .recommendedRescueToolIntroWithResult,
                          style: const TextStyle(
                            color: _teal,
                            fontSize: 16,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _RecommendedCard(
                          isSpanish: isSpanish,
                          selected: selectedTool == RescueTool.slowBreathing,
                          contextLabel: _primaryContext(context),
                          lastResult: _breathingResult,
                          onSelect: () =>
                              onToolChanged(RescueTool.slowBreathing),
                          onStart: () {
                            onToolChanged(RescueTool.slowBreathing);
                            onStart();
                          },
                        ),
                        const SizedBox(height: 16),
                        _WhyMatchCard(
                          isSpanish: isSpanish,
                          intensity: intensity,
                          stressSelected: stressSelected,
                          helpedBefore: _helpedBefore,
                          onTap: () => _showWhyMatch(context),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)
                                    .recommendedRescueToolOtherActionsLabel,
                                style: const TextStyle(
                                  color: _deepTeal,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)
                                  .recommendedRescueToolYourChoiceBadge,
                              style: const TextStyle(
                                color: _mutedTeal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stackCards = constraints.maxWidth < 430;
                            final move = _AlternateToolCard(
                              key: const ValueKey('rescue-tool-move'),
                              title: AppLocalizations.of(context)
                                  .recommendedRescueToolMoveName,
                              subtitle: AppLocalizations.of(context)
                                  .recommendedRescueToolMoveDescription,
                              footer: AppLocalizations.of(context)
                                  .recommendedRescueToolMoveFeatures,
                              icon: Icons.directions_walk_rounded,
                              selected: selectedTool == RescueTool.move,
                              onTap: () => onToolChanged(RescueTool.move),
                            );
                            final change = _AlternateToolCard(
                              key: const ValueKey('rescue-tool-change-scene'),
                              title: AppLocalizations.of(context)
                                  .recommendedRescueToolSceneName,
                              subtitle: AppLocalizations.of(context)
                                  .recommendedRescueToolSceneDescription,
                              footer: AppLocalizations.of(context)
                                  .recommendedRescueToolSceneFeatures,
                              icon: Icons.swap_horiz_rounded,
                              selected: selectedTool == RescueTool.changeScene,
                              onTap: () =>
                                  onToolChanged(RescueTool.changeScene),
                            );

                            if (stackCards) {
                              return Column(
                                children: [
                                  move,
                                  const SizedBox(height: 12),
                                  change,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: move),
                                const SizedBox(width: 12),
                                Expanded(child: change),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _SupportCard(
                          isSpanish: isSpanish,
                          supportName: supportName,
                          strongCraving: _strongCraving,
                          onViewSupport: onViewSupport,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3EF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                color: _mutedTeal,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)
                                      .recommendedRescueToolDataNote,
                                  style: const TextStyle(
                                    color: _mutedTeal,
                                    fontSize: 12.5,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Content v1.0',
                                style: TextStyle(
                                  color: _teal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            AppLocalizations.of(context)
                                .recommendedRescueToolSwitchNote,
                            style: const TextStyle(
                              color: _mutedTeal,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: _cream,
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  key: const ValueKey('rescue-tool-start'),
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: _deepTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _startLabel(context),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, color: _lime),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showWhyMatch(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _paper,
      builder: (context) {
        final triggerText = stressSelected
            ? AppLocalizations.of(context)
                .recommendedRescueToolWhySheetTitleStress
            : AppLocalizations.of(context).recommendedRescueToolWhySheetTitle;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)
                      .recommendedRescueToolWhyMatchLink,
                  style: const TextStyle(
                    color: _deepTeal,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _helpedBefore
                      ? AppLocalizations.of(context)
                          .recommendedRescueToolWhySheetBodyHelped(
                              triggerText, intensity)
                      : AppLocalizations.of(context)
                          .recommendedRescueToolWhySheetBody(
                              triggerText, intensity),
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)
                      .recommendedRescueToolWhySheetNote,
                  style: const TextStyle(
                    color: _mutedTeal,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('rescue-tool-why-done'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context)
                        .recommendedRescueToolWhySheetDoneButton),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isSpanish, required this.onBack});

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('rescue-tool-back'),
            tooltip:
                AppLocalizations.of(context).recommendedRescueToolBackTooltip,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: RecommendedRescueToolScreen._deepTeal,
              side: const BorderSide(color: RecommendedRescueToolScreen._line),
            ),
          ),
          const Expanded(
            child: Text(
              'Craving Rescue',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RecommendedRescueToolScreen._deepTeal,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F1EB),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              AppLocalizations.of(context).recommendedRescueToolStepCounter,
              style: const TextStyle(
                color: RecommendedRescueToolScreen._teal,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressIntro extends StatelessWidget {
  const _ProgressIntro({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context).recommendedRescueToolProgressLabel,
              style: const TextStyle(
                color: RecommendedRescueToolScreen._mutedTeal,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
            const Spacer(),
            const Text(
              '40%',
              style: TextStyle(
                color: RecommendedRescueToolScreen._mutedTeal,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: const LinearProgressIndicator(
            key: ValueKey('rescue-tool-progress'),
            value: .4,
            minHeight: 7,
            backgroundColor: RecommendedRescueToolScreen._line,
            valueColor: AlwaysStoppedAnimation<Color>(
              RecommendedRescueToolScreen._coral,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.isSpanish,
    required this.selected,
    required this.contextLabel,
    required this.lastResult,
    required this.onSelect,
    required this.onStart,
  });

  final bool isSpanish;
  final bool selected;
  final String? contextLabel;
  final RescueLastResult? lastResult;
  final VoidCallback onSelect;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: const ValueKey('rescue-tool-slow-breathing-card'),
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: RecommendedRescueToolScreen._deepTeal,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              selected ? RecommendedRescueToolScreen._lime : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A655C),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: RecommendedRescueToolScreen._coral,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        AppLocalizations.of(context)
                            .recommendedRescueToolRecommendedBadge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .recommendedRescueToolBreathingName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppLocalizations.of(context)
                                .recommendedRescueToolBreathingDescription,
                            style: const TextStyle(
                              color: Color(0xFFD5E6E1),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 106,
                      height: 106,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: RecommendedRescueToolScreen._lime,
                        shape: BoxShape.circle,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '2:00',
                            style: TextStyle(
                              color: RecommendedRescueToolScreen._deepTeal,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'MINUTES',
                            style: TextStyle(
                              color: RecommendedRescueToolScreen._teal,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (lastResult case final result?) ...[
                  const SizedBox(height: 18),
                  Container(
                    key: const ValueKey('rescue-tool-last-result'),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20594F),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .recommendedRescueToolLastResultLabel,
                                style: const TextStyle(
                                  color: Color(0xFFBFD4CD),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppLocalizations.of(context)
                                    .recommendedRescueToolLastResult(
                                        result.before, result.after),
                                style: const TextStyle(
                                  color: Color(0xFFC7DAD4),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: RecommendedRescueToolScreen._lime,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${result.before} → ${result.after}',
                                style: const TextStyle(
                                  color: RecommendedRescueToolScreen._deepTeal,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'LAST TIME',
                                style: TextStyle(
                                  color: RecommendedRescueToolScreen._teal,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (contextLabel case final label?)
                      _Pill(text: label, icon: Icons.circle, accent: true),
                    _Pill(
                      text: AppLocalizations.of(context)
                          .recommendedRescueToolBreathingOffline,
                      icon: Icons.wifi_rounded,
                    ),
                    _Pill(
                      text: AppLocalizations.of(context)
                          .recommendedRescueToolBreathingVoice,
                      icon: Icons.volume_up_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    key: const ValueKey('rescue-tool-start-breathing'),
                    onPressed: onStart,
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    label: Text(
                      AppLocalizations.of(context)
                          .recommendedRescueToolStartBreathingButton,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: RecommendedRescueToolScreen._lime,
                      foregroundColor: RecommendedRescueToolScreen._deepTeal,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.icon,
    this.accent = false,
  });

  final String text;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF56857B)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: accent
                ? RecommendedRescueToolScreen._coral
                : RecommendedRescueToolScreen._lime,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyMatchCard extends StatelessWidget {
  const _WhyMatchCard({
    required this.isSpanish,
    required this.intensity,
    required this.stressSelected,
    required this.helpedBefore,
    required this.onTap,
  });

  final bool isSpanish;
  final int intensity;
  final bool stressSelected;
  final bool helpedBefore;
  final VoidCallback onTap;

  String _reason(BuildContext context) {
    if (helpedBefore) {
      return stressSelected
          ? (AppLocalizations.of(context)
              .recommendedRescueToolReasonStressHelped(intensity))
          : (AppLocalizations.of(context)
              .recommendedRescueToolReasonHelped(intensity));
    }
    return stressSelected
        ? (AppLocalizations.of(context)
            .recommendedRescueToolReasonStress(intensity))
        : (AppLocalizations.of(context).recommendedRescueToolReason(intensity));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RecommendedRescueToolScreen._mint,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const ValueKey('rescue-tool-why-match'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: RecommendedRescueToolScreen._paper,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: RecommendedRescueToolScreen._deepTeal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .recommendedRescueToolWhyMatchLink,
                      style: const TextStyle(
                        color: RecommendedRescueToolScreen._deepTeal,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _reason(context),
                      style: const TextStyle(
                        color: RecommendedRescueToolScreen._teal,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: RecommendedRescueToolScreen._deepTeal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlternateToolCard extends StatelessWidget {
  const _AlternateToolCard({
    required super.key,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String footer;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RecommendedRescueToolScreen._paper,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? RecommendedRescueToolScreen._coral
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? RecommendedRescueToolScreen._coralSoft
                          : RecommendedRescueToolScreen._mint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: selected
                          ? RecommendedRescueToolScreen._coral
                          : RecommendedRescueToolScreen._deepTeal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: RecommendedRescueToolScreen._deepTeal,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: RecommendedRescueToolScreen._mutedTeal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: RecommendedRescueToolScreen._coral,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(
                  height: 1, color: RecommendedRescueToolScreen._line),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      footer,
                      style: const TextStyle(
                        color: RecommendedRescueToolScreen._teal,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: RecommendedRescueToolScreen._deepTeal,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.isSpanish,
    required this.supportName,
    required this.strongCraving,
    required this.onViewSupport,
  });

  final bool isSpanish;
  final String supportName;
  final bool strongCraving;
  final VoidCallback onViewSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RecommendedRescueToolScreen._coralSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFAF9F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: RecommendedRescueToolScreen._coral,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strongCraving
                          ? (AppLocalizations.of(context)
                              .recommendedRescueToolSupportTitleStrong)
                          : (AppLocalizations.of(context)
                              .recommendedRescueToolSupportTitle),
                      style: const TextStyle(
                        color: RecommendedRescueToolScreen._deepTeal,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppLocalizations.of(context)
                          .recommendedRescueToolSupportBody(supportName),
                      style: const TextStyle(
                        color: RecommendedRescueToolScreen._teal,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('rescue-tool-support'),
              onPressed: onViewSupport,
              style: FilledButton.styleFrom(
                backgroundColor: RecommendedRescueToolScreen._coral,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)
                  .recommendedRescueToolSupportButton),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).recommendedRescueToolSupportNote,
            style: const TextStyle(
              color: Color(0xFF8E756E),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
