class QuitPlanSupportPerson {
  const QuitPlanSupportPerson({
    required this.id,
    required this.name,
    required this.relationship,
    required this.channel,
    required this.checkIn,
    required this.enabled,
  });

  factory QuitPlanSupportPerson.fromJson(Map<String, Object?> json) =>
      QuitPlanSupportPerson(
        id: json['id']! as String,
        name: json['name']! as String,
        relationship: json['relationship']! as String,
        channel: json['channel']! as String,
        checkIn: json['checkIn']! as String,
        enabled: json['enabled']! as bool,
      );

  final String id;
  final String name;
  final String relationship;
  final String channel;
  final String checkIn;
  final bool enabled;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'channel': channel,
        'checkIn': checkIn,
        'enabled': enabled,
      };
}

class QuitPlan {
  const QuitPlan({
    required this.userId,
    required this.dailyCigaretteUse,
    required this.smokingTriggers,
    required this.customSmokingTrigger,
    required this.readinessPath,
    required this.quitPlanPath,
    required this.quitDate,
    required this.quitDayCheckIn,
    required this.quitReasons,
    required this.customQuitReason,
    required this.topQuitReason,
    required this.supportPeople,
    required this.preparationTasks,
    required this.treatmentSupport,
    required this.careTeamReminder,
    this.createdAt,
    this.updatedAt,
  });

  factory QuitPlan.fromJson(Map<String, Object?> json) => QuitPlan(
        userId: json['userId']! as String,
        dailyCigaretteUse: json['dailyCigaretteUse'] as String?,
        smokingTriggers: _strings(json['smokingTriggers']),
        customSmokingTrigger: json['customSmokingTrigger'] as String?,
        readinessPath: json['readinessPath']! as String,
        quitPlanPath: json['quitPlanPath']! as String,
        quitDate: DateTime.parse(json['quitDate']! as String),
        quitDayCheckIn: json['quitDayCheckIn']! as bool,
        quitReasons: _strings(json['quitReasons']),
        customQuitReason: json['customQuitReason'] as String?,
        topQuitReason: json['topQuitReason'] as String?,
        supportPeople: (json['supportPeople']! as List<Object?>)
            .map((value) =>
                QuitPlanSupportPerson.fromJson(value! as Map<String, Object?>))
            .toList(growable: false),
        preparationTasks: _strings(json['preparationTasks']),
        treatmentSupport: json['treatmentSupport']! as bool,
        careTeamReminder: json['careTeamReminder']! as bool,
        createdAt: _dateTime(json['createdAt']),
        updatedAt: _dateTime(json['updatedAt']),
      );

  final String userId;
  final String? dailyCigaretteUse;
  final List<String> smokingTriggers;
  final String? customSmokingTrigger;
  final String readinessPath;
  final String quitPlanPath;
  final DateTime quitDate;
  final bool quitDayCheckIn;
  final List<String> quitReasons;
  final String? customQuitReason;
  final String? topQuitReason;
  final List<QuitPlanSupportPerson> supportPeople;
  final List<String> preparationTasks;
  final bool treatmentSupport;
  final bool careTeamReminder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toRequestJson() => {
        'dailyCigaretteUse': dailyCigaretteUse,
        'smokingTriggers': smokingTriggers,
        'customSmokingTrigger': customSmokingTrigger,
        'readinessPath': readinessPath,
        'quitPlanPath': quitPlanPath,
        'quitDate': _date(quitDate),
        'quitDayCheckIn': quitDayCheckIn,
        'quitReasons': quitReasons,
        'customQuitReason': customQuitReason,
        'topQuitReason': topQuitReason,
        'supportPeople':
            supportPeople.map((person) => person.toJson()).toList(),
        'preparationTasks': preparationTasks,
        'treatmentSupport': treatmentSupport,
        'careTeamReminder': careTeamReminder,
      };
}

List<String> _strings(Object? value) =>
    (value! as List<Object?>).cast<String>().toList(growable: false);

DateTime? _dateTime(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
