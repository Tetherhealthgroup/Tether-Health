// Safety copy and hard rules for the Steady (diabetes) program module.
//
// HARD RULES (encoded here and enforced by the UI):
// - NO calorie counting anywhere in Steady: no calorie fields, no
//   food-calorie inputs, no "burn it off" / compensation language.
// - Missing readings are NEVER converted to zero.
// - High readings are data, not failure: no red "bad" grading, no
//   punitive copy.
// - Target ranges are set by the clinician; the app never invents one.

abstract final class SteadySafety {
  /// No calorie counting here — enforced by simply having no calorie
  /// fields, inputs, or language anywhere in this module.
  static const noCaloriesNote = 'Steady never counts calories.';

  /// Readings are information, not a grade. A high reading is not a
  /// failure.
  static const readingsAreDataNote =
      'Readings are information, not a grade. A high reading is not a failure.';

  /// The target range is recorded from the clinician or care team — the
  /// app never invents one.
  static const clinicianTargetsNote =
      'Your target range is set by your clinician. This app never invents one.';

  /// Gentle guidance for the energy-reset rescue flow. No calories, no
  /// compensation language.
  static const resetSteps = <String>[
    'Drink a glass of water.',
    'Sit and rest for a few minutes.',
    'Take five slow breaths.',
    'If you feel unwell, contact your clinician or a support person.',
  ];
}
