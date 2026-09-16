/// Every way BreatheFree can put a person in touch with help.
///
/// These values were previously written out at each place they were used —
/// the quitline name in `tap_target.dart` and the same service's number in
/// `main.dart`, with nothing tying the two together. For ordinary copy that is
/// untidy; for a safety route it is a defect, because a number can be corrected
/// in one file and left stale in another.
///
/// Values are taken from the approved artwork at
/// `design/approved/screen-27-support-hub-iphone.svg`, except [supportEmail],
/// which is the product's own support address.
library;

/// A telephone quitline, as presented on the approved Support hub screen.
class QuitlineContact {
  const QuitlineContact({
    required this.language,
    required this.vanityNumber,
    required this.dialledNumber,
    required this.telUri,
  });

  /// Language the service is offered in, e.g. `English`.
  final String language;

  /// Memorable form shown to the patient, e.g. `1-800-QUIT-NOW`.
  final String vanityNumber;

  /// Digits actually dialled, e.g. `1-800-784-8669`.
  final String dialledNumber;

  /// E.164 form for a `tel:` URI, e.g. `+18007848669`.
  final String telUri;

  /// Both forms together, as the artwork presents the Spanish line.
  String get combinedLabel => '$vanityNumber · $dialledNumber';
}

/// Contact routes for help, support and emergencies.
abstract final class ContactInfo {
  /// Where a patient reaches the people who build and run BreatheFree.
  ///
  /// This is a product-support address, not a clinical one. Nothing sent here
  /// reaches a clinician, and it must never be offered as a route for urgent
  /// symptoms — [emergencyNumber] and [quitlines] cover those.
  static const String supportEmail = 'support@tetherhealthgroup.com';

  /// Emergency services number presented to the patient.
  ///
  /// United States only. Jurisdiction-specific emergency routing is an
  /// outstanding item on `PRODUCTION_RELEASE_CHECKLIST.md`.
  static const String emergencyNumber = '911';

  /// The national English-language quitline.
  static const QuitlineContact english = QuitlineContact(
    language: 'English',
    vanityNumber: '1-800-QUIT-NOW',
    dialledNumber: '1-800-784-8669',
    telUri: '+18007848669',
  );

  /// The national Spanish-language quitline.
  ///
  /// Present in the approved Support hub artwork but previously unreachable in
  /// code, which left a bilingual product with a monolingual safety route.
  static const QuitlineContact spanish = QuitlineContact(
    language: 'Español',
    vanityNumber: '1-855-DÉJELO-YA',
    dialledNumber: '1-855-335-3569',
    telUri: '+18553353569',
  );

  /// Every quitline, in the order the approved artwork lists them.
  static const List<QuitlineContact> quitlines = <QuitlineContact>[
    english,
    spanish,
  ];
}
