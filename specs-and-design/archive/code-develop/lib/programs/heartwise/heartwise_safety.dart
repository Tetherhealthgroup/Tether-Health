// Safety copy and hard rules for the Heartwise program module.
//
// HARD RULES (encoded here and enforced by the UI):
// - The emergency card is permanent and always visible on the Heartwise
//   home screen: "Chest pain, pressure, or trouble breathing? Call
//   emergency services now." with a tel: link.
// - BP and cholesterol target ranges are clinician-provided ONLY. The app
//   never sets, suggests, or grades targets.
// - Readings are data, never a grade: no "good/bad" labels, no red
//   punitive styling, no judgmental copy.

abstract final class HeartwiseSafety {
  /// Permanent emergency card. Always visible on the Heartwise home screen.
  static const emergencyTitle = 'Emergency';
  static const emergencyBody =
      'Chest pain, pressure, or trouble breathing? Call emergency services now.';
  static const emergencyActionLabel = 'Call emergency services';

  /// TODO(srikanth): confirm the emergency number per region before release.
  /// US default; this must be configurable per market.
  static final emergencyUri = Uri(scheme: 'tel', path: '911');

  static const whenToCallDoctorTitle = 'When to call your doctor';
  static const whenToCallDoctorItems = <String>[
    'New or worsening symptoms your clinician asked you to watch for.',
    'You ran out of a medication or have questions about it.',
    'You want help understanding your readings or your plan.',
  ];

  /// Target ranges come from the clinician. The app never sets or grades
  /// them — readings are information, not a grade.
  static const targetsNote =
      'Target ranges come from your clinician. This app never sets or grades them — readings are information, not a grade.';
}
