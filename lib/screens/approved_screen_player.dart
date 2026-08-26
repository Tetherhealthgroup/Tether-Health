import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/screen_spec.dart';
import '../models/tap_target.dart';
import '../theme/app_colors.dart';
import '../widgets/approved_screen_viewport.dart';
import 'baseline_assessment_screen.dart';
import 'choose_quit_path_screen.dart';
import 'consent_privacy_screen.dart';
import 'my_reasons_screen.dart';
import 'readiness_result_screen.dart';
import 'select_quit_date_screen.dart';
import 'support_preparation_screen.dart';
import 'trigger_map_screen.dart';
import 'welcome_screen.dart';
import 'why_breathefree_screen.dart';

class ApprovedScreenPlayer extends StatefulWidget {
  const ApprovedScreenPlayer({
    required this.currentIndex,
    required this.onSelectScreen,
    required this.onPrevious,
    required this.onNext,
    required this.onTarget,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelectScreen;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<AppTapTarget> onTarget;

  @override
  State<ApprovedScreenPlayer> createState() => _ApprovedScreenPlayerState();
}

class _ApprovedScreenPlayerState extends State<ApprovedScreenPlayer> {
  bool _showHotspots = false;
  WelcomeLanguage _language = WelcomeLanguage.english;
  bool _helpfulReminders = true;
  bool _shareWithCareTeam = false;
  bool _helpImproveBreatheFree = false;
  DailyCigaretteUse? _dailyCigaretteUse;
  Set<SmokingTrigger> _smokingTriggers = <SmokingTrigger>{};
  String? _customSmokingTrigger;
  ReadinessPath _readinessPath = ReadinessPath.prepare;
  QuitPlanPath _quitPlanPath = QuitPlanPath.setQuitDate;
  DateTime? _quitDate;
  bool _quitDayCheckIn = true;
  Set<QuitReason> _quitReasons = <QuitReason>{
    QuitReason.family,
    QuitReason.breatheEasier,
    QuitReason.improveHealth,
  };
  String? _customQuitReason;
  QuitReason? _topQuitReason = QuitReason.family;
  List<SupportPersonPlan> _supportPeople = const [
    SupportPersonPlan(
      id: 'jordan',
      name: 'Jordan',
      relationship: 'Friend',
      channel: SupportChannel.text,
      checkIn: 'Check in the evening before my quit date',
    ),
  ];
  Set<PreparationTask> _completedPreparationTasks = {
    PreparationTask.removeSupplies,
    PreparationTask.smokeFreeSpaces,
  };
  bool _treatmentSupport = true;
  bool _careTeamReminder = true;

  @override
  void initState() {
    super.initState();
    _configureSystemUi();
  }

  @override
  void didUpdateWidget(covariant ApprovedScreenPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _configureSystemUi();
    }
  }

  void _configureSystemUi() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      return;
    }

