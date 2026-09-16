enum JourneyPhase {
  welcome('Welcome'),
  onboarding('Onboarding'),
  quitPlan('Quit plan'),
  dailySupport('Daily support'),
  cravingRescue('Craving rescue'),
  quitDay('Quit day'),
  resources('Resources'),
  account('Account');

  const JourneyPhase(this.label);
  final String label;
}

class ScreenSpec {
  const ScreenSpec({
    required this.number,
    required this.title,
    required this.description,
    required this.phase,
  });

  final int number;
  final String title;
  final String description;
  final JourneyPhase phase;

  String get assetPath {
    final padded = number.toString().padLeft(2, '0');
    return 'assets/screens/screen-$padded-${_slugFor(number)}-iphone.png';
  }
}

String _slugFor(int number) => switch (number) {
      1 => 'welcome',
      2 => 'why-tether-health',
      3 => 'consent-privacy',
      4 => 'baseline-assessment',
      5 => 'trigger-map',
      6 => 'readiness-result',
      7 => 'choose-quit-path',
      8 => 'select-quit-date',
      9 => 'my-reasons',
      10 => 'support-preparation',
      11 => 'review-quit-plan',
      12 => 'home-preparation',
      13 => 'daily-check-in',
      14 => 'personalized-next-step',
      15 => 'guided-stress-reset',
      16 => 'exercise-complete-recheck',
      17 => 'craving-rescue-start',
      18 => 'recommended-rescue-tool',
      19 => 'active-craving-rescue',
      20 => 'craving-recheck',
      21 => 'rescue-result-next-step',
      22 => 'quit-day-home',
      23 => 'slip-recovery',
      24 => 'medication-center',
      25 => 'learn-library',
      26 => 'progress-dashboard',
      27 => 'support-hub',
      28 => 'settings-privacy',
      _ => throw RangeError.range(number, 1, 28, 'number'),
    };

const approvedScreens = <ScreenSpec>[
  ScreenSpec(
    number: 1,
    title: 'Welcome',
    description: 'Introduces Tether Health, language choice and the private, judgment-free promise.',
    phase: JourneyPhase.welcome,
  ),
  ScreenSpec(
    number: 2,
    title: 'Why Tether Health',
    description: 'Explains how the app supports cravings, planning and progress.',
    phase: JourneyPhase.onboarding,
  ),
  ScreenSpec(
    number: 3,
    title: 'Consent & privacy',
    description:
        'Collects informed consent and explains data choices in plain language.',
    phase: JourneyPhase.onboarding,
  ),
  ScreenSpec(
    number: 4,
    title: 'Baseline assessment',
    description: 'Records current smoking patterns without judgment.',
    phase: JourneyPhase.onboarding,
  ),
  ScreenSpec(
    number: 5,
    title: 'Trigger map',
    description: 'Identifies situations and feelings linked to smoking.',
    phase: JourneyPhase.onboarding,
  ),
  ScreenSpec(
    number: 6,
    title: 'Readiness result',
    description: 'Reflects readiness and recommends a flexible next step.',
    phase: JourneyPhase.onboarding,
  ),
  ScreenSpec(
    number: 7,
    title: 'Choose quit path',
    description:
        'Lets the patient choose a quit-date or gradual-reduction path.',
    phase: JourneyPhase.quitPlan,
  ),
  ScreenSpec(
    number: 8,
    title: 'Select quit date',
    description: 'Selects a realistic quit date with planning guidance.',
    phase: JourneyPhase.quitPlan,
  ),
  ScreenSpec(
    number: 9,
    title: 'My reasons',
    description: 'Captures personal reasons the patient wants to quit.',
    phase: JourneyPhase.quitPlan,
  ),
  ScreenSpec(
    number: 10,
    title: 'Support preparation',
    description: 'Chooses a supporter and a specific help phrase.',
    phase: JourneyPhase.quitPlan,
  ),
  ScreenSpec(
    number: 11,
    title: 'Review quit plan',
    description: 'Reviews every plan choice before activation.',
    phase: JourneyPhase.quitPlan,
  ),
  ScreenSpec(
    number: 12,
    title: 'Preparation home',
    description:
        'Daily home before quit day with tasks, check-in and craving support.',
    phase: JourneyPhase.dailySupport,
  ),
  ScreenSpec(
    number: 13,
    title: 'Daily check-in',
    description:
        'Records a quick, nonpunitive daily status in under 90 seconds.',
    phase: JourneyPhase.dailySupport,
  ),
  ScreenSpec(
    number: 14,
    title: 'Personalized next step',
    description: 'Recommends one manageable action based on the check-in.',
    phase: JourneyPhase.dailySupport,
  ),
  ScreenSpec(
    number: 15,
    title: 'Guided stress reset',
    description: 'Runs a calm, guided breathing exercise.',
    phase: JourneyPhase.dailySupport,
  ),
  ScreenSpec(
    number: 16,
    title: 'Exercise complete & recheck',
    description:
        'Measures how the exercise felt and recommends what to do next.',
    phase: JourneyPhase.dailySupport,
  ),
  ScreenSpec(
    number: 17,
    title: 'Craving rescue start',
    description: 'Starts immediate, one-handed help that also works offline.',
    phase: JourneyPhase.cravingRescue,
  ),
  ScreenSpec(
    number: 18,
    title: 'Recommended rescue tool',
    description: 'Suggests a short coping tool matched to the craving.',
    phase: JourneyPhase.cravingRescue,
  ),
  ScreenSpec(
    number: 19,
    title: 'Active craving rescue',
    description: 'Guides the selected coping tool in real time.',
    phase: JourneyPhase.cravingRescue,
  ),
  ScreenSpec(
    number: 20,
    title: 'Craving recheck',
    description:
        'Rechecks craving intensity without claiming a clinical measurement.',
    phase: JourneyPhase.cravingRescue,
  ),
  ScreenSpec(
    number: 21,
    title: 'Rescue result & next step',
    description:
        'Shows the patient-reported change and offers another safe option.',
    phase: JourneyPhase.cravingRescue,
  ),
  ScreenSpec(
    number: 22,
    title: 'Quit-day home',
    description:
        'Supports the patient through quit day with immediate help and check-ins.',
    phase: JourneyPhase.quitDay,
  ),
  ScreenSpec(
    number: 23,
    title: 'Slip recovery',
    description:
        'Responds to a slip with support while preserving all prior progress.',
    phase: JourneyPhase.quitDay,
  ),
  ScreenSpec(
    number: 24,
    title: 'Medication center',
    description: 'Provides education and self-tracking without prescribing.',
    phase: JourneyPhase.resources,
  ),
  ScreenSpec(
    number: 25,
    title: 'Learn library',
    description:
        'Offers clinically reviewed, plain-language learning resources.',
    phase: JourneyPhase.resources,
  ),
  ScreenSpec(
    number: 26,
    title: 'Progress dashboard',
    description: 'Shows patterns and estimates without punishment after slips.',
    phase: JourneyPhase.resources,
  ),
  ScreenSpec(
    number: 27,
    title: 'Support hub',
    description:
        'Connects the patient to quitlines, supporters, coaches and care teams.',
    phase: JourneyPhase.resources,
  ),
  ScreenSpec(
    number: 28,
    title: 'Settings & privacy',
    description:
        'Centralizes notification privacy, consent, exports, accessibility and deletion.',
    phase: JourneyPhase.account,
  ),
];
