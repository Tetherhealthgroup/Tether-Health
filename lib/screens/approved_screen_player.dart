import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/prototype_catalog.dart';
import '../models/screen_spec.dart';
import '../models/tap_target.dart';
import '../theme/app_colors.dart';
import '../unplug/models/unplug_screen_spec.dart';
import '../unplug/screens/unplug_screen_host.dart';
import '../widgets/approved_screen_viewport.dart';
import 'active_craving_rescue_screen.dart';
import 'baseline_assessment_screen.dart';
import 'choose_quit_path_screen.dart';
import 'consent_privacy_screen.dart';
import 'craving_recheck_screen.dart';
import 'craving_rescue_start_screen.dart';
import 'daily_check_in_screen.dart';
import 'exercise_complete_recheck_screen.dart';
import 'guided_stress_reset_screen.dart';
import 'home_preparation_screen.dart';
import 'my_reasons_screen.dart';
import 'personalized_next_step_screen.dart';
import 'readiness_result_screen.dart';
import 'recommended_rescue_tool_screen.dart';
import 'review_quit_plan_screen.dart';
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
  bool _editingPlanFromReview = false;
  bool _hasUnreadPreparationNotifications = true;
  DailyMood _dailyMood = DailyMood.okay;
  int _dailyStressLevel = 4;
  DailySmokingStatus _dailySmokingStatus = DailySmokingStatus.oneOrMore;
  int _dailyCigaretteCount = 6;
  int _dailyStrongestCraving = 6;
  int _dailyConfidence = 7;
  Set<DailySymptom> _dailySymptoms = {
    DailySymptom.restless,
    DailySymptom.irritable,
  };
  String? _dailyOtherSymptom;
  NextStepStrategy? _nextStepStrategyOverride;
  final Set<NextStepStrategy> _copingPlanStrategies = <NextStepStrategy>{};
  StressResetStep _stressResetStep = StressResetStep.breathe;
  int _stressResetStepElapsedSeconds = 0;
  int _stressResetTotalElapsedSeconds = 0;
  bool _stressResetPaused = false;
  bool _stressResetVoiceGuidance = true;
  bool _stressResetReducedMotion = true;
  int _stressResetBeforeCraving = 6;
  int _stressResetRecheckCraving = 6;
  StressResetHelpfulChoice? _stressResetHelpfulChoice;
  bool _stressResetResultSaved = false;
  int _rescueIntensity = 6;
  Set<RescueContext> _rescueContexts = <RescueContext>{};
  RescueTool _rescueTool = RescueTool.slowBreathing;
  int? _rescueReturnScreen;
  int _activeRescueElapsedSeconds = 0;
  bool _activeRescuePaused = false;
  bool _activeRescueVoiceEnabled = true;
  bool _activeRescueHapticsEnabled = true;
  int _rescueRecheckCraving = 3;
  RescueHelpfulChoice? _rescueHelpfulChoice;
  bool _rescueRecheckSaved = false;

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

    if (widget.currentIndex <= 17) {
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

  void _openPlanEditor(int index) {
    setState(() => _editingPlanFromReview = true);
    widget.onSelectScreen(index);
  }

  void _finishPlanEdit() {
    setState(() => _editingPlanFromReview = false);
    widget.onPrevious();
  }

  void _cancelPlanEdit() {
    setState(() => _editingPlanFromReview = false);
    widget.onPrevious();
  }

  DateTime _defaultQuitDate() {
    final today = DateUtils.dateOnly(DateTime.now());
    return switch (_quitPlanPath) {
      QuitPlanPath.setQuitDate => today.add(const Duration(days: 7)),
      QuitPlanPath.quitToday => today,
      QuitPlanPath.reduceGradually => today.add(const Duration(days: 14)),
    };
  }

  void _saveEffectiveQuitDate() {
    setState(() => _quitDate ??= _defaultQuitDate());
  }

  void _openRescue([int? intensity]) {
    setState(() {
      _rescueReturnScreen = widget.currentIndex;
      _rescueIntensity =
          (intensity ?? _dailyStrongestCraving).clamp(1, 10).toInt();
    });
    widget.onSelectScreen(16);
  }

  String _rescueTopReasonLabel(bool isSpanish) {
    final reason = _topQuitReason ??
        (_quitReasons.isNotEmpty ? _quitReasons.first : QuitReason.family);
    return switch (reason) {
      QuitReason.family =>
        isSpanish ? 'Proteger a mi familia' : 'Protect my family',
      QuitReason.breatheEasier =>
        isSpanish ? 'Respirar mejor' : 'Breathe easier',
      QuitReason.improveHealth =>
        isSpanish ? 'Mejorar mi salud' : 'Improve my health',
      QuitReason.saveMoney => isSpanish ? 'Ahorrar dinero' : 'Save money',
      QuitReason.control =>
        isSpanish ? 'Sentirme en control' : 'Feel more in control',
      QuitReason.future =>
        isSpanish ? 'Estar presente para mi futuro' : 'Be there for my future',
      QuitReason.custom => _customQuitReason?.trim().isNotEmpty == true
          ? _customQuitReason!.trim()
          : (isSpanish ? 'Mi propia razón' : 'My own reason'),
    };
  }

  String _rescueSupportName(bool isSpanish) {
    for (final person in _supportPeople) {
      if (person.enabled && person.name.trim().isNotEmpty) {
        return person.name.trim();
      }
    }
    return isSpanish ? 'tu persona de apoyo' : 'your support person';
  }

  /// The screen body, whichever module the current entry belongs to.
  Widget _buildScreen(CatalogEntry entry, {required bool showHotspots}) {
    switch (entry) {
      case ApprovedCatalogEntry(:final spec):
        return ApprovedScreenViewport(
          spec: spec,
          showHotspots: showHotspots,
          onPrevious: widget.onPrevious,
          onNext: widget.onNext,
          onTarget: widget.onTarget,
        );
      case UnplugCatalogEntry(:final spec):
        return UnplugScreenHost(
          spec: spec,
          position: widget.currentIndex - unplugCatalogOffset + 1,
          total: unplugScreens.length,
          onPrevious: widget.onPrevious,
          onNext: widget.onNext,
          onSelectLetter: (letter) {
            final index = prototypeIndexOfLetter(letter);
            if (index >= 0) widget.onSelectScreen(index);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = prototypeCatalog[widget.currentIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _DesktopPlayer(
            entry: entry,
            currentIndex: widget.currentIndex,
            showHotspots: _showHotspots,
            onShowHotspotsChanged: (value) {
              setState(() => _showHotspots = value);
            },
            onSelectScreen: widget.onSelectScreen,
            onPrevious: widget.onPrevious,
            onNext: widget.onNext,
            screenBuilder: (showHotspots) =>
                _buildScreen(entry, showHotspots: showHotspots),
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
            onBack:
                _editingPlanFromReview ? _cancelPlanEdit : widget.onPrevious,
            onContinue:
                _editingPlanFromReview ? _finishPlanEdit : widget.onNext,
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
            onBack:
                _editingPlanFromReview ? _cancelPlanEdit : widget.onPrevious,
            onContinue: (value) {
              setState(() => _quitDate = value);
              if (_editingPlanFromReview) {
                _finishPlanEdit();
              } else {
                widget.onNext();
              }
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
            onBack:
                _editingPlanFromReview ? _cancelPlanEdit : widget.onPrevious,
            onContinue:
                _editingPlanFromReview ? _finishPlanEdit : widget.onNext,
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
            onBack:
                _editingPlanFromReview ? _cancelPlanEdit : widget.onPrevious,
            onContinue:
                _editingPlanFromReview ? _finishPlanEdit : widget.onNext,
          );
        }

        if (widget.currentIndex == 10) {
          return ReviewQuitPlanScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            quitPath: _quitPlanPath,
            quitDate: _quitDate,
            selectedReasons: _quitReasons,
            customReason: _customQuitReason,
            topReason: _topQuitReason,
            supportPeople: _supportPeople,
            completedTasks: _completedPreparationTasks,
            treatmentSupport: _treatmentSupport,
            careTeamReminder: _careTeamReminder,
            onBack: widget.onPrevious,
            onEditQuitDate: () => _openPlanEditor(7),
            onEditApproach: () => _openPlanEditor(6),
            onEditReasons: () => _openPlanEditor(8),
            onEditSupport: () => _openPlanEditor(9),
            onEditPreparation: () => _openPlanEditor(9),
            onEditTreatment: () => _openPlanEditor(9),
            onStartPlan: () {
              _saveEffectiveQuitDate();
              widget.onNext();
            },
            onSaveForLater: _saveEffectiveQuitDate,
          );
        }

        if (widget.currentIndex == 11) {
          return HomePreparationScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            quitPath: _quitPlanPath,
            quitDate: _quitDate,
            selectedReasons: _quitReasons,
            customReason: _customQuitReason,
            topReason: _topQuitReason,
            supportPeople: _supportPeople,
            completedTasks: _completedPreparationTasks,
            treatmentSupport: _treatmentSupport,
            careTeamReminder: _careTeamReminder,
            hasUnreadNotifications: _hasUnreadPreparationNotifications,
            onNotificationsViewed: () {
              setState(() => _hasUnreadPreparationNotifications = false);
            },
            onTaskCompleted: (task) {
              setState(() => _completedPreparationTasks.add(task));
            },
            onOpenRescue: _openRescue,
            onOpenPlan: () => widget.onSelectScreen(10),
            onOpenProgress: () => widget.onSelectScreen(25),
            onOpenLearn: () => widget.onSelectScreen(24),
            onOpenSupport: () => widget.onSelectScreen(26),
            onOpenProfile: () => widget.onSelectScreen(27),
            onOpenReasons: () => widget.onSelectScreen(8),
            onOpenPreparation: () => widget.onSelectScreen(9),
            onOpenDailyCheckIn: () => widget.onSelectScreen(12),
          );
        }

        if (widget.currentIndex == 12) {
          return DailyCheckInScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            mood: _dailyMood,
            stressLevel: _dailyStressLevel,
            smokingStatus: _dailySmokingStatus,
            cigaretteCount: _dailyCigaretteCount,
            strongestCraving: _dailyStrongestCraving,
            confidence: _dailyConfidence,
            symptoms: _dailySymptoms,
            otherSymptom: _dailyOtherSymptom,
            onMoodChanged: (value) {
              setState(() {
                _dailyMood = value;
                _nextStepStrategyOverride = null;
              });
            },
            onStressChanged: (value) {
              setState(() {
                _dailyStressLevel = value;
                _nextStepStrategyOverride = null;
              });
            },
            onSmokingStatusChanged: (value) {
              setState(() {
                _dailySmokingStatus = value;
                _nextStepStrategyOverride = null;
              });
            },
            onCigaretteCountChanged: (value) {
              setState(() => _dailyCigaretteCount = value);
            },
            onStrongestCravingChanged: (value) {
              setState(() {
                _dailyStrongestCraving = value;
                _nextStepStrategyOverride = null;
              });
            },
            onConfidenceChanged: (value) {
              setState(() {
                _dailyConfidence = value;
                _nextStepStrategyOverride = null;
              });
            },
            onSymptomsChanged: (value) {
              setState(() {
                _dailySymptoms = value;
                _nextStepStrategyOverride = null;
              });
            },
            onOtherSymptomChanged: (value) {
              setState(() => _dailyOtherSymptom = value);
            },
            onClose: widget.onPrevious,
            onOpenRescue: _openRescue,
            onSave: widget.onNext,
          );
        }

        if (widget.currentIndex == 13) {
          return PersonalizedNextStepScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            mood: _dailyMood,
            stressLevel: _dailyStressLevel,
            smokingStatus: _dailySmokingStatus,
            cigaretteCount: _dailyCigaretteCount,
            strongestCraving: _dailyStrongestCraving,
            confidence: _dailyConfidence,
            symptoms: _dailySymptoms,
            otherSymptom: _dailyOtherSymptom,
            supportPeople: _supportPeople,
            strategyOverride: _nextStepStrategyOverride,
            copingPlanStrategies: _copingPlanStrategies,
            onBack: widget.onPrevious,
            onStrategyChanged: (value) {
              setState(() => _nextStepStrategyOverride = value);
            },
            onCopingPlanChanged: (strategy, added) {
              setState(() {
                if (added) {
                  _copingPlanStrategies.add(strategy);
                } else {
                  _copingPlanStrategies.remove(strategy);
                }
              });
            },
            onPractice: (strategy) {
              switch (strategy) {
                case NextStepStrategy.stressReset:
                  widget.onSelectScreen(14);
                  return;
                case NextStepStrategy.cravingRescue:
                  _openRescue();
                  return;
                case NextStepStrategy.supportCheckIn:
                  widget.onSelectScreen(26);
                  return;
              }
            },
            onOpenRescue: _openRescue,
            onOpenSupport: () => widget.onSelectScreen(26),
          );
        }

        if (widget.currentIndex == 14) {
          return GuidedStressResetScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            step: _stressResetStep,
            stepElapsedSeconds: _stressResetStepElapsedSeconds,
            totalElapsedSeconds: _stressResetTotalElapsedSeconds,
            isPaused: _stressResetPaused,
            voiceGuidanceEnabled: _stressResetVoiceGuidance,
            reducedMotionEnabled: _stressResetReducedMotion,
            onProgressChanged: (step, stepElapsed, totalElapsed) {
              setState(() {
                _stressResetStep = step;
                _stressResetStepElapsedSeconds = stepElapsed;
                _stressResetTotalElapsedSeconds = totalElapsed;
              });
            },
            onPausedChanged: (value) {
              setState(() => _stressResetPaused = value);
            },
            onVoiceGuidanceChanged: (value) {
              setState(() => _stressResetVoiceGuidance = value);
            },
            onReducedMotionChanged: (value) {
              setState(() => _stressResetReducedMotion = value);
            },
            onClose: widget.onPrevious,
            onComplete: () {
              setState(() {
                _stressResetPaused = true;
                _stressResetBeforeCraving = _dailyStrongestCraving;
                _stressResetRecheckCraving = _dailyStrongestCraving;
                _stressResetHelpfulChoice = null;
                _stressResetResultSaved = false;
              });
              widget.onSelectScreen(15);
            },
            onOpenRescue: () {
              setState(() => _stressResetPaused = true);
              _openRescue();
            },
          );
        }

        if (widget.currentIndex == 15) {
          return ExerciseCompleteRecheckScreen(
            isSpanish: _language == WelcomeLanguage.spanish,
            elapsedSeconds: _stressResetTotalElapsedSeconds,
            beforeCraving: _stressResetBeforeCraving,
            currentCraving: _stressResetRecheckCraving,
            helpfulChoice: _stressResetHelpfulChoice,
            resultSaved: _stressResetResultSaved,
            onCravingChanged: (value) {
              setState(() {
                _stressResetRecheckCraving = value;
                _stressResetResultSaved = false;
              });
            },
            onHelpfulChoiceChanged: (value) {
              setState(() {
                _stressResetHelpfulChoice = value;
                _stressResetResultSaved = false;
              });
            },
            onSave: () {
              setState(() {
                _stressResetResultSaved = true;
                _dailyStrongestCraving = _stressResetRecheckCraving;
              });
              widget.onSelectScreen(11);
            },
            onRepeat: () {
              setState(() {
                _stressResetStep = StressResetStep.breathe;
                _stressResetStepElapsedSeconds = 0;
                _stressResetTotalElapsedSeconds = 0;
                _stressResetPaused = false;
                _stressResetResultSaved = false;
              });
              widget.onSelectScreen(14);
            },
            onOpenRescue: () => _openRescue(_stressResetRecheckCraving),
            onClose: () => widget.onSelectScreen(13),
          );
        }

        if (widget.currentIndex == 16) {
          final isSpanish = _language == WelcomeLanguage.spanish;
          return CravingRescueStartScreen(
            isSpanish: isSpanish,
            intensity: _rescueIntensity,
            selectedContexts: _rescueContexts,
            topReason: _rescueTopReasonLabel(isSpanish),
            supportName: _rescueSupportName(isSpanish),
            onIntensityChanged: (value) {
              setState(() => _rescueIntensity = value);
            },
            onContextsChanged: (value) {
              setState(() => _rescueContexts = value);
            },
            onClose: widget.onPrevious,
            onContinue: () => widget.onSelectScreen(17),
            onViewSupport: () => widget.onSelectScreen(26),
          );
        }

        if (widget.currentIndex == 17) {
          final isSpanish = _language == WelcomeLanguage.spanish;
          return RecommendedRescueToolScreen(
            isSpanish: isSpanish,
            intensity: _rescueIntensity,
            stressSelected: _rescueContexts.contains(RescueContext.stress),
            supportName: _rescueSupportName(isSpanish),
            selectedTool: _rescueTool,
            onToolChanged: (value) {
              setState(() => _rescueTool = value);
            },
            onBack: () {
              final returnScreen = _rescueReturnScreen;
              if (returnScreen != null) {
                setState(() => _rescueReturnScreen = null);
                widget.onSelectScreen(returnScreen);
              } else {
                widget.onPrevious();
              }
            },
            onStart: () => widget.onSelectScreen(18),
            onViewSupport: () => widget.onSelectScreen(26),
          );
        }

        if (widget.currentIndex == 18) {
          final isSpanish = _language == WelcomeLanguage.spanish;
          return ActiveCravingRescueScreen(
            isSpanish: isSpanish,
            tool: _rescueTool,
            elapsedSeconds: _activeRescueElapsedSeconds,
            isPaused: _activeRescuePaused,
            voiceEnabled: _activeRescueVoiceEnabled,
            hapticsEnabled: _activeRescueHapticsEnabled,
            onElapsedChanged: (value) {
              setState(() => _activeRescueElapsedSeconds = value);
            },
            onPausedChanged: (value) {
              setState(() => _activeRescuePaused = value);
            },
            onVoiceChanged: (value) {
              setState(() => _activeRescueVoiceEnabled = value);
            },
            onHapticsChanged: (value) {
              setState(() => _activeRescueHapticsEnabled = value);
            },
            onClose: () => widget.onSelectScreen(17),
            onComplete: () {
              setState(() {
                _activeRescuePaused = true;
              });
              widget.onSelectScreen(19);
            },
            onSwitchTool: () => widget.onSelectScreen(17),
            onOpenSupport: () => widget.onSelectScreen(26),
          );
        }

        if (widget.currentIndex == 19) {
          final isSpanish = _language == WelcomeLanguage.spanish;
          return CravingRecheckScreen(
            isSpanish: isSpanish,
            tool: _rescueTool,
            elapsedSeconds: _activeRescueElapsedSeconds,
            beforeCraving: _rescueIntensity,
            currentCraving: _rescueRecheckCraving,
            helpfulChoice: _rescueHelpfulChoice,
            resultSaved: _rescueRecheckSaved,
            onCravingChanged: (value) {
              setState(() {
                _rescueRecheckCraving = value;
                // A changed rating invalidates a saved result: Screen 21 must
                // never show a number the patient has since moved.
                _rescueRecheckSaved = false;
              });
            },
            onHelpfulChoiceChanged: (value) {
              setState(() => _rescueHelpfulChoice = value);
            },
            onSave: () {
              setState(() => _rescueRecheckSaved = true);
              widget.onSelectScreen(20);
            },
            onRepeat: () {
              setState(() {
                _activeRescueElapsedSeconds = 0;
                _activeRescuePaused = false;
              });
              widget.onSelectScreen(18);
            },
            onSwitchTool: () => widget.onSelectScreen(17),
            onOpenSupport: () => widget.onSelectScreen(26),
            onClose: () => widget.onSelectScreen(11),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: _buildScreen(entry, showHotspots: false),
        );
      },
    );
  }
}