    if (widget.currentIndex <= 9) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.cream,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
      return;
    }

    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = approvedScreens[widget.currentIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _DesktopPlayer(
            spec: spec,
            currentIndex: widget.currentIndex,
            showHotspots: _showHotspots,
            onShowHotspotsChanged: (value) {
              setState(() => _showHotspots = value);
            },
            onSelectScreen: widget.onSelectScreen,
            onPrevious: widget.onPrevious,
            onNext: widget.onNext,
            onTarget: widget.onTarget,
          );
        }

        if (widget.currentIndex == 0) {
          return WelcomeScreen(
            language: _language,
            onLanguageSelected: (language) {
              setState(() => _language = language);
            },
            onGetStarted: widget.onNext,
          );
        }

        if (widget.currentIndex == 1) {
          return WhyBreatheFreeScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            onBack: widget.onPrevious,
            onContinue: widget.onNext,
          );
        }

        if (widget.currentIndex == 2) {
          return ConsentPrivacyScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            helpfulReminders: _helpfulReminders,
            shareWithCareTeam: _shareWithCareTeam,
            helpImproveBreatheFree: _helpImproveBreatheFree,
            onHelpfulRemindersChanged: (value) {
              setState(() => _helpfulReminders = value);
            },
            onShareWithCareTeamChanged: (value) {
              setState(() => _shareWithCareTeam = value);
            },
            onHelpImproveBreatheFreeChanged: (value) {
              setState(() => _helpImproveBreatheFree = value);
            },
            onBack: widget.onPrevious,
            onContinue: widget.onNext,
          );
        }

        if (widget.currentIndex == 3) {
          return BaselineAssessmentScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            dailyCigaretteUse: _dailyCigaretteUse,
            onDailyCigaretteUseChanged: (value) {
              setState(() => _dailyCigaretteUse = value);
            },
            onBack: widget.onPrevious,
            onContinue: widget.onNext,
          );
        }

        if (widget.currentIndex == 4) {
          return TriggerMapScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            selectedTriggers: _smokingTriggers,
            customTrigger: _customSmokingTrigger,
            onSelectedTriggersChanged: (value) {
              setState(() => _smokingTriggers = value);
            },
            onCustomTriggerChanged: (value) {
              setState(() => _customSmokingTrigger = value);
            },
            onBack: widget.onPrevious,
            onContinue: widget.onNext,
          );
        }

        if (widget.currentIndex == 5) {
          return ReadinessResultScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            dailyCigaretteUse: _dailyCigaretteUse,
            selectedTriggers: _smokingTriggers,
            customTrigger: _customSmokingTrigger,
            selectedPath: _readinessPath,
            onPathChanged: (value) {
              setState(() => _readinessPath = value);
            },
            onBack: widget.onPrevious,
            onContinue: widget.onNext,
          );
        }

        if (widget.currentIndex == 6) {
          return ChooseQuitPathScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            selectedPath: _quitPlanPath,
            onPathChanged: (value) {
              setState(() {
                _quitPlanPath = value;
                _quitDate = null;
              });
            },
            onBack: widget.onPrevious,
            onContinue: widget.onNext,
          );
        }

        if (widget.currentIndex == 7) {
          return SelectQuitDateScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            quitPath: _quitPlanPath,
            selectedDate: _quitDate,
            quitDayCheckIn: _quitDayCheckIn,
            onDateChanged: (value) {
              setState(() => _quitDate = value);
            },
            onQuitDayCheckInChanged: (value) {
              setState(() => _quitDayCheckIn = value);
            },
            onBack: widget.onPrevious,
            onContinue: (value) {
              setState(() => _quitDate = value);
              widget.onNext();
            },
          );
        }

        if (widget.currentIndex == 8) {
          return MyReasonsScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            selectedReasons: _quitReasons,
            customReason: _customQuitReason,
            topReason: _topQuitReason,
            onSelectionChanged: (reasons, topReason) {
              setState(() {
                _quitReasons = reasons;
                _topQuitReason = topReason;
              });
            },
            onCustomReasonChanged: (value) {
              setState(() => _customQuitReason = value);
            },
            onBack: widget.onPrevious,
            onContinue: widget.onNext,
          );
        }

        if (widget.currentIndex == 9) {
          return SupportPreparationScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            supportPeople: _supportPeople,
            completedTasks: _completedPreparationTasks,
            treatmentSupport: _treatmentSupport,
            careTeamReminder: _careTeamReminder,
            onSupportPeopleChanged: (value) {
              setState(() => _supportPeople = value);
            },
            onCompletedTasksChanged: (value) {
              setState(() => _completedPreparationTasks = value);
            },
            onTreatmentSupportChanged: (value) {
              setState(() => _treatmentSupport = value);
            },
            onCareTeamReminderChanged: (value) {
              setState(() => _careTeamReminder = value);
            },
            onBack: widget.onPrevious,
            onContinue: widget.onNext,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: ApprovedScreenViewport(
            spec: spec,
            onPrevious: widget.onPrevious,
            onNext: widget.onNext,
            onTarget: widget.onTarget,
          ),
        );
      },
    );
  }
}

class _DesktopPlayer extends StatelessWidget {
  const _DesktopPlayer({
    required this.spec,
    required this.currentIndex,
    required this.showHotspots,
    required this.onShowHotspotsChanged,
    required this.onSelectScreen,
    required this.onPrevious,
    required this.onNext,
    required this.onTarget,
  });

