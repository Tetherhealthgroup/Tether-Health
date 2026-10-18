// GENERATED — route names for every screen and state in spec/screens.json.
abstract final class Routes {
  /// Welcome
  static const welcome = '/welcome';
  /// Choose programs
  static const obPrograms = '/onboarding/programs';
  /// Focus slots
  static const obFocus = '/onboarding/focus';
  /// Third program sheet
  static const obThird = '/onboarding/focus/third';
  /// Layered consent
  static const obConsent = '/onboarding/consent';
  /// Shared basics
  static const obBasics = '/onboarding/basics';
  /// Set up focus programs
  static const obSetup = '/onboarding/setup';
  /// Reminder prime
  static const obReminders = '/onboarding/reminders';
  /// Reminders denied (permission denied)
  static const obRemindersDenied = '/onboarding/reminders?state=denied';
  /// Save your progress
  static const obAccount = '/onboarding/account';
  /// Verify email
  static const authVerify = '/auth/verify';
  /// Sign in
  static const authSignin = '/auth/signin';
  /// Sign-in error (error)
  static const authSigninError = '/auth/signin?state=error';
  /// New account from Apple or Google
  static const authSocialNew = '/auth/social/new';
  /// Link accounts
  static const authLink = '/auth/link';
  /// Apple / Google sign-in failed
  static const authSocialError = '/auth/social/error';
  /// Reset password
  static const authForgot = '/auth/forgot';
  /// Reset link sent
  static const authForgotSent = '/auth/forgot/sent';
  /// Set new password
  static const authNewpass = '/auth/reset';
  /// Guest plan merge
  static const authMerge = '/auth/merge';
  /// Session expired
  static const authSession = '/auth/session';
  /// Today
  static const today = '/today';
  /// Today · loading (loading)
  static const todayLoading = '/today?state=loading';
  /// Today · offline (offline)
  static const todayOffline = '/today?state=offline';
  /// Today · nothing in focus (empty)
  static const todayEmpty = '/today?state=empty';
  /// Today · safety pinned (safety)
  static const todaySafety = '/today?state=safety';
  /// Daily check-in
  static const checkin = '/check-in';
  /// Check-in saved
  static const checkinDone = '/check-in/done';
  /// Rescue
  static const rescuePick = '/rescue';
  /// Active tool
  static const rescueActive = '/rescue/breathing';
  /// Switch tool
  static const rescueTools = '/rescue/tools';
  /// Recheck + result
  static const rescueResult = '/rescue/result';
  /// Add a person
  static const rescueEscalate = '/rescue/escalate';
  /// Crisis support
  static const crisis = '/crisis';
  /// My plans
  static const plans = '/plans';
  /// Add a program
  static const catalog = '/programs';
  /// Focus slots full
  static const focusFull = '/programs/focus-full';
  /// Program settings
  static const programSettings = '/p/:program/settings';
  /// Progress
  static const progress = '/progress';
  /// Progress · empty (empty)
  static const progressEmpty = '/progress?state=empty';
  /// Progress · error (error)
  static const progressError = '/progress?state=error';
  /// Learn
  static const learn = '/learn';
  /// Learn · error (error)
  static const learnError = '/learn?state=error';
  /// Lesson
  static const learnLesson = '/learn/:lesson';
  /// Support
  static const support = '/support';
  /// Support · empty (empty)
  static const supportEmpty = '/support?state=empty';
  /// Request call-back
  static const supportCallback = '/support/callback';
  /// Preview message
  static const supportMessage = '/support/message';
  /// Message care team
  static const supportMessageCare = '/support/care-team';
  /// Add a supporter
  static const supportAddPerson = '/support/people/new';
  /// Connect a clinic
  static const supportConnect = '/support/connect';
  /// Account
  static const account = '/account';
  /// Sign-in methods
  static const accountSigninMethods = '/account/sign-in';
  /// Programs & sharing
  static const accountPrograms = '/account/programs';
  /// Leave a program
  static const accountLeave = '/account/programs/leave';
  /// Notifications
  static const accountNotifications = '/account/notifications';
  /// Privacy & consent
  static const accountPrivacy = '/account/privacy';
  /// Your data
  static const accountData = '/account/data';
  /// Delete account
  static const accountDelete = '/account/delete';
  /// Deletion receipt
  static const accountDeleted = '/account/deleted';
  /// Sign out
  static const accountSignout = '/account/signout';
  /// Update required
  static const sysUpdate = '/system/update';
  /// BreatheFree intro
  static const bfIntro = '/p/bf';
  /// Baseline: amount
  static const bfQ1 = '/p/bf/onboarding/1';
  /// Baseline: triggers
  static const bfQ2 = '/p/bf/onboarding/2';
  /// Baseline: reasons
  static const bfQ3 = '/p/bf/onboarding/3';
  /// Choose path
  static const bfPath = '/p/bf/plan/path';
  /// Select quit date
  static const bfDate = '/p/bf/plan/date';
  /// Step-down schedule
  static const bfStepdown = '/p/bf/plan/reduce';
  /// Support & preparation
  static const bfSupport = '/p/bf/plan/support';
  /// Review plan
  static const bfReview = '/p/bf/plan/review';
  /// BreatheFree home
  static const bfHome = '/p/bf/home';
  /// BreatheFree · quit day (quit day)
  static const bfHomeQuitday = '/p/bf/home?state=quit-day';
  /// BreatheFree · explore (explore)
  static const bfHomeExplore = '/p/bf/home?state=explore';
  /// Slip recovery
  static const bfSlip = '/p/bf/slip';
  /// Medication center
  static const bfMeds = '/p/bf/meds';
  /// Edit recorded plan
  static const bfMedsEdit = '/p/bf/meds/edit';
  /// BreatheFree progress
  static const bfProgress = '/p/bf/progress';
  /// How estimates work
  static const bfEstimates = '/p/bf/progress/estimates';
  /// ScrollFree intro
  static const sfIntro = '/p/sf';
  /// Baseline: use
  static const sfQ1 = '/p/sf/onboarding/1';
  /// Baseline: triggers
  static const sfQ2 = '/p/sf/onboarding/2';
  /// Goal & windows
  static const sfGoal = '/p/sf/plan/goal';
  /// Connect Screen Time
  static const sfScreentime = '/p/sf/screen-time';
  /// Screen Time denied (permission denied)
  static const sfScreentimeDenied = '/p/sf/screen-time?state=denied';
  /// Accountability buddy
  static const sfBuddy = '/p/sf/plan/buddy';
  /// ScrollFree home
  static const sfHome = '/p/sf/home';
  /// Pause 60
  static const sfPause = '/p/sf/pause';
  /// Long-scroll recovery
  static const sfSlip = '/p/sf/slip';
  /// Weekly reflection
  static const sfWeek = '/p/sf/week';
  /// ClearAir intro
  static const caIntro = '/p/ca';
  /// Diagnosis & plan
  static const caQ1 = '/p/ca/onboarding/1';
  /// Enter action plan
  static const caPlan = '/p/ca/plan';
  /// No action plan yet (empty)
  static const caNoplan = '/p/ca/plan?state=none';
  /// ClearAir home
  static const caHome = '/p/ca/home';
  /// Zone check
  static const caZone = '/p/ca/zone';
  /// Yellow zone
  static const caYellow = '/p/ca/zone/yellow';
  /// Red zone
  static const caRed = '/p/ca/zone/red';
  /// Symptom log
  static const caSymptoms = '/p/ca/symptoms';
  /// ClearAir progress
  static const caProgress = '/p/ca/progress';
  /// Heartwise intro
  static const hwIntro = '/p/hw';
  /// Baseline
  static const hwQ1 = '/p/hw/onboarding/1';
  /// Clinician targets
  static const hwTargets = '/p/hw/plan/targets';
  /// Heartwise home
  static const hwHome = '/p/hw/home';
  /// Log BP · reading 1
  static const hwLog = '/p/hw/log';
  /// Log BP · reading 2
  static const hwLog2 = '/p/hw/log/2';
  /// Log BP · validation (error)
  static const hwLogError = '/p/hw/log/2?state=error';
  /// Reading saved
  static const hwResult = '/p/hw/log/result';
  /// Crisis range
  static const hwCrisis = '/p/hw/crisis';
  /// Re-check timer
  static const hwRecheck = '/p/hw/crisis/recheck';
  /// Trends
  static const hwTrends = '/p/hw/trends';
  /// Cholesterol panel
  static const hwLipids = '/p/hw/lipids';
  /// Visit summary
  static const hwSummary = '/p/hw/summary';
  /// Steady intro
  static const stIntro = '/p/st';
  /// Type & device
  static const stQ1 = '/p/st/onboarding/1';
  /// Range & low plan
  static const stRange = '/p/st/plan/range';
  /// Steady home
  static const stHome = '/p/st/home';
  /// Log reading
  static const stLog = '/p/st/log';
  /// Low reading
  static const stLow = '/p/st/low';
  /// Meal energy reset
  static const stReset = '/p/st/reset';
  /// Patterns
  static const stPatterns = '/p/st/patterns';
  /// A1C
  static const stA1c = '/p/st/a1c';
  /// Renew intro
  static const reIntro = '/p/re';
  /// Risk check
  static const reQ1 = '/p/re/onboarding/1';
  /// Risk result
  static const reResult = '/p/re/plan';
  /// Renew home
  static const reHome = '/p/re/home';
  /// Add labs
  static const reLabs = '/p/re/labs';
  /// Lab history
  static const reHistory = '/p/re/history';
  /// Symptom check
  static const reSymptoms = '/p/re/symptoms';
  /// Nourish intro
  static const nuIntro = '/p/nu';
  /// Goals & screen
  static const nuQ1 = '/p/nu/onboarding/1';
  /// Weekly habit
  static const nuHabit = '/p/nu/plan';
  /// Nourish home
  static const nuHome = '/p/nu/home';
  /// Off-track reset
  static const nuReset = '/p/nu/reset';
  /// Week 4 milestone
  static const nuWeek4 = '/p/nu/milestone';
  /// Protective mode
  static const nuProtect = '/p/nu/support';
  /// Stride intro
  static const sdIntro = '/p/sd';
  /// Falls check
  static const sdQ1 = '/p/sd/onboarding/1';
  /// Movement plan
  static const sdPlan = '/p/sd/plan';
  /// Stride home
  static const sdHome = '/p/sd/home';
  /// Session player
  static const sdSession = '/p/sd/session';
  /// I fell
  static const sdFell = '/p/sd/fell';
  /// Home safety
  static const sdSafety = '/p/sd/safety';
  /// Caregiver access
  static const sdCaregiver = '/p/sd/caregiver';
  /// Ease intro
  static const eaIntro = '/p/ea';
  /// Optional screener
  static const eaQ1 = '/p/ea/onboarding/1';
  /// Screener result
  static const eaResult = '/p/ea/result';
  /// Safety plan
  static const eaPlan = '/p/ea/plan';
  /// Ease home
  static const eaHome = '/p/ea/home';
  /// Mood check-in
  static const eaMood = '/p/ea/mood';
  /// Check-back day
  static const eaCheckback = '/p/ea/check-back';
  /// Checkup intro
  static const ckIntro = '/p/ck';
  /// About you
  static const ckQ1 = '/p/ck/onboarding/1';
  /// Due list
  static const ckList = '/p/ck/home';
  /// Up to date (empty)
  static const ckUptodate = '/p/ck/home?state=empty';
  /// Item detail
  static const ckItem = '/p/ck/item/:id';
  /// Mark done
  static const ckDone = '/p/ck/done';
  /// Screening day
  static const ckDay = '/p/ck/day';
  /// Beacon intro
  static const beIntro = '/p/be';
  /// Journey stage
  static const beQ1 = '/p/be/onboarding/1';
  /// Family history
  static const beQ2 = '/p/be/onboarding/2';
  /// Beacon home
  static const beHome = '/p/be/home';
  /// Treatment support
  static const beTx = '/p/be/treatment';
  /// Treatment diary
  static const beDiary = '/p/be/diary';
  /// Visit questions
  static const beQuestions = '/p/be/questions';
  /// Survivorship
  static const beSurvivor = '/p/be/survivorship';
  /// Health records
  static const recordsHub = '/records';
  /// Health records · empty (empty)
  static const recordsHubEmpty = '/records?state=empty';
  /// Add a source
  static const recordsAdd = '/records/add';
  /// Find your provider
  static const recordsSearch = '/records/search';
  /// Other FHIR server
  static const recordsFhirUrl = '/records/fhir-url';
  /// Consent: Epic
  static const recordsConsent = '/records/consent';
  /// Consent: Medicare (Medicare)
  static const recordsConsentBb = '/records/consent?source=medicare';
  /// Consent: phone health data (Apple Health / Health Connect)
  static const recordsConsentDevice = '/records/consent?source=device';
  /// Importing
  static const recordsImporting = '/records/importing';
  /// Review imported data
  static const recordsReview = '/records/review';
  /// Resolve conflicts
  static const recordsConflict = '/records/conflicts';
  /// Connection problem
  static const recordsError = '/records/error';
  /// Source details
  static const recordsSource = '/records/source';
  /// Disconnect source
  static const recordsDisconnect = '/records/source/disconnect';
  /// Enter a value
  static const recordsManual = '/records/manual';
  /// Enter a value · out of range (error)
  static const recordsManualError = '/records/manual?state=error';
  /// Imported values
  static const recordsItem = '/records/item';
  /// Unplug intro
  static const sfUnplugIntro = '/p/sf/unplug';
  /// Allow Screen Time
  static const sfUnplugAuth = '/p/sf/unplug/permission';
  /// Screen Time not allowed (permission denied)
  static const sfUnplugAuthDenied = '/p/sf/unplug/permission?state=denied';
  /// Screen Time unavailable (unavailable)
  static const sfUnplugAuthUnavailable = '/p/sf/unplug/permission?state=unavailable';
  /// Notifications off (notifications off)
  static const sfUnplugAuthNotifications = '/p/sf/unplug/permission?state=notifications';
  /// Android permissions for Unplug (android)
  static const sfUnplugAuthAndroid = '/p/sf/unplug/permission?state=android';
  /// Choose apps
  static const sfUnplugApps = '/p/sf/unplug/apps';
  /// Apple app picker
  static const sfUnplugPickerIos = '/p/sf/unplug/apps/picker';
  /// Choose apps (Android) (android)
  static const sfUnplugAppsAndroid = '/p/sf/unplug/apps?state=android';
  /// Name your groups (apps chosen)
  static const sfUnplugAppsChosen = '/p/sf/unplug/apps?state=chosen';
  /// Limits & pause screen
  static const sfUnplugLimits = '/p/sf/unplug/limits';
  /// Unplug
  static const sfUnplugHome = '/p/sf/unplug/home';
  /// Start a focus session
  static const sfUnplugSession = '/p/sf/unplug/session';
  /// Focus session running
  static const sfUnplugSessionActive = '/p/sf/unplug/session/active';
  /// End session early
  static const sfUnplugSessionEnd = '/p/sf/unplug/session/end';
  /// Session complete
  static const sfUnplugSessionDone = '/p/sf/unplug/session/done';
  /// Session ended early (ended early)
  static const sfUnplugSessionDoneEarly = '/p/sf/unplug/session/done?state=early';
  /// Pause screen (iPhone shield)
  static const sfUnplugShield = '/system/unplug/shield';
  /// Pause screen (iPhone shield, firm) (no “open anyway” left)
  static const sfUnplugShieldFirm = '/system/unplug/shield?state=firm';
  /// Pause screen (Android overlay)
  static const sfUnplugOverlay = '/system/unplug/overlay';
  /// Small step: one breath
  static const sfUnplugGate = '/p/sf/unplug/step';
  /// Small step: type a sentence (typed sentence)
  static const sfUnplugGateCommit = '/p/sf/unplug/step?state=sentence';
  /// Small step: quick sum (quick sum)
  static const sfUnplugGateSum = '/p/sf/unplug/step?state=sum';
  /// Tracking check
  static const sfUnplugHealth = '/p/sf/unplug/health';
  /// Tracking check · notifications off (notifications off)
  static const sfUnplugHealthNotifications = '/p/sf/unplug/health?state=notifications';
  /// Tracking stopped (tracking stopped)
  static const sfUnplugHealthStopped = '/p/sf/unplug/health?state=stopped';
  /// Tracking check (Android) (android)
  static const sfUnplugHealthAndroid = '/p/sf/unplug/health?state=android';
  /// Turn off Unplug
  static const sfUnplugOff = '/p/sf/unplug/off';
  /// ScrollFree home · Unplug on (iPhone) (Unplug on · iPhone)
  static const sfHomeUnplug = '/p/sf/home?state=unplug';
  /// Weekly reflection · Unplug on (iPhone) (Unplug on · iPhone)
  static const sfWeekUnplug = '/p/sf/week?state=unplug';
  /// Program settings · ScrollFree with Unplug (ScrollFree)
  static const programSettingsSf = '/p/:program/settings?state=sf-unplug';
  /// Delete account · Apple account (Apple account)
  static const accountDeleteApple = '/account/delete?state=apple';
  /// Delete account · Google account (Google account)
  static const accountDeleteGoogle = '/account/delete?state=google';
  /// Session expired · Apple account (Apple account)
  static const authSessionApple = '/auth/session?state=apple';
  /// Session expired · Google account (Google account)
  static const authSessionGoogle = '/auth/session?state=google';
  /// Connect usage access (Android) (android)
  static const sfScreentimeAndroid = '/p/sf/screen-time?state=android';
  /// Usage access off (Android) (android · not allowed)
  static const sfScreentimeAndroidDenied = '/p/sf/screen-time?state=android-denied';
  /// Update required (Android) (android)
  static const sysUpdateAndroid = '/system/update?state=android';
  /// Home-screen widget (iPhone)
  static const surfaceWidgetIos = '/surface/widget/ios';
  /// Home-screen widget (Android)
  static const surfaceWidgetAndroid = '/surface/widget/android';
  /// Siri & App Shortcuts (iPhone)
  static const surfaceShortcutsIos = '/surface/shortcuts/ios';
  /// Siri & App Shortcuts (sensitive details on) (Show sensitive details on)
  static const surfaceShortcutsIosNamed = '/surface/shortcuts/ios?state=named';
  /// Launcher shortcuts (Android)
  static const surfaceShortcutsAndroid = '/surface/shortcuts/android';
  /// Launcher shortcuts (sensitive details on) (Show sensitive details on)
  static const surfaceShortcutsAndroidNamed = '/surface/shortcuts/android?state=named';
}
