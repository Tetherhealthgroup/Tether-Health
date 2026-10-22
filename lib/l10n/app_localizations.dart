import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// lib/screens/active_craving_rescue_screen.dart: Guidance line while breathing in
  ///
  /// In en, this message translates to:
  /// **'Let the breath come in gently.'**
  String get activeCravingRescueBreathingInGuide;

  /// lib/screens/active_craving_rescue_screen.dart: Big label in the breathing circle while breathing in
  ///
  /// In en, this message translates to:
  /// **'BREATHE IN'**
  String get activeCravingRescueBreathingInLabel;

  /// lib/screens/active_craving_rescue_screen.dart: Guidance line while breathing out
  ///
  /// In en, this message translates to:
  /// **'Let your shoulders soften as you exhale.'**
  String get activeCravingRescueBreathingOutGuide;

  /// lib/screens/active_craving_rescue_screen.dart: Big label in the breathing circle while breathing out
  ///
  /// In en, this message translates to:
  /// **'BREATHE OUT'**
  String get activeCravingRescueBreathingOutLabel;

  /// lib/screens/active_craving_rescue_screen.dart: Word under the circle label: breathe slowly
  ///
  /// In en, this message translates to:
  /// **'Slowly'**
  String get activeCravingRescueBreathingPace;

  /// lib/screens/active_craving_rescue_screen.dart: Unit under the seconds countdown in the circle
  ///
  /// In en, this message translates to:
  /// **'SECONDS'**
  String get activeCravingRescueBreathingSecondsUnit;

  /// lib/screens/active_craving_rescue_screen.dart: Time left on the breathing card ({time} is minutes:seconds); short form
  ///
  /// In en, this message translates to:
  /// **'{time} LEFT'**
  String activeCravingRescueBreathingTimeLeft(Object time);

  /// lib/screens/active_craving_rescue_screen.dart: Title of the breathing card
  ///
  /// In en, this message translates to:
  /// **'SLOW BREATHING'**
  String get activeCravingRescueBreathingTitle;

  /// lib/screens/active_craving_rescue_screen.dart: Guidance on the change-the-scene card
  ///
  /// In en, this message translates to:
  /// **'Go somewhere smoke-free and change what you are doing.'**
  String get activeCravingRescueChangeSceneGuide;

  /// lib/screens/active_craving_rescue_screen.dart: Big instruction on the change-the-scene card
  ///
  /// In en, this message translates to:
  /// **'CHANGE YOUR SURROUNDINGS'**
  String get activeCravingRescueChangeSceneHeadline;

  /// lib/screens/active_craving_rescue_screen.dart: Title of the change-the-scene card
  ///
  /// In en, this message translates to:
  /// **'CHANGE THE SCENE'**
  String get activeCravingRescueChangeSceneTitle;

  /// lib/screens/active_craving_rescue_screen.dart: Tooltip and accessibility label of the header close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get activeCravingRescueCloseTooltip;

  /// lib/screens/active_craving_rescue_screen.dart: State shown under the voice or haptics control when it is off
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get activeCravingRescueControlOff;

  /// lib/screens/active_craving_rescue_screen.dart: State shown under the voice or haptics control when it is on
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get activeCravingRescueControlOn;

  /// lib/screens/active_craving_rescue_screen.dart: Encouragement card text: let the urge pass without smoking
  ///
  /// In en, this message translates to:
  /// **'You can let it rise and pass without smoking.'**
  String get activeCravingRescueEncouragementBody;

  /// lib/screens/active_craving_rescue_screen.dart: Encouragement card note: stay with this breath
  ///
  /// In en, this message translates to:
  /// **'You only need to stay with this breath—not solve the whole day.'**
  String get activeCravingRescueEncouragementNote;

  /// lib/screens/active_craving_rescue_screen.dart: Encouragement card: the urge is a wave
  ///
  /// In en, this message translates to:
  /// **'The urge is a wave.'**
  String get activeCravingRescueEncouragementTitle;

  /// lib/screens/active_craving_rescue_screen.dart: Button that ends the exercise
  ///
  /// In en, this message translates to:
  /// **'End exercise'**
  String get activeCravingRescueEndButton;

  /// lib/screens/active_craving_rescue_screen.dart: Dialog text: the craving can be rated again next
  ///
  /// In en, this message translates to:
  /// **'You can rate the craving again next.'**
  String get activeCravingRescueEndDialogBody;

  /// lib/screens/active_craving_rescue_screen.dart: Dialog button that keeps practicing
  ///
  /// In en, this message translates to:
  /// **'Keep practicing'**
  String get activeCravingRescueEndDialogCancel;

  /// lib/screens/active_craving_rescue_screen.dart: Dialog button that ends the exercise and goes to the recheck
  ///
  /// In en, this message translates to:
  /// **'End and recheck'**
  String get activeCravingRescueEndDialogConfirm;

  /// lib/screens/active_craving_rescue_screen.dart: Title of the dialog that asks whether to end the exercise
  ///
  /// In en, this message translates to:
  /// **'End the exercise now?'**
  String get activeCravingRescueEndDialogTitle;

  /// lib/screens/active_craving_rescue_screen.dart: Vibration control button: the word Haptics and, on a second line, its state ({state} is on or off)
  ///
  /// In en, this message translates to:
  /// **'Haptics\n{state}'**
  String activeCravingRescueHapticsControl(Object state);

  /// lib/screens/active_craving_rescue_screen.dart: Text under the title: follow the circle or breathe slowly
  ///
  /// In en, this message translates to:
  /// **'Follow the circle—or breathe slowly in your own way.'**
  String get activeCravingRescueIntro;

  /// lib/screens/active_craving_rescue_screen.dart: Dialog text: progress is kept
  ///
  /// In en, this message translates to:
  /// **'Your progress will be kept so you can return.'**
  String get activeCravingRescueLeaveDialogBody;

  /// lib/screens/active_craving_rescue_screen.dart: Dialog button that saves and leaves
  ///
  /// In en, this message translates to:
  /// **'Save and leave'**
  String get activeCravingRescueLeaveDialogLeave;

  /// lib/screens/active_craving_rescue_screen.dart: Dialog button that stays and keeps breathing
  ///
  /// In en, this message translates to:
  /// **'Keep breathing'**
  String get activeCravingRescueLeaveDialogStay;

  /// lib/screens/active_craving_rescue_screen.dart: Title of the dialog that asks whether to leave the exercise
  ///
  /// In en, this message translates to:
  /// **'Leave this exercise?'**
  String get activeCravingRescueLeaveDialogTitle;

  /// lib/screens/active_craving_rescue_screen.dart: Guidance on the movement card
  ///
  /// In en, this message translates to:
  /// **'Walk, stretch, or move gently.'**
  String get activeCravingRescueMovementGuide;

  /// lib/screens/active_craving_rescue_screen.dart: Vibration control on the movement card when vibration is off
  ///
  /// In en, this message translates to:
  /// **'Haptics OFF'**
  String get activeCravingRescueMovementHapticsOff;

  /// lib/screens/active_craving_rescue_screen.dart: Vibration control on the movement card when vibration is on
  ///
  /// In en, this message translates to:
  /// **'Haptics ON'**
  String get activeCravingRescueMovementHapticsOn;

  /// lib/screens/active_craving_rescue_screen.dart: Big instruction on the movement card
  ///
  /// In en, this message translates to:
  /// **'KEEP MOVING'**
  String get activeCravingRescueMovementHeadline;

  /// lib/screens/active_craving_rescue_screen.dart: Title of the movement card
  ///
  /// In en, this message translates to:
  /// **'MOVEMENT'**
  String get activeCravingRescueMovementTitle;

  /// lib/screens/active_craving_rescue_screen.dart: Voice control on the movement card when voice is off
  ///
  /// In en, this message translates to:
  /// **'Voice OFF'**
  String get activeCravingRescueMovementVoiceOff;

  /// lib/screens/active_craving_rescue_screen.dart: Voice control on the movement card when voice is on
  ///
  /// In en, this message translates to:
  /// **'Voice ON'**
  String get activeCravingRescueMovementVoiceOn;

  /// lib/screens/active_craving_rescue_screen.dart: Badge: the breathing tool works offline
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get activeCravingRescueOfflineBadge;

  /// lib/screens/active_craving_rescue_screen.dart: Card text: tools can be changed without losing the check-in
  ///
  /// In en, this message translates to:
  /// **'You can change tools without losing this check-in.'**
  String get activeCravingRescueOtherSupportBody;

  /// lib/screens/active_craving_rescue_screen.dart: Title of the card offering different support
  ///
  /// In en, this message translates to:
  /// **'Need different support right now?'**
  String get activeCravingRescueOtherSupportTitle;

  /// lib/screens/active_craving_rescue_screen.dart: Button that pauses the exercise
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get activeCravingRescuePauseButton;

  /// lib/screens/active_craving_rescue_screen.dart: Button that opens support from a person
  ///
  /// In en, this message translates to:
  /// **'Get support from a person'**
  String get activeCravingRescuePersonSupportButton;

  /// lib/screens/active_craving_rescue_screen.dart: Privacy note: no data is sent or shared during the exercise (two lines)
  ///
  /// In en, this message translates to:
  /// **'No data is being sent or shared during this exercise.\nContent v1.0'**
  String get activeCravingRescuePrivacyNote;

  /// lib/screens/active_craving_rescue_screen.dart: Label of the progress bar: the active tool
  ///
  /// In en, this message translates to:
  /// **'ACTIVE TOOL'**
  String get activeCravingRescueProgressLabel;

  /// lib/screens/active_craving_rescue_screen.dart: Note: after 2 minutes the member rates the craving again
  ///
  /// In en, this message translates to:
  /// **'After 2 minutes, you’ll rate the craving again'**
  String get activeCravingRescueRecheckNote;

  /// lib/screens/active_craving_rescue_screen.dart: Note: reduced motion follows the phone setting
  ///
  /// In en, this message translates to:
  /// **'Reduced motion follows your phone setting'**
  String get activeCravingRescueReducedMotionNote;

  /// lib/screens/active_craving_rescue_screen.dart: Button that resumes the paused exercise
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get activeCravingRescueResumeButton;

  /// lib/screens/active_craving_rescue_screen.dart: Spoken aloud: breathe in slowly
  ///
  /// In en, this message translates to:
  /// **'Breathe in slowly'**
  String get activeCravingRescueSpokenBreatheIn;

  /// lib/screens/active_craving_rescue_screen.dart: Spoken aloud: breathe out slowly
  ///
  /// In en, this message translates to:
  /// **'Breathe out slowly'**
  String get activeCravingRescueSpokenBreatheOut;

  /// lib/screens/active_craving_rescue_screen.dart: Spoken aloud every 30 seconds during movement
  ///
  /// In en, this message translates to:
  /// **'Keep moving'**
  String get activeCravingRescueSpokenKeepMoving;

  /// lib/screens/active_craving_rescue_screen.dart: Spoken aloud when the three-minute movement is complete
  ///
  /// In en, this message translates to:
  /// **'Great job. You completed three minutes.'**
  String get activeCravingRescueSpokenMovementDone;

  /// lib/screens/active_craving_rescue_screen.dart: Spoken aloud at the start of the movement exercise
  ///
  /// In en, this message translates to:
  /// **'Start moving'**
  String get activeCravingRescueSpokenMovementStart;

  /// lib/screens/active_craving_rescue_screen.dart: Spoken aloud: one minute left
  ///
  /// In en, this message translates to:
  /// **'One minute left'**
  String get activeCravingRescueSpokenOneMinuteLeft;

  /// lib/screens/active_craving_rescue_screen.dart: Spoken aloud when the change of scene is complete
  ///
  /// In en, this message translates to:
  /// **'Great job. You changed your surroundings.'**
  String get activeCravingRescueSpokenSceneDone;

  /// lib/screens/active_craving_rescue_screen.dart: Spoken aloud near the end of changing the scene
  ///
  /// In en, this message translates to:
  /// **'Keep going. You are making a positive change.'**
  String get activeCravingRescueSpokenSceneEncouragement;

  /// lib/screens/active_craving_rescue_screen.dart: Spoken aloud halfway through changing the scene
  ///
  /// In en, this message translates to:
  /// **'You are halfway there. Keep going.'**
  String get activeCravingRescueSpokenSceneHalfway;

  /// lib/screens/active_craving_rescue_screen.dart: Spoken aloud while changing the scene
  ///
  /// In en, this message translates to:
  /// **'Keep moving to a smoke-free place.'**
  String get activeCravingRescueSpokenSceneKeepGoing;

  /// lib/screens/active_craving_rescue_screen.dart: Spoken aloud: ten seconds left
  ///
  /// In en, this message translates to:
  /// **'Ten seconds left'**
  String get activeCravingRescueSpokenTenSecondsLeft;

  /// lib/screens/active_craving_rescue_screen.dart: Spoken aloud: thirty seconds left
  ///
  /// In en, this message translates to:
  /// **'Thirty seconds left'**
  String get activeCravingRescueSpokenThirtySecondsLeft;

  /// lib/screens/active_craving_rescue_screen.dart: Step counter in the header: step 3 of 5 of the rescue
  ///
  /// In en, this message translates to:
  /// **'3 OF 5'**
  String get activeCravingRescueStepCounter;

  /// lib/screens/active_craving_rescue_screen.dart: Button that switches to another coping tool
  ///
  /// In en, this message translates to:
  /// **'Switch coping tool'**
  String get activeCravingRescueSwitchToolButton;

  /// lib/screens/active_craving_rescue_screen.dart: Progress-bar caption while breathing in
  ///
  /// In en, this message translates to:
  /// **'Inhale gently'**
  String get activeCravingRescueThisBreathIn;

  /// lib/screens/active_craving_rescue_screen.dart: Label of the progress bar for the current breath
  ///
  /// In en, this message translates to:
  /// **'THIS BREATH'**
  String get activeCravingRescueThisBreathLabel;

  /// lib/screens/active_craving_rescue_screen.dart: Progress-bar caption while breathing out
  ///
  /// In en, this message translates to:
  /// **'Exhale slowly'**
  String get activeCravingRescueThisBreathOut;

  /// lib/screens/active_craving_rescue_screen.dart: Time left on the movement and change-the-scene cards ({time} is minutes:seconds)
  ///
  /// In en, this message translates to:
  /// **'{time} LEFT'**
  String activeCravingRescueTimeLeft(Object time);

  /// lib/screens/active_craving_rescue_screen.dart: Screen title: stay with this moment
  ///
  /// In en, this message translates to:
  /// **'Stay with this moment.'**
  String get activeCravingRescueTitle;

  /// lib/screens/active_craving_rescue_screen.dart: Voice control button: the word Voice and, on a second line, its state ({state} is on or off)
  ///
  /// In en, this message translates to:
  /// **'Voice\n{state}'**
  String activeCravingRescueVoiceControl(Object state);

  /// lib/screens/baseline_assessment_screen.dart: Tooltip and accessibility label of the header back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get baselineAssessmentBackTooltip;

  /// lib/screens/baseline_assessment_screen.dart: Answer choice: 11 to 20 cigarettes a day
  ///
  /// In en, this message translates to:
  /// **'11–20 cigarettes'**
  String get baselineAssessmentChoiceElevenToTwenty;

  /// lib/screens/baseline_assessment_screen.dart: Answer choice: does not smoke every day
  ///
  /// In en, this message translates to:
  /// **'I don’t smoke every day'**
  String get baselineAssessmentChoiceNotEveryDay;

  /// lib/screens/baseline_assessment_screen.dart: Badge on the chosen answer
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get baselineAssessmentChoiceSelectedBadge;

  /// lib/screens/baseline_assessment_screen.dart: Answer choice: 10 or fewer cigarettes a day
  ///
  /// In en, this message translates to:
  /// **'10 or fewer cigarettes'**
  String get baselineAssessmentChoiceTenOrFewer;

  /// lib/screens/baseline_assessment_screen.dart: Answer choice: 31 or more cigarettes a day
  ///
  /// In en, this message translates to:
  /// **'31 or more cigarettes'**
  String get baselineAssessmentChoiceThirtyOneOrMore;

  /// lib/screens/baseline_assessment_screen.dart: Answer choice: 21 to 30 cigarettes a day
  ///
  /// In en, this message translates to:
  /// **'21–30 cigarettes'**
  String get baselineAssessmentChoiceTwentyOneToThirty;

  /// lib/screens/baseline_assessment_screen.dart: Header title of the screen
  ///
  /// In en, this message translates to:
  /// **'About your smoking'**
  String get baselineAssessmentHeaderTitle;

  /// lib/screens/baseline_assessment_screen.dart: Button that goes to the next question
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get baselineAssessmentNextButton;

  /// lib/screens/baseline_assessment_screen.dart: Label of the progress bar: the assessment section
  ///
  /// In en, this message translates to:
  /// **'ASSESSMENT'**
  String get baselineAssessmentProgressLabel;

  /// lib/screens/baseline_assessment_screen.dart: The question: how many cigarettes the member smokes on a typical day
  ///
  /// In en, this message translates to:
  /// **'On a typical day, how many cigarettes do you smoke?'**
  String get baselineAssessmentQuestion;

  /// lib/screens/baseline_assessment_screen.dart: Help text under the question
  ///
  /// In en, this message translates to:
  /// **'Choose the answer closest to your usual day.'**
  String get baselineAssessmentQuestionHint;

  /// lib/screens/baseline_assessment_screen.dart: Small label above the question: which question of the assessment this is
  ///
  /// In en, this message translates to:
  /// **'QUESTION 1'**
  String get baselineAssessmentQuestionLabel;

  /// lib/screens/baseline_assessment_screen.dart: Note under the button: the answer is saved automatically
  ///
  /// In en, this message translates to:
  /// **'Your answer is saved automatically.'**
  String get baselineAssessmentSavedNote;

  /// lib/screens/baseline_assessment_screen.dart: Card text: what the answer is used for
  ///
  /// In en, this message translates to:
  /// **'This helps tailor your plan and estimate money saved.'**
  String get baselineAssessmentWhyWeAskBody;

  /// lib/screens/baseline_assessment_screen.dart: Card text: the answer is not a diagnosis or a judgment
  ///
  /// In en, this message translates to:
  /// **'It is not a diagnosis or a judgment.'**
  String get baselineAssessmentWhyWeAskNote;

  /// lib/screens/baseline_assessment_screen.dart: Title of the card that explains why the question is asked
  ///
  /// In en, this message translates to:
  /// **'Why we ask'**
  String get baselineAssessmentWhyWeAskTitle;

  /// lib/screens/choose_quit_path_screen.dart: Tooltip and accessibility label of the header back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get chooseQuitPathBackTooltip;

  /// lib/screens/choose_quit_path_screen.dart: Button that confirms the chosen path
  ///
  /// In en, this message translates to:
  /// **'Continue with this path'**
  String get chooseQuitPathContinueButton;

  /// lib/screens/choose_quit_path_screen.dart: Small label above the screen title
  ///
  /// In en, this message translates to:
  /// **'CHOOSE YOUR PATH'**
  String get chooseQuitPathEyebrow;

  /// lib/screens/choose_quit_path_screen.dart: Reassurance note: the path can be changed later
  ///
  /// In en, this message translates to:
  /// **'Your path is flexible. You can adjust it at any time.'**
  String get chooseQuitPathFlexibleNote;

  /// lib/screens/choose_quit_path_screen.dart: Header title of the screen
  ///
  /// In en, this message translates to:
  /// **'Build your plan'**
  String get chooseQuitPathHeaderTitle;

  /// lib/screens/choose_quit_path_screen.dart: Text under the title
  ///
  /// In en, this message translates to:
  /// **'There is no wrong place to start. Choose what fits you.'**
  String get chooseQuitPathIntro;

  /// lib/screens/choose_quit_path_screen.dart: Name of the path option: quit today
  ///
  /// In en, this message translates to:
  /// **'Quit today'**
  String get chooseQuitPathOptionQuitToday;

  /// lib/screens/choose_quit_path_screen.dart: Description of the quit-today option
  ///
  /// In en, this message translates to:
  /// **'Begin your smoke-free time now and get extra support through the first day.'**
  String get chooseQuitPathOptionQuitTodayDescription;

  /// lib/screens/choose_quit_path_screen.dart: Name of the path option: reduce gradually
  ///
  /// In en, this message translates to:
  /// **'Reduce gradually'**
  String get chooseQuitPathOptionReduceGradually;

  /// lib/screens/choose_quit_path_screen.dart: Description of the reduce-gradually option
  ///
  /// In en, this message translates to:
  /// **'Follow a step-down schedule and work toward stopping completely on a future date.'**
  String get chooseQuitPathOptionReduceGraduallyDescription;

  /// lib/screens/choose_quit_path_screen.dart: Name of the path option: set a quit date
  ///
  /// In en, this message translates to:
  /// **'Set a quit date'**
  String get chooseQuitPathOptionSetQuitDate;

  /// lib/screens/choose_quit_path_screen.dart: Description of the set-a-quit-date option
  ///
  /// In en, this message translates to:
  /// **'Prepare for 7–14 days, then stop completely on the date you choose. We’ll guide one small step each day.'**
  String get chooseQuitPathOptionSetQuitDateDescription;

  /// lib/screens/choose_quit_path_screen.dart: Line under the set-a-quit-date option: it matches the member’s earlier answer
  ///
  /// In en, this message translates to:
  /// **'Matches your preparation preference'**
  String get chooseQuitPathOptionSetQuitDateMatch;

  /// lib/screens/choose_quit_path_screen.dart: Label of the progress bar: the quit plan section
  ///
  /// In en, this message translates to:
  /// **'QUIT PLAN'**
  String get chooseQuitPathProgressLabel;

  /// lib/screens/choose_quit_path_screen.dart: Badge on the recommended option
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get chooseQuitPathRecommendedBadge;

  /// lib/screens/choose_quit_path_screen.dart: Status line: which path is selected ({path} is the path name) and that it is saved
  ///
  /// In en, this message translates to:
  /// **'{path} selected · Saved automatically'**
  String chooseQuitPathSavedStatus(Object path);

  /// lib/screens/choose_quit_path_screen.dart: Step counter in the header: step 1 of 5 of the quit plan
  ///
  /// In en, this message translates to:
  /// **'1 OF 5'**
  String get chooseQuitPathStepCounter;

  /// lib/screens/choose_quit_path_screen.dart: Screen title: the question of which path feels possible
  ///
  /// In en, this message translates to:
  /// **'What feels possible right now?'**
  String get chooseQuitPathTitle;

  /// lib/screens/consent_privacy_screen.dart: Button that agrees and continues
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get consentPrivacyAgreeButton;

  /// lib/screens/consent_privacy_screen.dart: Tooltip and accessibility label of the header back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get consentPrivacyBackTooltip;

  /// lib/screens/consent_privacy_screen.dart: Note under the button: optional choices can be changed in Settings
  ///
  /// In en, this message translates to:
  /// **'You can change optional choices anytime in Settings.'**
  String get consentPrivacyChangeLaterNote;

  /// lib/screens/consent_privacy_screen.dart: What essential app data is used for
  ///
  /// In en, this message translates to:
  /// **'Save your account, quit plan, and progress securely.'**
  String get consentPrivacyEssentialDataDescription;

  /// lib/screens/consent_privacy_screen.dart: Required item: essential app data
  ///
  /// In en, this message translates to:
  /// **'Essential app data'**
  String get consentPrivacyEssentialDataTitle;

  /// lib/screens/consent_privacy_screen.dart: Small label above the screen title
  ///
  /// In en, this message translates to:
  /// **'YOUR PRIVACY'**
  String get consentPrivacyEyebrow;

  /// lib/screens/consent_privacy_screen.dart: What health information is used for
  ///
  /// In en, this message translates to:
  /// **'Personalize your plan, support tools, and recovery insights.'**
  String get consentPrivacyHealthInformationDescription;

  /// lib/screens/consent_privacy_screen.dart: Required item: health information
  ///
  /// In en, this message translates to:
  /// **'Health information'**
  String get consentPrivacyHealthInformationTitle;

  /// lib/screens/consent_privacy_screen.dart: What helping improve BreatheFree shares
  ///
  /// In en, this message translates to:
  /// **'Contribute de-identified information to approved research.'**
  String get consentPrivacyHelpImproveDescription;

  /// lib/screens/consent_privacy_screen.dart: Optional switch: help improve BreatheFree
  ///
  /// In en, this message translates to:
  /// **'Help improve BreatheFree'**
  String get consentPrivacyHelpImproveTitle;

  /// lib/screens/consent_privacy_screen.dart: Text under the title: required and optional items
  ///
  /// In en, this message translates to:
  /// **'Choose how your information is used. Required items keep the app working; optional choices can change anytime.'**
  String get consentPrivacyIntro;

  /// lib/screens/consent_privacy_screen.dart: Badge on the optional card
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get consentPrivacyOptionalBadge;

  /// lib/screens/consent_privacy_screen.dart: Title of the card with the optional choices
  ///
  /// In en, this message translates to:
  /// **'YOUR CHOICES'**
  String get consentPrivacyOptionalSectionTitle;

  /// lib/screens/consent_privacy_screen.dart: What the reminders switch turns on
  ///
  /// In en, this message translates to:
  /// **'Receive private check-ins and plan reminders.'**
  String get consentPrivacyRemindersDescription;

  /// lib/screens/consent_privacy_screen.dart: Optional switch: helpful reminders
  ///
  /// In en, this message translates to:
  /// **'Helpful reminders'**
  String get consentPrivacyRemindersTitle;

  /// lib/screens/consent_privacy_screen.dart: Badge on the required card
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get consentPrivacyRequiredBadge;

  /// lib/screens/consent_privacy_screen.dart: Title of the card that lists what is required to use the app
  ///
  /// In en, this message translates to:
  /// **'REQUIRED TO USE BREATHEFREE'**
  String get consentPrivacyRequiredSectionTitle;

  /// lib/screens/consent_privacy_screen.dart: Link that opens the Terms and Privacy Notice
  ///
  /// In en, this message translates to:
  /// **'Review Terms and Privacy Notice'**
  String get consentPrivacyReviewTermsLink;

  /// lib/screens/consent_privacy_screen.dart: What sharing with the care team allows
  ///
  /// In en, this message translates to:
  /// **'Allow a connected clinician to view progress summaries.'**
  String get consentPrivacyShareCareTeamDescription;

  /// lib/screens/consent_privacy_screen.dart: Optional switch: share with the member’s care team
  ///
  /// In en, this message translates to:
  /// **'Share with my care team'**
  String get consentPrivacyShareCareTeamTitle;

  /// lib/screens/consent_privacy_screen.dart: Sheet text: how the legal documents will be shown (development build)
  ///
  /// In en, this message translates to:
  /// **'This development build demonstrates how the legal documents will be presented. Before release, the complete Terms of Use and Privacy Notice will appear here, including data practices, retention periods, and your rights.'**
  String get consentPrivacyTermsSheetBody;

  /// lib/screens/consent_privacy_screen.dart: Button that closes the sheet
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get consentPrivacyTermsSheetDoneButton;

  /// lib/screens/consent_privacy_screen.dart: Sheet text: optional and required processing
  ///
  /// In en, this message translates to:
  /// **'Optional controls can be changed later in Settings. Required processing will be limited to what is necessary to provide and secure the service.'**
  String get consentPrivacyTermsSheetNote;

  /// lib/screens/consent_privacy_screen.dart: Title of the sheet about the Terms and Privacy Notice
  ///
  /// In en, this message translates to:
  /// **'Terms and Privacy Notice'**
  String get consentPrivacyTermsSheetTitle;

  /// lib/screens/consent_privacy_screen.dart: Screen title
  ///
  /// In en, this message translates to:
  /// **'Your story stays yours.'**
  String get consentPrivacyTitle;

  /// lib/screens/consent_privacy_screen.dart: Trust note: no ads and no tobacco-industry funding
  ///
  /// In en, this message translates to:
  /// **'No ads. No tobacco-industry funding.'**
  String get consentPrivacyTrustNoteFunding;

  /// lib/screens/consent_privacy_screen.dart: Trust note: health information is never sold
  ///
  /// In en, this message translates to:
  /// **'We never sell patient health information.'**
  String get consentPrivacyTrustNoteNoSale;

  /// lib/screens/craving_rescue_start_screen.dart: Tooltip and accessibility label of the header back button
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get cravingRescueStartBackTooltip;

  /// lib/screens/craving_rescue_start_screen.dart: Message when the phone app could not be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open the Phone app.'**
  String get cravingRescueStartCallFailed;

  /// lib/screens/craving_rescue_start_screen.dart: Context option: after a meal
  ///
  /// In en, this message translates to:
  /// **'After a meal'**
  String get cravingRescueStartContextAfterMeal;

  /// lib/screens/craving_rescue_start_screen.dart: Context option: alcohol
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get cravingRescueStartContextAlcohol;

  /// lib/screens/craving_rescue_start_screen.dart: Context option: around someone smoking
  ///
  /// In en, this message translates to:
  /// **'Around someone smoking'**
  String get cravingRescueStartContextAroundSmoking;

  /// lib/screens/craving_rescue_start_screen.dart: Context option: bored
  ///
  /// In en, this message translates to:
  /// **'Bored'**
  String get cravingRescueStartContextBored;

  /// lib/screens/craving_rescue_start_screen.dart: Context option: driving
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get cravingRescueStartContextDriving;

  /// lib/screens/craving_rescue_start_screen.dart: Context option: not sure
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get cravingRescueStartContextNotSure;

  /// lib/screens/craving_rescue_start_screen.dart: Note: trigger details are optional
  ///
  /// In en, this message translates to:
  /// **'Trigger details are optional and never block Rescue.'**
  String get cravingRescueStartContextNote;

  /// lib/screens/craving_rescue_start_screen.dart: Note next to the question: optional
  ///
  /// In en, this message translates to:
  /// **'Optional · Skip anytime'**
  String get cravingRescueStartContextOptional;

  /// lib/screens/craving_rescue_start_screen.dart: Question: what might be behind the craving
  ///
  /// In en, this message translates to:
  /// **'What might be behind it?'**
  String get cravingRescueStartContextQuestion;

  /// lib/screens/craving_rescue_start_screen.dart: Context option: stress
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get cravingRescueStartContextStress;

  /// lib/screens/craving_rescue_start_screen.dart: Main button that shows what to do
  ///
  /// In en, this message translates to:
  /// **'Show me what to do'**
  String get cravingRescueStartContinueButton;

  /// lib/screens/craving_rescue_start_screen.dart: Button that calls emergency services (911)
  ///
  /// In en, this message translates to:
  /// **'Call 911'**
  String get cravingRescueStartEmergencyCallButton;

  /// lib/screens/craving_rescue_start_screen.dart: Button that closes the emergency sheet
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get cravingRescueStartEmergencyCloseButton;

  /// lib/screens/craving_rescue_start_screen.dart: Link that opens emergency guidance
  ///
  /// In en, this message translates to:
  /// **'Medical emergency?'**
  String get cravingRescueStartEmergencyLink;

  /// lib/screens/craving_rescue_start_screen.dart: Sheet text: what to do in an emergency
  ///
  /// In en, this message translates to:
  /// **'If this is a medical emergency or you are in immediate danger, call 911 now.'**
  String get cravingRescueStartEmergencySheetBody;

  /// lib/screens/craving_rescue_start_screen.dart: Sheet text: a call starts only when the member taps the call button
  ///
  /// In en, this message translates to:
  /// **'BreatheFree will only start a call when you tap “Call 911.”'**
  String get cravingRescueStartEmergencySheetNote;

  /// lib/screens/craving_rescue_start_screen.dart: Title of the emergency guidance sheet
  ///
  /// In en, this message translates to:
  /// **'Medical emergency'**
  String get cravingRescueStartEmergencySheetTitle;

  /// lib/screens/craving_rescue_start_screen.dart: Small label above the title
  ///
  /// In en, this message translates to:
  /// **'RIGHT NOW'**
  String get cravingRescueStartEyebrow;

  /// lib/screens/craving_rescue_start_screen.dart: Header title: craving rescue
  ///
  /// In en, this message translates to:
  /// **'Craving Rescue'**
  String get cravingRescueStartHeaderTitle;

  /// lib/screens/craving_rescue_start_screen.dart: Hint: only a number is needed
  ///
  /// In en, this message translates to:
  /// **'You only need to choose a number.'**
  String get cravingRescueStartIntensityHint;

  /// lib/screens/craving_rescue_start_screen.dart: Label at the strongest end of the scale
  ///
  /// In en, this message translates to:
  /// **'Strongest'**
  String get cravingRescueStartIntensityMaxLabel;

  /// lib/screens/craving_rescue_start_screen.dart: Intensity word for a rating of 0 to 3
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get cravingRescueStartIntensityMild;

  /// lib/screens/craving_rescue_start_screen.dart: Intensity word for a rating of 4 to 6
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get cravingRescueStartIntensityModerate;

  /// lib/screens/craving_rescue_start_screen.dart: Note: the next screen gives one recommended action
  ///
  /// In en, this message translates to:
  /// **'The next screen gives one recommended action.'**
  String get cravingRescueStartIntensityNext;

  /// lib/screens/craving_rescue_start_screen.dart: Question on the intensity card
  ///
  /// In en, this message translates to:
  /// **'How strong is it right now?'**
  String get cravingRescueStartIntensityQuestion;

  /// lib/screens/craving_rescue_start_screen.dart: Intensity word for a rating of 7 or 8
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get cravingRescueStartIntensityStrong;

  /// lib/screens/craving_rescue_start_screen.dart: Title of the craving-intensity card
  ///
  /// In en, this message translates to:
  /// **'CRAVING INTENSITY'**
  String get cravingRescueStartIntensityTitle;

  /// lib/screens/craving_rescue_start_screen.dart: Intensity word for a rating of 9 or 10
  ///
  /// In en, this message translates to:
  /// **'Very strong'**
  String get cravingRescueStartIntensityVeryStrong;

  /// lib/screens/craving_rescue_start_screen.dart: Text under the title
  ///
  /// In en, this message translates to:
  /// **'Start with what you feel now. No typing is required.'**
  String get cravingRescueStartIntro;

  /// lib/screens/craving_rescue_start_screen.dart: Badge in the header: works offline
  ///
  /// In en, this message translates to:
  /// **'OFFLINE READY'**
  String get cravingRescueStartOfflineBadge;

  /// lib/screens/craving_rescue_start_screen.dart: Privacy note, first line: used to personalize support, never to monitor
  ///
  /// In en, this message translates to:
  /// **'Used to personalize support — never to monitor you.\n'**
  String get cravingRescueStartPrivacyNoteBody;

  /// lib/screens/craving_rescue_start_screen.dart: Privacy note, second line: no location or conversation tracking
  ///
  /// In en, this message translates to:
  /// **'No background location or conversation tracking.'**
  String get cravingRescueStartPrivacyNoteTracking;

  /// lib/screens/craving_rescue_start_screen.dart: Note: private and works offline
  ///
  /// In en, this message translates to:
  /// **'Private · Works offline'**
  String get cravingRescueStartPrivateOffline;

  /// lib/screens/craving_rescue_start_screen.dart: Card text: contact the support person ({supportName}) or a quitline counselor
  ///
  /// In en, this message translates to:
  /// **'Contact {supportName} or a trained quitline counselor.'**
  String cravingRescueStartSupportBody(Object supportName);

  /// lib/screens/craving_rescue_start_screen.dart: Button that opens support
  ///
  /// In en, this message translates to:
  /// **'View support'**
  String get cravingRescueStartSupportButton;

  /// lib/screens/craving_rescue_start_screen.dart: Note: messages and calls only happen when the member chooses
  ///
  /// In en, this message translates to:
  /// **'Messages and calls only happen when you choose them.'**
  String get cravingRescueStartSupportNote;

  /// lib/screens/craving_rescue_start_screen.dart: Title of the card offering a person instead
  ///
  /// In en, this message translates to:
  /// **'Want a person instead?'**
  String get cravingRescueStartSupportTitle;

  /// lib/screens/craving_rescue_start_screen.dart: Screen title
  ///
  /// In en, this message translates to:
  /// **'Let’s get through this moment.'**
  String get cravingRescueStartTitle;

  /// lib/screens/craving_rescue_start_screen.dart: Label of the card showing the member’s top reason
  ///
  /// In en, this message translates to:
  /// **'YOUR TOP REASON'**
  String get cravingRescueStartTopReasonLabel;

  /// lib/screens/craving_rescue_start_screen.dart: Card text: this moment can pass
  ///
  /// In en, this message translates to:
  /// **'This moment can pass without changing your goal.'**
  String get cravingRescueStartTopReasonNote;

  /// lib/screens/guided_stress_reset_screen.dart: Breath counter: breath number ({number}) of 10
  ///
  /// In en, this message translates to:
  /// **'Breath {number} of 10'**
  String guidedStressResetBreathCount(Object number);

  /// lib/screens/guided_stress_reset_screen.dart: Small label above the instruction in the breathing step
  ///
  /// In en, this message translates to:
  /// **'SLOW BREATHING'**
  String get guidedStressResetBreatheEyebrow;

  /// lib/screens/guided_stress_reset_screen.dart: Instruction while breathing in; also spoken aloud
  ///
  /// In en, this message translates to:
  /// **'Slowly breathe in through your nose.'**
  String get guidedStressResetBreatheInInstruction;

  /// lib/screens/guided_stress_reset_screen.dart: Instruction while breathing out; also spoken aloud
  ///
  /// In en, this message translates to:
  /// **'Slowly breathe out through your mouth.'**
  String get guidedStressResetBreatheOutInstruction;

  /// lib/screens/guided_stress_reset_screen.dart: Label in the exercise circle while breathing in
  ///
  /// In en, this message translates to:
  /// **'BREATHE IN'**
  String get guidedStressResetCircleBreatheIn;

  /// lib/screens/guided_stress_reset_screen.dart: Label in the exercise circle while breathing out
  ///
  /// In en, this message translates to:
  /// **'BREATHE OUT'**
  String get guidedStressResetCircleBreatheOut;

  /// lib/screens/guided_stress_reset_screen.dart: Label in the exercise circle during the water step
  ///
  /// In en, this message translates to:
  /// **'DRINK WATER'**
  String get guidedStressResetCircleDrinkWater;

  /// lib/screens/guided_stress_reset_screen.dart: Unit under the seconds countdown in the circle
  ///
  /// In en, this message translates to:
  /// **'SECONDS'**
  String get guidedStressResetCircleSecondsUnit;

  /// lib/screens/guided_stress_reset_screen.dart: Tooltip and accessibility label of the header close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get guidedStressResetCloseTooltip;

  /// lib/screens/guided_stress_reset_screen.dart: Button that ends the exercise
  ///
  /// In en, this message translates to:
  /// **'End exercise'**
  String get guidedStressResetEndButton;

  /// lib/screens/guided_stress_reset_screen.dart: Dialog text: time and finished steps are saved
  ///
  /// In en, this message translates to:
  /// **'Your time and completed steps will still be saved.'**
  String get guidedStressResetEndDialogBody;

  /// lib/screens/guided_stress_reset_screen.dart: Dialog button that keeps practicing
  ///
  /// In en, this message translates to:
  /// **'Keep practicing'**
  String get guidedStressResetEndDialogCancel;

  /// lib/screens/guided_stress_reset_screen.dart: Dialog button that ends the exercise and goes to the review
  ///
  /// In en, this message translates to:
  /// **'End and review'**
  String get guidedStressResetEndDialogConfirm;

  /// lib/screens/guided_stress_reset_screen.dart: Title of the dialog that asks whether to end the exercise
  ///
  /// In en, this message translates to:
  /// **'End the exercise now?'**
  String get guidedStressResetEndDialogTitle;

  /// lib/screens/guided_stress_reset_screen.dart: Button on the last step that finishes the exercise
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get guidedStressResetFinishButton;

  /// lib/screens/guided_stress_reset_screen.dart: Hint: follow the circle, listen or use the countdown
  ///
  /// In en, this message translates to:
  /// **'Follow the circle, listen, or use the countdown.'**
  String get guidedStressResetFollowHint;

  /// lib/screens/guided_stress_reset_screen.dart: Motion control when full motion is on
  ///
  /// In en, this message translates to:
  /// **'Full motion on'**
  String get guidedStressResetFullMotionOn;

  /// lib/screens/guided_stress_reset_screen.dart: Header title: stress reset
  ///
  /// In en, this message translates to:
  /// **'Stress reset'**
  String get guidedStressResetHeaderTitle;

  /// lib/screens/guided_stress_reset_screen.dart: Dialog text: partial progress is saved
  ///
  /// In en, this message translates to:
  /// **'Your partial progress will be saved so you can continue later.'**
  String get guidedStressResetLeaveDialogBody;

  /// lib/screens/guided_stress_reset_screen.dart: Dialog button that saves and leaves
  ///
  /// In en, this message translates to:
  /// **'Save and leave'**
  String get guidedStressResetLeaveDialogLeave;

  /// lib/screens/guided_stress_reset_screen.dart: Dialog button that continues the exercise
  ///
  /// In en, this message translates to:
  /// **'Continue exercise'**
  String get guidedStressResetLeaveDialogStay;

  /// lib/screens/guided_stress_reset_screen.dart: Title of the dialog that asks whether to leave the exercise
  ///
  /// In en, this message translates to:
  /// **'Leave the exercise?'**
  String get guidedStressResetLeaveDialogTitle;

  /// lib/screens/guided_stress_reset_screen.dart: Button that pauses the exercise
  ///
  /// In en, this message translates to:
  /// **'Pause exercise'**
  String get guidedStressResetPauseButton;

  /// lib/screens/guided_stress_reset_screen.dart: Motion control when reduced motion is on
  ///
  /// In en, this message translates to:
  /// **'Reduced motion on'**
  String get guidedStressResetReducedMotionOn;

  /// lib/screens/guided_stress_reset_screen.dart: Button that opens craving rescue
  ///
  /// In en, this message translates to:
  /// **'Open Rescue'**
  String get guidedStressResetRescueButton;

  /// lib/screens/guided_stress_reset_screen.dart: Card question: is the craving getting stronger
  ///
  /// In en, this message translates to:
  /// **'Craving getting stronger?'**
  String get guidedStressResetRescueTitle;

  /// lib/screens/guided_stress_reset_screen.dart: Button that resumes the paused exercise
  ///
  /// In en, this message translates to:
  /// **'Resume exercise'**
  String get guidedStressResetResumeButton;

  /// lib/screens/guided_stress_reset_screen.dart: Note: partial completion is saved and the exercise works offline
  ///
  /// In en, this message translates to:
  /// **'Partial completion is saved · Works offline'**
  String get guidedStressResetSavedNote;

  /// lib/screens/guided_stress_reset_screen.dart: Step in the exercise sequence: breathe
  ///
  /// In en, this message translates to:
  /// **'Breathe'**
  String get guidedStressResetSequenceBreathe;

  /// lib/screens/guided_stress_reset_screen.dart: Status of a finished step in the sequence
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get guidedStressResetSequenceDone;

  /// lib/screens/guided_stress_reset_screen.dart: Status of a coming step in the sequence
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get guidedStressResetSequenceNext;

  /// lib/screens/guided_stress_reset_screen.dart: Note: the timer pauses when the member leaves the screen
  ///
  /// In en, this message translates to:
  /// **'The timer pauses automatically if you leave this screen.'**
  String get guidedStressResetSequenceNote;

  /// lib/screens/guided_stress_reset_screen.dart: Status of the current step in the sequence
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get guidedStressResetSequenceNow;

  /// lib/screens/guided_stress_reset_screen.dart: Step in the exercise sequence: switch activities
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get guidedStressResetSequenceSwitch;

  /// lib/screens/guided_stress_reset_screen.dart: Title of the exercise sequence list
  ///
  /// In en, this message translates to:
  /// **'Exercise sequence'**
  String get guidedStressResetSequenceTitle;

  /// lib/screens/guided_stress_reset_screen.dart: Step in the exercise sequence: water
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get guidedStressResetSequenceWater;

  /// lib/screens/guided_stress_reset_screen.dart: Button that skips to the next step
  ///
  /// In en, this message translates to:
  /// **'Skip step'**
  String get guidedStressResetSkipButton;

  /// lib/screens/guided_stress_reset_screen.dart: Spoken aloud in the switch-activities step
  ///
  /// In en, this message translates to:
  /// **'Switch what you are doing. Walk, play music, or start one quick task.'**
  String get guidedStressResetSpokenSwitch;

  /// lib/screens/guided_stress_reset_screen.dart: Step counter: step number ({step}) of 3 and the step name ({name})
  ///
  /// In en, this message translates to:
  /// **'STEP {step} OF 3 · {name}'**
  String guidedStressResetStepCounter(Object step, Object name);

  /// lib/screens/guided_stress_reset_screen.dart: Step name in the step counter (upper case): breathe
  ///
  /// In en, this message translates to:
  /// **'BREATHE'**
  String get guidedStressResetStepNameBreathe;

  /// lib/screens/guided_stress_reset_screen.dart: Step name in the step counter (upper case): switch activities
  ///
  /// In en, this message translates to:
  /// **'SWITCH'**
  String get guidedStressResetStepNameSwitch;

  /// lib/screens/guided_stress_reset_screen.dart: Step name in the step counter (upper case): water
  ///
  /// In en, this message translates to:
  /// **'WATER'**
  String get guidedStressResetStepNameWater;

  /// lib/screens/guided_stress_reset_screen.dart: Small label above the instruction in the switch-activities step
  ///
  /// In en, this message translates to:
  /// **'SWITCH ACTIVITIES'**
  String get guidedStressResetSwitchEyebrow;

  /// lib/screens/guided_stress_reset_screen.dart: Instruction in the switch-activities step
  ///
  /// In en, this message translates to:
  /// **'Walk, play music, or start one quick task.'**
  String get guidedStressResetSwitchInstruction;

  /// lib/screens/guided_stress_reset_screen.dart: Title of the switch-activities step
  ///
  /// In en, this message translates to:
  /// **'Switch what you are doing'**
  String get guidedStressResetSwitchTitle;

  /// lib/screens/guided_stress_reset_screen.dart: Time left in the step ({time} is minutes:seconds)
  ///
  /// In en, this message translates to:
  /// **'{time} LEFT'**
  String guidedStressResetTimeLeft(Object time);

  /// lib/screens/guided_stress_reset_screen.dart: Voice guidance control when it is off
  ///
  /// In en, this message translates to:
  /// **'Voice guidance off'**
  String get guidedStressResetVoiceGuidanceOff;

  /// lib/screens/guided_stress_reset_screen.dart: Voice guidance control when it is on
  ///
  /// In en, this message translates to:
  /// **'Voice guidance on'**
  String get guidedStressResetVoiceGuidanceOn;

  /// lib/screens/guided_stress_reset_screen.dart: Accessibility label of the voice guidance toggle in the header
  ///
  /// In en, this message translates to:
  /// **'Voice guidance'**
  String get guidedStressResetVoiceToggleLabel;

  /// lib/screens/guided_stress_reset_screen.dart: Voice toggle in the header when voice guidance is off
  ///
  /// In en, this message translates to:
  /// **'VOICE OFF'**
  String get guidedStressResetVoiceToggleOff;

  /// lib/screens/guided_stress_reset_screen.dart: Voice toggle in the header when voice guidance is on
  ///
  /// In en, this message translates to:
  /// **'VOICE ON'**
  String get guidedStressResetVoiceToggleOn;

  /// lib/screens/guided_stress_reset_screen.dart: Small label above the instruction in the water step
  ///
  /// In en, this message translates to:
  /// **'WATER BREAK'**
  String get guidedStressResetWaterEyebrow;

  /// lib/screens/guided_stress_reset_screen.dart: Instruction in the water step; also spoken aloud
  ///
  /// In en, this message translates to:
  /// **'Sip slowly and notice the temperature.'**
  String get guidedStressResetWaterInstruction;

  /// lib/screens/guided_stress_reset_screen.dart: Title of the water step
  ///
  /// In en, this message translates to:
  /// **'Drink a glass of water'**
  String get guidedStressResetWaterTitle;

  /// lib/screens/my_reasons_screen.dart: Tooltip and accessibility label of the header back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get myReasonsBackTooltip;

  /// lib/screens/my_reasons_screen.dart: Label of the own-reason card before the member writes one
  ///
  /// In en, this message translates to:
  /// **'ADD YOUR OWN REASON'**
  String get myReasonsCustomCardLabelEmpty;

  /// lib/screens/my_reasons_screen.dart: Label of the own-reason card once the member has written one
  ///
  /// In en, this message translates to:
  /// **'YOUR OWN REASON'**
  String get myReasonsCustomCardLabelFilled;

  /// lib/screens/my_reasons_screen.dart: Placeholder text on the empty own-reason card
  ///
  /// In en, this message translates to:
  /// **'Write what matters most in your own words'**
  String get myReasonsCustomCardPlaceholder;

  /// lib/screens/my_reasons_screen.dart: Tooltip of the button that removes the member’s own reason
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get myReasonsCustomRemoveTooltip;

  /// lib/screens/my_reasons_screen.dart: Example shown in the empty text field
  ///
  /// In en, this message translates to:
  /// **'For example: I want more energy'**
  String get myReasonsCustomSheetHint;

  /// lib/screens/my_reasons_screen.dart: Sheet text: what to write
  ///
  /// In en, this message translates to:
  /// **'Write something you want to remember when a craving hits.'**
  String get myReasonsCustomSheetIntro;

  /// lib/screens/my_reasons_screen.dart: Switch label: make the own reason the top reason
  ///
  /// In en, this message translates to:
  /// **'Make this my top reason'**
  String get myReasonsCustomSheetMakeTop;

  /// lib/screens/my_reasons_screen.dart: Button that saves the own reason
  ///
  /// In en, this message translates to:
  /// **'Save reason'**
  String get myReasonsCustomSheetSaveButton;

  /// lib/screens/my_reasons_screen.dart: Title of the sheet for writing an own reason
  ///
  /// In en, this message translates to:
  /// **'Add your own reason'**
  String get myReasonsCustomSheetTitle;

  /// lib/screens/my_reasons_screen.dart: Small label above the screen title
  ///
  /// In en, this message translates to:
  /// **'YOUR MOTIVATION'**
  String get myReasonsEyebrow;

  /// lib/screens/my_reasons_screen.dart: Header title of the screen
  ///
  /// In en, this message translates to:
  /// **'My reasons'**
  String get myReasonsHeaderTitle;

  /// lib/screens/my_reasons_screen.dart: Text under the title: choose reasons and star a top reason
  ///
  /// In en, this message translates to:
  /// **'Choose everything that matters to you. Tap the star to make one your top reason.'**
  String get myReasonsIntro;

  /// lib/screens/my_reasons_screen.dart: Label above the list of reasons
  ///
  /// In en, this message translates to:
  /// **'SELECT ALL THAT MATTER'**
  String get myReasonsListLabel;

  /// lib/screens/my_reasons_screen.dart: Reason option: breathe easier
  ///
  /// In en, this message translates to:
  /// **'Breathe easier'**
  String get myReasonsOptionBreatheEasier;

  /// lib/screens/my_reasons_screen.dart: Reason option: feel more in control
  ///
  /// In en, this message translates to:
  /// **'Feel more in control'**
  String get myReasonsOptionControl;

  /// lib/screens/my_reasons_screen.dart: Name of the member’s own reason when used as the top reason
  ///
  /// In en, this message translates to:
  /// **'My own reason'**
  String get myReasonsOptionCustom;

  /// lib/screens/my_reasons_screen.dart: Reason option: protect my family
  ///
  /// In en, this message translates to:
  /// **'Protect my family'**
  String get myReasonsOptionFamily;

  /// lib/screens/my_reasons_screen.dart: Reason option: be there for my future
  ///
  /// In en, this message translates to:
  /// **'Be there for my future'**
  String get myReasonsOptionFuture;

  /// lib/screens/my_reasons_screen.dart: Reason option: improve my health
  ///
  /// In en, this message translates to:
  /// **'Improve my health'**
  String get myReasonsOptionImproveHealth;

  /// lib/screens/my_reasons_screen.dart: Reason option: save money
  ///
  /// In en, this message translates to:
  /// **'Save money'**
  String get myReasonsOptionSaveMoney;

  /// lib/screens/my_reasons_screen.dart: Preview message for the breathe-easier reason
  ///
  /// In en, this message translates to:
  /// **'“You chose this to breathe easier. This feeling will pass.”'**
  String get myReasonsPreviewBreatheEasier;

  /// lib/screens/my_reasons_screen.dart: Preview message for the feel-in-control reason
  ///
  /// In en, this message translates to:
  /// **'“You chose this to feel in control. This feeling will pass.”'**
  String get myReasonsPreviewControl;

  /// lib/screens/my_reasons_screen.dart: Preview message quoting the member’s own reason ({value})
  ///
  /// In en, this message translates to:
  /// **'“You chose this because ‘{value}.’ This feeling will pass.”'**
  String myReasonsPreviewCustom(Object value);

  /// lib/screens/my_reasons_screen.dart: Preview message for the family reason
  ///
  /// In en, this message translates to:
  /// **'“You chose this for your family. This feeling will pass.”'**
  String get myReasonsPreviewFamily;

  /// lib/screens/my_reasons_screen.dart: Preview message for the future reason
  ///
  /// In en, this message translates to:
  /// **'“You chose this for your future. This feeling will pass.”'**
  String get myReasonsPreviewFuture;

  /// lib/screens/my_reasons_screen.dart: Preview message for the health reason
  ///
  /// In en, this message translates to:
  /// **'“You chose this for your health. This feeling will pass.”'**
  String get myReasonsPreviewImproveHealth;

  /// lib/screens/my_reasons_screen.dart: Label in the preview: the message is shown when a craving hits
  ///
  /// In en, this message translates to:
  /// **'WHEN A CRAVING HITS'**
  String get myReasonsPreviewMoment;

  /// lib/screens/my_reasons_screen.dart: Preview text when no reason is chosen yet
  ///
  /// In en, this message translates to:
  /// **'Choose a reason to create your personal reminder.'**
  String get myReasonsPreviewNone;

  /// lib/screens/my_reasons_screen.dart: Preview message for the save-money reason
  ///
  /// In en, this message translates to:
  /// **'“You chose this to save money. This feeling will pass.”'**
  String get myReasonsPreviewSaveMoney;

  /// lib/screens/my_reasons_screen.dart: Title of the card that previews the motivation message
  ///
  /// In en, this message translates to:
  /// **'MOTIVATION PREVIEW'**
  String get myReasonsPreviewTitle;

  /// lib/screens/my_reasons_screen.dart: Line under the preview naming the top reason ({topLabel})
  ///
  /// In en, this message translates to:
  /// **'Based on your top reason: {topLabel}'**
  String myReasonsPreviewTopReason(Object topLabel);

  /// lib/screens/my_reasons_screen.dart: Line under the preview when no top reason is set
  ///
  /// In en, this message translates to:
  /// **'Choose a top reason anytime'**
  String get myReasonsPreviewTopReasonNone;

  /// lib/screens/my_reasons_screen.dart: Privacy note: reasons stay private
  ///
  /// In en, this message translates to:
  /// **'Your reasons stay private and only personalize your quit support.'**
  String get myReasonsPrivacyNote;

  /// lib/screens/my_reasons_screen.dart: Label of the progress bar: the quit plan section
  ///
  /// In en, this message translates to:
  /// **'QUIT PLAN'**
  String get myReasonsProgressLabel;

  /// lib/screens/my_reasons_screen.dart: Button that saves the reasons
  ///
  /// In en, this message translates to:
  /// **'Save my reasons'**
  String get myReasonsSaveButton;

  /// lib/screens/my_reasons_screen.dart: Counter next to the list label: how many reasons are selected ({selectionCount})
  ///
  /// In en, this message translates to:
  /// **'{selectionCount} SELECTED'**
  String myReasonsSelectedCount(Object selectionCount);

  /// lib/screens/my_reasons_screen.dart: Bottom bar: how many reasons are selected ({count}) and whether a top reason is set ({hasTopReason} is true or false)
  ///
  /// In en, this message translates to:
  /// **'{count} reasons selected · {hasTopReason, select, true{1 top reason} other{no top reason}}'**
  String myReasonsSelectionSummary(Object count, String hasTopReason);

  /// lib/screens/my_reasons_screen.dart: Step counter in the header: step 3 of 5 of the quit plan
  ///
  /// In en, this message translates to:
  /// **'3 OF 5'**
  String get myReasonsStepCounter;

  /// lib/screens/my_reasons_screen.dart: Screen title: what the member is quitting for
  ///
  /// In en, this message translates to:
  /// **'What are you quitting for?'**
  String get myReasonsTitle;

  /// lib/screens/my_reasons_screen.dart: Tooltip of the star that makes a reason the top reason
  ///
  /// In en, this message translates to:
  /// **'Top reason'**
  String get myReasonsTopReasonTooltip;

  /// lib/screens/readiness_result_screen.dart: Tooltip and accessibility label of the header back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get readinessResultBackTooltip;

  /// lib/screens/readiness_result_screen.dart: Badge in the header: the assessment is complete
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get readinessResultCompleteBadge;

  /// lib/screens/readiness_result_screen.dart: Main button when the connect path is chosen
  ///
  /// In en, this message translates to:
  /// **'Find support options'**
  String get readinessResultContinueConnectButton;

  /// lib/screens/readiness_result_screen.dart: Main button when the explore path is chosen
  ///
  /// In en, this message translates to:
  /// **'Explore without setting a date'**
  String get readinessResultContinueExploreButton;

  /// lib/screens/readiness_result_screen.dart: Main button when the prepare path is chosen
  ///
  /// In en, this message translates to:
  /// **'Build my preparation plan'**
  String get readinessResultContinuePrepareButton;

  /// lib/screens/readiness_result_screen.dart: Small label above the screen title
  ///
  /// In en, this message translates to:
  /// **'YOUR REFLECTION'**
  String get readinessResultEyebrow;

  /// lib/screens/readiness_result_screen.dart: Header title of the screen
  ///
  /// In en, this message translates to:
  /// **'Your starting point'**
  String get readinessResultHeaderTitle;

  /// lib/screens/readiness_result_screen.dart: Note under the button: the path can be changed anytime
  ///
  /// In en, this message translates to:
  /// **'You’re in control. Change your path anytime.'**
  String get readinessResultInControlNote;

  /// lib/screens/readiness_result_screen.dart: Text under the title: a summary of the answers follows
  ///
  /// In en, this message translates to:
  /// **'Here is what we heard from your answers.'**
  String get readinessResultIntro;

  /// lib/screens/readiness_result_screen.dart: Label above the other paths the member can choose
  ///
  /// In en, this message translates to:
  /// **'YOU CAN CHOOSE A DIFFERENT PATH'**
  String get readinessResultOtherPathsLabel;

  /// lib/screens/readiness_result_screen.dart: Description of the connect path
  ///
  /// In en, this message translates to:
  /// **'Talk with a coach or care team'**
  String get readinessResultPathConnectDescription;

  /// lib/screens/readiness_result_screen.dart: Other path: connect with a coach or care team
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get readinessResultPathConnectName;

  /// lib/screens/readiness_result_screen.dart: Description of the explore path
  ///
  /// In en, this message translates to:
  /// **'Learn without setting a date'**
  String get readinessResultPathExploreDescription;

  /// lib/screens/readiness_result_screen.dart: Other path: explore first
  ///
  /// In en, this message translates to:
  /// **'Explore first'**
  String get readinessResultPathExploreName;

  /// lib/screens/readiness_result_screen.dart: Smoking pattern summary: 11 to 20 cigarettes a day
  ///
  /// In en, this message translates to:
  /// **'11–20 cigarettes on a typical day'**
  String get readinessResultPatternElevenToTwenty;

  /// lib/screens/readiness_result_screen.dart: Label in the summary card: the smoking pattern
  ///
  /// In en, this message translates to:
  /// **'YOUR PATTERN'**
  String get readinessResultPatternLabel;

  /// lib/screens/readiness_result_screen.dart: Smoking pattern summary when the question was skipped
  ///
  /// In en, this message translates to:
  /// **'You can add your smoking pattern anytime'**
  String get readinessResultPatternNone;

  /// lib/screens/readiness_result_screen.dart: Smoking pattern summary: does not smoke every day
  ///
  /// In en, this message translates to:
  /// **'You do not smoke every day'**
  String get readinessResultPatternNotEveryDay;

  /// lib/screens/readiness_result_screen.dart: Smoking pattern summary: 10 or fewer cigarettes a day
  ///
  /// In en, this message translates to:
  /// **'10 or fewer cigarettes on a typical day'**
  String get readinessResultPatternTenOrFewer;

  /// lib/screens/readiness_result_screen.dart: Smoking pattern summary: 31 or more cigarettes a day
  ///
  /// In en, this message translates to:
  /// **'31 or more cigarettes on a typical day'**
  String get readinessResultPatternThirtyOneOrMore;

  /// lib/screens/readiness_result_screen.dart: Smoking pattern summary: 21 to 30 cigarettes a day
  ///
  /// In en, this message translates to:
  /// **'21–30 cigarettes on a typical day'**
  String get readinessResultPatternTwentyOneToThirty;

  /// lib/screens/readiness_result_screen.dart: Label of the progress bar: the assessment section
  ///
  /// In en, this message translates to:
  /// **'ASSESSMENT'**
  String get readinessResultProgressLabel;

  /// lib/screens/readiness_result_screen.dart: Badge on the recommended path card
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get readinessResultRecommendedBadge;

  /// lib/screens/readiness_result_screen.dart: Description of the recommended path
  ///
  /// In en, this message translates to:
  /// **'Practice coping tools and choose a quit date in the next 7–14 days. We’ll guide one small step each day.'**
  String get readinessResultRecommendedPathDescription;

  /// lib/screens/readiness_result_screen.dart: Name of the recommended path: prepare
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get readinessResultRecommendedPathName;

  /// lib/screens/readiness_result_screen.dart: Starting-point summary: how many situations the member identified ({count})
  ///
  /// In en, this message translates to:
  /// **'You identified {count} {count, plural, =1{situation} other{situations}} to prepare for'**
  String readinessResultStartingPointCount(int count);

  /// lib/screens/readiness_result_screen.dart: Label in the summary card: the starting point
  ///
  /// In en, this message translates to:
  /// **'STARTING POINT'**
  String get readinessResultStartingPointLabel;

  /// lib/screens/readiness_result_screen.dart: Starting-point summary when no situations were identified
  ///
  /// In en, this message translates to:
  /// **'You can start small and add details later'**
  String get readinessResultStartingPointNone;

  /// lib/screens/readiness_result_screen.dart: Screen title: the member is ready to prepare
  ///
  /// In en, this message translates to:
  /// **'You’re ready to prepare—at your own pace.'**
  String get readinessResultTitle;

  /// lib/screens/readiness_result_screen.dart: Trigger name inside the triggers summary (lower case): after meals
  ///
  /// In en, this message translates to:
  /// **'after meals'**
  String get readinessResultTriggerAfterMeals;

  /// lib/screens/readiness_result_screen.dart: Trigger name inside the triggers summary (lower case): alcohol
  ///
  /// In en, this message translates to:
  /// **'alcohol'**
  String get readinessResultTriggerAlcohol;

  /// lib/screens/readiness_result_screen.dart: Trigger name inside the triggers summary (lower case): before bed
  ///
  /// In en, this message translates to:
  /// **'before bed'**
  String get readinessResultTriggerBeforeBed;

  /// lib/screens/readiness_result_screen.dart: Trigger name inside the triggers summary (lower case): boredom
  ///
  /// In en, this message translates to:
  /// **'boredom'**
  String get readinessResultTriggerBoredom;

  /// lib/screens/readiness_result_screen.dart: Trigger name inside the triggers summary (lower case): coffee
  ///
  /// In en, this message translates to:
  /// **'coffee'**
  String get readinessResultTriggerCoffee;

  /// lib/screens/readiness_result_screen.dart: Trigger name inside the triggers summary (lower case): driving
  ///
  /// In en, this message translates to:
  /// **'driving'**
  String get readinessResultTriggerDriving;

  /// lib/screens/readiness_result_screen.dart: Trigger name inside the triggers summary (lower case): mornings
  ///
  /// In en, this message translates to:
  /// **'mornings'**
  String get readinessResultTriggerMorning;

  /// lib/screens/readiness_result_screen.dart: Trigger name inside the triggers summary (lower case): social settings
  ///
  /// In en, this message translates to:
  /// **'social settings'**
  String get readinessResultTriggerSocialSettings;

  /// lib/screens/readiness_result_screen.dart: Trigger name inside the triggers summary (lower case): stress
  ///
  /// In en, this message translates to:
  /// **'stress'**
  String get readinessResultTriggerStress;

  /// lib/screens/readiness_result_screen.dart: Trigger name inside the triggers summary (lower case): work breaks
  ///
  /// In en, this message translates to:
  /// **'work breaks'**
  String get readinessResultTriggerWorkBreaks;

  /// lib/screens/readiness_result_screen.dart: Label in the summary card: the triggers
  ///
  /// In en, this message translates to:
  /// **'TRIGGERS'**
  String get readinessResultTriggersLabel;

  /// lib/screens/readiness_result_screen.dart: Short list of many triggers: the first two ({first}, {second}) and how many more ({remaining})
  ///
  /// In en, this message translates to:
  /// **'{first}, {second}, and {remaining} more'**
  String readinessResultTriggersMany(
      Object first, Object second, Object remaining);

  /// lib/screens/readiness_result_screen.dart: Triggers summary when none were chosen
  ///
  /// In en, this message translates to:
  /// **'You can identify triggers anytime'**
  String get readinessResultTriggersNone;

  /// lib/screens/readiness_result_screen.dart: Triggers summary with one trigger ({first})
  ///
  /// In en, this message translates to:
  /// **'You want support for {first}'**
  String readinessResultTriggersOne(Object first);

  /// lib/screens/readiness_result_screen.dart: Triggers summary with two triggers ({first}, {last})
  ///
  /// In en, this message translates to:
  /// **'You want support for {first} and {last}'**
  String readinessResultTriggersTwo(Object first, Object last);

  /// lib/screens/readiness_result_screen.dart: Link that explains why the path fits the answers
  ///
  /// In en, this message translates to:
  /// **'Why this fits your answers'**
  String get readinessResultWhyThisFitsLink;

  /// lib/screens/readiness_result_screen.dart: Sheet text: how the answers led to the recommendation
  ///
  /// In en, this message translates to:
  /// **'You identified your smoking pattern and situations that may bring on an urge. Practicing coping tools before choosing a date can make the next step feel more manageable.'**
  String get readinessResultWhyThisFitsSheetBody;

  /// lib/screens/readiness_result_screen.dart: Button that closes the sheet
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get readinessResultWhyThisFitsSheetDoneButton;

  /// lib/screens/readiness_result_screen.dart: Sheet text: a flexible recommendation, not a medical assessment
  ///
  /// In en, this message translates to:
  /// **'This is a flexible recommendation, not a medical assessment. You can choose another path now or change it later.'**
  String get readinessResultWhyThisFitsSheetNote;

  /// lib/screens/readiness_result_screen.dart: Title of the sheet that explains why preparation may fit
  ///
  /// In en, this message translates to:
  /// **'Why preparation may fit'**
  String get readinessResultWhyThisFitsSheetTitle;

  /// lib/screens/recommended_rescue_tool_screen.dart: Tooltip and accessibility label of the header back button
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get recommendedRescueToolBackTooltip;

  /// lib/screens/recommended_rescue_tool_screen.dart: Description of slow breathing
  ///
  /// In en, this message translates to:
  /// **'Let the urge rise and fall while you follow a calm breathing cue.'**
  String get recommendedRescueToolBreathingDescription;

  /// lib/screens/recommended_rescue_tool_screen.dart: Name of the recommended tool: slow breathing
  ///
  /// In en, this message translates to:
  /// **'Slow breathing'**
  String get recommendedRescueToolBreathingName;

  /// lib/screens/recommended_rescue_tool_screen.dart: Feature of slow breathing: works offline
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get recommendedRescueToolBreathingOffline;

  /// lib/screens/recommended_rescue_tool_screen.dart: Feature of slow breathing: voice is optional
  ///
  /// In en, this message translates to:
  /// **'Voice optional'**
  String get recommendedRescueToolBreathingVoice;

  /// lib/screens/recommended_rescue_tool_screen.dart: Chip naming why the tool is suggested: a personalized match
  ///
  /// In en, this message translates to:
  /// **'Personalized match'**
  String get recommendedRescueToolContextPersonal;

  /// lib/screens/recommended_rescue_tool_screen.dart: Chip naming why the tool is suggested: stress was selected
  ///
  /// In en, this message translates to:
  /// **'Stress selected'**
  String get recommendedRescueToolContextStress;

  /// lib/screens/recommended_rescue_tool_screen.dart: Note: the recommendation uses data only for personalized support
  ///
  /// In en, this message translates to:
  /// **'Recommendation uses your data only for personalized support.'**
  String get recommendedRescueToolDataNote;

  /// lib/screens/recommended_rescue_tool_screen.dart: Small label above the title
  ///
  /// In en, this message translates to:
  /// **'BEST MATCH'**
  String get recommendedRescueToolEyebrow;

  /// lib/screens/recommended_rescue_tool_screen.dart: Text under the title when there is no earlier result
  ///
  /// In en, this message translates to:
  /// **'One recommended action, based on this craving.'**
  String get recommendedRescueToolIntro;

  /// lib/screens/recommended_rescue_tool_screen.dart: Text under the title when there is an earlier result
  ///
  /// In en, this message translates to:
  /// **'One recommended action, based on this craving and your results.'**
  String get recommendedRescueToolIntroWithResult;

  /// lib/screens/recommended_rescue_tool_screen.dart: The last result: craving before ({before}) and after ({after}) the exercise
  ///
  /// In en, this message translates to:
  /// **'Craving changed from {before} to {after} after the exercise.'**
  String recommendedRescueToolLastResult(Object before, Object after);

  /// lib/screens/recommended_rescue_tool_screen.dart: Label of the member’s last result with this tool
  ///
  /// In en, this message translates to:
  /// **'YOUR LAST RESULT'**
  String get recommendedRescueToolLastResultLabel;

  /// lib/screens/recommended_rescue_tool_screen.dart: Description of the movement action
  ///
  /// In en, this message translates to:
  /// **'Walk or stretch'**
  String get recommendedRescueToolMoveDescription;

  /// lib/screens/recommended_rescue_tool_screen.dart: Features of the movement action
  ///
  /// In en, this message translates to:
  /// **'Offline · No equipment'**
  String get recommendedRescueToolMoveFeatures;

  /// lib/screens/recommended_rescue_tool_screen.dart: Other action: move for 3 minutes
  ///
  /// In en, this message translates to:
  /// **'Move for 3 minutes'**
  String get recommendedRescueToolMoveName;

  /// lib/screens/recommended_rescue_tool_screen.dart: Label above the other actions
  ///
  /// In en, this message translates to:
  /// **'Or choose another action'**
  String get recommendedRescueToolOtherActionsLabel;

  /// lib/screens/recommended_rescue_tool_screen.dart: Label of the progress bar: choose support
  ///
  /// In en, this message translates to:
  /// **'CHOOSE SUPPORT'**
  String get recommendedRescueToolProgressLabel;

  /// lib/screens/recommended_rescue_tool_screen.dart: Reason line: craving rating ({intensity})
  ///
  /// In en, this message translates to:
  /// **'Craving {intensity}/10.'**
  String recommendedRescueToolReason(Object intensity);

  /// lib/screens/recommended_rescue_tool_screen.dart: Reason line: craving rating ({intensity}) and an earlier helpful result
  ///
  /// In en, this message translates to:
  /// **'Craving {intensity}/10 + your previous helpful result.'**
  String recommendedRescueToolReasonHelped(Object intensity);

  /// lib/screens/recommended_rescue_tool_screen.dart: Reason line: stress and craving rating ({intensity})
  ///
  /// In en, this message translates to:
  /// **'Stress trigger + craving {intensity}/10.'**
  String recommendedRescueToolReasonStress(Object intensity);

  /// lib/screens/recommended_rescue_tool_screen.dart: Reason line: stress, craving rating ({intensity}) and an earlier helpful result
  ///
  /// In en, this message translates to:
  /// **'Stress trigger + craving {intensity}/10 + your previous helpful result.'**
  String recommendedRescueToolReasonStressHelped(Object intensity);

  /// lib/screens/recommended_rescue_tool_screen.dart: Badge on the recommended tool card
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get recommendedRescueToolRecommendedBadge;

  /// lib/screens/recommended_rescue_tool_screen.dart: Description of the change-the-scene action
  ///
  /// In en, this message translates to:
  /// **'Go somewhere smoke-free'**
  String get recommendedRescueToolSceneDescription;

  /// lib/screens/recommended_rescue_tool_screen.dart: Feature of the change-the-scene action
  ///
  /// In en, this message translates to:
  /// **'Quick environment shift'**
  String get recommendedRescueToolSceneFeatures;

  /// lib/screens/recommended_rescue_tool_screen.dart: Other action: change the scene
  ///
  /// In en, this message translates to:
  /// **'Change the scene'**
  String get recommendedRescueToolSceneName;

  /// lib/screens/recommended_rescue_tool_screen.dart: Button on the card that starts the 2-minute breathing
  ///
  /// In en, this message translates to:
  /// **'Start 2-minute breathing'**
  String get recommendedRescueToolStartBreathingButton;

  /// lib/screens/recommended_rescue_tool_screen.dart: Main button when movement is chosen
  ///
  /// In en, this message translates to:
  /// **'Start 3-minute movement'**
  String get recommendedRescueToolStartMoveButton;

  /// lib/screens/recommended_rescue_tool_screen.dart: Main button that starts the recommended tool
  ///
  /// In en, this message translates to:
  /// **'Start recommended tool'**
  String get recommendedRescueToolStartRecommendedButton;

  /// lib/screens/recommended_rescue_tool_screen.dart: Main button when change the scene is chosen
  ///
  /// In en, this message translates to:
  /// **'Start scene change'**
  String get recommendedRescueToolStartSceneButton;

  /// lib/screens/recommended_rescue_tool_screen.dart: Step counter in the header: step 2 of 5 of the rescue
  ///
  /// In en, this message translates to:
  /// **'2 OF 5'**
  String get recommendedRescueToolStepCounter;

  /// lib/screens/recommended_rescue_tool_screen.dart: Card text: contact the support person ({supportName}) or a quitline counselor
  ///
  /// In en, this message translates to:
  /// **'Contact {supportName} or a trained quitline counselor.'**
  String recommendedRescueToolSupportBody(Object supportName);

  /// lib/screens/recommended_rescue_tool_screen.dart: Button that opens support
  ///
  /// In en, this message translates to:
  /// **'View support'**
  String get recommendedRescueToolSupportButton;

  /// lib/screens/recommended_rescue_tool_screen.dart: Note: nothing is sent unless the member chooses
  ///
  /// In en, this message translates to:
  /// **'Nothing is sent or shared unless you choose it.'**
  String get recommendedRescueToolSupportNote;

  /// lib/screens/recommended_rescue_tool_screen.dart: Title of the support card otherwise
  ///
  /// In en, this message translates to:
  /// **'Want a person instead?'**
  String get recommendedRescueToolSupportTitle;

  /// lib/screens/recommended_rescue_tool_screen.dart: Title of the support card when the craving is strong
  ///
  /// In en, this message translates to:
  /// **'Your craving is strong. Want a person?'**
  String get recommendedRescueToolSupportTitleStrong;

  /// lib/screens/recommended_rescue_tool_screen.dart: Note: tools can be switched anytime
  ///
  /// In en, this message translates to:
  /// **'You can switch tools at any time'**
  String get recommendedRescueToolSwitchNote;

  /// lib/screens/recommended_rescue_tool_screen.dart: Screen title when no tool has helped before yet
  ///
  /// In en, this message translates to:
  /// **'What feels possible right now?'**
  String get recommendedRescueToolTitle;

  /// lib/screens/recommended_rescue_tool_screen.dart: Screen title when a tool helped before
  ///
  /// In en, this message translates to:
  /// **'Start with what helped before.'**
  String get recommendedRescueToolTitleHelpedBefore;

  /// lib/screens/recommended_rescue_tool_screen.dart: Link that explains why this tool is suggested
  ///
  /// In en, this message translates to:
  /// **'Why this match?'**
  String get recommendedRescueToolWhyMatchLink;

  /// lib/screens/recommended_rescue_tool_screen.dart: Sheet text otherwise: the trigger ({triggerText}) and craving rating ({intensity})
  ///
  /// In en, this message translates to:
  /// **'{triggerText} + craving {intensity}/10 make slow breathing a practical first step.'**
  String recommendedRescueToolWhySheetBody(
      Object triggerText, Object intensity);

  /// lib/screens/recommended_rescue_tool_screen.dart: Sheet text when a tool helped before: the trigger ({triggerText}) and craving rating ({intensity})
  ///
  /// In en, this message translates to:
  /// **'{triggerText} + craving {intensity}/10 + a previously helpful breathing result make slow breathing a practical first step.'**
  String recommendedRescueToolWhySheetBodyHelped(
      Object triggerText, Object intensity);

  /// lib/screens/recommended_rescue_tool_screen.dart: Button that closes the sheet
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get recommendedRescueToolWhySheetDoneButton;

  /// lib/screens/recommended_rescue_tool_screen.dart: Sheet text: another action or personalization settings
  ///
  /// In en, this message translates to:
  /// **'You can choose another action now or change personalization later in Settings.'**
  String get recommendedRescueToolWhySheetNote;

  /// lib/screens/recommended_rescue_tool_screen.dart: Title of the why-this-match sheet otherwise
  ///
  /// In en, this message translates to:
  /// **'Your current context'**
  String get recommendedRescueToolWhySheetTitle;

  /// lib/screens/recommended_rescue_tool_screen.dart: Title of the why-this-match sheet when stress was selected
  ///
  /// In en, this message translates to:
  /// **'Stress trigger'**
  String get recommendedRescueToolWhySheetTitleStress;

  /// lib/screens/recommended_rescue_tool_screen.dart: Badge on the action the member chose
  ///
  /// In en, this message translates to:
  /// **'Your choice'**
  String get recommendedRescueToolYourChoiceBadge;

  /// lib/screens/select_quit_date_screen.dart: Tooltip and accessibility label of the header back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get selectQuitDateBackTooltip;

  /// lib/screens/select_quit_date_screen.dart: Calendar heading: month name ({month}) and year ({year})
  ///
  /// In en, this message translates to:
  /// **'{month} {year}'**
  String selectQuitDateCalendarMonthHeading(Object month, Object year);

  /// lib/screens/select_quit_date_screen.dart: Label on the chosen-date card: the quit date is today
  ///
  /// In en, this message translates to:
  /// **'YOUR QUIT DATE IS TODAY'**
  String get selectQuitDateCardLabelQuitToday;

  /// lib/screens/select_quit_date_screen.dart: Label on the chosen-date card: the target date
  ///
  /// In en, this message translates to:
  /// **'YOUR TARGET DATE'**
  String get selectQuitDateCardLabelReduceGradually;

  /// lib/screens/select_quit_date_screen.dart: Label on the chosen-date card: the quit date
  ///
  /// In en, this message translates to:
  /// **'YOUR QUIT DATE'**
  String get selectQuitDateCardLabelSetQuitDate;

  /// lib/screens/select_quit_date_screen.dart: What the lock screen shows for the check-in
  ///
  /// In en, this message translates to:
  /// **'Lock screen only shows: “You have a check-in.”'**
  String get selectQuitDateCheckInLockScreen;

  /// lib/screens/select_quit_date_screen.dart: Time and kind of the quit-day check-in
  ///
  /// In en, this message translates to:
  /// **'7:00 AM · Private notification'**
  String get selectQuitDateCheckInTime;

  /// lib/screens/select_quit_date_screen.dart: Title of the quit-day check-in switch
  ///
  /// In en, this message translates to:
  /// **'Quit-day check-in'**
  String get selectQuitDateCheckInTitle;

  /// lib/screens/select_quit_date_screen.dart: Main button on the quit-today path
  ///
  /// In en, this message translates to:
  /// **'Start my quit today'**
  String get selectQuitDateConfirmButtonQuitToday;

  /// lib/screens/select_quit_date_screen.dart: Main button on the reduce-gradually path
  ///
  /// In en, this message translates to:
  /// **'Confirm target date'**
  String get selectQuitDateConfirmButtonReduceGradually;

  /// lib/screens/select_quit_date_screen.dart: Main button on the set-a-quit-date path
  ///
  /// In en, this message translates to:
  /// **'Confirm this date'**
  String get selectQuitDateConfirmButtonSetQuitDate;

  /// lib/screens/select_quit_date_screen.dart: Small label above the screen title
  ///
  /// In en, this message translates to:
  /// **'YOUR DATE'**
  String get selectQuitDateEyebrow;

  /// lib/screens/select_quit_date_screen.dart: Reassurance note: the date can be changed later
  ///
  /// In en, this message translates to:
  /// **'You can change this date later without losing progress.'**
  String get selectQuitDateFlexibleNote;

  /// lib/screens/select_quit_date_screen.dart: Header title when the member chose to quit today
  ///
  /// In en, this message translates to:
  /// **'Start your quit today'**
  String get selectQuitDateHeaderTitleQuitToday;

  /// lib/screens/select_quit_date_screen.dart: Header title when the member chose to reduce gradually
  ///
  /// In en, this message translates to:
  /// **'Choose your target date'**
  String get selectQuitDateHeaderTitleReduceGradually;

  /// lib/screens/select_quit_date_screen.dart: Header title when the member chose to set a quit date
  ///
  /// In en, this message translates to:
  /// **'Choose your quit date'**
  String get selectQuitDateHeaderTitleSetQuitDate;

  /// lib/screens/select_quit_date_screen.dart: Text under the title for the quit-today path
  ///
  /// In en, this message translates to:
  /// **'Your smoke-free time begins today. We’ll add extra support through your first day.'**
  String get selectQuitDateIntroQuitToday;

  /// lib/screens/select_quit_date_screen.dart: Text under the title for the reduce-gradually path
  ///
  /// In en, this message translates to:
  /// **'A target 14–30 days away gives you time to reduce gradually with a clear goal.'**
  String get selectQuitDateIntroReduceGradually;

  /// lib/screens/select_quit_date_screen.dart: Text under the title for the set-a-quit-date path
  ///
  /// In en, this message translates to:
  /// **'A date 7–14 days away gives you time to prepare without losing momentum.'**
  String get selectQuitDateIntroSetQuitDate;

  /// lib/screens/select_quit_date_screen.dart: The chosen date in full: weekday, month, day and year
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {month} {day}, {year}'**
  String selectQuitDateLongDate(
      Object weekday, Object month, Object day, Object year);

  /// lib/screens/select_quit_date_screen.dart: Full month name, chosen by month (january…december); used in the calendar heading and dates
  ///
  /// In en, this message translates to:
  /// **'{month, select, january{January} february{February} march{March} april{April} may{May} june{June} july{July} august{August} september{September} october{October} november{November} december{December} other{}}'**
  String selectQuitDateMonthName(String month);

  /// lib/screens/select_quit_date_screen.dart: Short month name, chosen by month (january…december); used in date ranges and on the date card
  ///
  /// In en, this message translates to:
  /// **'{month, select, january{Jan} february{Feb} march{Mar} april{Apr} may{May} june{Jun} july{Jul} august{Aug} september{Sep} october{Oct} november{Nov} december{Dec} other{}}'**
  String selectQuitDateMonthShort(String month);

  /// lib/screens/select_quit_date_screen.dart: Label of the progress bar: the quit plan section
  ///
  /// In en, this message translates to:
  /// **'QUIT PLAN'**
  String get selectQuitDateProgressLabel;

  /// lib/screens/select_quit_date_screen.dart: A date range across two months: short month names and days ({startMonth} {start}, {endMonth} {end})
  ///
  /// In en, this message translates to:
  /// **'{startMonth} {start} – {endMonth} {end}'**
  String selectQuitDateRange(
      Object startMonth, Object start, Object endMonth, Object end);

  /// lib/screens/select_quit_date_screen.dart: A date range within one month: short month name ({month}), first and last day ({start}, {end})
  ///
  /// In en, this message translates to:
  /// **'{month} {start}–{end}'**
  String selectQuitDateRangeSameMonth(Object month, Object start, Object end);

  /// lib/screens/select_quit_date_screen.dart: Badge on the date card when the date is in the recommended window
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get selectQuitDateRecommendedBadge;

  /// lib/screens/select_quit_date_screen.dart: Note under the button: the date is saved automatically
  ///
  /// In en, this message translates to:
  /// **'Date saved automatically'**
  String get selectQuitDateSavedNote;

  /// lib/screens/select_quit_date_screen.dart: Step counter in the header: step 2 of 5 of the quit plan
  ///
  /// In en, this message translates to:
  /// **'2 OF 5'**
  String get selectQuitDateStepCounter;

  /// lib/screens/select_quit_date_screen.dart: Timing line on the date card: days left to prepare ({days})
  ///
  /// In en, this message translates to:
  /// **'{days} days to prepare'**
  String selectQuitDateTimingPrepare(Object days);

  /// lib/screens/select_quit_date_screen.dart: Timing line on the date card: days left to reduce ({days})
  ///
  /// In en, this message translates to:
  /// **'{days} days to reduce gradually'**
  String selectQuitDateTimingReduce(Object days);

  /// lib/screens/select_quit_date_screen.dart: Timing line on the date card: starting today
  ///
  /// In en, this message translates to:
  /// **'Starting today'**
  String get selectQuitDateTimingToday;

  /// lib/screens/select_quit_date_screen.dart: Screen title for the quit-today path
  ///
  /// In en, this message translates to:
  /// **'Today is your starting point.'**
  String get selectQuitDateTitleQuitToday;

  /// lib/screens/select_quit_date_screen.dart: Screen title for the reduce-gradually path
  ///
  /// In en, this message translates to:
  /// **'Choose the day to become smoke-free.'**
  String get selectQuitDateTitleReduceGradually;

  /// lib/screens/select_quit_date_screen.dart: Screen title for the set-a-quit-date path
  ///
  /// In en, this message translates to:
  /// **'Choose a day to begin.'**
  String get selectQuitDateTitleSetQuitDate;

  /// lib/screens/select_quit_date_screen.dart: Date card message when the saved date can no longer be chosen
  ///
  /// In en, this message translates to:
  /// **'This date is no longer available. Choose a new date.'**
  String get selectQuitDateUnavailableMessage;

  /// lib/screens/select_quit_date_screen.dart: One-letter weekday heading of a calendar column, chosen by weekday (sunday…saturday)
  ///
  /// In en, this message translates to:
  /// **'{weekday, select, sunday{S} monday{M} tuesday{T} wednesday{W} thursday{T} friday{F} saturday{S} other{}}'**
  String selectQuitDateWeekdayInitial(String weekday);

  /// lib/screens/select_quit_date_screen.dart: Weekday name, chosen by weekday (monday…sunday); used in dates and on the date card
  ///
  /// In en, this message translates to:
  /// **'{weekday, select, monday{Monday} tuesday{Tuesday} wednesday{Wednesday} thursday{Thursday} friday{Friday} saturday{Saturday} sunday{Sunday} other{}}'**
  String selectQuitDateWeekdayName(String weekday);

  /// lib/screens/select_quit_date_screen.dart: Note above the calendar on the quit-today path: today is selected
  ///
  /// In en, this message translates to:
  /// **'Today is selected based on your path'**
  String get selectQuitDateWindowQuitToday;

  /// lib/screens/select_quit_date_screen.dart: Note above the calendar: the recommended reduction window ({range} is a date range)
  ///
  /// In en, this message translates to:
  /// **'Recommended reduction window: {range}'**
  String selectQuitDateWindowReduceGradually(Object range);

  /// lib/screens/select_quit_date_screen.dart: Note above the calendar: the recommended preparation window ({range} is a date range)
  ///
  /// In en, this message translates to:
  /// **'Recommended preparation window: {range}'**
  String selectQuitDateWindowSetQuitDate(Object range);

  /// lib/screens/trigger_map_screen.dart: Tooltip and accessibility label of the header back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get triggerMapBackTooltip;

  /// lib/screens/trigger_map_screen.dart: Button that continues to the next step
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get triggerMapContinueButton;

  /// lib/screens/trigger_map_screen.dart: Label of the own-trigger card before the member writes one
  ///
  /// In en, this message translates to:
  /// **'ADD YOUR OWN TRIGGER'**
  String get triggerMapCustomCardLabelEmpty;

  /// lib/screens/trigger_map_screen.dart: Label of the own-trigger card once the member has written one
  ///
  /// In en, this message translates to:
  /// **'YOUR TRIGGER'**
  String get triggerMapCustomCardLabelFilled;

  /// lib/screens/trigger_map_screen.dart: Placeholder text on the empty own-trigger card
  ///
  /// In en, this message translates to:
  /// **'Type another situation…'**
  String get triggerMapCustomCardPlaceholder;

  /// lib/screens/trigger_map_screen.dart: Tooltip of the button that removes the member’s own trigger
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get triggerMapCustomRemoveTooltip;

  /// lib/screens/trigger_map_screen.dart: Label of the text field
  ///
  /// In en, this message translates to:
  /// **'My trigger'**
  String get triggerMapCustomSheetFieldLabel;

  /// lib/screens/trigger_map_screen.dart: Example shown in the empty text field
  ///
  /// In en, this message translates to:
  /// **'For example, phone calls'**
  String get triggerMapCustomSheetHint;

  /// lib/screens/trigger_map_screen.dart: Sheet text: what to write
  ///
  /// In en, this message translates to:
  /// **'Enter a situation, feeling, or routine that makes you want to smoke.'**
  String get triggerMapCustomSheetIntro;

  /// lib/screens/trigger_map_screen.dart: Button that saves the own trigger
  ///
  /// In en, this message translates to:
  /// **'Save trigger'**
  String get triggerMapCustomSheetSaveButton;

  /// lib/screens/trigger_map_screen.dart: Title of the sheet for writing an own trigger
  ///
  /// In en, this message translates to:
  /// **'Add your own trigger'**
  String get triggerMapCustomSheetTitle;

  /// lib/screens/trigger_map_screen.dart: Header title of the screen
  ///
  /// In en, this message translates to:
  /// **'Your triggers'**
  String get triggerMapHeaderTitle;

  /// lib/screens/trigger_map_screen.dart: Trigger option: after meals
  ///
  /// In en, this message translates to:
  /// **'After meals'**
  String get triggerMapOptionAfterMeals;

  /// lib/screens/trigger_map_screen.dart: Trigger option: alcohol
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get triggerMapOptionAlcohol;

  /// lib/screens/trigger_map_screen.dart: Trigger option: before bed
  ///
  /// In en, this message translates to:
  /// **'Before bed'**
  String get triggerMapOptionBeforeBed;

  /// lib/screens/trigger_map_screen.dart: Trigger option: boredom
  ///
  /// In en, this message translates to:
  /// **'Boredom'**
  String get triggerMapOptionBoredom;

  /// lib/screens/trigger_map_screen.dart: Trigger option: with coffee
  ///
  /// In en, this message translates to:
  /// **'With coffee'**
  String get triggerMapOptionCoffee;

  /// lib/screens/trigger_map_screen.dart: Trigger option: driving
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get triggerMapOptionDriving;

  /// lib/screens/trigger_map_screen.dart: Trigger option: morning
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get triggerMapOptionMorning;

  /// lib/screens/trigger_map_screen.dart: Trigger option: social settings
  ///
  /// In en, this message translates to:
  /// **'Social settings'**
  String get triggerMapOptionSocialSettings;

  /// lib/screens/trigger_map_screen.dart: Trigger option: stress
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get triggerMapOptionStress;

  /// lib/screens/trigger_map_screen.dart: Trigger option: work breaks
  ///
  /// In en, this message translates to:
  /// **'Work breaks'**
  String get triggerMapOptionWorkBreaks;

  /// lib/screens/trigger_map_screen.dart: Privacy note: what the choices shape
  ///
  /// In en, this message translates to:
  /// **'Your choices shape coping tools and reminder timing.'**
  String get triggerMapPrivacyNoteBody;

  /// lib/screens/trigger_map_screen.dart: Privacy note: location is not tracked in the background
  ///
  /// In en, this message translates to:
  /// **'BreatheFree does not track your location in the background.'**
  String get triggerMapPrivacyNoteLocation;

  /// lib/screens/trigger_map_screen.dart: Title of the privacy note: triggers are used to prepare, not to monitor
  ///
  /// In en, this message translates to:
  /// **'Used to prepare, not to monitor'**
  String get triggerMapPrivacyNoteTitle;

  /// lib/screens/trigger_map_screen.dart: Label of the progress bar: the assessment section
  ///
  /// In en, this message translates to:
  /// **'ASSESSMENT'**
  String get triggerMapProgressLabel;

  /// lib/screens/trigger_map_screen.dart: The question: when the member most wants a cigarette
  ///
  /// In en, this message translates to:
  /// **'When are you most likely to want a cigarette?'**
  String get triggerMapQuestion;

  /// lib/screens/trigger_map_screen.dart: Help text under the question
  ///
  /// In en, this message translates to:
  /// **'Choose every situation that feels true for you.'**
  String get triggerMapQuestionHint;

  /// lib/screens/trigger_map_screen.dart: Small label above the question: which question it is, and that several answers may be chosen
  ///
  /// In en, this message translates to:
  /// **'QUESTION 2 · CHOOSE ALL THAT APPLY'**
  String get triggerMapQuestionLabel;

  /// lib/screens/trigger_map_screen.dart: Bottom bar: how many triggers are selected ({count}) and that the choice is saved
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{trigger selected} other{triggers selected}} · Saved automatically'**
  String triggerMapSelectionCount(int count);

  /// lib/screens/welcome_screen.dart: Benefit card text for help with cravings
  ///
  /// In en, this message translates to:
  /// **'Quick tools that work anywhere'**
  String get welcomeBenefitCravingsDescription;

  /// lib/screens/welcome_screen.dart: Benefit card: help when cravings hit
  ///
  /// In en, this message translates to:
  /// **'Help when cravings hit'**
  String get welcomeBenefitCravingsTitle;

  /// lib/screens/welcome_screen.dart: Benefit card text for lasting progress
  ///
  /// In en, this message translates to:
  /// **'A slip never erases your wins'**
  String get welcomeBenefitProgressDescription;

  /// lib/screens/welcome_screen.dart: Benefit card: progress that stays
  ///
  /// In en, this message translates to:
  /// **'Progress that stays'**
  String get welcomeBenefitProgressTitle;

  /// lib/screens/welcome_screen.dart: Small label above the headline
  ///
  /// In en, this message translates to:
  /// **'WELCOME TO BREATHEFREE'**
  String get welcomeEyebrow;

  /// lib/screens/welcome_screen.dart: Main button that starts the setup
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeGetStartedButton;

  /// lib/screens/welcome_screen.dart: Headline of the first screen
  ///
  /// In en, this message translates to:
  /// **'Your next breath can be different.'**
  String get welcomeHeadline;

  /// lib/screens/welcome_screen.dart: Text under the headline
  ///
  /// In en, this message translates to:
  /// **'Small steps, practical support, and no judgment—whenever you are ready.'**
  String get welcomeIntro;

  /// lib/screens/welcome_screen.dart: Legal line, part 3, between the two links: and acknowledge the
  ///
  /// In en, this message translates to:
  /// **' and acknowledge the '**
  String get welcomeLegalMiddle;

  /// lib/screens/welcome_screen.dart: Legal line, part 1, before the Terms link: by continuing, you agree to the
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to the '**
  String get welcomeLegalPrefix;

  /// lib/screens/welcome_screen.dart: Button that switches the app to the other language; written in that other language
  ///
  /// In en, this message translates to:
  /// **'Continuar en español'**
  String get welcomeOtherLanguageButton;

  /// lib/screens/welcome_screen.dart: Legal line, part 4: the link to the Privacy Notice
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice.'**
  String get welcomePrivacyNoticeLink;

  /// lib/screens/welcome_screen.dart: Text of the Privacy Notice sheet
  ///
  /// In en, this message translates to:
  /// **'BreatheFree will clearly explain what data is collected, why it is needed, and how to delete it.'**
  String get welcomePrivacySheetBody;

  /// lib/screens/welcome_screen.dart: Title of the sheet the Privacy Notice link opens
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice'**
  String get welcomePrivacySheetTitle;

  /// lib/screens/welcome_screen.dart: Button that closes the Terms or Privacy Notice sheet
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get welcomeSheetDoneButton;

  /// lib/screens/welcome_screen.dart: Button for members who already have an account
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get welcomeSignInButton;

  /// lib/screens/welcome_screen.dart: Legal line, part 2: the link to the Terms
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get welcomeTermsLink;

  /// lib/screens/welcome_screen.dart: Text of the Terms sheet
  ///
  /// In en, this message translates to:
  /// **'The final Terms of Use will be published before production distribution.'**
  String get welcomeTermsSheetBody;

  /// lib/screens/welcome_screen.dart: Title of the sheet the Terms link opens
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get welcomeTermsSheetTitle;

  /// lib/screens/why_breathefree_screen.dart: Tooltip and accessibility label of the header back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get whyBreatheFreeBackTooltip;

  /// lib/screens/why_breathefree_screen.dart: Button that continues to the next screen
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get whyBreatheFreeContinueButton;

  /// lib/screens/why_breathefree_screen.dart: Detail sheet text for the craving card
  ///
  /// In en, this message translates to:
  /// **'Use guided breathing, a brief distraction, or your top reason for quitting. Essential tools will remain available offline.'**
  String get whyBreatheFreeCravingDetail;

  /// lib/screens/why_breathefree_screen.dart: Card text for the craving card
  ///
  /// In en, this message translates to:
  /// **'Open a calming tool in one tap—available offline.'**
  String get whyBreatheFreeCravingSummary;

  /// lib/screens/why_breathefree_screen.dart: Card title, also the title of its detail sheet: when a craving hits
  ///
  /// In en, this message translates to:
  /// **'When a craving hits'**
  String get whyBreatheFreeCravingTitle;

  /// lib/screens/why_breathefree_screen.dart: Small label above the headline
  ///
  /// In en, this message translates to:
  /// **'A BETTER WAY TO QUIT'**
  String get whyBreatheFreeEyebrow;

  /// lib/screens/why_breathefree_screen.dart: Headline of the screen
  ///
  /// In en, this message translates to:
  /// **'Support for the moments that matter most.'**
  String get whyBreatheFreeHeadline;

  /// lib/screens/why_breathefree_screen.dart: Detail sheet text for the healing card
  ///
  /// In en, this message translates to:
  /// **'Track your smoke-free time and the money you chose not to spend on tobacco. Recovery milestones will be educational and will not replace medical advice.'**
  String get whyBreatheFreeHealingDetail;

  /// lib/screens/why_breathefree_screen.dart: Card text for the healing card
  ///
  /// In en, this message translates to:
  /// **'See smoke-free time, money saved, and recovery.'**
  String get whyBreatheFreeHealingSummary;

  /// lib/screens/why_breathefree_screen.dart: Card title, also the title of its detail sheet: as your body heals
  ///
  /// In en, this message translates to:
  /// **'As your body heals'**
  String get whyBreatheFreeHealingTitle;

  /// lib/screens/why_breathefree_screen.dart: Text under the headline
  ///
  /// In en, this message translates to:
  /// **'BreatheFree responds to what you need now—and helps you protect the progress you have already made.'**
  String get whyBreatheFreeIntro;

  /// lib/screens/why_breathefree_screen.dart: Button that closes a detail sheet
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get whyBreatheFreeSheetDoneButton;

  /// lib/screens/why_breathefree_screen.dart: Detail sheet text for the slip card
  ///
  /// In en, this message translates to:
  /// **'A slip does not erase the work you have already done. BreatheFree will help you record what happened without judgment and choose your next step.'**
  String get whyBreatheFreeSlipDetail;

  /// lib/screens/why_breathefree_screen.dart: Card text for the slip card
  ///
  /// In en, this message translates to:
  /// **'Keep your progress. Learn, adjust, and continue.'**
  String get whyBreatheFreeSlipSummary;

  /// lib/screens/why_breathefree_screen.dart: Card title, also the title of its detail sheet: if a slip happens
  ///
  /// In en, this message translates to:
  /// **'If a slip happens'**
  String get whyBreatheFreeSlipTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