  final ScreenSpec spec;
  final int currentIndex;
  final bool showHotspots;
  final ValueChanged<bool> onShowHotspotsChanged;
  final ValueChanged<int> onSelectScreen;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<AppTapTarget> onTarget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2724),
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 300,
              child: _ScreenNavigator(
                currentIndex: currentIndex,
                onSelectScreen: onSelectScreen,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _DesktopToolbar(
                    spec: spec,
                    currentIndex: currentIndex,
                    showHotspots: showHotspots,
                    onShowHotspotsChanged: onShowHotspotsChanged,
                    onPrevious: onPrevious,
                    onNext: onNext,
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: AspectRatio(
                          aspectRatio: 1290 / 2796,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(42),
                              border: Border.all(
                                color: const Color(0xFF31534F),
                                width: 9,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x99000000),
                                  blurRadius: 40,
                                  offset: Offset(0, 20),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: ApprovedScreenViewport(
                                spec: spec,
                                showHotspots: showHotspots,
                                onPrevious: onPrevious,
                                onNext: onNext,
                                onTarget: onTarget,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 300,
              child: _DetailsPanel(
                spec: spec,
                currentIndex: currentIndex,
                onPrevious: onPrevious,
                onNext: onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenNavigator extends StatelessWidget {
  const _ScreenNavigator({
    required this.currentIndex,
    required this.onSelectScreen,
  });

  final int currentIndex;
  final ValueChanged<int> onSelectScreen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.deepTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.air_rounded,
                        color: AppColors.lime,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Text(
                        'BreatheFree',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.deepTeal,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${approvedScreens.length} approved screens',
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: approvedScreens.length,
              itemBuilder: (context, index) {
                final item = approvedScreens[index];
                final selected = currentIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  child: ListTile(
                    selected: selected,
                    selectedTileColor: AppColors.mint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minLeadingWidth: 30,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          selected ? AppColors.deepTeal : AppColors.cream,
                      foregroundColor:
                          selected ? Colors.white : AppColors.deepTeal,
                      child: Text(
                        item.number.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      item.phase.label,
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 11,
                      ),
                    ),
                    onTap: () => onSelectScreen(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopToolbar extends StatelessWidget {
  const _DesktopToolbar({
    required this.spec,
    required this.currentIndex,
    required this.showHotspots,
    required this.onShowHotspotsChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final ScreenSpec spec;
  final int currentIndex;
  final bool showHotspots;
  final ValueChanged<bool> onShowHotspotsChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Color(0xFF123C37),
        border: Border(bottom: BorderSide(color: Color(0xFF31534F))),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Previous screen',
            onPressed: currentIndex == 0 ? null : onPrevious,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            tooltip: 'Next screen',
            onPressed:
                currentIndex == approvedScreens.length - 1 ? null : onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              'Screen ${spec.number} · ${spec.title}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Text(
            'Show tap areas',
            style: TextStyle(color: Color(0xFFBFD5CD), fontSize: 13),
          ),
          Switch(
            value: showHotspots,
            onChanged: onShowHotspotsChanged,
          ),
        ],
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.spec,
    required this.currentIndex,
    required this.onPrevious,
    required this.onNext,
  });

  final ScreenSpec spec;
  final int currentIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.paper,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                spec.phase.label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              spec.title,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 28,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              spec.description,
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 18),
            const _InfoRow(
              icon: Icons.phone_iphone_rounded,
              title: 'Reference',
              value: '430 × 932 pt',
            ),
            const _InfoRow(
              icon: Icons.image_outlined,
              title: 'App Store asset',
              value: '1290 × 2796 px',
            ),
            const _InfoRow(
              icon: Icons.devices_rounded,
              title: 'Targets',
              value: 'iOS · Android · Desktop · Web',
            ),
            const Spacer(),
            const Text(
              'Use ← and →, swipe the phone preview, select a screen, or enable tap areas.',
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: currentIndex == 0 ? null : onPrevious,
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: currentIndex == approvedScreens.length - 1
                        ? null
                        : onNext,
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: AppColors.deepTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 12,
                    height: 1.35,
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