class _DesktopPlayer extends StatelessWidget {
  const _DesktopPlayer({
    required this.entry,
    required this.currentIndex,
    required this.showHotspots,
    required this.onShowHotspotsChanged,
    required this.onSelectScreen,
    required this.onPrevious,
    required this.onNext,
    required this.screenBuilder,
  });

  final CatalogEntry entry;
  final int currentIndex;
  final bool showHotspots;
  final ValueChanged<bool> onShowHotspotsChanged;
  final ValueChanged<int> onSelectScreen;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget Function(bool showHotspots) screenBuilder;

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
                    entry: entry,
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
                              child: screenBuilder(showHotspots),
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
                entry: entry,
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
                        'Tether Health',
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
              itemCount: prototypeCatalog.length,
              itemBuilder: (context, index) {
                final item = prototypeCatalog[index];
                final selected = currentIndex == index;
                final header = index == unplugCatalogOffset
                    ? const _NavigatorHeading('Unplug v2.1 · screens A–L')
                    : null;

                final tile = Padding(
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
                        item.badge,
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
                      item.sectionLabel,
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 11,
                      ),
                    ),
                    onTap: () => onSelectScreen(index),
                  ),
                );

                if (header == null) return tile;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [header, tile],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigatorHeading extends StatelessWidget {
  const _NavigatorHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.mutedTeal,
          fontSize: 10.5,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DesktopToolbar extends StatelessWidget {
  const _DesktopToolbar({
    required this.entry,
    required this.currentIndex,
    required this.showHotspots,
    required this.onShowHotspotsChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final CatalogEntry entry;
  final int currentIndex;
  final bool showHotspots;
  final ValueChanged<bool> onShowHotspotsChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final approved = entry is ApprovedCatalogEntry;

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
            onPressed: currentIndex == prototypeCatalog.length - 1
                ? null
                : onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              'Screen ${entry.badge} · ${entry.title}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            approved ? 'Show tap areas' : 'Tap areas are approved-screen only',
            style: const TextStyle(color: Color(0xFFBFD5CD), fontSize: 13),
          ),
          Switch(
            value: showHotspots && approved,
            onChanged: approved ? onShowHotspotsChanged : null,
          ),
        ],
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.entry,
    required this.currentIndex,
    required this.onPrevious,
    required this.onNext,
  });

  final CatalogEntry entry;
  final int currentIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  String get _description => switch (entry) {
        ApprovedCatalogEntry(:final spec) => spec.description,
        UnplugCatalogEntry(:final spec) => spec.description,
      };

  List<Widget> get _facts => switch (entry) {
        ApprovedCatalogEntry() => const [
            _InfoRow(
              icon: Icons.phone_iphone_rounded,
              title: 'Reference',
              value: '430 × 932 pt',
            ),
            _InfoRow(
              icon: Icons.image_outlined,
              title: 'App Store asset',
              value: '1290 × 2796 px',
            ),
            _InfoRow(
              icon: Icons.devices_rounded,
              title: 'Targets',
              value: 'iOS · Android · Desktop · Web',
            ),
          ],
        UnplugCatalogEntry(:final spec) => [
            _InfoRow(
              icon: Icons.description_outlined,
              title: 'Specified by',
              value: 'Addendum ${spec.addendumRef}',
            ),
            const _InfoRow(
              icon: Icons.widgets_outlined,
              title: 'Rendering',
              value: 'Native widgets · no bitmap',
            ),
            const _InfoRow(
              icon: Icons.devices_rounded,
              title: 'Targets',
              value: 'iOS · Android · Desktop · Web',
            ),
          ],
      };

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
                entry.sectionLabel.toUpperCase(),
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
              entry.title,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 28,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _description,
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 18),
            ..._facts,
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
                    onPressed: currentIndex == prototypeCatalog.length - 1
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
