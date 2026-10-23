// Safety copy and hard rules for the ClearAir (asthma) program module.
//
// HARD RULES (encoded here and enforced by the UI):
// - The red route is always visible from the ClearAir home screen.
// - Red zone always means: follow your red-zone plan and seek urgent care.
// - Action-plan zones are clinician-recorded — the app never decides a
//   zone clinically; it shows the plan's guidance for the zone the user
//   identifies from their own plan.
// - NEVER any smoking-cessation content in this module. Asthma support
//   here is about following the clinician's action plan.

import 'models/action_plan.dart';

abstract final class ClearAirSafety {
  /// The red route is always visible from the ClearAir home screen.
  static const redZoneButtonLabel = 'Red-zone plan';
  static const redZoneHeading = 'Red zone — act now';
  static const redZoneBody =
      'Follow your red-zone plan and seek urgent care now.';
  static const urgentCareActionLabel = 'Contact urgent care now';

  /// TODO(srikanth): configure the urgent-care / clinic number before
  /// release. US default for now.
  static final defaultUrgentCareUri = Uri(scheme: 'tel', path: '911');

  /// Zone guidance mirrors the user's own action plan. The app shows the
  /// guidance for the zone the user identifies — it does not determine
  /// zones clinically.
  static const greenZoneGuidance =
      'You are in your green zone. Follow your green-zone routine exactly as written in your action plan.';
  static const yellowZoneGuidance =
      'You are in your yellow zone. Follow the yellow-zone steps in your action plan, and let your clinician or care team know as your plan directs.';
  static const redZoneGuidance =
      'You are in your red zone. Follow your red-zone plan and seek urgent care now.';

  static String guidanceFor(ActionPlanZone zone) => switch (zone) {
        ActionPlanZone.green => greenZoneGuidance,
        ActionPlanZone.yellow => yellowZoneGuidance,
        ActionPlanZone.red => redZoneGuidance,
      };

  static const symptomOptions = <String>[
    'Coughing',
    'Wheezing',
    'Shortness of breath',
    'Chest tightness',
    'Waking at night with symptoms',
  ];
}
