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

  /// lib/screens/baseline_assessment_screen.dart: AssessmentBottomAction text (line 656 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get baselineAssessmentAssessmentBottomActionText;

  /// lib/screens/baseline_assessment_screen.dart: AssessmentBottomAction text (line 676 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Your answer is saved automatically.'**
  String get baselineAssessmentAssessmentBottomActionText2;

  /// lib/screens/baseline_assessment_screen.dart: AssessmentChoice text (line 425 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get baselineAssessmentAssessmentChoiceText;

  /// lib/screens/baseline_assessment_screen.dart: AssessmentHeader label (line 228 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'About your smoking'**
  String get baselineAssessmentAssessmentHeaderBackLabel;

  /// lib/screens/baseline_assessment_screen.dart: AssessmentHeader tooltip (line 220 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get baselineAssessmentAssessmentHeaderBackTooltip;

  /// lib/screens/baseline_assessment_screen.dart: AssessmentProgress text (line 311 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'ASSESSMENT'**
  String get baselineAssessmentAssessmentProgressText;

  /// lib/screens/baseline_assessment_screen.dart: choiceLabel (line 33 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'I don’t smoke every day'**
  String get baselineAssessmentChoiceLabel;

  /// lib/screens/baseline_assessment_screen.dart: choiceLabel (line 35 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'10 or fewer cigarettes'**
  String get baselineAssessmentChoiceLabel2;

  /// lib/screens/baseline_assessment_screen.dart: choiceLabel (line 37 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'11–20 cigarettes'**
  String get baselineAssessmentChoiceLabel3;

  /// lib/screens/baseline_assessment_screen.dart: choiceLabel (line 39 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'21–30 cigarettes'**
  String get baselineAssessmentChoiceLabel4;

  /// lib/screens/baseline_assessment_screen.dart: choiceLabel (line 41 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'31 or more cigarettes'**
  String get baselineAssessmentChoiceLabel5;

  /// lib/screens/baseline_assessment_screen.dart: text (line 130 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'QUESTION 1'**
  String get baselineAssessmentText;

  /// lib/screens/baseline_assessment_screen.dart: text (line 141 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'On a typical day, how many cigarettes do you smoke?'**
  String get baselineAssessmentText2;

  /// lib/screens/baseline_assessment_screen.dart: text (line 158 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Choose the answer closest to your usual day.'**
  String get baselineAssessmentText3;

  /// lib/screens/baseline_assessment_screen.dart: WhyWeAskCard text (line 538 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Why we ask'**
  String get baselineAssessmentWhyWeAskCardText;

  /// lib/screens/baseline_assessment_screen.dart: WhyWeAskCard text (line 547 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'This helps tailor your plan and estimate money saved.'**
  String get baselineAssessmentWhyWeAskCardText2;

  /// lib/screens/baseline_assessment_screen.dart: WhyWeAskCard text (line 558 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'It is not a diagnosis or a judgment.'**
  String get baselineAssessmentWhyWeAskCardText3;

  /// lib/screens/choose_quit_path_screen.dart: description (line 175 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Prepare for 7–14 days, then stop completely on the date you choose. We’ll guide one small step each day.'**
  String get chooseQuitPathDescription;

  /// lib/screens/choose_quit_path_screen.dart: description (line 202 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Begin your smoke-free time now and get extra support through the first day.'**
  String get chooseQuitPathDescription2;

  /// lib/screens/choose_quit_path_screen.dart: description (line 223 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Follow a step-down schedule and work toward stopping completely on a future date.'**
  String get chooseQuitPathDescription3;

  /// lib/screens/choose_quit_path_screen.dart: FlexiblePathNote text (line 687 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Your path is flexible. You can adjust it at any time.'**
  String get chooseQuitPathFlexiblePathNoteText;

  /// lib/screens/choose_quit_path_screen.dart: pathLabel (line 27 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Set a quit date'**
  String get chooseQuitPathPathLabel;

  /// lib/screens/choose_quit_path_screen.dart: pathLabel (line 28 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Quit today'**
  String get chooseQuitPathPathLabel2;

  /// lib/screens/choose_quit_path_screen.dart: pathLabel (line 30 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Reduce gradually'**
  String get chooseQuitPathPathLabel3;

  /// lib/screens/choose_quit_path_screen.dart: QuitPathBottomAction text (line 759 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Continue with this path'**
  String get chooseQuitPathQuitPathBottomActionText;

  /// lib/screens/choose_quit_path_screen.dart: QuitPathHeader label (line 276 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Build your plan'**
  String get chooseQuitPathQuitPathHeaderBackLabel;

  /// lib/screens/choose_quit_path_screen.dart: QuitPathHeader tooltip (line 268 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get chooseQuitPathQuitPathHeaderBackTooltip;

  /// lib/screens/choose_quit_path_screen.dart: QuitPathHeader text (line 306 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'1 OF 5'**
  String get chooseQuitPathQuitPathHeaderText;

  /// lib/screens/choose_quit_path_screen.dart: QuitPlanProgress text (line 364 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'QUIT PLAN'**
  String get chooseQuitPathQuitPlanProgressText;

  /// lib/screens/choose_quit_path_screen.dart: recommendedLabel (line 186 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get chooseQuitPathRecommendedLabel;

  /// lib/screens/choose_quit_path_screen.dart: savedMessage (line 36 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'{path} selected · Saved automatically'**
  String chooseQuitPathSavedMessage(Object path);

  /// lib/screens/choose_quit_path_screen.dart: supportingText (line 178 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Matches your preparation preference'**
  String get chooseQuitPathSupportingText;

  /// lib/screens/choose_quit_path_screen.dart: text (line 125 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'CHOOSE YOUR PATH'**
  String get chooseQuitPathText;

  /// lib/screens/choose_quit_path_screen.dart: text (line 137 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'What feels possible right now?'**
  String get chooseQuitPathText2;

  /// lib/screens/choose_quit_path_screen.dart: text (line 154 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'There is no wrong place to start. Choose what fits you.'**
  String get chooseQuitPathText3;

  /// lib/screens/consent_privacy_screen.dart: ConsentBottomAction text (line 994 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get consentPrivacyConsentBottomActionText;

  /// lib/screens/consent_privacy_screen.dart: ConsentBottomAction text (line 1015 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'You can change optional choices anytime in Settings.'**
  String get consentPrivacyConsentBottomActionText2;

  /// lib/screens/consent_privacy_screen.dart: ConsentHeader tooltip (line 259 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get consentPrivacyConsentHeaderBackTooltip;

  /// lib/screens/consent_privacy_screen.dart: OptionalConsentCard badge (line 618 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get consentPrivacyOptionalConsentCardBadge;

  /// lib/screens/consent_privacy_screen.dart: OptionalConsentCard subtitle (line 652 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Contribute de-identified information to approved research.'**
  String get consentPrivacyOptionalConsentCardHelpImproveSubtitle;

  /// lib/screens/consent_privacy_screen.dart: OptionalConsentCard title (line 649 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Help improve BreatheFree'**
  String get consentPrivacyOptionalConsentCardHelpImproveTitle;

  /// lib/screens/consent_privacy_screen.dart: OptionalConsentCard subtitle (line 626 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Receive private check-ins and plan reminders.'**
  String get consentPrivacyOptionalConsentCardHelpfulRemindersSubtitle;

  /// lib/screens/consent_privacy_screen.dart: OptionalConsentCard title (line 625 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Helpful reminders'**
  String get consentPrivacyOptionalConsentCardHelpfulRemindersTitle;

  /// lib/screens/consent_privacy_screen.dart: OptionalConsentCard subtitle (line 639 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Allow a connected clinician to view progress summaries.'**
  String get consentPrivacyOptionalConsentCardShareCareTeamSubtitle;

  /// lib/screens/consent_privacy_screen.dart: OptionalConsentCard title (line 636 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Share with my care team'**
  String get consentPrivacyOptionalConsentCardShareCareTeamTitle;

  /// lib/screens/consent_privacy_screen.dart: OptionalConsentCard title (line 617 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'YOUR CHOICES'**
  String get consentPrivacyOptionalConsentCardTitle;

  /// lib/screens/consent_privacy_screen.dart: RequiredConsentCard badge (line 516 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get consentPrivacyRequiredConsentCardBadge;

  /// lib/screens/consent_privacy_screen.dart: RequiredConsentCard text (line 556 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Review Terms and Privacy Notice'**
  String get consentPrivacyRequiredConsentCardReviewPrivacyText;

  /// lib/screens/consent_privacy_screen.dart: RequiredConsentCard subtitle (line 526 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Save your account, quit plan, and progress securely.'**
  String get consentPrivacyRequiredConsentCardSubtitle;

  /// lib/screens/consent_privacy_screen.dart: RequiredConsentCard subtitle (line 536 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Personalize your plan, support tools, and recovery insights.'**
  String get consentPrivacyRequiredConsentCardSubtitle2;

  /// lib/screens/consent_privacy_screen.dart: RequiredConsentCard title (line 513 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'REQUIRED TO USE BREATHEFREE'**
  String get consentPrivacyRequiredConsentCardTitle;

  /// lib/screens/consent_privacy_screen.dart: RequiredConsentCard title (line 523 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Essential app data'**
  String get consentPrivacyRequiredConsentCardTitle2;

  /// lib/screens/consent_privacy_screen.dart: RequiredConsentCard title (line 535 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Health information'**
  String get consentPrivacyRequiredConsentCardTitle3;

  /// lib/screens/consent_privacy_screen.dart: showPrivacyReview text (line 98 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get consentPrivacySheetDoneText;

  /// lib/screens/consent_privacy_screen.dart: showPrivacyReview text (line 60 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Terms and Privacy Notice'**
  String get consentPrivacyShowPrivacyReviewText;

  /// lib/screens/consent_privacy_screen.dart: showPrivacyReview text (line 70 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'This development build demonstrates how the legal documents will be presented. Before release, the complete Terms of Use and Privacy Notice will appear here, including data practices, retention periods, and your rights.'**
  String get consentPrivacyShowPrivacyReviewText2;

  /// lib/screens/consent_privacy_screen.dart: showPrivacyReview text (line 80 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Optional controls can be changed later in Settings. Required processing will be limited to what is necessary to provide and secure the service.'**
  String get consentPrivacyShowPrivacyReviewText3;

  /// lib/screens/consent_privacy_screen.dart: text (line 160 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'YOUR PRIVACY'**
  String get consentPrivacyText;

  /// lib/screens/consent_privacy_screen.dart: text (line 171 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Your story stays yours.'**
  String get consentPrivacyText2;

  /// lib/screens/consent_privacy_screen.dart: text (line 184 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Choose how your information is used. Required items keep the app working; optional choices can change anytime.'**
  String get consentPrivacyText3;

  /// lib/screens/consent_privacy_screen.dart: TrustNote text (line 911 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'No ads. No tobacco-industry funding.'**
  String get consentPrivacyTrustNoteText;

  /// lib/screens/consent_privacy_screen.dart: TrustNote text (line 922 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'We never sell patient health information.'**
  String get consentPrivacyTrustNoteText2;

  /// lib/screens/my_reasons_screen.dart: CustomReasonCard (line 751 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'YOUR OWN REASON'**
  String get myReasonsCustomReasonCard;

  /// lib/screens/my_reasons_screen.dart: CustomReasonCard (line 752 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'ADD YOUR OWN REASON'**
  String get myReasonsCustomReasonCard2;

  /// lib/screens/my_reasons_screen.dart: CustomReasonCard (line 766 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Write what matters most in your own words'**
  String get myReasonsCustomReasonCard3;

  /// lib/screens/my_reasons_screen.dart: CustomReasonCard tooltip (line 793 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get myReasonsCustomReasonCardReasonCustomRemoveTooltip;

  /// lib/screens/my_reasons_screen.dart: CustomReasonCard tooltip (line 784 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Top reason'**
  String get myReasonsCustomReasonCardReasonTopCustomTooltip;

  /// lib/screens/my_reasons_screen.dart: CustomReasonEditorSheetState text (line 1128 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Make this my top reason'**
  String get myReasonsCustomReasonEditorSheetStateReasonCustomMakeTopText;

  /// lib/screens/my_reasons_screen.dart: CustomReasonEditorSheetState text (line 1155 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Save reason'**
  String get myReasonsCustomReasonEditorSheetStateReasonCustomSaveText;

  /// lib/screens/my_reasons_screen.dart: CustomReasonEditorSheetState hintText (line 1109 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'For example: I want more energy'**
  String get myReasonsCustomReasonEditorSheetStateReasonCustomTextFieldHintText;

  /// lib/screens/my_reasons_screen.dart: CustomReasonEditorSheetState text (line 1084 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Add your own reason'**
  String get myReasonsCustomReasonEditorSheetStateText;

  /// lib/screens/my_reasons_screen.dart: CustomReasonEditorSheetState text (line 1093 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Write something you want to remember when a craving hits.'**
  String get myReasonsCustomReasonEditorSheetStateText2;

  /// lib/screens/my_reasons_screen.dart: labelFor (line 57 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Protect my family'**
  String get myReasonsLabelFor;

  /// lib/screens/my_reasons_screen.dart: labelFor (line 59 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Breathe easier'**
  String get myReasonsLabelFor2;

  /// lib/screens/my_reasons_screen.dart: labelFor (line 61 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Improve my health'**
  String get myReasonsLabelFor3;

  /// lib/screens/my_reasons_screen.dart: labelFor (line 62 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Save money'**
  String get myReasonsLabelFor4;

  /// lib/screens/my_reasons_screen.dart: labelFor (line 64 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Feel more in control'**
  String get myReasonsLabelFor5;

  /// lib/screens/my_reasons_screen.dart: labelFor (line 66 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Be there for my future'**
  String get myReasonsLabelFor6;

  /// lib/screens/my_reasons_screen.dart: labelFor (line 69 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'My own reason'**
  String get myReasonsLabelFor7;

  /// lib/screens/my_reasons_screen.dart: MotivationPreview (line 890 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Choose a top reason anytime'**
  String get myReasonsMotivationPreview;

  /// lib/screens/my_reasons_screen.dart: MotivationPreview (line 893 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Based on your top reason: {topLabel}'**
  String myReasonsMotivationPreview2(Object topLabel);

  /// lib/screens/my_reasons_screen.dart: MotivationPreview text (line 845 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'MOTIVATION PREVIEW'**
  String get myReasonsMotivationPreviewReasonPreviewText;

  /// lib/screens/my_reasons_screen.dart: MotivationPreview text (line 866 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'WHEN A CRAVING HITS'**
  String get myReasonsMotivationPreviewText;

  /// lib/screens/my_reasons_screen.dart: previewFor (line 154 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Choose a reason to create your personal reminder.'**
  String get myReasonsPreviewFor;

  /// lib/screens/my_reasons_screen.dart: previewFor (line 160 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'“You chose this because ‘{value}.’ This feeling will pass.”'**
  String myReasonsPreviewFor2(Object value);

  /// lib/screens/my_reasons_screen.dart: previewFor (line 165 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'“You chose this for your family. This feeling will pass.”'**
  String get myReasonsPreviewFor3;

  /// lib/screens/my_reasons_screen.dart: previewFor (line 168 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'“You chose this to breathe easier. This feeling will pass.”'**
  String get myReasonsPreviewFor4;

  /// lib/screens/my_reasons_screen.dart: previewFor (line 171 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'“You chose this for your health. This feeling will pass.”'**
  String get myReasonsPreviewFor5;

  /// lib/screens/my_reasons_screen.dart: previewFor (line 174 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'“You chose this to save money. This feeling will pass.”'**
  String get myReasonsPreviewFor6;

  /// lib/screens/my_reasons_screen.dart: previewFor (line 177 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'“You chose this to feel in control. This feeling will pass.”'**
  String get myReasonsPreviewFor7;

  /// lib/screens/my_reasons_screen.dart: previewFor (line 180 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'“You chose this for your future. This feeling will pass.”'**
  String get myReasonsPreviewFor8;

  /// lib/screens/my_reasons_screen.dart: ReasonsBottomAction text (line 1006 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Save my reasons'**
  String get myReasonsReasonsBottomActionText;

  /// lib/screens/my_reasons_screen.dart: ReasonsHeader label (line 470 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'My reasons'**
  String get myReasonsReasonsHeaderBackLabel;

  /// lib/screens/my_reasons_screen.dart: ReasonsHeader tooltip (line 462 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get myReasonsReasonsHeaderBackTooltip;

  /// lib/screens/my_reasons_screen.dart: ReasonsHeader text (line 500 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'3 OF 5'**
  String get myReasonsReasonsHeaderText;

  /// lib/screens/my_reasons_screen.dart: ReasonsPrivacyNote text (line 928 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Your reasons stay private and only personalize your quit support.'**
  String get myReasonsReasonsPrivacyNoteText;

  /// lib/screens/my_reasons_screen.dart: ReasonsProgress text (line 560 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'QUIT PLAN'**
  String get myReasonsReasonsProgressText;

  /// lib/screens/my_reasons_screen.dart: text (line 235 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'{selectionCount} SELECTED'**
  String myReasonsSelectedCountText(Object selectionCount);

  /// lib/screens/my_reasons_screen.dart: bottom bar, reasons selected and whether a top reason is set
  ///
  /// In en, this message translates to:
  /// **'{count} reasons selected · {hasTopReason, select, true{1 top reason} other{no top reason}}'**
  String myReasonsSelectionSummary(Object count, String hasTopReason);

  /// lib/screens/my_reasons_screen.dart: text (line 214 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'SELECT ALL THAT MATTER'**
  String get myReasonsText;

  /// lib/screens/my_reasons_screen.dart: text (line 306 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'YOUR MOTIVATION'**
  String get myReasonsText2;

  /// lib/screens/my_reasons_screen.dart: text (line 316 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'What are you quitting for?'**
  String get myReasonsText3;

  /// lib/screens/my_reasons_screen.dart: text (line 333 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Choose everything that matters to you. Tap the star to make one your top reason.'**
  String get myReasonsText4;

  /// lib/screens/readiness_result_screen.dart: actionLabel (line 118 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Build my preparation plan'**
  String get readinessResultActionLabel;

  /// lib/screens/readiness_result_screen.dart: actionLabel (line 121 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Explore without setting a date'**
  String get readinessResultActionLabel2;

  /// lib/screens/readiness_result_screen.dart: actionLabel (line 125 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Find support options'**
  String get readinessResultActionLabel3;

  /// lib/screens/readiness_result_screen.dart: AlternativePaths subtitle (line 902 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Talk with a coach or care team'**
  String get readinessResultAlternativePathsPathConnectSubtitle;

  /// lib/screens/readiness_result_screen.dart: AlternativePaths title (line 901 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get readinessResultAlternativePathsPathConnectTitle;

  /// lib/screens/readiness_result_screen.dart: AlternativePaths subtitle (line 890 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Learn without setting a date'**
  String get readinessResultAlternativePathsPathExploreSubtitle;

  /// lib/screens/readiness_result_screen.dart: AlternativePaths title (line 889 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Explore first'**
  String get readinessResultAlternativePathsPathExploreTitle;

  /// lib/screens/readiness_result_screen.dart: showWhyThisFits text (line 182 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get readinessResultDoneText;

  /// lib/screens/readiness_result_screen.dart: ReadinessBottomAction text (line 1095 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'You’re in control. Change your path anytime.'**
  String get readinessResultReadinessBottomActionText;

  /// lib/screens/readiness_result_screen.dart: ReadinessHeader label (line 388 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Your starting point'**
  String get readinessResultReadinessHeaderBackLabel;

  /// lib/screens/readiness_result_screen.dart: ReadinessHeader tooltip (line 380 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get readinessResultReadinessHeaderBackTooltip;

  /// lib/screens/readiness_result_screen.dart: ReadinessHeader text (line 426 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get readinessResultReadinessHeaderText;

  /// lib/screens/readiness_result_screen.dart: ReadinessProgress text (line 486 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'ASSESSMENT'**
  String get readinessResultReadinessProgressText;

  /// lib/screens/readiness_result_screen.dart: RecommendationCard text (line 850 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Why this fits your answers'**
  String get readinessResultRecommendationCardFitText;

  /// lib/screens/readiness_result_screen.dart: RecommendationCard text (line 793 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get readinessResultRecommendationCardText;

  /// lib/screens/readiness_result_screen.dart: RecommendationCard text (line 830 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Practice coping tools and choose a quit date in the next 7–14 days. We’ll guide one small step each day.'**
  String get readinessResultRecommendationCardText2;

  /// lib/screens/readiness_result_screen.dart: RecommendationCard title (line 749 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get readinessResultRecommendationCardTitle;

  /// lib/screens/readiness_result_screen.dart: ReflectionCard label (line 638 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'YOUR PATTERN'**
  String get readinessResultReflectionCardLabel;

  /// lib/screens/readiness_result_screen.dart: ReflectionCard label (line 646 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'TRIGGERS'**
  String get readinessResultReflectionCardLabel2;

  /// lib/screens/readiness_result_screen.dart: ReflectionCard label (line 654 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'STARTING POINT'**
  String get readinessResultReflectionCardLabel3;

  /// lib/screens/readiness_result_screen.dart: showWhyThisFits text (line 144 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Why preparation may fit'**
  String get readinessResultShowWhyThisFitsText;

  /// lib/screens/readiness_result_screen.dart: showWhyThisFits text (line 154 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'You identified your smoking pattern and situations that may bring on an urge. Practicing coping tools before choosing a date can make the next step feel more manageable.'**
  String get readinessResultShowWhyThisFitsText2;

  /// lib/screens/readiness_result_screen.dart: showWhyThisFits text (line 164 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'This is a flexible recommendation, not a medical assessment. You can choose another path now or change it later.'**
  String get readinessResultShowWhyThisFitsText3;

  /// lib/screens/readiness_result_screen.dart: starting point summary, number of situations
  ///
  /// In en, this message translates to:
  /// **'You identified {count} {count, plural, =1{situation} other{situations}} to prepare for'**
  String readinessResultSituationCount(int count);

  /// lib/screens/readiness_result_screen.dart: startingPointSummary (line 107 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'You can start small and add details later'**
  String get readinessResultStartingPointSummary;

  /// lib/screens/readiness_result_screen.dart: text (line 276 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'YOUR REFLECTION'**
  String get readinessResultText;

  /// lib/screens/readiness_result_screen.dart: text (line 286 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'You’re ready to prepare—at your own pace.'**
  String get readinessResultText2;

  /// lib/screens/readiness_result_screen.dart: text (line 303 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Here is what we heard from your answers.'**
  String get readinessResultText3;

  /// lib/screens/readiness_result_screen.dart: text (line 332 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'YOU CAN CHOOSE A DIFFERENT PATH'**
  String get readinessResultText4;

  /// lib/screens/readiness_result_screen.dart: triggerLabel (line 56 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'stress'**
  String get readinessResultTriggerLabel;

  /// lib/screens/readiness_result_screen.dart: triggerLabel (line 68 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'before bed'**
  String get readinessResultTriggerLabel10;

  /// lib/screens/readiness_result_screen.dart: triggerLabel (line 58 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'after meals'**
  String get readinessResultTriggerLabel2;

  /// lib/screens/readiness_result_screen.dart: triggerLabel (line 59 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'driving'**
  String get readinessResultTriggerLabel3;

  /// lib/screens/readiness_result_screen.dart: triggerLabel (line 60 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'coffee'**
  String get readinessResultTriggerLabel4;

  /// lib/screens/readiness_result_screen.dart: triggerLabel (line 62 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'social settings'**
  String get readinessResultTriggerLabel5;

  /// lib/screens/readiness_result_screen.dart: triggerLabel (line 64 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'work breaks'**
  String get readinessResultTriggerLabel6;

  /// lib/screens/readiness_result_screen.dart: triggerLabel (line 65 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'alcohol'**
  String get readinessResultTriggerLabel7;

  /// lib/screens/readiness_result_screen.dart: triggerLabel (line 66 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'boredom'**
  String get readinessResultTriggerLabel8;

  /// lib/screens/readiness_result_screen.dart: triggerLabel (line 67 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'mornings'**
  String get readinessResultTriggerLabel9;

  /// lib/screens/readiness_result_screen.dart: triggerSummary (line 84 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'You can identify triggers anytime'**
  String get readinessResultTriggerSummary;

  /// lib/screens/readiness_result_screen.dart: triggerSummary (line 89 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'You want support for {first}'**
  String readinessResultTriggerSummary2(Object first);

  /// lib/screens/readiness_result_screen.dart: triggerSummary (line 94 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'You want support for {first} and {last}'**
  String readinessResultTriggerSummary3(Object first, Object last);

  /// lib/screens/readiness_result_screen.dart: triggerSummary (line 99 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'{value}, {value2}, and {remaining} more'**
  String readinessResultTriggerSummary4(
      Object value, Object value2, Object remaining);

  /// lib/screens/readiness_result_screen.dart: usageLabel (line 35 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'You do not smoke every day'**
  String get readinessResultUsageLabel;

  /// lib/screens/readiness_result_screen.dart: usageLabel (line 36 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'10 or fewer cigarettes on a typical day'**
  String get readinessResultUsageLabel2;

  /// lib/screens/readiness_result_screen.dart: usageLabel (line 39 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'11–20 cigarettes on a typical day'**
  String get readinessResultUsageLabel3;

  /// lib/screens/readiness_result_screen.dart: usageLabel (line 42 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'21–30 cigarettes on a typical day'**
  String get readinessResultUsageLabel4;

  /// lib/screens/readiness_result_screen.dart: usageLabel (line 45 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'31 or more cigarettes on a typical day'**
  String get readinessResultUsageLabel5;

  /// lib/screens/readiness_result_screen.dart: usageLabel (line 48 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'You can add your smoking pattern anytime'**
  String get readinessResultUsageLabel6;

  /// lib/screens/select_quit_date_screen.dart: CheckInCard text (line 1207 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Quit-day check-in'**
  String get selectQuitDateCheckInCardText;

  /// lib/screens/select_quit_date_screen.dart: CheckInCard text (line 1215 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'7:00 AM · Private notification'**
  String get selectQuitDateCheckInCardText2;

  /// lib/screens/select_quit_date_screen.dart: CheckInCard text (line 1270 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Lock screen only shows: “You have a check-in.”'**
  String get selectQuitDateCheckInCardText3;

  /// lib/screens/select_quit_date_screen.dart: continueLabel (line 234 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Confirm this date'**
  String get selectQuitDateContinueLabel;

  /// lib/screens/select_quit_date_screen.dart: continueLabel (line 236 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Start my quit today'**
  String get selectQuitDateContinueLabel2;

  /// lib/screens/select_quit_date_screen.dart: continueLabel (line 238 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Confirm target date'**
  String get selectQuitDateContinueLabel3;

  /// lib/screens/select_quit_date_screen.dart: DateBottomAction text (line 1409 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Date saved automatically'**
  String get selectQuitDateDateBottomActionText;

  /// lib/screens/select_quit_date_screen.dart: DateHeader tooltip (line 556 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get selectQuitDateDateHeaderBackTooltip;

  /// lib/screens/select_quit_date_screen.dart: DateHeader text (line 593 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'2 OF 5'**
  String get selectQuitDateDateHeaderText;

  /// lib/screens/select_quit_date_screen.dart: dateLabel (line 210 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'YOUR QUIT DATE'**
  String get selectQuitDateDateLabel;

  /// lib/screens/select_quit_date_screen.dart: dateLabel (line 212 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'YOUR QUIT DATE IS TODAY'**
  String get selectQuitDateDateLabel2;

  /// lib/screens/select_quit_date_screen.dart: dateLabel (line 214 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'YOUR TARGET DATE'**
  String get selectQuitDateDateLabel3;

  /// lib/screens/select_quit_date_screen.dart: DateProgress text (line 653 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'QUIT PLAN'**
  String get selectQuitDateDateProgressText;

  /// lib/screens/select_quit_date_screen.dart: description (line 179 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'A date 7–14 days away gives you time to prepare without losing momentum.'**
  String get selectQuitDateDescription;

  /// lib/screens/select_quit_date_screen.dart: description (line 182 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Your smoke-free time begins today. We’ll add extra support through your first day.'**
  String get selectQuitDateDescription2;

  /// lib/screens/select_quit_date_screen.dart: description (line 185 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'A target 14–30 days away gives you time to reduce gradually with a clear goal.'**
  String get selectQuitDateDescription3;

  /// lib/screens/select_quit_date_screen.dart: FlexibleDateNote text (line 1304 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'You can change this date later without losing progress.'**
  String get selectQuitDateFlexibleDateNoteText;

  /// lib/screens/select_quit_date_screen.dart: headerTitle (line 156 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Choose your quit date'**
  String get selectQuitDateHeaderTitle;

  /// lib/screens/select_quit_date_screen.dart: headerTitle (line 160 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Start your quit today'**
  String get selectQuitDateHeaderTitle2;

  /// lib/screens/select_quit_date_screen.dart: headerTitle (line 161 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Choose your target date'**
  String get selectQuitDateHeaderTitle3;

  /// lib/screens/select_quit_date_screen.dart: selected date card, full date
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {month} {day}, {year}'**
  String selectQuitDateLongDate(
      Object weekday, Object month, Object day, Object year);

  /// lib/screens/select_quit_date_screen.dart: full month name, chosen by month key (january…december)
  ///
  /// In en, this message translates to:
  /// **'{month, select, january{January} february{February} march{March} april{April} may{May} june{June} july{July} august{August} september{September} october{October} november{November} december{December} other{}}'**
  String selectQuitDateMonthName(String month);

  /// lib/screens/select_quit_date_screen.dart: short month name, chosen by month key
  ///
  /// In en, this message translates to:
  /// **'{month, select, january{Jan} february{Feb} march{Mar} april{Apr} may{May} june{Jun} july{Jul} august{Aug} september{Sep} october{Oct} november{Nov} december{Dec} other{}}'**
  String selectQuitDateMonthShort(String month);

  /// lib/screens/select_quit_date_screen.dart: calendar month heading
  ///
  /// In en, this message translates to:
  /// **'{month} {year}'**
  String selectQuitDateMonthYear(Object month, Object year);

  /// lib/screens/select_quit_date_screen.dart: recommended window across two months
  ///
  /// In en, this message translates to:
  /// **'{startMonth} {start} – {endMonth} {end}'**
  String selectQuitDateRange(
      Object startMonth, Object start, Object endMonth, Object end);

  /// lib/screens/select_quit_date_screen.dart: recommended window within one month
  ///
  /// In en, this message translates to:
  /// **'{month} {start}–{end}'**
  String selectQuitDateRangeSameMonth(Object month, Object start, Object end);

  /// lib/screens/select_quit_date_screen.dart: SelectedDateCard text (line 1126 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get selectQuitDateSelectedDateCardUnavailableText;

  /// lib/screens/select_quit_date_screen.dart: text (line 432 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'YOUR DATE'**
  String get selectQuitDateText;

  /// lib/screens/select_quit_date_screen.dart: timingLabel (line 220 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Starting today'**
  String get selectQuitDateTimingLabel;

  /// lib/screens/select_quit_date_screen.dart: timingLabel (line 223 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'{days} days to reduce gradually'**
  String selectQuitDateTimingLabel2(Object days);

  /// lib/screens/select_quit_date_screen.dart: timingLabel (line 226 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'{days} days to prepare'**
  String selectQuitDateTimingLabel3(Object days);

  /// lib/screens/select_quit_date_screen.dart: title (line 167 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Choose a day to begin.'**
  String get selectQuitDateTitle;

  /// lib/screens/select_quit_date_screen.dart: title (line 170 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Today is your starting point.'**
  String get selectQuitDateTitle2;

  /// lib/screens/select_quit_date_screen.dart: title (line 173 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Choose the day to become smoke-free.'**
  String get selectQuitDateTitle3;

  /// lib/screens/select_quit_date_screen.dart: selected date card when the saved date is outside the allowed window (QuitDateCopy)
  ///
  /// In en, this message translates to:
  /// **'This date is no longer available. Choose a new date.'**
  String get selectQuitDateUnavailableMessage;

  /// lib/screens/select_quit_date_screen.dart: calendar weekday initial, chosen by weekday key
  ///
  /// In en, this message translates to:
  /// **'{weekday, select, sunday{S} monday{M} tuesday{T} wednesday{W} thursday{T} friday{F} saturday{S} other{}}'**
  String selectQuitDateWeekdayInitial(String weekday);

  /// lib/screens/select_quit_date_screen.dart: weekday name, chosen by weekday key (monday…sunday)
  ///
  /// In en, this message translates to:
  /// **'{weekday, select, monday{Monday} tuesday{Tuesday} wednesday{Wednesday} thursday{Thursday} friday{Friday} saturday{Saturday} sunday{Sunday} other{}}'**
  String selectQuitDateWeekdayName(String weekday);

  /// lib/screens/select_quit_date_screen.dart: windowMessage (line 192 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Today is selected based on your path'**
  String get selectQuitDateWindowMessage;

  /// lib/screens/select_quit_date_screen.dart: windowMessage (line 198 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Recommended preparation window: {range}'**
  String selectQuitDateWindowMessage2(Object range);

  /// lib/screens/select_quit_date_screen.dart: windowMessage (line 201 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Recommended reduction window: {range}'**
  String selectQuitDateWindowMessage3(Object range);

  /// lib/screens/trigger_map_screen.dart: CustomTriggerCard (line 694 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'YOUR TRIGGER'**
  String get triggerMapCustomTriggerCard;

  /// lib/screens/trigger_map_screen.dart: CustomTriggerCard (line 695 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'ADD YOUR OWN TRIGGER'**
  String get triggerMapCustomTriggerCard2;

  /// lib/screens/trigger_map_screen.dart: CustomTriggerCard (line 709 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Type another situation…'**
  String get triggerMapCustomTriggerCard3;

  /// lib/screens/trigger_map_screen.dart: CustomTriggerCard tooltip (line 722 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get triggerMapCustomTriggerCardCustomRemoveTooltip;

  /// lib/screens/trigger_map_screen.dart: CustomTriggerEditorSheetState hintText (line 396 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'For example, phone calls'**
  String get triggerMapCustomTriggerEditorSheetStateCustomInputHintText;

  /// lib/screens/trigger_map_screen.dart: CustomTriggerEditorSheetState labelText (line 395 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'My trigger'**
  String get triggerMapCustomTriggerEditorSheetStateCustomInputLabelText;

  /// lib/screens/trigger_map_screen.dart: CustomTriggerEditorSheetState text (line 419 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Save trigger'**
  String get triggerMapCustomTriggerEditorSheetStateCustomSaveText;

  /// lib/screens/trigger_map_screen.dart: CustomTriggerEditorSheetState text (line 368 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Add your own trigger'**
  String get triggerMapCustomTriggerEditorSheetStateText;

  /// lib/screens/trigger_map_screen.dart: CustomTriggerEditorSheetState text (line 378 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Enter a situation, feeling, or routine that makes you want to smoke.'**
  String get triggerMapCustomTriggerEditorSheetStateText2;

  /// lib/screens/trigger_map_screen.dart: labelFor (line 48 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get triggerMapLabelFor;

  /// lib/screens/trigger_map_screen.dart: labelFor (line 60 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Before bed'**
  String get triggerMapLabelFor10;

  /// lib/screens/trigger_map_screen.dart: labelFor (line 50 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'After meals'**
  String get triggerMapLabelFor2;

  /// lib/screens/trigger_map_screen.dart: labelFor (line 51 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get triggerMapLabelFor3;

  /// lib/screens/trigger_map_screen.dart: labelFor (line 52 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'With coffee'**
  String get triggerMapLabelFor4;

  /// lib/screens/trigger_map_screen.dart: labelFor (line 54 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Social settings'**
  String get triggerMapLabelFor5;

  /// lib/screens/trigger_map_screen.dart: labelFor (line 56 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Work breaks'**
  String get triggerMapLabelFor6;

  /// lib/screens/trigger_map_screen.dart: labelFor (line 57 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get triggerMapLabelFor7;

  /// lib/screens/trigger_map_screen.dart: labelFor (line 58 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Boredom'**
  String get triggerMapLabelFor8;

  /// lib/screens/trigger_map_screen.dart: labelFor (line 59 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get triggerMapLabelFor9;

  /// lib/screens/trigger_map_screen.dart: question label above the triggers (line 193 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'QUESTION 2 · CHOOSE ALL THAT APPLY'**
  String get triggerMapQuestionLabel;

  /// lib/screens/trigger_map_screen.dart: bottom bar, number of triggers selected
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{trigger selected} other{triggers selected}} · Saved automatically'**
  String triggerMapSelectionCount(int count);

  /// lib/screens/trigger_map_screen.dart: text (line 204 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'When are you most likely to want a cigarette?'**
  String get triggerMapText2;

  /// lib/screens/trigger_map_screen.dart: text (line 221 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Choose every situation that feels true for you.'**
  String get triggerMapText3;

  /// lib/screens/trigger_map_screen.dart: TriggerBottomAction text (line 925 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get triggerMapTriggerBottomActionText;

  /// lib/screens/trigger_map_screen.dart: TriggerHeader label (line 450 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Your triggers'**
  String get triggerMapTriggerHeaderBackLabel;

  /// lib/screens/trigger_map_screen.dart: TriggerHeader tooltip (line 442 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get triggerMapTriggerHeaderBackTooltip;

  /// lib/screens/trigger_map_screen.dart: TriggerPrivacyNote text (line 799 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Used to prepare, not to monitor'**
  String get triggerMapTriggerPrivacyNoteText;

  /// lib/screens/trigger_map_screen.dart: TriggerPrivacyNote text (line 810 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Your choices shape coping tools and reminder timing.'**
  String get triggerMapTriggerPrivacyNoteText2;

  /// lib/screens/trigger_map_screen.dart: TriggerPrivacyNote text (line 821 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'BreatheFree does not track your location in the background.'**
  String get triggerMapTriggerPrivacyNoteText3;

  /// lib/screens/trigger_map_screen.dart: TriggerProgress text (line 539 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'ASSESSMENT'**
  String get triggerMapTriggerProgressText;

  /// lib/screens/welcome_screen.dart: Benefits subtitle (line 680 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Quick tools that work anywhere'**
  String get welcomeBenefitsSubtitle;

  /// lib/screens/welcome_screen.dart: Benefits subtitle (line 689 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'A slip never erases your wins'**
  String get welcomeBenefitsSubtitle2;

  /// lib/screens/welcome_screen.dart: Benefits title (line 679 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Help when cravings hit'**
  String get welcomeBenefitsTitle;

  /// lib/screens/welcome_screen.dart: Benefits title (line 688 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Progress that stays'**
  String get welcomeBenefitsTitle2;

  /// lib/screens/welcome_screen.dart: headline (line 123 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Your next breath can be different.'**
  String get welcomeHeadline;

  /// lib/screens/welcome_screen.dart: LegalText text (line 788 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to the '**
  String get welcomeLegalText;

  /// lib/screens/welcome_screen.dart: LegalText text (line 803 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get welcomeLegalText2;

  /// lib/screens/welcome_screen.dart: LegalText text (line 806 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **' and acknowledge the '**
  String get welcomeLegalText3;

  /// lib/screens/welcome_screen.dart: LegalText text (line 819 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice.'**
  String get welcomeLegalText4;

  /// lib/screens/welcome_screen.dart: message (line 263 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'The final Terms of Use will be published before production distribution.'**
  String get welcomeMessage;

  /// lib/screens/welcome_screen.dart: message (line 271 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'BreatheFree will clearly explain what data is collected, why it is needed, and how to delete it.'**
  String get welcomeMessage2;

  /// lib/screens/welcome_screen.dart: showInformationSheet text (line 64 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get welcomeShowInformationSheetText;

  /// lib/screens/welcome_screen.dart: text (line 211 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get welcomeSignInText;

  /// lib/screens/welcome_screen.dart: text (line 109 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'WELCOME TO BREATHEFREE'**
  String get welcomeText;

  /// lib/screens/welcome_screen.dart: text (line 154 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Small steps, practical support, and no judgment—whenever you are ready.'**
  String get welcomeText2;

  /// lib/screens/welcome_screen.dart: text (line 189 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeText3;

  /// lib/screens/welcome_screen.dart: text (line 247 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Continuar en español'**
  String get welcomeText4;

  /// lib/screens/welcome_screen.dart: title (line 262 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get welcomeTitle;

  /// lib/screens/welcome_screen.dart: title (line 268 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice'**
  String get welcomeTitle2;

  /// lib/screens/why_breathefree_screen.dart: WhyBottomAction text (line 695 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get whyBreatheFreeBottomActionText;

  /// lib/screens/why_breathefree_screen.dart: WhyBreatheFreeScreen subtitle (line 202 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Open a calming tool in one tap—available offline.'**
  String get whyBreatheFreeCardCravingSubtitle;

  /// lib/screens/why_breathefree_screen.dart: WhyBreatheFreeScreen title (line 199 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'When a craving hits'**
  String get whyBreatheFreeCardCravingTitle;

  /// lib/screens/why_breathefree_screen.dart: WhyBreatheFreeScreen subtitle (line 227 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'See smoke-free time, money saved, and recovery.'**
  String get whyBreatheFreeCardHealingSubtitle;

  /// lib/screens/why_breathefree_screen.dart: WhyBreatheFreeScreen title (line 224 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'As your body heals'**
  String get whyBreatheFreeCardHealingTitle;

  /// lib/screens/why_breathefree_screen.dart: WhyBreatheFreeScreen subtitle (line 253 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Keep your progress. Learn, adjust, and continue.'**
  String get whyBreatheFreeCardSlipSubtitle;

  /// lib/screens/why_breathefree_screen.dart: WhyBreatheFreeScreen title (line 250 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'If a slip happens'**
  String get whyBreatheFreeCardSlipTitle;

  /// lib/screens/why_breathefree_screen.dart: WhyHeader tooltip (line 312 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get whyBreatheFreeHeaderBackTooltip;

  /// lib/screens/why_breathefree_screen.dart: WhyBreatheFreeScreen headline (line 150 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Support for the moments that matter most.'**
  String get whyBreatheFreeHeadline;

  /// lib/screens/why_breathefree_screen.dart: WhyBreatheFreeScreen message (line 210 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Use guided breathing, a brief distraction, or your top reason for quitting. Essential tools will remain available offline.'**
  String get whyBreatheFreeMessage;

  /// lib/screens/why_breathefree_screen.dart: WhyBreatheFreeScreen message (line 235 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Track your smoke-free time and the money you chose not to spend on tobacco. Recovery milestones will be educational and will not replace medical advice.'**
  String get whyBreatheFreeMessage2;

  /// lib/screens/why_breathefree_screen.dart: WhyBreatheFreeScreen message (line 261 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'A slip does not erase the work you have already done. BreatheFree will help you record what happened without judgment and choose your next step.'**
  String get whyBreatheFreeMessage3;

  /// lib/screens/why_breathefree_screen.dart: WhyBreatheFreeScreen showCardDetails text (line 74 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get whyBreatheFreeSheetDoneText;

  /// lib/screens/why_breathefree_screen.dart: WhyBreatheFreeScreen text (line 136 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'A BETTER WAY TO QUIT'**
  String get whyBreatheFreeText;

  /// lib/screens/why_breathefree_screen.dart: WhyBreatheFreeScreen text (line 181 at 97d81ce)
  ///
  /// In en, this message translates to:
  /// **'BreatheFree responds to what you need now—and helps you protect the progress you have already made.'**
  String get whyBreatheFreeText2;
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
